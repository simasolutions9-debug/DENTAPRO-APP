import "package:flutter/material.dart";

import "app_theme.dart";
import "screens/login_screen.dart";
import "services/auth_service.dart";

void main() {
  runApp(const DentaproApp());
}

class DentaproApp extends StatelessWidget {
  const DentaproApp({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Dentapro",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: LoginScreen(authRepository: authRepository),
    );
  }
}
