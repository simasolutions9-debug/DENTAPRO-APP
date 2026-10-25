from django.db import connection, transaction
from rest_framework import serializers
from rest_framework.exceptions import AuthenticationFailed
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer


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
        return token
