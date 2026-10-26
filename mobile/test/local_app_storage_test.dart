import "dart:io";

import "package:dentapro_mobile/services/appointment_service.dart";
import "package:dentapro_mobile/services/local_app_storage.dart";
import "package:dentapro_mobile/state/app_user.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";

void main() {
  test("Hive persists the active profile and local appointments", () async {
    final directory =
        await Directory.systemTemp.createTemp("dentapro-hive-test-");
    Hive.init(directory.path);
    try {
      final storage = await HiveLocalAppStorage.open();
      final user = AppUser(
        id: "patient-1",
        name: "Paciente Demo",
        email: "paciente@example.test",
        phone: "099 111 2222",
        role: "paciente",
        isDemo: true,
      );
      final appointment = AppointmentSummary(
        id: "local-appointment-1",
        patientId: user.id,
        patientName: user.name,
        clinicSlug: "clinica-sonrisa",
        clinicName: "Clínica Sonrisa",
        scheduledAt: DateTime(2026, 11, 3, 10, 30),
        durationMinutes: 30,
        status: "confirmed",
        estimatedFee: 45,
        reason: "Consulta dental",
      );

      await storage.saveCurrentUser(user);
      await storage.saveAppointment(appointment);
      await Hive.close();

      final reopenedStorage = await HiveLocalAppStorage.open();
      final restoredUser = await reopenedStorage.readCurrentUser();
      final restoredAppointments =
          await reopenedStorage.readAppointments(user.id);

      expect(restoredUser?.id, user.id);
      expect(restoredUser?.name, user.name);
      expect(restoredUser?.phone, user.phone);
      expect(restoredUser?.isDemo, isTrue);
      expect(restoredAppointments, hasLength(1));
      expect(restoredAppointments.single.id, appointment.id);
      expect(restoredAppointments.single.scheduledAt, appointment.scheduledAt);
      expect(restoredAppointments.single.estimatedFee, 45);
    } finally {
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });
}
