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
        if not settings.DEBUG:
            return Response(
                {"detail": "El registro de demostración solo está habilitado en desarrollo."},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            with transaction.atomic():
                tenant_id = uuid.UUID(settings.DENTAPRO_DEMO_TENANT_ID)
                tenant, _ = Tenant.objects.get_or_create(
                    pk=tenant_id,
                    defaults={"name": _DEMO_TENANT_NAME},
                )
                if tenant.name != _DEMO_TENANT_NAME or not tenant.is_active:
                    return Response(
                        {"detail": "El tenant de demostración no está disponible."},
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
                {"detail": "El identificador del tenant de demostración no es válido."},
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
