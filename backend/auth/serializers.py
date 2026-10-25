from django.db import connection, transaction
from rest_framework import serializers
from rest_framework.exceptions import AuthenticationFailed
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from auth.models import User
from core.models import Paciente, Tenant


class PatientRegistrationSerializer(serializers.Serializer):
    first_name = serializers.CharField(max_length=100, trim_whitespace=True)
    last_name = serializers.CharField(max_length=100, trim_whitespace=True)
    email = serializers.EmailField()
    password = serializers.CharField(
        write_only=True,
        min_length=8,
        trim_whitespace=False,
        error_messages={
            "min_length": "La contraseña debe tener al menos 8 caracteres."
        },
    )
    phone = serializers.CharField(
        max_length=32,
        required=False,
        allow_blank=True,
        default="",
    )

    def validate_email(self, value):
        return value.strip().lower()

    def create(self, validated_data):
        tenant = validated_data.pop("tenant")
        first_name = validated_data.pop("first_name")
        last_name = validated_data.pop("last_name")
        phone = validated_data.pop("phone", "")
        password = validated_data.pop("password")
        email = validated_data["email"]

        user = User.objects.create_user(
            email=email,
            password=password,
            role=User.Role.PATIENT,
            tenant=tenant,
        )
        Paciente.objects.create(
            tenant=tenant,
            first_name=first_name,
            last_name=last_name,
            email=email,
            phone=phone,
        )
        return user


class TenantTokenObtainPairSerializer(TokenObtainPairSerializer):
    tenant_id = serializers.UUIDField(
        write_only=True,
        error_messages={
            "invalid": "El identificador del tenant debe ser un UUID válido.",
            "required": "El identificador del tenant es obligatorio.",
        },
    )
    default_error_messages = {
        "no_active_account": "Credenciales incorrectas o cuenta inactiva."
    }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields["email"].error_messages.update(
            {
                "required": "El correo electrónico es obligatorio.",
                "blank": "El correo electrónico no puede estar vacío.",
            }
        )
        self.fields["password"].error_messages.update(
            {
                "required": "La contraseña es obligatoria.",
                "blank": "La contraseña no puede estar vacía.",
            }
        )

    def validate(self, attrs):
        tenant_id = str(attrs["tenant_id"])
        with transaction.atomic():
            with connection.cursor() as cursor:
                cursor.execute(
                    "SELECT set_config('app.current_tenant', %s, true)",
                    [tenant_id],
                )
            try:
                data = super().validate(attrs)
            except AuthenticationFailed as exc:
                raise AuthenticationFailed(
                    "Credenciales incorrectas o cuenta inactiva."
                ) from exc
        return data

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token["tenant_id"] = str(user.tenant_id)
        token["role"] = user.role
        patient_id = Paciente.objects.filter(
            tenant_id=user.tenant_id,
            email__iexact=user.email,
        ).values_list("id", flat=True).first()
        token["patient_id"] = str(patient_id) if patient_id else None
        return token
