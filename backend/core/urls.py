from django.urls import path

from core.branding import TenantBrandingView
from core.clinics import ClinicDirectoryView
from core.scheduling import AppointmentListCreateView, ClinicAvailabilityView

urlpatterns = [
    path("clinics/", ClinicDirectoryView.as_view(), name="clinic-directory"),
    path(
        "clinics/<slug:slug>/availability/",
        ClinicAvailabilityView.as_view(),
        name="clinic-availability",
    ),
    path(
        "appointments/",
        AppointmentListCreateView.as_view(),
        name="appointments",
    ),
    path("tenant/branding/", TenantBrandingView.as_view(), name="tenant-branding"),
]
