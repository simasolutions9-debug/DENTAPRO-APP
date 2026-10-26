import "package:flutter/material.dart";

import "../app_theme.dart";
import "../services/appointment_service.dart";
import "../services/auth_service.dart";
import "../state/app_provider.dart";
import "dentist_dashboard_screen.dart";
import "patient_dashboard_screen.dart";

class RoleDashboardScreen extends StatelessWidget {
  const RoleDashboardScreen({
    super.key,
    required this.loginBuilder,
    this.authRepository,
    this.appointmentsRepository,
  });

  final WidgetBuilder loginBuilder;
  final AuthRepository? authRepository;
  final AppointmentDashboardRepository? appointmentsRepository;

  Future<void> _logout(BuildContext context) async {
    final provider = AppProviderScope.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    Object? logoutError;
    try {
      await (authRepository ?? AuthService()).logout();
    } catch (error) {
      logoutError = error;
    }
    await provider.signOut();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: loginBuilder),
      (_) => false,
    );
    if (logoutError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text(
              "Se cerró la sesión, pero no se pudieron borrar todas las credenciales locales.",
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppProviderScope.of(context);
    final user = provider.currentUser;
    if (user == null) return loginBuilder(context);

    final onLogout = () => _logout(context);
    return switch (user.role) {
      "paciente" => PatientDashboardScreen(
          displayName: user.name,
          demoPatient: provider.isDemoMode ? provider.currentPatient : null,
          demoAppointments: provider.appointments,
          appointmentsRepository: appointmentsRepository,
          onLogout: onLogout,
        ),
      "dentista" => DentistDashboardScreen(
          appointmentsRepository: appointmentsRepository,
          onLogout: onLogout,
        ),
      "super_admin" => SuperAdminDashboard(
          onLogout: onLogout,
        ),
      "distribuidor" => DistributorDashboard(
          displayName: user.name,
          onLogout: onLogout,
        ),
      _ => loginBuilder(context),
    };
  }
}

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({
    super.key,
    required this.onLogout,
  });

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key("super-admin-dashboard"),
      appBar: AppBar(
        title: const Text("Panel de Super Admin"),
        actions: [
          IconButton(
            tooltip: "Cerrar sesión",
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
        children: [
          Text(
            "Administración SIMA",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 7),
          Text(
            "Gestiona la red de clínicas y distribuidores.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 23),
          _RoleActionCard(
            icon: Icons.groups_rounded,
            title: "Gestión de Distribuidores",
            subtitle: "Administra cuentas y acceso de distribuidores.",
            onTap: () => _openPlaceholder(
              context,
              "Gestión de Distribuidores",
            ),
          ),
          const SizedBox(height: 13),
          _RoleActionCard(
            icon: Icons.business_center_rounded,
            title: "Gestión de Clientes",
            subtitle: "Consulta y administra los clientes registrados.",
            onTap: () => _openPlaceholder(context, "Gestión de Clientes"),
          ),
          const SizedBox(height: 13),
          _RoleActionCard(
            icon: Icons.tune_rounded,
            title: "Configuración Global SIMA",
            subtitle: "Opciones generales de la plataforma.",
            onTap: () => _openPlaceholder(
              context,
              "Configuración Global SIMA",
            ),
          ),
          const SizedBox(height: 24),
          _LogoutButton(onPressed: onLogout),
        ],
      ),
    );
  }
}

class DistributorDashboard extends StatelessWidget {
  const DistributorDashboard({
    super.key,
    required this.displayName,
    required this.onLogout,
  });

  final String displayName;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key("distributor-dashboard"),
      appBar: AppBar(
        title: const Text("Panel de Distribuidor"),
        actions: [
          IconButton(
            tooltip: "Cerrar sesión",
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
        children: [
          Text(
            "Hola, $displayName",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 7),
          Text(
            "Administra tus clientes y clínicas desde aquí.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 23),
          _RoleActionCard(
            icon: Icons.people_alt_outlined,
            title: "Ver Clientes",
            subtitle: "Consulta los clientes asociados a tu cuenta.",
            onTap: () => _openPlaceholder(context, "Clientes"),
          ),
          const SizedBox(height: 13),
          _RoleActionCard(
            icon: Icons.local_hospital_outlined,
            title: "Ver Clínicas",
            subtitle: "Revisa las clínicas de tu red.",
            onTap: () => _openPlaceholder(context, "Clínicas"),
          ),
          const SizedBox(height: 24),
          _LogoutButton(onPressed: onLogout),
        ],
      ),
    );
  }
}

class _RoleActionCard extends StatelessWidget {
  const _RoleActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.045),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.teal),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key("dashboard-logout-button"),
      onPressed: onPressed,
      icon: const Icon(Icons.logout_rounded),
      label: const Text("Cerrar sesión"),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        minimumSize: const Size.fromHeight(52),
      ),
    );
  }
}

void _openPlaceholder(BuildContext context, String title) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _RolePlaceholderScreen(title: title),
    ),
  );
}

class _RolePlaceholderScreen extends StatelessWidget {
  const _RolePlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: "Volver",
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction_rounded,
                color: AppColors.teal,
                size: 52,
              ),
              const SizedBox(height: 15),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                "Esta sección estará disponible próximamente.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
