from pathlib import Path

from django.conf import settings
from django.core.management.base import BaseCommand
from django.db import connection


class Command(BaseCommand):
    help = "Apply tenant row-level security to the user table."

    def handle(self, *args, **options):
        policy_file = settings.PROJECT_ROOT / "infra" / "rls_policies.sql"
        if not policy_file.is_file():
            raise FileNotFoundError(f"RLS policy file not found: {policy_file}")

        with connection.cursor() as cursor:
            cursor.execute(policy_file.read_text(encoding="utf-8"))

        self.stdout.write(self.style.SUCCESS("Tenant RLS policy applied."))
