from types import SimpleNamespace
from unittest.mock import patch

from django.test import SimpleTestCase
from rest_framework.test import APIRequestFactory

from core.branding import DEFAULT_BRANDING, TenantBrandingView
from core.clinics import ClinicDirectoryView


class TenantBrandingViewTests(SimpleTestCase):
    def setUp(self):
        self.factory = APIRequestFactory()

    def test_missing_slug_returns_default_branding(self):
        request = self.factory.get("/api/v1/tenant/branding/")

        response = TenantBrandingView.as_view()(request)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, DEFAULT_BRANDING)

    def test_public_branding_route_returns_default_without_authentication(self):
        response = self.client.get("/api/v1/tenant/branding/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), DEFAULT_BRANDING)

    def test_jwt_validation_error_is_in_spanish(self):
        response = self.client.post(
            "/api/v1/auth/token/",
            data={},
            content_type="application/json",
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(
            response.json()["detail"],
            "La solicitud contiene datos inválidos.",
        )

    @patch("core.branding.ClinicBranding.objects.filter")
    def test_unknown_slug_returns_default_branding(self, filter_branding):
        filter_branding.return_value.first.return_value = None
        request = self.factory.get(
            "/api/v1/tenant/branding/",
            {"slug": "unknown-clinic"},
        )

        response = TenantBrandingView.as_view()(request)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, DEFAULT_BRANDING)
        filter_branding.assert_called_once_with(slug="unknown-clinic")

    @patch("core.branding.ClinicBranding.objects.filter")
    def test_known_slug_returns_clinic_branding(self, filter_branding):
        filter_branding.return_value.first.return_value = SimpleNamespace(
            clinic_name="North Dental",
            primary_color="#123456",
            secondary_color="#654321",
            logo_url="https://example.test/logo.png",
        )
        request = self.factory.get(
            "/api/v1/tenant/branding/",
            {"slug": "north-dental"},
        )

        response = TenantBrandingView.as_view()(request)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.data,
            {
                "nombre_clinica": "North Dental",
                "color_primario": "#123456",
                "color_secundario": "#654321",
                "logo_url": "https://example.test/logo.png",
            },
        )


class ClinicDirectoryViewTests(SimpleTestCase):
    @patch("core.clinics.ClinicBranding.objects.filter")
    def test_lists_active_clinics_with_public_branding_only(self, filter_branding):
        branding_query = filter_branding.return_value
        branding_query.values.return_value = [
            {
                "tenant_id": "clinic-tenant-id",
                "slug": "north-dental",
                "clinic_name": "North Dental",
                "logo_url": "https://example.test/logo.png",
                "primary_color": "#123456",
                "secondary_color": "#654321",
            }
        ]

        request = APIRequestFactory().get("/api/v1/clinics/")
        response = ClinicDirectoryView.as_view()(request)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.data,
            [
                {
                    "tenant_id": "clinic-tenant-id",
                    "slug": "north-dental",
                    "name": "North Dental",
                    "logo_url": "https://example.test/logo.png",
                    "primary_color": "#123456",
                    "secondary_color": "#654321",
                }
            ],
        )
        filter_branding.assert_called_once_with(tenant__is_active=True)
