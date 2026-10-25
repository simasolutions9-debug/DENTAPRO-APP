from django.urls import path

from core.branding import TenantBrandingView
from core.clinics import ClinicDirectoryView

urlpatterns = [
    path("clinics/", ClinicDirectoryView.as_view(), name="clinic-directory"),
    path("tenant/branding/", TenantBrandingView.as_view(), name="tenant-branding"),
]
