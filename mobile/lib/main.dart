import "package:flutter/material.dart";

import "app_theme.dart";
import "screens/login_screen.dart";
import "screens/dentist_dashboard_screen.dart";
import "screens/patient_dashboard_screen.dart";
import "services/appointment_service.dart";
import "state/app_provider.dart";
import "services/auth_service.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = await AppProvider.openHive();
  runApp(DentaproApp(appProvider: provider));
}

class DentaproApp extends StatefulWidget {
  const DentaproApp({
    super.key,
    this.appProvider,
    this.authRepository,
    this.appointmentsRepository,
  });

  final AppProvider? appProvider;
  final AuthRepository? authRepository;
  final AppointmentDashboardRepository? appointmentsRepository;

  @override
  State<DentaproApp> createState() => _DentaproAppState();
}

class _DentaproAppState extends State<DentaproApp> {
  late final AppProvider _provider =
      widget.appProvider ?? AppProvider.inMemory();

  @override
  void dispose() {
    if (widget.appProvider == null) _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppProviderScope(
      provider: _provider,
      child: MaterialApp(
        title: "Dentapro",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: _DentaproHome(
          authRepository: widget.authRepository,
          appointmentsRepository: widget.appointmentsRepository,
        ),
      ),
    );
  }
}

class _DentaproHome extends StatelessWidget {
  const _DentaproHome({
    this.authRepository,
    this.appointmentsRepository,
  });

  final AuthRepository? authRepository;
  final AppointmentDashboardRepository? appointmentsRepository;

  @override
  Widget build(BuildContext context) {
    final provider = AppProviderScope.of(context);
    if (!provider.isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = provider.currentUser;
    if (user == null) {
      return LoginScreen(
        authRepository: authRepository,
        appointmentsRepository: appointmentsRepository,
      );
    }
    return switch (user.role) {
      "paciente" => PatientDashboardScreen(
          displayName: user.name,
          demoPatient: provider.isDemoMode ? provider.currentPatient : null,
          demoAppointments: provider.appointments,
          appointmentsRepository: appointmentsRepository,
        ),
      "dentista" => DentistDashboardScreen(
          appointmentsRepository: appointmentsRepository,
        ),
      _ => LoginScreen(
          authRepository: authRepository,
          appointmentsRepository: appointmentsRepository,
        ),
    };
  }
}
