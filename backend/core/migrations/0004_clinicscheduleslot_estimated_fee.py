from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("core", "0003_clinic_schedule_slots"),
    ]

    operations = [
        migrations.AddField(
            model_name="clinicscheduleslot",
            name="estimated_fee",
            field=models.DecimalField(
                blank=True,
                decimal_places=2,
                max_digits=8,
                null=True,
                default=None,
            ),
        ),
    ]
