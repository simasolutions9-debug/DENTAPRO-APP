import "package:flutter/material.dart";

import "../app_theme.dart";
import "../demo/demo_data.dart";
import "../services/appointment_service.dart";
import "../state/app_provider.dart";
import "../state/app_user.dart";

class PatientAppointmentsTab extends StatelessWidget {
  const PatientAppointmentsTab({
    super.key,
    required this.appointments,
    this.patient,
  });

  final DemoPatient? patient;
  final List<AppointmentSummary> appointments;

  @override
  Widget build(BuildContext context) {
    final sortedAppointments = [...appointments]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
      children: [
        Text(
          "Mis citas",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 5),
        Text(
          patient == null
              ? "Consulta el estado de tus citas."
              : "Hola, ${patient!.name}. Aquí tienes tu agenda.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        if (sortedAppointments.isEmpty)
          const _EmptyState(
            icon: Icons.event_available_outlined,
            title: "No tienes citas",
            message: "Cuando agendes una cita, aparecerá aquí.",
          )
        else
          for (final appointment in sortedAppointments) ...[
            _AppointmentCard(appointment: appointment),
            const SizedBox(height: 11),
          ],
      ],
    );
  }
}

class PatientProfileTab extends StatelessWidget {
  const PatientProfileTab({
    super.key,
    this.patient,
    this.appointments = const [],
    this.onLogout,
  });

  final DemoPatient? patient;
  final List<AppointmentSummary> appointments;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final appProvider = AppProviderScope.maybeOf(context);
    final activeUser = appProvider?.currentUser;
    final activePatient = appProvider?.currentPatient ?? patient;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
      children: [
        Text(
          "Mi perfil",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 5),
        Text(
          "Información de tu cuenta.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.teal.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.teal,
                  size: 34,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                activePatient?.name ?? "Paciente",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _ProfileDetail(
                icon: Icons.mail_outline_rounded,
                label: "Correo",
                value: activePatient?.email ?? "No disponible",
              ),
              const SizedBox(height: 12),
              _ProfileDetail(
                icon: Icons.phone_outlined,
                label: "Teléfono",
                value: activePatient?.phone ?? "No disponible",
              ),
              if (activePatient != null) ...[
                const SizedBox(height: 12),
                _ProfileDetail(
                  icon: Icons.badge_outlined,
                  label: "Tipo de cuenta",
                  value:
                      activeUser?.role == "paciente" ? "Paciente" : "Usuario",
                ),
                const SizedBox(height: 12),
                _ProfileDetail(
                  icon: Icons.event_note_outlined,
                  label: "Citas guardadas",
                  value: "${appointments.length}",
                ),
                if (appProvider != null && activeUser?.role == "paciente") ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key("edit-profile-button"),
                      onPressed: () => _showEditProfile(
                        context,
                        appProvider,
                        activeUser!,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text("Editar perfil"),
                    ),
                  ),
                ],
                if (onLogout != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key("patient-logout-button"),
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text("Cerrar sesión"),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showEditProfile(
    BuildContext context,
    AppProvider provider,
    AppUser user,
  ) =>
      showDialog<void>(
        context: context,
        builder: (_) => _EditProfileDialog(provider: provider, user: user),
      );
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.provider,
    required this.user,
  });

  final AppProvider provider;
  final AppUser user;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.user.name);
  late final TextEditingController _phoneController =
      TextEditingController(text: widget.user.phone);
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.provider.updatePatientProfile(
        name: _nameController.text,
        phone: _phoneController.text,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = "No se pudo guardar el perfil: $error";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Editar perfil"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key("profile-name-field"),
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nombre"),
              validator: (value) =>
                  (value?.trim().isEmpty ?? true) ? "Ingresa tu nombre." : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key("profile-phone-field"),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Teléfono"),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text("Cancelar"),
        ),
        FilledButton(
          key: const Key("profile-save-button"),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Guardar cambios"),
        ),
      ],
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    this.patient,
    this.appointments = const [],
  });

  final DemoPatient? patient;
  final List<AppointmentSummary> appointments;

  @override
  Widget build(BuildContext context) {
    final sortedAppointments = [...appointments]
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return Scaffold(
      appBar: _backAppBar(context, "Historial"),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
        children: [
          Text(
            patient == null
                ? "Historial de citas"
                : "Historial de ${patient!.name}",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            "Registros de tus citas guardadas localmente.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          if (sortedAppointments.isEmpty)
            const _EmptyState(
              icon: Icons.history_rounded,
              title: "Sin registros",
              message: "No hay citas para mostrar.",
            )
          else
            for (final appointment in sortedAppointments) ...[
              _AppointmentCard(appointment: appointment),
              const SizedBox(height: 11),
            ],
        ],
      ),
    );
  }
}

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({
    super.key,
    this.patient,
    this.appointments = const [],
  });

  final DemoPatient? patient;
  final List<AppointmentSummary> appointments;

  @override
  Widget build(BuildContext context) {
    final estimate = appointments
        .where((appointment) => appointment.status != "cancelled")
        .fold<double>(
          0,
          (total, appointment) => total + (appointment.estimatedFee ?? 0),
        );
    return Scaffold(
      appBar: _backAppBar(context, "Pagos"),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
        children: [
          Text(
            patient == null ? "Pagos" : "Pagos de ${patient!.name}",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            "Vista informativa. No se realizan cobros.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "REFERENCIA ESTIMADA",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.muted,
                        letterSpacing: 0.8,
                      ),
                ),
                const SizedBox(height: 7),
                Text(
                  "\$${estimate.toStringAsFixed(2)}",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Tarifa estimada basada en tus citas guardadas.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final appointment in appointments) ...[
            _AppointmentCard(appointment: appointment),
            const SizedBox(height: 11),
          ],
        ],
      ),
    );
  }
}

class PatientNotificationsScreen extends StatelessWidget {
  const PatientNotificationsScreen({
    super.key,
    this.patient,
    this.appointments = const [],
  });

  final DemoPatient? patient;
  final List<AppointmentSummary> appointments;

  @override
  Widget build(BuildContext context) {
    final nextAppointment = appointments
        .where(
          (appointment) =>
              appointment.status != "cancelled" &&
              appointment.scheduledAt.isAfter(DateTime.now()),
        )
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final next = nextAppointment.isEmpty ? null : nextAppointment.first;

    return Scaffold(
      key: const Key("notifications-screen"),
      appBar: _backAppBar(context, "Notificaciones"),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
        children: [
          Text(
            patient == null ? "Avisos importantes" : "Hola, ${patient!.name}",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            "Aquí encontrarás novedades sobre tu atención.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          _NotificationCard(
            icon: Icons.event_available_rounded,
            title: next == null ? "Tu agenda está al día" : "Cita confirmada",
            message: next == null
                ? "Cuando agendes una cita, verás aquí sus avisos."
                : "${next.clinicName} · ${MaterialLocalizations.of(context).formatFullDate(next.scheduledAt.toLocal())}",
            tint: AppColors.teal,
          ),
          const SizedBox(height: 12),
          const _NotificationCard(
            icon: Icons.health_and_safety_outlined,
            title: "Cuida tu sonrisa",
            message: "Recuerda mantener tus controles odontológicos al día.",
            tint: AppColors.blue,
          ),
        ],
      ),
    );
  }
}

class PatientSettingsScreen extends StatelessWidget {
  const PatientSettingsScreen({
    super.key,
    this.patient,
    this.appointments = const [],
    this.onLogout,
  });

  final DemoPatient? patient;
  final List<AppointmentSummary> appointments;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key("patient-settings-screen"),
      appBar: _backAppBar(context, "Configuración"),
      body: PatientProfileTab(
        patient: patient,
        appointments: appointments,
        onLogout: onLogout,
      ),
    );
  }
}

class AppointmentDetailScreen extends StatelessWidget {
  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
    this.patient,
  });

  final AppointmentSummary appointment;
  final DemoPatient? patient;

  @override
  Widget build(BuildContext context) {
    final date = appointment.scheduledAt.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date));
    final status = switch (appointment.status) {
      "completed" => "Completada",
      "confirmed" => "Confirmada",
      "cancelled" => "Cancelada",
      _ => "Agendada",
    };

    return Scaffold(
      key: const Key("appointment-detail-screen"),
      appBar: _backAppBar(context, "Detalle de la cita"),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
        children: [
          Text(
            appointment.reason.trim().isEmpty
                ? "Cita odontológica"
                : appointment.reason,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            patient == null
                ? "Información de tu próxima cita."
                : "Paciente: ${patient!.name}",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _ProfileDetail(
                  icon: Icons.local_hospital_outlined,
                  label: "Clínica",
                  value: appointment.clinicName,
                ),
                const SizedBox(height: 14),
                _ProfileDetail(
                  icon: Icons.calendar_today_outlined,
                  label: "Fecha",
                  value: localizations.formatFullDate(date),
                ),
                const SizedBox(height: 14),
                _ProfileDetail(
                  icon: Icons.access_time_rounded,
                  label: "Hora",
                  value: time,
                ),
                const SizedBox(height: 14),
                _ProfileDetail(
                  icon: Icons.timelapse_rounded,
                  label: "Duración",
                  value: "${appointment.durationMinutes} minutos",
                ),
                const SizedBox(height: 14),
                _ProfileDetail(
                  icon: Icons.verified_outlined,
                  label: "Estado",
                  value: status,
                ),
                if (appointment.estimatedFee != null) ...[
                  const SizedBox(height: 14),
                  _ProfileDetail(
                    icon: Icons.payments_outlined,
                    label: "Tarifa estimada",
                    value: "\$${appointment.estimatedFee!.toStringAsFixed(2)}",
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

AppBar _backAppBar(BuildContext context, String title) => AppBar(
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        tooltip: "Volver",
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text(title),
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
    );

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final AppointmentSummary appointment;

  @override
  Widget build(BuildContext context) {
    final date = appointment.scheduledAt.toLocal();
    final status = switch (appointment.status) {
      "completed" => "Completada",
      "confirmed" => "Confirmada",
      "cancelled" => "Cancelada",
      _ => "Agendada",
    };
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.teal,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.reason.isEmpty
                      ? "Consulta dental"
                      : appointment.reason,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.clinicName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  "${date.day.toString().padLeft(2, "0")}/"
                  "${date.month.toString().padLeft(2, "0")}/${date.year}"
                  " · $status",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          if (appointment.estimatedFee != null)
            Text(
              "\$${appointment.estimatedFee!.toStringAsFixed(2)}",
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
            ),
        ],
      ),
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: AppColors.teal, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Icon(icon, color: AppColors.teal, size: 34),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.035),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
