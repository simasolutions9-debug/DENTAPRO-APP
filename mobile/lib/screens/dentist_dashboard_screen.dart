import "package:flutter/material.dart";

import "../app_theme.dart";
import "../services/api_client.dart";
import "../services/appointment_service.dart";
import "manage_schedule_screen.dart";

class DentistDashboardScreen extends StatefulWidget {
  const DentistDashboardScreen({
    super.key,
    this.appointmentsRepository,
    this.onLogout,
  });

  final AppointmentDashboardRepository? appointmentsRepository;
  final VoidCallback? onLogout;

  @override
  State<DentistDashboardScreen> createState() => _DentistDashboardScreenState();
}

class _DentistDashboardScreenState extends State<DentistDashboardScreen> {
  static const _weekdayLabels = [
    "Lun",
    "Mar",
    "Mié",
    "Jue",
    "Vie",
    "Sáb",
    "Dom"
  ];

  late final AppointmentDashboardRepository _appointmentsRepository =
      widget.appointmentsRepository ?? AppointmentService();
  List<AppointmentSummary> _weekAppointments = const [];
  bool _isLoading = true;
  String? _error;

  List<AppointmentSummary> get _todayAppointments => _weekAppointments
      .where((appointment) =>
          DateUtils.isSameDay(appointment.scheduledAt, DateTime.now()))
      .toList(growable: false);

  double get _todayEstimatedIncome => _todayAppointments
      .where((appointment) => appointment.status != "cancelled")
      .fold(
        0,
        (sum, appointment) => sum + (appointment.estimatedFee ?? 0),
      );

  int get _todayMissingTariffCount => _todayAppointments
      .where((appointment) => appointment.estimatedFee == null)
      .length;

  List<_WeekdayAppointments> get _weeklyAppointments {
    final today = DateUtils.dateOnly(DateTime.now());
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      final count = _weekAppointments
          .where((appointment) =>
              DateUtils.isSameDay(appointment.scheduledAt, day))
          .length;
      return _WeekdayAppointments(_weekdayLabels[index], count);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final today = DateUtils.dateOnly(DateTime.now());
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    try {
      final appointments =
          await _appointmentsRepository.fetchClinicAppointments(
        from: weekStart,
        to: weekEnd,
      );
      if (!mounted) return;
      setState(() {
        _weekAppointments = appointments;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = switch (error) {
          ApiException(:final message) => message,
          FormatException(:final message) => message.toString(),
          _ => "No se pudieron cargar las citas de la clínica.",
        };
      });
    }
  }

  String get _todayLabel {
    const weekdays = [
      "Lunes",
      "Martes",
      "Miércoles",
      "Jueves",
      "Viernes",
      "Sábado",
      "Domingo",
    ];
    final today = DateTime.now();
    return "${weekdays[today.weekday - 1]} · Agenda de hoy";
  }

  @override
  Widget build(BuildContext context) {
    final todayAppointments = _todayAppointments;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: "Volver",
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          "Panel odontológico",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.navy,
                fontSize: 18,
              ),
        ),
        actions: [
          if (widget.onLogout != null)
            IconButton(
              key: const Key("dentist-logout-button"),
              tooltip: "Cerrar sesión",
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout_rounded),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 19),
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.teal,
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            _DoctorWelcome(),
            const SizedBox(height: 18),
            _DailyIncomeCard(
              estimatedAmount: _todayEstimatedIncome,
              missingTariffCount: _todayMissingTariffCount,
              isLoading: _isLoading,
              error: _error,
              onRetry: _loadDashboard,
            ),
            const SizedBox(height: 20),
            _SectionTitle(
              title: "Actividad semanal",
              detail: "RESUMEN",
            ),
            const SizedBox(height: 10),
            _WeeklyAppointmentsCard(
              appointments: _weeklyAppointments,
              total: _weekAppointments.length,
              isLoading: _isLoading,
              error: _error,
            ),
            const SizedBox(height: 12),
            _ManageScheduleCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ManageScheduleScreen(
                    clinicSlug: ApiClient.clinicSlug,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Pacientes de hoy",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 17,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${todayAppointments.length} citas",
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              _todayLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: CircularProgressIndicator(
                    key: Key("dentist-appointments-loading"),
                    color: AppColors.teal,
                  ),
                ),
              )
            else if (_error != null)
              _DashboardLoadError(
                message: _error!,
                onRetry: _loadDashboard,
              )
            else if (todayAppointments.isEmpty)
              const _NoPatientsTodayCard()
            else
              for (final appointment in todayAppointments) ...[
                _AppointmentCard(appointment: appointment),
                const SizedBox(height: 9),
              ],
          ],
        ),
      ),
    );
  }
}

class _ManageScheduleCard extends StatelessWidget {
  const _ManageScheduleCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: const Key("manage-schedule-access"),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Gestionar Horarios",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.navy,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Publica y revisa la disponibilidad de tu clínica",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorWelcome extends StatelessWidget {
  const _DoctorWelcome();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Buenos días,",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 3),
              Text(
                "Panel de la clínica",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                "Agenda y métricas de tu clínica",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 49,
          height: 49,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Center(
            child: Icon(
              Icons.medical_services_outlined,
              color: AppColors.teal,
              size: 23,
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyIncomeCard extends StatelessWidget {
  const _DailyIncomeCard({
    required this.estimatedAmount,
    required this.missingTariffCount,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final double estimatedAmount;
  final int missingTariffCount;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key("daily-income-card"),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepBlue, AppColors.navy, AppColors.blue],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -44,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.055),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 25,
            bottom: -78,
            child: Container(
              width: 152,
              height: 152,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "INGRESOS PREVISTOS HOY",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                            letterSpacing: 0.8,
                            fontSize: 9,
                          ),
                    ),
                  ),
                  if (error != null)
                    IconButton(
                      tooltip: "Reintentar",
                      onPressed: onRetry,
                      color: Colors.white,
                      icon: const Icon(Icons.refresh_rounded, size: 19),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "ESTIMADO",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 19),
              if (isLoading)
                const SizedBox(
                  height: 41,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        key: Key("estimated-income-loading"),
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  error == null
                      ? "\$${estimatedAmount.toStringAsFixed(2)}"
                      : "No disponible",
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontSize: error == null ? 34 : 21,
                        letterSpacing: -0.8,
                      ),
                ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF7DE3CF),
                    size: 17,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      missingTariffCount > 0
                          ? "Estimación parcial: faltan tarifas en "
                              "$missingTariffCount citas; no son pagos cobrados."
                          : "Estimado con tarifas de citas; no son pagos cobrados.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.84),
                            fontSize: 10,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 17,
                ),
          ),
        ),
        Text(
          detail,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.teal,
                letterSpacing: 0.8,
                fontSize: 9,
              ),
        ),
      ],
    );
  }
}

class _WeeklyAppointmentsCard extends StatelessWidget {
  const _WeeklyAppointmentsCard({
    required this.appointments,
    required this.total,
    required this.isLoading,
    required this.error,
  });

  final List<_WeekdayAppointments> appointments;
  final int total;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final maxCount = appointments.fold<int>(
      1,
      (maximum, day) => day.count > maximum ? day.count : maximum,
    );
    return Container(
      key: const Key("weekly-appointments-chart"),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Citas agendadas",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 13,
                      ),
                ),
              ),
              Text(
                "$total esta semana",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.teal,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else if (error != null)
            SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  "No se pudieron cargar las citas.",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final day in appointments)
                    Expanded(
                      child: _WeekdayBar(
                        day: day,
                        maxCount: maxCount,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekdayBar extends StatelessWidget {
  const _WeekdayBar({required this.day, required this.maxCount});

  final _WeekdayAppointments day;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          SizedBox(
            height: 15,
            child: Center(
              child: Text(
                "${day.count}",
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              width: 21,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: day.count / maxCount,
                widthFactor: 1,
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            day.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: AppColors.muted,
                ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final AppointmentSummary appointment;

  @override
  Widget build(BuildContext context) {
    final localTime = appointment.scheduledAt.toLocal();
    final statusLabel = switch (appointment.status) {
      "confirmed" => "Confirmada",
      "completed" => "Completada",
      _ => "Programada",
    };
    final statusColor =
        appointment.status == "completed" ? AppColors.blue : AppColors.teal;

    return Container(
      key: ValueKey("appointment-card-${appointment.id}"),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 57,
            height: 57,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.teal,
                  size: 15,
                ),
                const SizedBox(height: 3),
                Text(
                  "${localTime.hour.toString().padLeft(2, "0")}:"
                  "${localTime.minute.toString().padLeft(2, "0")}",
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.reason.trim().isEmpty
                      ? "Cita odontológica"
                      : appointment.reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPatientsTodayCard extends StatelessWidget {
  const _NoPatientsTodayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.event_busy_rounded, color: AppColors.muted),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "No hay pacientes con cita hoy.",
              key: Key("no-patients-today"),
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoadError extends StatelessWidget {
  const _DashboardLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Color(0xFFB42318)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB42318),
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            tooltip: "Reintentar",
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFFB42318),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayAppointments {
  const _WeekdayAppointments(this.label, this.count);

  final String label;
  final int count;
}
