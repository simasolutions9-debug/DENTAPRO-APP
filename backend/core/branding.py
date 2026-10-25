from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from core.models import ClinicBranding

DEFAULT_BRANDING = {
    "nombre_clinica": "DENTAPRO",
    "color_primario": "#2563EB",
    "color_secundario": "#0F172A",
    "logo_url": None,
}


class TenantBrandingView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        slug = request.query_params.get("slug", "").strip()
        branding = ClinicBranding.objects.filter(slug=slug).first() if slug else None

        if branding is None:
            return Response(DEFAULT_BRANDING)

        return Response(
            {
                "nombre_clinica": branding.clinic_name,
                "color_primario": branding.primary_color,
                "color_secundario": branding.secondary_color,
                "logo_url": branding.logo_url or None,
            }
        )
