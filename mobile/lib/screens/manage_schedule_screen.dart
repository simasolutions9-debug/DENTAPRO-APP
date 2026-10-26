import "package:flutter/material.dart";

import "../app_theme.dart";
import "../services/api_client.dart";
import "../services/clinic_service.dart";
import "../services/schedule_service.dart";

class ManageScheduleScreen extends StatefulWidget {
  const ManageScheduleScreen({
    super.key,
    required this.clinicSlug,
    this.availabilityRepository,
    this.schedulePublisher,
  });

  final String clinicSlug;
  final ClinicAvailabilityRepository? availabilityRepository;
  final SchedulePublisher? schedulePublisher;

  @override
  State<ManageScheduleScreen> createState() => _ManageScheduleScreenState();
}

class _ManageScheduleScreenState extends State<ManageScheduleScreen> {
  static const _weekdays = [
    "Lunes",
    "Martes",
    "Miércoles",
    "Jueves",
    "Viernes",
    "Sábado",
    "Domingo",
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

  late final ClinicAvailabilityRepository _availabilityRepository =
      widget.availabilityRepository ?? ClinicService();
  late final SchedulePublisher _schedulePublisher =
      widget.schedulePublisher ?? ScheduleService();
  late final DateTime _today = DateUtils.dateOnly(DateTime.now());
  final TextEditingController _estimatedFeeController = TextEditingController();
  late DateTime _weekStart = _mondayOf(_today);
  late DateTime _selectedDate = _today;

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 30);
  List<ClinicSlot> _weekSlots = const [];
  String? _error;
  String? _formError;
  bool _isLoading = true;
  bool _isSaving = false;
  int _requestId = 0;

  bool get _clinicIsConfigured => widget.clinicSlug.trim().isNotEmpty;
  bool get _canGoBack => _weekStart.isAfter(_mondayOf(_today));

  static DateTime _mondayOf(DateTime date) {
    final day = DateUtils.dateOnly(date);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  String _dateLabel(DateTime date) =>
      "${date.day} de ${_months[date.month - 1]}";

  String _timeLabel(DateTime date) => "${date.hour.toString().padLeft(2, "0")}:"
      "${date.minute.toString().padLeft(2, "0")}";

  String _timeOfDayLabel(TimeOfDay time) =>
      "${time.hour.toString().padLeft(2, "0")}:"
      "${time.minute.toString().padLeft(2, "0")}";

  int get _durationMinutes {
    final starts = _startTime.hour * 60 + _startTime.minute;
    final ends = _endTime.hour * 60 + _endTime.minute;
    return ends - starts;
  }

  @override
  void dispose() {
    _estimatedFeeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadWeek();
  }

  Future<void> _loadWeek() async {
    final requestId = ++_requestId;
    if (!_clinicIsConfigured) {
      setState(() {
        _isLoading = false;
        _weekSlots = const [];
        _error =
            "Configura DENTAPRO_CLINIC_SLUG para asociar horarios a tu clínica.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dates = List.generate(
        7,
        (index) => _weekStart.add(Duration(days: index)),
      );
      final slotsByDay = await Future.wait(
        dates.map(
          (date) => _availabilityRepository.fetchAvailability(
            clinicSlug: widget.clinicSlug,
            date: date,
          ),
        ),
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _weekSlots = slotsByDay.expand((slots) => slots).toList()
          ..sort((first, second) => first.startsAt.compareTo(second.startsAt));
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _weekSlots = const [];
        _isLoading = false;
        _error = switch (error) {
          ApiException(:final message) => message,
          FormatException(:final message) => message.toString(),
          _ => "No se pudieron cargar los horarios. Intenta de nuevo.",
        };
      });
    }
  }

  void _changeWeek(int offset) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: offset * 7));
      _selectedDate = _weekStart.isBefore(_mondayOf(_today)) ||
              DateUtils.isSameDay(_weekStart, _mondayOf(_today))
          ? _today
          : _weekStart;
    });
    _loadWeek();
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(_today) ? _today : _selectedDate,
      firstDate: _today,
      lastDate: _today.add(const Duration(days: 120)),
      helpText: "Selecciona el día del horario",
    );
    if (date == null || !mounted) return;
    setState(() {
      _selectedDate = DateUtils.dateOnly(date);
      _weekStart = _mondayOf(date);
      _formError = null;
    });
    _loadWeek();
  }

  Future<void> _chooseTime({required bool chooseStart}) async {
    final initialTime = chooseStart ? _startTime : _endTime;
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: chooseStart ? "Hora de inicio" : "Hora de fin",
      builder: (context, child) => Localizations.override(
        context: context,
        locale: const Locale("es", "EC"),
        child: child,
      ),
    );
    if (time == null || !mounted) return;
    setState(() {
      if (chooseStart) {
        _startTime = time;
      } else {
        _endTime = time;
      }
      _formError = null;
    });
  }

  Future<void> _publishSchedule() async {
    if (!_clinicIsConfigured || _isSaving) return;
    final duration = _durationMinutes;
    final estimatedFee =
        _estimatedFeeController.text.trim().replaceAll(",", ".");
    if (duration < 15 || duration > 240) {
      setState(() {
        _formError = "El bloque debe durar entre 15 minutos y 4 horas.";
      });
      return;
    }
    if (!RegExp(r"^\d{1,6}(?:\.\d{1,2})?$").hasMatch(estimatedFee)) {
      setState(() {
        _formError = "Ingresa una tarifa válida con máximo 2 decimales.";
      });
      return;
    }
    if (_selectedDate.isBefore(_today)) {
      setState(() {
        _formError = "Selecciona una fecha futura.";
      });
      return;
    }

    final startsAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    if (!startsAt.isAfter(DateTime.now())) {
      setState(() {
        _formError = "La hora de inicio debe ser posterior a la hora actual.";
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _formError = null;
      _error = null;
    });
    try {
      await _schedulePublisher.publishSlot(
        clinicSlug: widget.clinicSlug,
        startsAt: startsAt,
        durationMinutes: duration,
        estimatedFee: estimatedFee,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Horario publicado correctamente."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _weekStart = _mondayOf(_selectedDate);
      await _loadWeek();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _formError = switch (error) {
          ApiException(:final message) => message,
          FormatException(:final message) => message.toString(),
          _ => "No se pudo guardar el horario. Intenta de nuevo.",
        };
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: "Volver",
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          "Gestionar Horarios",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.navy,
                fontSize: 18,
              ),
        ),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            Text(
              "Disponibilidad de la clínica",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                  ),
            ),
            const SizedBox(height: 5),
            Text(
              "Publica bloques para fechas específicas. Solo estos horarios "
              "aparecerán disponibles para reservar.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            _AddScheduleCard(
              selectedDate: _selectedDate,
              startTime: _timeOfDayLabel(_startTime),
              endTime: _timeOfDayLabel(_endTime),
              durationMinutes: _durationMinutes,
              estimatedFeeController: _estimatedFeeController,
              isSaving: _isSaving,
              error: _formError,
              clinicIsConfigured: _clinicIsConfigured,
              onChooseDate: _chooseDate,
              onChooseStartTime: () => _chooseTime(chooseStart: true),
              onChooseEndTime: () => _chooseTime(chooseStart: false),
              onSave: _publishSchedule,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Horarios publicados",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 17,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: "Actualizar horarios",
                  onPressed: _isLoading ? null : _loadWeek,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _WeekSelector(
              startDate: _weekStart,
              endDate: weekEnd,
              canGoBack: _canGoBack,
              onPrevious: () => _changeWeek(-1),
              onNext: () => _changeWeek(1),
              formatDate: _dateLabel,
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.teal,
                    key: Key("schedule-loading-indicator"),
                  ),
                ),
              )
            else if (_error case final error?)
              _ScheduleError(message: error, onRetry: _loadWeek)
            else
              for (var index = 0; index < 7; index++) ...[
                _DayScheduleCard(
                  date: _weekStart.add(Duration(days: index)),
                  weekday: _weekdays[index],
                  slots: _weekSlots
                      .where(
                        (slot) => DateUtils.isSameDay(
                          slot.startsAt.toLocal(),
                          _weekStart.add(Duration(days: index)),
                        ),
                      )
                      .toList(growable: false),
                  formatTime: _timeLabel,
                ),
                const SizedBox(height: 9),
              ],
          ],
        ),
      ),
    );
  }
}

class _AddScheduleCard extends StatelessWidget {
  const _AddScheduleCard({
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.estimatedFeeController,
    required this.isSaving,
    required this.error,
    required this.clinicIsConfigured,
    required this.onChooseDate,
    required this.onChooseStartTime,
    required this.onChooseEndTime,
    required this.onSave,
  });

  final DateTime selectedDate;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final TextEditingController estimatedFeeController;
  final bool isSaving;
  final String? error;
  final bool clinicIsConfigured;
  final VoidCallback onChooseDate;
  final VoidCallback onChooseStartTime;
  final VoidCallback onChooseEndTime;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Añadir bloque de disponibilidad",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.navy,
                  fontSize: 15,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            "El bloque se publicará para una fecha concreta.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const Key("schedule-date-picker-button"),
            onPressed: onChooseDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
              "${_weekdayName(selectedDate.weekday)}, "
              "${selectedDate.day} ${_monthName(selectedDate.month)} "
              "${selectedDate.year}",
            ),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.border),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TimePickerButton(
                  key: const Key("schedule-start-time-button"),
                  label: "Inicio",
                  value: startTime,
                  onPressed: onChooseStartTime,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimePickerButton(
                  key: const Key("schedule-end-time-button"),
                  label: "Fin",
                  value: endTime,
                  onPressed: onChooseEndTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key("schedule-estimated-fee-field"),
            controller: estimatedFeeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Tarifa estimada por cita",
              prefixText: "\$ ",
              suffixText: "USD",
            ),
          ),
          if (durationMinutes > 0) ...[
            const SizedBox(height: 8),
            Text(
              "Duración: ${durationMinutes ~/ 60 > 0 ? "${durationMinutes ~/ 60} h " : ""}"
              "${durationMinutes % 60 > 0 ? "${durationMinutes % 60} min" : ""}",
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
          if (!clinicIsConfigured) ...[
            const SizedBox(height: 10),
            const _InlineScheduleError(
              message:
                  "Configura DENTAPRO_CLINIC_SLUG para asociar el horario a tu clínica.",
            ),
          ],
          if (error case final message?) ...[
            const SizedBox(height: 10),
            _InlineScheduleError(message: message),
          ],
          const SizedBox(height: 14),
          ElevatedButton.icon(
            key: const Key("save-schedule-button"),
            onPressed: isSaving || !clinicIsConfigured ? null : onSave,
            icon: isSaving
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.publish_rounded, size: 18),
            label: Text(isSaving ? "Guardando..." : "Guardar Horario"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekSelector extends StatelessWidget {
  const _WeekSelector({
    required this.startDate,
    required this.endDate,
    required this.canGoBack,
    required this.onPrevious,
    required this.onNext,
    required this.formatDate,
  });

  final DateTime startDate;
  final DateTime endDate;
  final bool canGoBack;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: "Semana anterior",
          onPressed: canGoBack ? onPrevious : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            "${formatDate(startDate)} – ${formatDate(endDate)}",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        IconButton(
          tooltip: "Semana siguiente",
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _DayScheduleCard extends StatelessWidget {
  const _DayScheduleCard({
    required this.date,
    required this.weekday,
    required this.slots,
    required this.formatTime,
  });

  final DateTime date;
  final String weekday;
  final List<ClinicSlot> slots;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weekday.substring(0, 3).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${date.day}",
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$weekday, ${_monthName(date.month)} ${date.year}",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 7),
                  if (slots.isEmpty)
                    Text(
                      "Sin horarios publicados",
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final slot in slots)
                          _SlotChip(
                            label: "${formatTime(slot.startsAt.toLocal())}–"
                                "${formatTime(slot.startsAt.toLocal().add(Duration(minutes: slot.durationMinutes)))}"
                                " · ${slot.estimatedFee == null ? "Tarifa pendiente" : "\$${slot.estimatedFee!.toStringAsFixed(2)}"}",
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  const _TimePickerButton({
    super.key,
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleError extends StatelessWidget {
  const _ScheduleError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _InlineScheduleError(
      message: message,
      action: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text("Reintentar"),
      ),
    );
  }
}

class _InlineScheduleError extends StatelessWidget {
  const _InlineScheduleError({
    required this.message,
    this.action,
  });

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F2),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFFB42318),
              fontSize: 12,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 4),
            action!,
          ],
        ],
      ),
    );
  }
}

String _weekdayName(int weekday) => const [
      "lunes",
      "martes",
      "miércoles",
      "jueves",
      "viernes",
      "sábado",
      "domingo",
    ][weekday - 1];

String _monthName(int month) => const [
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
    ][month - 1];
