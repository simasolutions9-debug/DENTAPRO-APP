import "package:flutter/material.dart";

import "../app_theme.dart";

class DentistDashboardScreen extends StatefulWidget {
  const DentistDashboardScreen({super.key});

  @override
  State<DentistDashboardScreen> createState() => _DentistDashboardScreenState();
}

class _DentistDashboardScreenState extends State<DentistDashboardScreen> {
  static const _weeklyAppointments = [
    _WeekdayAppointments("Lun", 4),
    _WeekdayAppointments("Mar", 6),
    _WeekdayAppointments("Mié", 3),
    _WeekdayAppointments("Jue", 8),
    _WeekdayAppointments("Vie", 5),
    _WeekdayAppointments("Sáb", 2),
    _WeekdayAppointments("Dom", 1),
  ];

  static const _appointments = [
    _TodayAppointment(
      time: "09:00",
      patient: "María Fernanda López",
      treatment: "Limpieza dental",
    ),
    _TodayAppointment(
      time: "10:30",
      patient: "Carlos Andrade",
      treatment: "Revisión general",
    ),
    _TodayAppointment(
      time: "12:00",
      patient: "Sofía Reyes",
      treatment: "Restauración con resina",
    ),
    _TodayAppointment(
      time: "14:30",
      patient: "Andrés Viteri",
      treatment: "Control de ortodoncia",
    ),
  ];

  final Map<int, _AppointmentStatus> _appointmentStatuses = {
    0: _AppointmentStatus.inProgress,
  };

  int get _weeklyTotal => _weeklyAppointments.fold(
        0,
        (total, entry) => total + entry.count,
      );

  void _advanceAppointment(int index) {
    setState(() {
      final current =
          _appointmentStatuses[index] ?? _AppointmentStatus.scheduled;
      _appointmentStatuses[index] = switch (current) {
        _AppointmentStatus.scheduled => _AppointmentStatus.inProgress,
        _AppointmentStatus.inProgress => _AppointmentStatus.completed,
        _AppointmentStatus.completed => _AppointmentStatus.completed,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.only(right: 19),
            child: ClipOval(
              child: Image.asset(
                "assets/images/dentapro-doctor-profile.jpg",
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                semanticLabel: "Foto de la Dra. Valentina Ortiz",
                errorBuilder: (context, error, stackTrace) =>
                    const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.teal,
                  child: Text(
                    "VO",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
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
            const _DailyIncomeCard(),
            const SizedBox(height: 20),
            _SectionTitle(
              title: "Actividad semanal",
              detail: "RESUMEN",
            ),
            const SizedBox(height: 10),
            _WeeklyAppointmentsCard(
              appointments: _weeklyAppointments,
              total: _weeklyTotal,
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
                    "${_appointments.length} citas",
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
              "Lunes · Agenda de hoy",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < _appointments.length; index++) ...[
              _AppointmentCard(
                key: ValueKey("appointment-card-$index"),
                appointment: _appointments[index],
                status:
                    _appointmentStatuses[index] ?? _AppointmentStatus.scheduled,
                onAction: () => _advanceAppointment(index),
              ),
              const SizedBox(height: 9),
            ],
            const SizedBox(height: 5),
            Text(
              "Agenda e ingresos de ejemplo para esta vista previa.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                  ),
            ),
          ],
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
                "Dra. Valentina Ortiz",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                "Odontología general · Clínica Sonríe",
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
  const _DailyIncomeCard();

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
                  Text(
                    "INGRESOS DEL DÍA",
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          letterSpacing: 1,
                          fontSize: 10,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "HOY",
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
              Text(
                "\$350.00",
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 34,
                      letterSpacing: -0.8,
                    ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    color: Color(0xFF7DE3CF),
                    size: 17,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "Ingresos registrados hoy",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontSize: 11,
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
  });

  final List<_WeekdayAppointments> appointments;
  final int total;

  static const _maxCount = 8;

  @override
  Widget build(BuildContext context) {
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
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final day in appointments)
                  Expanded(
                    child: _WeekdayBar(
                      day: day,
                      maxCount: _maxCount,
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
  const _AppointmentCard({
    super.key,
    required this.appointment,
    required this.status,
    required this.onAction,
  });

  final _TodayAppointment appointment;
  final _AppointmentStatus status;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final actionLabel = switch (status) {
      _AppointmentStatus.scheduled => "Iniciar",
      _AppointmentStatus.inProgress => "Completar",
      _AppointmentStatus.completed => "Completada",
    };
    final actionColor = status == _AppointmentStatus.inProgress
        ? AppColors.blue
        : AppColors.teal;

    return Container(
      key: ValueKey("appointment-card-${appointment.patient}"),
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
                  appointment.time,
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
                  appointment.patient,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.treatment,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 10,
                      ),
                ),
                if (status != _AppointmentStatus.scheduled) ...[
                  const SizedBox(height: 4),
                  Text(
                    status == _AppointmentStatus.inProgress
                        ? "En consulta"
                        : "Atención completada",
                    style: TextStyle(
                      color: status == _AppointmentStatus.inProgress
                          ? AppColors.blue
                          : AppColors.teal,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: status == _AppointmentStatus.completed ? 80 : 84,
            height: 37,
            child: ElevatedButton(
              key: ValueKey("appointment-action-${appointment.patient}"),
              onPressed:
                  status == _AppointmentStatus.completed ? null : onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                disabledBackgroundColor: AppColors.teal.withValues(alpha: 0.12),
                disabledForegroundColor: AppColors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(actionLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AppointmentStatus { scheduled, inProgress, completed }

class _WeekdayAppointments {
  const _WeekdayAppointments(this.label, this.count);

  final String label;
  final int count;
}

class _TodayAppointment {
  const _TodayAppointment({
    required this.time,
    required this.patient,
    required this.treatment,
  });

  final String time;
  final String patient;
  final String treatment;
}
