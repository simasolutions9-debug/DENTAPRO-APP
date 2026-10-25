import "package:flutter/material.dart";

import "../app_theme.dart";
import "../widgets/dentapro_logo.dart";
import "patient_dashboard_screen.dart";

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _openPatientDashboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PatientDashboardScreen()),
    );
  }

  void _showDentistNotice(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text("El acceso para odontólogos estará disponible pronto."),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        const DentaproLogo(markSize: 100, wordmarkSize: 34),
                        const SizedBox(height: 28),
                        Text(
                          "Tu sonrisa, en buenas manos",
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 21, color: AppColors.navy),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Todo el cuidado de tu salud dental,\nen un solo lugar.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 14, height: 1.55),
                        ),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _openPatientDashboard(context),
                            child: const Text("SOY PACIENTE"),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showDentistNotice(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blue,
                            ),
                            child: const Text("ACCESO ODONTÓLOGOS"),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 28),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 7,
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 15,
                              color: AppColors.teal,
                            ),
                            Text(
                              "Cuidamos de ti y de tu sonrisa",
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
