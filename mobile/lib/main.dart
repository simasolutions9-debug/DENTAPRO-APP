import "package:flutter/material.dart";

import "app_theme.dart";
import "screens/login_screen.dart";
import "services/appointment_service.dart";
import "services/auth_service.dart";

void main() {
  runApp(const DentaproApp());
}

class DentaproApp extends StatelessWidget {
  const DentaproApp({
    super.key,
    this.authRepository,
    this.appointmentsRepository,
  });

  final AuthRepository? authRepository;
  final AppointmentDashboardRepository? appointmentsRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Dentapro",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: LoginScreen(
        authRepository: authRepository,
        appointmentsRepository: appointmentsRepository,
      ),
    );
  }
}
