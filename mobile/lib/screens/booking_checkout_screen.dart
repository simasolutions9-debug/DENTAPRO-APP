import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";

import "../app_theme.dart";
import "../services/api_client.dart";
import "../services/clinic_service.dart";
import "../state/app_provider.dart";

class BookingCheckoutScreen extends StatefulWidget {
  const BookingCheckoutScreen({
    super.key,
    required this.clinicSlug,
    required this.clinicName,
    this.availabilityRepository,
  });

  final String clinicSlug;
  final String clinicName;
  final ClinicAvailabilityRepository? availabilityRepository;

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
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

  late final DateTime _today = DateUtils.dateOnly(DateTime.now());
  late final DateTime _lastDate = DateTime(
    _today.year,
    _today.month + 4,
    _today.day,
  );
  late DateTime _selectedDate = _today;
  late final ClinicAvailabilityRepository _availabilityRepository =
      widget.availabilityRepository ?? ClinicService();

  List<ClinicSlot> _slots = const [];
  ClinicSlot? _selectedSlot;
  String? _availabilityError;
  String? _bookingError;
  bool _isLoadingAvailability = true;
  bool _isBooking = false;
  int _availabilityRequestId = 0;

  String get _formattedDate {
    final weekday = _weekdays[_selectedDate.weekday - 1];
    final month = _months[_selectedDate.month - 1];
    return "$weekday, ${_selectedDate.day} de $month";
  }

  String _timeLabel(ClinicSlot slot) {
    final localTime = slot.startsAt.toLocal();
    return "${localTime.hour.toString().padLeft(2, "0")}:"
        "${localTime.minute.toString().padLeft(2, "0")}";
  }

  @override
  void initState() {
    super.initState();
    _loadAvailability(_selectedDate);
  }

  Future<void> _loadAvailability(DateTime date) async {
    final requestId = ++_availabilityRequestId;
    setState(() {
      _isLoadingAvailability = true;
      _availabilityError = null;
      _bookingError = null;
      _selectedSlot = null;
    });
    try {
      final slots = await _availabilityRepository.fetchAvailability(
        clinicSlug: widget.clinicSlug,
        date: date,
      );
      if (!mounted || requestId != _availabilityRequestId) return;
      setState(() {
        _slots = slots;
        _isLoadingAvailability = false;
      });
    } catch (error) {
      if (!mounted || requestId != _availabilityRequestId) return;
      setState(() {
        _slots = const [];
        _isLoadingAvailability = false;
        _availabilityError = switch (error) {
          ApiException(:final message) => message,
          FormatException(:final message) => message.toString(),
          _ => "No se pudo cargar la disponibilidad. Intenta de nuevo.",
        };
      });
    }
  }

  Future<void> _submitBooking() async {
    final slot = _selectedSlot;
    if (slot == null || _isBooking) return;
    setState(() {
      _isBooking = true;
      _bookingError = null;
    });
    try {
      final provider = AppProviderScope.maybeOf(context);
      if (provider == null) {
        throw StateError("La sesión local no está disponible.");
      }
      await provider.createLocalAppointment(
        clinicSlug: widget.clinicSlug,
        clinicName: widget.clinicName,
        startsAt: slot.startsAt,
        durationMinutes: slot.durationMinutes,
        estimatedFee: slot.estimatedFee,
      );
      if (!mounted) return;
      setState(() {
        _isBooking = false;
        _selectedSlot = null;
        _bookingError = null;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("¡Cita confirmada!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isBooking = false;
        _bookingError = switch (error) {
          ApiException(:final message) => message,
          FormatException(:final message) => message.toString(),
          StateError(:final message) => "$message",
          _ => "No se pudo guardar la cita localmente. Intenta de nuevo.",
        };
      });
    }
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
          "Reserva tu cita",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.navy,
                fontSize: 18,
              ),
        ),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 7, 20, 20),
          children: [
            Text(
              "Elige fecha y hora",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                  ),
            ),
            const SizedBox(height: 5),
            Text(
              "Selecciona el momento que mejor te convenga.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 17),
            _CalendarCard(
              today: _today,
              selectedDate: _selectedDate,
              lastDate: _lastDate,
              onDateChanged: (date) {
                final selectedDate = DateUtils.dateOnly(date);
                setState(() => _selectedDate = selectedDate);
                _loadAvailability(selectedDate);
              },
            ),
            const SizedBox(height: 19),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Horarios disponibles",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 17,
                        ),
                  ),
                ),
                Text(
                  "Hora local",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 11),
            if (_isLoadingAvailability)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 26),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.teal,
                    key: Key("availability-loading-indicator"),
                  ),
                ),
              )
            else if (_availabilityError case final error?)
              _AvailabilityError(
                message: error,
                onRetry: () => _loadAvailability(_selectedDate),
              )
            else if (_slots.isEmpty)
              const _NoAvailability()
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slot in _slots)
                    _TimeSlotButton(
                      key: ValueKey("appointment-slot-${slot.id}"),
                      time: _timeLabel(slot),
                      selected: slot.id == _selectedSlot?.id,
                      onPressed: () => setState(() {
                        _selectedSlot = slot;
                        _bookingError = null;
                      }),
                    ),
                ],
              ),
            if (_bookingError case final error?) ...[
              const SizedBox(height: 12),
              _BookingError(message: error),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _BookingSummary(
          clinicName: widget.clinicName,
          formattedDate: _formattedDate,
          selectedTime:
              _selectedSlot == null ? null : _timeLabel(_selectedSlot!),
          estimatedFee: _selectedSlot?.estimatedFee,
          isLoading: _isBooking,
          canConfirm: !_isLoadingAvailability && _selectedSlot != null,
          onConfirm: _submitBooking,
        ),
      ),
    );
  }
}

class _AvailabilityError extends StatelessWidget {
  const _AvailabilityError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Reintentar"),
          ),
        ],
      ),
    );
  }
}

class _NoAvailability extends StatelessWidget {
  const _NoAvailability();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        "La clínica no publicó horarios disponibles para esta fecha.",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _BookingError extends StatelessWidget {
  const _BookingError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key("appointment-booking-error"),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFB42318).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFFB42318),
            ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.today,
    required this.selectedDate,
    required this.lastDate,
    required this.onDateChanged,
  });

  final DateTime today;
  final DateTime selectedDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: Localizations.override(
          context: context,
          locale: const Locale("es", "EC"),
          delegates: GlobalMaterialLocalizations.delegates,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.teal,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColors.ink,
                  ),
            ),
            child: CalendarDatePicker(
              initialDate: selectedDate,
              firstDate: today,
              lastDate: lastDate,
              currentDate: today,
              onDateChanged: onDateChanged,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeSlotButton extends StatelessWidget {
  const _TimeSlotButton({
    super.key,
    required this.time,
    required this.selected,
    required this.onPressed,
  });

  final String time;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: EdgeInsets.zero,
        foregroundColor: selected ? Colors.white : AppColors.ink,
        backgroundColor: selected ? AppColors.teal : Colors.white,
        side: BorderSide(
          color: selected ? AppColors.teal : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(time),
      ),
    );
  }
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({
    required this.clinicName,
    required this.formattedDate,
    required this.selectedTime,
    required this.estimatedFee,
    required this.isLoading,
    required this.canConfirm,
    required this.onConfirm,
  });

  final String clinicName;
  final String formattedDate;
  final String? selectedTime;
  final double? estimatedFee;
  final bool isLoading;
  final bool canConfirm;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.teal,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Resumen de reserva",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  color: AppColors.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinicName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 13,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: AppColors.muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  formattedDate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: AppColors.muted,
              ),
              const SizedBox(width: 5),
              Text(
                selectedTime ?? "Selecciona un horario",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          if (selectedTime != null) ...[
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Tarifa estimada · no se realiza cobro",
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                Text(
                  estimatedFee == null
                      ? "Tarifa pendiente"
                      : "\$${estimatedFee!.toStringAsFixed(2)}",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canConfirm && !isLoading ? onConfirm : null,
              icon: isLoading
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.event_available_outlined, size: 17),
              label: Text(isLoading ? "Reservando..." : "Confirmar cita"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
