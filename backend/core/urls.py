from django.urls import path

from core.branding import TenantBrandingView

urlpatterns = [
    path("tenant/branding/", TenantBrandingView.as_view(), name="tenant-branding"),
]
