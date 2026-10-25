from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from core.models import ClinicBranding


class ClinicDirectoryView(APIView):
    """Public directory of active clinics with explicitly public branding only."""

    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        branding_records = ClinicBranding.objects.filter(
            tenant__is_active=True,
        ).values(
            "tenant_id",
            "slug",
            "clinic_name",
            "logo_url",
            "primary_color",
            "secondary_color",
        )
        return Response(
            [
                {
                    "tenant_id": str(record["tenant_id"]),
                    "slug": record["slug"],
                    "name": record["clinic_name"],
                    "logo_url": record["logo_url"] or None,
                    "primary_color": record["primary_color"],
                    "secondary_color": record["secondary_color"],
                }
                for record in branding_records
            ]
        )
