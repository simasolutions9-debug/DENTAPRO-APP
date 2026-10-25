import uuid

from django.db import connection, transaction
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import AccessToken


class TenantRLSMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        tenant_id = self._tenant_id_from_authorization(request)
        if tenant_id is None:
            return self.get_response(request)

        with transaction.atomic():
            with connection.cursor() as cursor:
                cursor.execute(
                    "SELECT set_config('app.current_tenant', %s, true)",
                    [tenant_id],
                )
            return self.get_response(request)

    @staticmethod
    def _tenant_id_from_authorization(request):
        authorization = request.headers.get("Authorization", "")
        parts = authorization.split()
        if len(parts) != 2 or parts[0].lower() != "bearer":
            return None

        try:
            token = AccessToken(parts[1])
            tenant_id = token.get("tenant_id")
            return str(uuid.UUID(str(tenant_id))) if tenant_id else None
        except (TokenError, TypeError, ValueError):
            return None
