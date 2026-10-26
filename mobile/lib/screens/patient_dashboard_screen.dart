import "package:flutter/material.dart";

import "../app_theme.dart";
import "../services/api_client.dart";
import "../services/appointment_service.dart";
import "../widgets/dentapro_logo.dart";
import "clinic_catalog_screen.dart";
import "dental_odontogram_screen.dart";

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({
    super.key,
    this.appointmentsRepository,
    this.displayName,
  });

  final AppointmentDashboardRepository? appointmentsRepository;
  final String? displayName;

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  late final AppointmentDashboardRepository _appointmentsRepository =
      widget.appointmentsRepository ?? AppointmentService();

  AppointmentSummary? _nextAppointment;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUpcomingAppointment();
  }

  Future<void> _loadUpcomingAppointment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final appointments =
          await _appointmentsRepository.fetchUpcomingAppointments();
      if (!mounted) return;
      setState(() {
        _nextAppointment = appointments.isEmpty ? null : appointments.first;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = switch (error) {
          ApiException(:final message) => message,
          FormatException(:final message) => message.toString(),
          _ => "No se pudo cargar tu próxima cita.",
        };
      });
    }
  }

  void _showComingSoon(BuildContext context, String section) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text("$section estará disponible próximamente."),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.displayName?.trim();
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            _showComingSoon(context, "Tus citas");
          } else if (index == 2) {
            _showComingSoon(context, "Tu perfil");
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: "Inicio",
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: "Citas",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: "Perfil",
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
          children: [
            _DashboardHeader(
              onSearchTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ClinicCatalogScreen(),
                  ),
                );
              },
              onNotificationsTap: () {
                _showComingSoon(context, "Las notificaciones");
              },
            ),
            const SizedBox(height: 25),
            Text(
              displayName == null || displayName.isEmpty
                  ? "Hola"
                  : "Hola, $displayName",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 5),
            Text(
              "Tu salud dental, al día.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 22),
            _NextAppointmentCard(
              appointment: _nextAppointment,
              isLoading: _isLoading,
              error: _error,
              onRetry: _loadUpcomingAppointment,
              onTap: _nextAppointment == null
                  ? null
                  : () => _showComingSoon(context, "El detalle de la cita"),
            ),
            const SizedBox(height: 27),
            _SectionHeading(
              title: "Accesos rápidos",
              actionLabel: "Ver todo",
              onAction: () => _showComingSoon(context, "Tus accesos"),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.grid_view_rounded,
                    label: "Odontograma",
                    tint: AppColors.teal,
                    onTap: () => _openOdontogram(context),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.assignment_outlined,
                    label: "Historial",
                    tint: AppColors.cyan,
                    onTap: () => _openOdontogram(context),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.credit_card_outlined,
                    label: "Pagos",
                    tint: AppColors.blue,
                    onTap: () => _showComingSoon(context, "Tus pagos"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openOdontogram(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DentalOdontogramScreen(),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.onSearchTap,
    required this.onNotificationsTap,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _MiniBrand(),
        const Spacer(),
        IconButton(
          onPressed: onSearchTap,
          tooltip: "Buscar clínicas",
          icon: const Icon(
            Icons.search_rounded,
            color: AppColors.navy,
            size: 25,
          ),
        ),
        IconButton(
          onPressed: onNotificationsTap,
          tooltip: "Notificaciones",
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.navy,
                size: 25,
              ),
              Positioned(
                right: 1,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppColors.navy,
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _MiniBrand extends StatelessWidget {
  const _MiniBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const DentaproMark(size: 25),
        const SizedBox(width: 7),
        Text(
          "Dentapro",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({
    required this.appointment,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onTap,
  });

  final AppointmentSummary? appointment;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback? onTap;

  static const _weekdays = [
    "lunes",
    "martes",
    "miércoles",
    "jueves",
    "viernes",
    "sábado",
    "domingo",
  ];
  static const _months = [
    "enero",
    "febrero",
    "marzo",
    "abril",
    "mayo",
    "junio",
    "julio",
    "agosto",
    "septiembre",
    "octubre",
    "noviembre",
    "diciembre",
  ];

  String _dateLabel(BuildContext context, DateTime value) {
    final date = value.toLocal();
    final time = TimeOfDay.fromDateTime(date);
    return "${_weekdays[date.weekday - 1]}, ${date.day} de "
        "${_months[date.month - 1]} · ${time.format(context)}";
  }

  @override
  Widget build(BuildContext context) {
    final details = appointment;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.navy, AppColors.blue, AppColors.cyan],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.2),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.event_available_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "PRÓXIMA CITA",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                            letterSpacing: 1.1,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: CircularProgressIndicator(
                        key: Key("patient-appointment-loading"),
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (error != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          error!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: "Reintentar",
                        onPressed: onRetry,
                        color: Colors.white,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  )
                else if (details == null)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      "No tienes citas próximas",
                      key: Key("no-upcoming-appointments"),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else ...[
                  Text(
                    details.reason.trim().isEmpty
                        ? "Cita odontológica"
                        : details.reason,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          _dateLabel(context, details.scheduledAt),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontSize: 12,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_hospital_outlined,
                            color: AppColors.navy,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            details.clinicName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 17),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.teal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(44, 36),
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          height: 105,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tint, size: 22),
              ),
              const SizedBox(height: 9),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.ink,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
