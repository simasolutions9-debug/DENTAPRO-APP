import uuid

from django.db import models


class Tenant(models.Model):
    class Plan(models.TextChoices):
        FREE = "free", "Free"
        PRO = "pro", "Pro"
        ENTERPRISE = "enterprise", "Enterprise"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=160)
    is_active = models.BooleanField(default=True)
    plan = models.CharField(max_length=24, choices=Plan.choices, default=Plan.FREE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "tenant"
        ordering = ["name"]

    def __str__(self) -> str:
        return self.name


class ClinicBranding(models.Model):
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.CASCADE,
        related_name="brandings",
    )
    slug = models.SlugField(max_length=120, unique=True)
    clinic_name = models.CharField(max_length=160)
    primary_color = models.CharField(max_length=7, default="#2563EB")
    secondary_color = models.CharField(max_length=7, default="#0F172A")
    logo_url = models.URLField(max_length=500, blank=True)

    class Meta:
        db_table = "clinic_branding"
        ordering = ["clinic_name"]

    def __str__(self) -> str:
        return self.slug
