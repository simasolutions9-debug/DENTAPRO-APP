import "../services/appointment_service.dart";
import "../services/clinic_service.dart";

class DemoPatient {
  const DemoPatient({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
}

const demoPatient = DemoPatient(
  id: "demo-patient",
  name: "Paciente Demo",
  email: "paciente.demo@dentapro.local",
  phone: "099 000 0000",
);

List<AppointmentSummary> buildDemoAppointments() {
  final today = DateTime.now();
  final clinic = "Clínica Sonrisa";
  return [
    AppointmentSummary(
      id: "demo-appointment-past",
      patientId: demoPatient.id,
      patientName: demoPatient.name,
      clinicSlug: "clinica-sonrisa-demo",
      clinicName: clinic,
      scheduledAt: DateTime(today.year, today.month, today.day - 45, 11),
      durationMinutes: 30,
      status: "completed",
      reason: "Limpieza y revisión",
      estimatedFee: 35,
    ),
    AppointmentSummary(
      id: "demo-appointment-next",
      patientId: demoPatient.id,
      patientName: demoPatient.name,
      clinicSlug: "clinica-sonrisa-demo",
      clinicName: clinic,
      scheduledAt: DateTime(today.year, today.month, today.day + 3, 10, 30),
      durationMinutes: 30,
      status: "confirmed",
      reason: "Control de rutina",
      estimatedFee: 45,
    ),
  ];
}

class DemoClinicRepository implements ClinicRepository {
  const DemoClinicRepository();

  @override
  Future<List<ClinicListing>> fetchClinics() async => const [
        ClinicListing(
          slug: "clinica-sonrisa-demo",
          name: "Clínica Sonrisa",
        ),
      ];
}

class DemoClinicAvailabilityRepository implements ClinicAvailabilityRepository {
  const DemoClinicAvailabilityRepository();

  @override
  Future<List<ClinicSlot>> fetchAvailability({
    required String clinicSlug,
    required DateTime date,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    return [
      ClinicSlot(
        id: "demo-slot-1000",
        startsAt: day.add(const Duration(hours: 10)),
        durationMinutes: 30,
        estimatedFee: 35,
      ),
      ClinicSlot(
        id: "demo-slot-1130",
        startsAt: day.add(const Duration(hours: 11, minutes: 30)),
        durationMinutes: 30,
        estimatedFee: 45,
      ),
    ];
  }
}
