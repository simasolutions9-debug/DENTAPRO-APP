from django.urls import path
from auth.views import TenantTokenObtainPairView, TenantTokenRefreshView

urlpatterns = [
    path("token/", TenantTokenObtainPairView.as_view(), name="token-obtain"),
    path("token/refresh/", TenantTokenRefreshView.as_view(), name="token-refresh"),
]
