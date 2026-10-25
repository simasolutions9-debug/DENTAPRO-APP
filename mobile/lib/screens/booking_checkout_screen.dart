import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";

import "../app_theme.dart";

class BookingCheckoutScreen extends StatefulWidget {
  const BookingCheckoutScreen({
    super.key,
    this.clinicName = "Clínica Sonríe",
    this.doctorName = "Dra. Valentina Ortiz",
    this.specialty = "Odontología general",
    this.priceLabel = "\$28",
  });

  final String clinicName;
  final String doctorName;
  final String specialty;
  final String priceLabel;

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
  static const _availableTimes = ["09:00", "10:30", "12:00", "15:00"];
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
  late DateTime _selectedDate = _today.add(const Duration(days: 2));
  String _selectedTime = "10:30";

  String get _formattedDate {
    final weekday = _weekdays[_selectedDate.weekday - 1];
    final month = _months[_selectedDate.month - 1];
    return "$weekday, ${_selectedDate.day} de $month";
  }

  void _showMockConfirmation() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text("Vista previa: no se realizó ningún cobro."),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                setState(() => _selectedDate = DateUtils.dateOnly(date));
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
            Row(
              children: [
                for (var index = 0;
                    index < _availableTimes.length;
                    index++) ...[
                  if (index > 0) const SizedBox(width: 7),
                  Expanded(
                    child: _TimeSlotButton(
                      time: _availableTimes[index],
                      selected: _availableTimes[index] == _selectedTime,
                      onPressed: () {
                        setState(() => _selectedTime = _availableTimes[index]);
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Text(
              "Los horarios mostrados son de ejemplo.",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _BookingSummary(
          clinicName: widget.clinicName,
          doctorName: widget.doctorName,
          specialty: widget.specialty,
          priceLabel: widget.priceLabel,
          formattedDate: _formattedDate,
          selectedTime: _selectedTime,
          onConfirm: _showMockConfirmation,
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
    required this.doctorName,
    required this.specialty,
    required this.priceLabel,
    required this.formattedDate,
    required this.selectedTime,
    required this.onConfirm,
  });

  final String clinicName;
  final String doctorName;
  final String specialty;
  final String priceLabel;
  final String formattedDate;
  final String selectedTime;
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
              const Spacer(),
              Text(
                priceLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.navy,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
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
                    const SizedBox(height: 2),
                    Text(
                      "$doctorName · $specialty",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 10,
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
                selectedTime,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.lock_outline_rounded, size: 17),
              label: const Text("Confirmar y Pagar"),
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
