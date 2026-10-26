import uuid

from django.db import models
from django.utils import timezone


class Tenant(models.Model):
    class Plan(models.TextChoices):
        FREE = "free", "Free"
        PRO = "pro", "Pro"
        ENTERPRISE = "enterprise", "Enterprise"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=160)
    is_active = models.BooleanField(default=True)
    plan = models.CharField(max_length=24, choices=Plan.choices, default=Plan.FREE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "tenant"
        ordering = ["name"]

    def __str__(self) -> str:
        return self.name


class ClinicBranding(models.Model):
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.CASCADE,
        related_name="brandings",
    )
    slug = models.SlugField(max_length=120, unique=True)
    clinic_name = models.CharField(max_length=160)
    primary_color = models.CharField(max_length=7, default="#2563EB")
    secondary_color = models.CharField(max_length=7, default="#0F172A")
    logo_url = models.URLField(max_length=500, blank=True)

    class Meta:
        db_table = "clinic_branding"
        ordering = ["clinic_name"]

    def __str__(self) -> str:
        return self.slug


class Paciente(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.PROTECT,
        db_column="tenant_id",
        related_name="patients",
    )
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    email = models.EmailField(blank=True)
    phone = models.CharField(max_length=32, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "paciente"
        ordering = ["last_name", "first_name"]

    def __str__(self) -> str:
        return f"{self.first_name} {self.last_name}"


class HistorialClinico(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.PROTECT,
        db_column="tenant_id",
        related_name="clinical_records",
    )
    patient = models.ForeignKey(
        Paciente,
        on_delete=models.PROTECT,
        related_name="clinical_records",
    )
    recorded_at = models.DateTimeField(default=timezone.now)
    diagnosis = models.TextField(blank=True)
    treatment = models.TextField(blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "historial_clinico"
        ordering = ["-recorded_at"]

    def __str__(self) -> str:
        return f"Clinical record for {self.patient}"


class ClinicScheduleSlot(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.CASCADE,
        db_column="tenant_id",
        related_name="schedule_slots",
    )
    starts_at = models.DateTimeField()
    duration_minutes = models.PositiveSmallIntegerField(default=30)
    estimated_fee = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        null=True,
        blank=True,
        default=None,
    )
    is_published = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "clinic_schedule_slot"
        ordering = ["starts_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["tenant", "starts_at"],
                name="uniq_clinic_slot_start",
            ),
        ]

    def __str__(self) -> str:
        return f"Slot for {self.tenant} at {self.starts_at}"


class Cita(models.Model):
    class Status(models.TextChoices):
        SCHEDULED = "scheduled", "Scheduled"
        CONFIRMED = "confirmed", "Confirmed"
        COMPLETED = "completed", "Completed"
        CANCELLED = "cancelled", "Cancelled"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.PROTECT,
        db_column="tenant_id",
        related_name="appointments",
    )
    patient = models.ForeignKey(
        Paciente,
        on_delete=models.PROTECT,
        related_name="appointments",
    )
    availability_slot = models.OneToOneField(
        ClinicScheduleSlot,
        on_delete=models.PROTECT,
        related_name="appointment",
        null=True,
        blank=True,
    )
    scheduled_at = models.DateTimeField()
    duration_minutes = models.PositiveSmallIntegerField(default=30)
    status = models.CharField(
        max_length=16,
        choices=Status.choices,
        default=Status.SCHEDULED,
    )
    reason = models.CharField(max_length=240, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "cita"
        ordering = ["scheduled_at"]

    def __str__(self) -> str:
        return f"Appointment for {self.patient} at {self.scheduled_at}"
