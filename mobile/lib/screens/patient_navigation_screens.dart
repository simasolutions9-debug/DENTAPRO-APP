import "package:flutter/material.dart";

import "../demo/demo_data.dart";
import "../services/appointment_service.dart";
import "../services/clinic_service.dart";
import "clinic_catalog_screen.dart";
import "patient_secondary_screens.dart";

class SearchScreen extends StatelessWidget {
  const SearchScreen({
    super.key,
    this.clinicRepository,
    this.availabilityRepository,
  });

  final ClinicRepository? clinicRepository;
  final ClinicAvailabilityRepository? availabilityRepository;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
        key: const Key("search-screen"),
        child: ClinicCatalogScreen(
          clinicRepository: clinicRepository,
          availabilityRepository: availabilityRepository,
        ),
      );
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    super.key,
    this.patient,
    this.appointments = const [],
  });

  final DemoPatient? patient;
  final List<AppointmentSummary> appointments;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
        key: const Key("notifications-route-screen"),
        child: PatientNotificationsScreen(
          patient: patient,
          appointments: appointments,
        ),
      );
}

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({
    super.key,
    required this.appointments,
    this.patient,
  });

  final DemoPatient? patient;
  final List<AppointmentSummary> appointments;

  @override
  Widget build(BuildContext context) => Scaffold(
        key: const Key("appointments-route-screen"),
        appBar: _backAppBar(context, "Citas"),
        body: PatientAppointmentsTab(
          patient: patient,
          appointments: appointments,
        ),
      );
}

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({
    super.key,
    required this.appointments,
    this.patient,
    this.onLogout,
  });

  final DemoPatient? patient;
  final List<AppointmentSummary> appointments;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) => Scaffold(
        key: const Key("user-profile-route-screen"),
        appBar: _backAppBar(context, "Perfil"),
        body: PatientProfileTab(
          patient: patient,
          appointments: appointments,
          onLogout: onLogout,
        ),
      );
}

AppBar _backAppBar(BuildContext context, String title) => AppBar(
      leading: IconButton(
        tooltip: "Volver",
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text(title),
    );
