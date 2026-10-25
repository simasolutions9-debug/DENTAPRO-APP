import uuid

from django.conf import settings
from django.db import IntegrityError, connection, transaction
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from auth.models import User
from auth.serializers import (
    PatientRegistrationSerializer,
    TenantTokenObtainPairSerializer,
)
from core.models import Tenant

_DEMO_TENANT_NAME = "Clínica Dental Demo"


class TenantTokenObtainPairView(TokenObtainPairView):
    permission_classes = [AllowAny]
    authentication_classes = []
    serializer_class = TenantTokenObtainPairSerializer


class TenantTokenRefreshView(TokenRefreshView):
    permission_classes = [AllowAny]
    authentication_classes = []


class PatientRegistrationView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        try:
            with transaction.atomic():
                tenant_id = uuid.UUID(settings.DENTAPRO_DEFAULT_TENANT_ID)
                if settings.DEBUG:
                    tenant, _ = Tenant.objects.get_or_create(
                        pk=tenant_id,
                        defaults={"name": _DEMO_TENANT_NAME},
                    )
                    if tenant.name != _DEMO_TENANT_NAME:
                        return Response(
                            {"detail": "El tenant de desarrollo no está disponible."},
                            status=status.HTTP_409_CONFLICT,
                        )
                else:
                    tenant = Tenant.objects.filter(pk=tenant_id).first()
                    if tenant is None:
                        return Response(
                            {"detail": "El tenant predeterminado no está configurado."},
                            status=status.HTTP_503_SERVICE_UNAVAILABLE,
                        )

                if not tenant.is_active:
                    return Response(
                        {"detail": "El tenant predeterminado está inactivo."},
                        status=status.HTTP_409_CONFLICT,
                    )

                with connection.cursor() as cursor:
                    cursor.execute(
                        "SELECT set_config('app.current_tenant', %s, true)",
                        [str(tenant.pk)],
                    )

                serializer = PatientRegistrationSerializer(data=request.data)
                serializer.is_valid(raise_exception=True)
                user = serializer.save(tenant=tenant)
        except IntegrityError:
            return Response(
                {"email": ["Ya existe una cuenta con este correo electrónico."]},
                status=status.HTTP_400_BAD_REQUEST,
            )
        except ValueError:
            return Response(
                {"detail": "El identificador del tenant predeterminado no es válido."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        return Response(
            {
                "id": str(user.pk),
                "email": user.email,
                "role": user.role,
                "tenant_id": str(tenant.pk),
            },
            status=status.HTTP_201_CREATED,
        )
