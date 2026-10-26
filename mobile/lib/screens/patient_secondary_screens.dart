import "package:flutter/material.dart";

import "../app_theme.dart";
import "../demo/demo_data.dart";
import "../services/appointment_service.dart";

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
  });

  final DemoPatient? patient;
  final List<AppointmentSummary> appointments;

  @override
  Widget build(BuildContext context) {
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
                patient?.name ?? "Paciente",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _ProfileDetail(
                icon: Icons.mail_outline_rounded,
                label: "Correo",
                value: patient?.email ?? "No disponible",
              ),
              const SizedBox(height: 12),
              _ProfileDetail(
                icon: Icons.phone_outlined,
                label: "Teléfono",
                value: patient?.phone ?? "No disponible",
              ),
              if (patient != null) ...[
                const SizedBox(height: 12),
                _ProfileDetail(
                  icon: Icons.badge_outlined,
                  label: "Modo",
                  value: "Demostración sin conexión",
                ),
                const SizedBox(height: 12),
                _ProfileDetail(
                  icon: Icons.event_note_outlined,
                  label: "Citas de ejemplo",
                  value: "${appointments.length}",
                ),
              ],
            ],
          ),
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
            "Registros locales de esta demostración.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          if (sortedAppointments.isEmpty)
            const _EmptyState(
              icon: Icons.history_rounded,
              title: "Sin registros",
              message: "No hay citas de ejemplo para mostrar.",
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
            "Vista de demostración. No se realizan cobros.",
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
                  "Importe de ejemplo basado en las citas mock.",
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
