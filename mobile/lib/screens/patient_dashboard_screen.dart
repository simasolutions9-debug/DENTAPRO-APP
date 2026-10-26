import "package:flutter/material.dart";

import "../app_theme.dart";
import "../demo/demo_data.dart";
import "../services/api_client.dart";
import "../services/appointment_service.dart";
import "../state/app_provider.dart";
import "../widgets/dentapro_logo.dart";
import "dental_odontogram_screen.dart";
import "patient_navigation_screens.dart";
import "patient_secondary_screens.dart";

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({
    super.key,
    this.appointmentsRepository,
    this.displayName,
    this.demoPatient,
    this.demoAppointments,
    this.onLogout,
  });

  final AppointmentDashboardRepository? appointmentsRepository;
  final String? displayName;
  final DemoPatient? demoPatient;
  final List<AppointmentSummary>? demoAppointments;
  final VoidCallback? onLogout;

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  late final AppointmentDashboardRepository _appointmentsRepository =
      widget.appointmentsRepository ?? AppointmentService();

  AppointmentSummary? _nextAppointment;
  List<AppointmentSummary> _appointments = const [];
  bool _isLoading = true;
  String? _error;
  int _selectedTabIndex = 0;
  bool _fallbackLoadStarted = false;

  DemoPatient? _patientForRoutes(BuildContext context) {
    final providerPatient = AppProviderScope.maybeOf(context)?.currentPatient;
    if (providerPatient != null) return providerPatient;
    if (widget.demoPatient != null) return widget.demoPatient;
    final name = widget.displayName?.trim();
    if (name == null || name.isEmpty) return null;
    return DemoPatient(
      id: "demo-patient",
      name: name,
      email: "paciente.demo@dentapro.local",
      phone: "099 000 0000",
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = AppProviderScope.maybeOf(context);
    if (provider != null) {
      _appointments = provider.appointments;
      _nextAppointment = _findNextAppointment(_appointments);
      _isLoading = false;
      _error = null;
      return;
    }
    if (_fallbackLoadStarted) return;
    _fallbackLoadStarted = true;
    if (widget.demoPatient != null || widget.demoAppointments != null) {
      _appointments = List.unmodifiable(widget.demoAppointments ?? const []);
      _nextAppointment = _findNextAppointment(_appointments);
      _isLoading = false;
      return;
    }
    _loadUpcomingAppointment();
  }

  AppointmentSummary? _findNextAppointment(
    List<AppointmentSummary> appointments,
  ) {
    final upcoming = appointments
        .where(
          (appointment) =>
              appointment.status != "cancelled" &&
              appointment.scheduledAt.isAfter(DateTime.now()),
        )
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return upcoming.isEmpty ? null : upcoming.first;
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
        _appointments = appointments;
        _nextAppointment = _findNextAppointment(appointments);
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

  Future<void> _refreshAppointments() async {
    final provider = AppProviderScope.maybeOf(context);
    if (provider == null) {
      await _loadUpcomingAppointment();
    } else {
      await provider.reloadAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppProviderScope.maybeOf(context);
    final patient = _patientForRoutes(context);
    final appointments = provider?.appointments ?? _appointments;
    final nextAppointment = provider == null
        ? _nextAppointment
        : _findNextAppointment(appointments);
    final isLoading = provider == null ? _isLoading : !provider.isReady;
    final error = provider == null ? _error : null;
    final displayName = patient?.name ?? widget.displayName?.trim();
    return Scaffold(
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: AppColors.teal.withValues(alpha: 0.14),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.teal
                  : AppColors.muted,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: states.contains(WidgetState.selected)
                      ? AppColors.navy
                      : AppColors.muted,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedTabIndex,
          onDestinationSelected: (index) =>
              _onNavigationDestinationSelected(index, patient, appointments),
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
      ),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedTabIndex,
          children: [
            _buildHomeTab(
              context,
              displayName,
              patient,
              appointments,
              nextAppointment,
              isLoading,
              error,
            ),
            PatientAppointmentsTab(
              patient: patient,
              appointments: appointments,
            ),
            PatientProfileTab(
              patient: patient,
              appointments: appointments,
              onLogout: widget.onLogout,
            ),
          ],
        ),
      ),
    );
  }

  void _onNavigationDestinationSelected(
    int index,
    DemoPatient? patient,
    List<AppointmentSummary> appointments,
  ) {
    if (index == 0) {
      _resetToDashboard();
      return;
    }
    setState(() => _selectedTabIndex = index);
    final screen = index == 1
        ? AppointmentsScreen(patient: patient, appointments: appointments)
        : UserProfileScreen(
            patient: patient,
            appointments: appointments,
            onLogout: widget.onLogout,
          );
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  void _resetToDashboard() {
    setState(() => _selectedTabIndex = 0);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildHomeTab(
    BuildContext context,
    String? displayName,
    DemoPatient? patient,
    List<AppointmentSummary> appointments,
    AppointmentSummary? nextAppointment,
    bool isLoading,
    String? error,
  ) =>
      ListView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
        children: [
          _DashboardHeader(
            onHomeTap: _resetToDashboard,
            onSearchTap: () => _openClinicCatalog(context, patient),
            onNotificationsTap: () =>
                _openNotifications(context, patient, appointments),
            onProfileTap: () => _openSettings(context, patient, appointments),
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
            appointment: nextAppointment,
            isLoading: isLoading,
            error: error,
            onRetry: _refreshAppointments,
            onTap: nextAppointment == null
                ? null
                : () => _openAppointmentDetails(
                      context,
                      patient,
                      nextAppointment,
                    ),
          ),
          const SizedBox(height: 27),
          _SectionHeading(
            title: "Accesos rápidos",
            actionLabel: "Ver todo",
            onAction: () => _openHistory(context, patient, appointments),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.grid_view_rounded,
                  label: "Odontograma",
                  tint: AppColors.teal,
                  onTap: () => _openOdontogram(context, patient, appointments),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: _QuickAction(
                  icon: Icons.assignment_outlined,
                  label: "Historial",
                  tint: AppColors.cyan,
                  onTap: () => _openHistory(context, patient, appointments),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: _QuickAction(
                  icon: Icons.credit_card_outlined,
                  label: "Pagos",
                  tint: AppColors.blue,
                  onTap: () => _openPayments(context, patient, appointments),
                ),
              ),
            ],
          ),
        ],
      );

  void _openClinicCatalog(
    BuildContext context,
    DemoPatient? patient,
  ) {
    final demoMode =
        AppProviderScope.maybeOf(context)?.isDemoMode ?? patient != null;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchScreen(
          clinicRepository: demoMode ? const DemoClinicRepository() : null,
          availabilityRepository:
              demoMode ? const DemoClinicAvailabilityRepository() : null,
        ),
      ),
    );
  }

  void _openOdontogram(
    BuildContext context,
    DemoPatient? patient,
    List<AppointmentSummary> appointments,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OdontogramScreen(
          patient: patient,
          appointments: appointments,
        ),
      ),
    );
  }

  void _openHistory(
    BuildContext context,
    DemoPatient? patient,
    List<AppointmentSummary> appointments,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryScreen(
          patient: patient,
          appointments: appointments,
        ),
      ),
    );
  }

  void _openPayments(
    BuildContext context,
    DemoPatient? patient,
    List<AppointmentSummary> appointments,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaymentsScreen(
          patient: patient,
          appointments: appointments,
        ),
      ),
    );
  }

  void _openNotifications(
    BuildContext context,
    DemoPatient? patient,
    List<AppointmentSummary> appointments,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(
          patient: patient,
          appointments: appointments,
        ),
      ),
    );
  }

  void _openSettings(
    BuildContext context,
    DemoPatient? patient,
    List<AppointmentSummary> appointments,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PatientSettingsScreen(
          patient: patient,
          appointments: appointments,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  void _openAppointmentDetails(
    BuildContext context,
    DemoPatient? patient,
    AppointmentSummary appointment,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AppointmentDetailScreen(
          patient: patient,
          appointment: appointment,
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.onHomeTap,
    required this.onSearchTap,
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniBrand(onTap: onHomeTap),
        const Spacer(),
        IconButton(
          key: const Key("dashboard-search-button"),
          onPressed: onSearchTap,
          tooltip: "Buscar clínicas",
          icon: const Icon(
            Icons.search_rounded,
            color: AppColors.navy,
            size: 25,
          ),
        ),
        IconButton(
          key: const Key("dashboard-notifications-button"),
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
        IconButton(
          key: const Key("dashboard-profile-button"),
          onPressed: onProfileTap,
          tooltip: "Abrir perfil y ajustes",
          icon: Container(
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
        ),
      ],
    );
  }
}

class _MiniBrand extends StatelessWidget {
  const _MiniBrand({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: "Ir al inicio de Dentapro",
      child: InkWell(
        key: const Key("dashboard-brand-button"),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
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
          ),
        ),
      ),
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
                        IconButton(
                          tooltip: "Ver detalle de la cita",
                          onPressed: onTap,
                          color: Colors.white,
                          icon: const Icon(Icons.chevron_right_rounded),
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
          key: const Key("dashboard-see-all-button"),
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
