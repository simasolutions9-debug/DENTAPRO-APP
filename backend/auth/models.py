import uuid

from django.contrib.auth.base_user import AbstractBaseUser
from django.contrib.auth.models import PermissionsMixin
from django.db import models

from auth.managers import UserManager
from core.models import Tenant


class User(AbstractBaseUser, PermissionsMixin):
    class Role(models.TextChoices):
        ADMIN_SIMA = "admin_sima", "Platform administrator"
        DENTIST = "dentista", "Dentist"
        PATIENT = "paciente", "Patient"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.PROTECT,
        related_name="users",
    )
    email = models.EmailField(unique=True)
    role = models.CharField(max_length=24, choices=Role.choices)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(auto_now_add=True)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["tenant"]

    class Meta:
        db_table = "usuario"
        ordering = ["email"]

    def __str__(self) -> str:
        return self.email
