import django.db.models.deletion
import uuid
from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("core", "0002_paciente_historialclinico_cita"),
    ]

    operations = [
        migrations.CreateModel(
            name="ClinicScheduleSlot",
            fields=[
                (
                    "id",
                    models.UUIDField(
                        default=uuid.uuid4,
                        editable=False,
                        primary_key=True,
                        serialize=False,
                    ),
                ),
                ("starts_at", models.DateTimeField()),
                ("duration_minutes", models.PositiveSmallIntegerField(default=30)),
                ("is_published", models.BooleanField(default=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "tenant",
                    models.ForeignKey(
                        db_column="tenant_id",
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="schedule_slots",
                        to="core.tenant",
                    ),
                ),
            ],
            options={
                "db_table": "clinic_schedule_slot",
                "ordering": ["starts_at"],
            },
        ),
        migrations.AddConstraint(
            model_name="clinicscheduleslot",
            constraint=models.UniqueConstraint(
                fields=("tenant", "starts_at"),
                name="uniq_clinic_slot_start",
            ),
        ),
        migrations.AddField(
            model_name="cita",
            name="availability_slot",
            field=models.OneToOneField(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.PROTECT,
                related_name="appointment",
                to="core.clinicscheduleslot",
            ),
        ),
    ]
