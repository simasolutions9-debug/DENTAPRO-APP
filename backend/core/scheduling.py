from datetime import datetime, time, timedelta
from decimal import Decimal, InvalidOperation

from django.db import IntegrityError, connection, transaction
from django.utils import timezone
from django.utils.dateparse import parse_date, parse_datetime
from rest_framework import status
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.models import Cita, ClinicBranding, ClinicScheduleSlot, Paciente, Tenant


def _set_tenant_context(tenant_id):
    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT set_config('app.current_tenant', %s, true)",
            [str(tenant_id)],
        )


def _clinic_for_slug(slug):
    try:
        return ClinicBranding.objects.select_related("tenant").get(
            slug=slug,
            tenant__is_active=True,
        )
    except ClinicBranding.DoesNotExist as exc:
        raise NotFound("La clínica solicitada no existe.") from exc


def _slot_payload(slot):
    return {
        "id": str(slot.id),
        "starts_at": timezone.localtime(slot.starts_at).isoformat(),
        "duration_minutes": slot.duration_minutes,
        "estimated_fee": (
            format(slot.estimated_fee, ".2f")
            if slot.estimated_fee is not None
            else None
        ),
    }


def _has_conflicting_appointment(slot):
    slot_end = slot.starts_at + timedelta(minutes=slot.duration_minutes)
    appointments = Cita.objects.filter(
        tenant_id=slot.tenant_id,
        status__in=(Cita.Status.SCHEDULED, Cita.Status.CONFIRMED),
        scheduled_at__lt=slot_end,
        scheduled_at__gte=slot.starts_at - timedelta(minutes=240),
    )
    return any(
        appointment.scheduled_at
        + timedelta(minutes=appointment.duration_minutes)
        > slot.starts_at
        for appointment in appointments
    )


class ClinicAvailabilityView(APIView):
    def get_permissions(self):
        permission = AllowAny if self.request.method == "GET" else IsAuthenticated
        return [permission()]

    def get(self, request, slug):
        selected_date = parse_date(request.query_params.get("date", ""))
        if selected_date is None:
            raise ValidationError(
                {"date": "Envía una fecha válida con formato YYYY-MM-DD."}
            )

        clinic = _clinic_for_slug(slug)
        start_of_day = timezone.make_aware(
            datetime.combine(selected_date, time.min)
        )
        start_of_next_day = start_of_day + timedelta(days=1)
        with transaction.atomic():
            _set_tenant_context(clinic.tenant_id)
            candidate_slots = list(
                ClinicScheduleSlot.objects.filter(
                    tenant=clinic.tenant,
                    is_published=True,
                    starts_at__gte=start_of_day,
                    starts_at__lt=start_of_next_day,
                    starts_at__gt=timezone.now(),
                    appointment__isnull=True,
                ).order_by("starts_at")
            )
            slots = [
                slot
                for slot in candidate_slots
                if not _has_conflicting_appointment(slot)
            ]

        return Response({"slots": [_slot_payload(slot) for slot in slots]})

    def post(self, request, slug):
        clinic = _clinic_for_slug(slug)
        role = getattr(request.user, "role", "")
        is_platform_admin = role == "admin_sima"
        if role != "dentista" and not is_platform_admin:
            raise PermissionDenied("Solo una clínica puede publicar horarios.")
        if not is_platform_admin and request.user.tenant_id != clinic.tenant_id:
            raise PermissionDenied(
                "Solo puedes publicar horarios para tu propia clínica."
            )

        starts_at = parse_datetime(str(request.data.get("starts_at", "")))
        if starts_at is None or timezone.is_naive(starts_at):
            raise ValidationError(
                {"starts_at": "Envía la fecha y hora con zona horaria."}
            )
        if starts_at <= timezone.now():
            raise ValidationError({"starts_at": "El horario debe ser futuro."})

        try:
            duration = int(request.data.get("duration_minutes", 30))
        except (TypeError, ValueError) as exc:
            raise ValidationError(
                {"duration_minutes": "La duración debe ser un número entero."}
            ) from exc
        if duration < 15 or duration > 240:
            raise ValidationError(
                {"duration_minutes": "La duración debe estar entre 15 y 240 minutos."}
            )

        fee_value = request.data.get("estimated_fee")
        if fee_value in (None, ""):
            estimated_fee = None
        else:
            try:
                estimated_fee = Decimal(str(fee_value))
            except (InvalidOperation, TypeError, ValueError) as exc:
                raise ValidationError(
                    {"estimated_fee": "Envía una tarifa válida en dólares."}
                ) from exc
            if (
                not estimated_fee.is_finite()
                or estimated_fee < Decimal("0.00")
                or estimated_fee > Decimal("999999.99")
                or estimated_fee.as_tuple().exponent < -2
            ):
                raise ValidationError(
                    {"estimated_fee": "La tarifa debe estar entre $0.00 y $999999.99."}
                )

        slot_end = starts_at + timedelta(minutes=duration)
        try:
            with transaction.atomic():
                _set_tenant_context(clinic.tenant_id)
                Tenant.objects.select_for_update().get(pk=clinic.tenant_id)
                overlapping_slots = ClinicScheduleSlot.objects.filter(
                    tenant=clinic.tenant,
                    is_published=True,
                    starts_at__gte=starts_at - timedelta(minutes=240),
                    starts_at__lt=slot_end,
                )
                for existing in overlapping_slots:
                    existing_end = existing.starts_at + timedelta(
                        minutes=existing.duration_minutes
                    )
                    if existing_end > starts_at:
                        return Response(
                            {"detail": "Ese horario se superpone con otro publicado."},
                            status=status.HTTP_409_CONFLICT,
                        )

                slot = ClinicScheduleSlot.objects.create(
                    tenant=clinic.tenant,
                    starts_at=starts_at,
                    duration_minutes=duration,
                    estimated_fee=estimated_fee,
                    is_published=True,
                )
        except IntegrityError:
            return Response(
                {"detail": "Ese horario ya está publicado."},
                status=status.HTTP_409_CONFLICT,
            )

        return Response(_slot_payload(slot), status=status.HTTP_201_CREATED)


def _appointment_payload(appointment, clinic=None):
    slot = appointment.availability_slot
    estimated_fee = slot.estimated_fee if slot is not None else None
    patient_name = str(appointment.patient)
    clinic_name = (
        clinic.clinic_name
        if clinic is not None
        else appointment.tenant.name
    )
    return {
        "id": str(appointment.id),
        "patient_id": str(appointment.patient_id),
        "patient_name": patient_name,
        "clinic_slug": clinic.slug if clinic is not None else "",
        "clinic_name": clinic_name,
        "scheduled_at": timezone.localtime(appointment.scheduled_at).isoformat(),
        "duration_minutes": appointment.duration_minutes,
        "status": appointment.status,
        "reason": appointment.reason,
        "estimated_fee": (
            format(estimated_fee, ".2f") if estimated_fee is not None else None
        ),
    }


class AppointmentListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        role = getattr(request.user, "role", "")
        if role == "paciente":
            return self._get_patient_appointments(request)
        if role == "dentista":
            return self._get_clinic_appointments(request)
        raise PermissionDenied("Este usuario no puede consultar estas citas.")

    def _get_patient_appointments(self, request):
        token_patient_id = request.auth.get("patient_id") if request.auth else None
        if not token_patient_id:
            raise PermissionDenied("La sesión no contiene un perfil de paciente.")
        patient = Paciente.objects.filter(
            pk=token_patient_id,
            tenant_id=request.user.tenant_id,
            email__iexact=request.user.email,
        ).first()
        if patient is None:
            raise PermissionDenied("La cuenta no tiene un perfil de paciente válido.")

        now = timezone.now()
        appointments = []
        with transaction.atomic():
            tenant_ids = list(Tenant.objects.values_list("id", flat=True))
            for tenant_id in tenant_ids:
                _set_tenant_context(tenant_id)
                clinic = ClinicBranding.objects.filter(
                    tenant_id=tenant_id,
                ).first()
                tenant_appointments = Cita.objects.filter(
                    tenant_id=tenant_id,
                    patient_id=patient.id,
                    status__in=(Cita.Status.SCHEDULED, Cita.Status.CONFIRMED),
                    scheduled_at__gte=now,
                ).select_related(
                    "patient",
                    "tenant",
                    "availability_slot",
                )
                appointments.extend(
                    (appointment, clinic) for appointment in tenant_appointments
                )
            _set_tenant_context(request.user.tenant_id)

        appointments.sort(key=lambda item: item[0].scheduled_at)
        return Response(
            [
                _appointment_payload(appointment, clinic)
                for appointment, clinic in appointments[:50]
            ]
        )

    def _get_clinic_appointments(self, request):
        start_date_value = request.query_params.get("from")
        end_date_value = request.query_params.get("to")
        single_date_value = request.query_params.get("date")
        if start_date_value or end_date_value:
            if not start_date_value or not end_date_value:
                raise ValidationError(
                    {"date": "Envía tanto 'from' como 'to' para consultar un rango."}
                )
            start_date = parse_date(start_date_value)
            end_date = parse_date(end_date_value)
        else:
            selected_date = (
                parse_date(single_date_value)
                if single_date_value
                else timezone.localdate()
            )
            start_date = selected_date
            end_date = selected_date

        if start_date is None or end_date is None:
            raise ValidationError(
                {"date": "Envía fechas válidas con formato YYYY-MM-DD."}
            )
        if end_date < start_date or (end_date - start_date).days > 30:
            raise ValidationError(
                {"date": "El rango debe ser válido y no superar 31 días."}
            )

        current_tenant_id = request.user.tenant_id
        start_at = timezone.make_aware(datetime.combine(start_date, time.min))
        end_at = timezone.make_aware(
            datetime.combine(end_date + timedelta(days=1), time.min)
        )
        with transaction.atomic():
            _set_tenant_context(current_tenant_id)
            clinic = ClinicBranding.objects.filter(
                tenant_id=current_tenant_id,
            ).first()
            appointments = (
                Cita.objects.filter(
                    tenant_id=current_tenant_id,
                    scheduled_at__gte=start_at,
                    scheduled_at__lt=end_at,
                    status__in=(
                        Cita.Status.SCHEDULED,
                        Cita.Status.CONFIRMED,
                        Cita.Status.COMPLETED,
                    ),
                )
                .select_related("patient", "tenant", "availability_slot")
                .order_by("scheduled_at")
            )
            payload = [
                _appointment_payload(appointment, clinic)
                for appointment in appointments
            ]
        return Response(payload)

    def post(self, request):
        if getattr(request.user, "role", "") != "paciente":
            raise PermissionDenied("Solo los pacientes pueden reservar citas.")

        token_patient_id = request.auth.get("patient_id") if request.auth else None
        supplied_patient_id = request.data.get("patient_id")
        if not token_patient_id or str(supplied_patient_id) != str(token_patient_id):
            raise PermissionDenied("El paciente no coincide con la sesión activa.")

        clinic_slug = request.data.get("clinic_slug")
        slot_id = request.data.get("slot_id")
        starts_at = parse_datetime(str(request.data.get("starts_at", "")))
        if not isinstance(clinic_slug, str) or not clinic_slug.strip():
            raise ValidationError({"clinic_slug": "Selecciona una clínica válida."})
        if not slot_id:
            raise ValidationError({"slot_id": "Selecciona un horario publicado."})
        if starts_at is None or timezone.is_naive(starts_at):
            raise ValidationError(
                {"starts_at": "Envía la fecha y hora con zona horaria."}
            )

        patient = Paciente.objects.filter(
            pk=token_patient_id,
            tenant_id=request.user.tenant_id,
            email__iexact=request.user.email,
        ).first()
        if patient is None:
            raise PermissionDenied("La cuenta no tiene un perfil de paciente válido.")
        clinic = _clinic_for_slug(clinic_slug)

        try:
            with transaction.atomic():
                _set_tenant_context(clinic.tenant_id)
                slot = (
                    ClinicScheduleSlot.objects.select_for_update()
                    .select_related("tenant")
                    .get(
                        pk=slot_id,
                        tenant=clinic.tenant,
                        is_published=True,
                        starts_at__gt=timezone.now(),
                    )
                )
                if slot.starts_at != starts_at:
                    raise ValidationError(
                        {"starts_at": "La fecha ya no coincide con el horario."}
                    )
                if Cita.objects.filter(availability_slot=slot).exists():
                    return Response(
                        {"detail": "Ese horario ya fue reservado. Elige otro."},
                        status=status.HTTP_409_CONFLICT,
                    )
                if _has_conflicting_appointment(slot):
                    return Response(
                        {"detail": "Ese horario se superpone con otra cita."},
                        status=status.HTTP_409_CONFLICT,
                    )

                appointment = Cita.objects.create(
                    tenant=slot.tenant,
                    patient=patient,
                    availability_slot=slot,
                    scheduled_at=slot.starts_at,
                    duration_minutes=slot.duration_minutes,
                )
        except ClinicScheduleSlot.DoesNotExist as exc:
            raise NotFound(
                "El horario ya no está disponible para esa clínica."
            ) from exc
        except IntegrityError:
            return Response(
                {"detail": "Ese horario acaba de ser reservado. Elige otro."},
                status=status.HTTP_409_CONFLICT,
            )

        return Response(
            {
                "id": str(appointment.id),
                "clinic_slug": clinic.slug,
                "clinic_name": clinic.clinic_name,
                "patient_id": str(patient.id),
                "scheduled_at": timezone.localtime(
                    appointment.scheduled_at
                ).isoformat(),
                "status": appointment.status,
            },
            status=status.HTTP_201_CREATED,
        )
