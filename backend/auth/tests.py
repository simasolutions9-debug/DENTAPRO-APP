import uuid
from contextlib import nullcontext
from types import SimpleNamespace
from unittest import TestCase
from unittest.mock import MagicMock, patch

from django.test import override_settings
from rest_framework.test import APIRequestFactory

from auth.views import PatientRegistrationView

_TENANT_ID = "10000000-0000-0000-0000-000000000001"


class PatientRegistrationViewTests(TestCase):
    def setUp(self):
        self.factory = APIRequestFactory()

    def test_production_does_not_create_a_missing_tenant(self):
        with (
            override_settings(
                DEBUG=False,
                DENTAPRO_DEFAULT_TENANT_ID=_TENANT_ID,
            ),
            patch(
                "auth.views.transaction.atomic",
                return_value=nullcontext(),
            ),
            patch("auth.views.Tenant.objects.get_or_create") as get_or_create,
            patch("auth.views.Tenant.objects.filter") as filter_tenant,
        ):
            filter_tenant.return_value.first.return_value = None
            request = self.factory.post(
                "/api/auth/register/",
                data={},
                format="json",
            )

            response = PatientRegistrationView.as_view()(request)

            self.assertEqual(response.status_code, 503)
            self.assertEqual(
                response.data["detail"],
                "El tenant predeterminado no está configurado.",
            )
            get_or_create.assert_not_called()

    def test_production_registers_with_the_existing_active_tenant(self):
        tenant = SimpleNamespace(
            pk=uuid.UUID(_TENANT_ID),
            is_active=True,
            name="Clínica de Producción",
        )
        cursor_context = MagicMock()
        user = SimpleNamespace(
            pk=uuid.UUID("20000000-0000-0000-0000-000000000001"),
            email="patient@example.com",
            role="paciente",
        )
        with (
            override_settings(
                DEBUG=False,
                DENTAPRO_DEFAULT_TENANT_ID=_TENANT_ID,
            ),
            patch(
                "auth.views.transaction.atomic",
                return_value=nullcontext(),
            ),
            patch("auth.views.Tenant.objects.filter") as filter_tenant,
            patch("auth.views.PatientRegistrationSerializer") as serializer_class,
            patch(
                "auth.views.connection.cursor",
                return_value=cursor_context,
            ),
        ):
            filter_tenant.return_value.first.return_value = tenant
            serializer = serializer_class.return_value
            serializer.save.return_value = user
            request = self.factory.post(
                "/api/auth/register/",
                data={"email": user.email},
                format="json",
            )

            response = PatientRegistrationView.as_view()(request)

            self.assertEqual(response.status_code, 201)
            self.assertEqual(response.data["tenant_id"], _TENANT_ID)
            self.assertEqual(response.data["role"], "paciente")
            serializer.save.assert_called_once_with(tenant=tenant)
            cursor_context.__enter__.return_value.execute.assert_called_once_with(
                "SELECT set_config('app.current_tenant', %s, true)",
                [_TENANT_ID],
            )
