import "package:flutter/material.dart";

import "../app_theme.dart";

class DentalOdontogramScreen extends StatelessWidget {
  const DentalOdontogramScreen({super.key});

  static const _upperTeeth = [
    _Tooth(18, _ToothCondition.healthy),
    _Tooth(17, _ToothCondition.healthy),
    _Tooth(16, _ToothCondition.review),
    _Tooth(15, _ToothCondition.healthy),
    _Tooth(14, _ToothCondition.healthy),
    _Tooth(13, _ToothCondition.healthy),
    _Tooth(12, _ToothCondition.healthy),
    _Tooth(11, _ToothCondition.healthy),
    _Tooth(21, _ToothCondition.healthy),
    _Tooth(22, _ToothCondition.healthy),
    _Tooth(23, _ToothCondition.review),
    _Tooth(24, _ToothCondition.healthy),
    _Tooth(25, _ToothCondition.healthy),
    _Tooth(26, _ToothCondition.healthy),
    _Tooth(27, _ToothCondition.urgent),
    _Tooth(28, _ToothCondition.healthy),
  ];

  static const _lowerTeeth = [
    _Tooth(48, _ToothCondition.healthy),
    _Tooth(47, _ToothCondition.healthy),
    _Tooth(46, _ToothCondition.healthy),
    _Tooth(45, _ToothCondition.healthy),
    _Tooth(44, _ToothCondition.review),
    _Tooth(43, _ToothCondition.healthy),
    _Tooth(42, _ToothCondition.healthy),
    _Tooth(41, _ToothCondition.healthy),
    _Tooth(31, _ToothCondition.healthy),
    _Tooth(32, _ToothCondition.healthy),
    _Tooth(33, _ToothCondition.healthy),
    _Tooth(34, _ToothCondition.healthy),
    _Tooth(35, _ToothCondition.healthy),
    _Tooth(36, _ToothCondition.urgent),
    _Tooth(37, _ToothCondition.healthy),
    _Tooth(38, _ToothCondition.healthy),
  ];

  static const _treatments = [
    _Treatment(
      date: "24 oct 2026",
      doctor: "Dra. Valentina Ortiz",
      treatment: "Limpieza dental",
      detail: "Profilaxis y revisión general",
      icon: Icons.auto_awesome_rounded,
      tint: AppColors.teal,
    ),
    _Treatment(
      date: "14 jul 2026",
      doctor: "Dr. Mateo Ruiz",
      treatment: "Restauración con resina",
      detail: "Pieza 16 · tratamiento completado",
      icon: Icons.health_and_safety_outlined,
      tint: AppColors.blue,
    ),
    _Treatment(
      date: "05 mar 2026",
      doctor: "Dra. Valentina Ortiz",
      treatment: "Evaluación de ortodoncia",
      detail: "Control preventivo",
      icon: Icons.fact_check_outlined,
      tint: AppColors.cyan,
    ),
  ];

  int get _healthyCount => _countFor(_ToothCondition.healthy);
  int get _reviewCount => _countFor(_ToothCondition.review);
  int get _urgentCount => _countFor(_ToothCondition.urgent);

  int _countFor(_ToothCondition condition) => [
        ..._upperTeeth,
        ..._lowerTeeth,
      ].where((tooth) => tooth.condition == condition).length;

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
          "Odontograma",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.navy,
                fontSize: 18,
              ),
        ),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            Text(
              "Tu salud dental",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 25,
                  ),
            ),
            const SizedBox(height: 5),
            Text(
              "Consulta el estado de tus piezas y tratamientos.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatusSummaryCard(
                    count: _healthyCount,
                    label: "Sanos",
                    color: _ToothCondition.healthy.color,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _StatusSummaryCard(
                    count: _reviewCount,
                    label: "Revisión",
                    color: _ToothCondition.review.color,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _StatusSummaryCard(
                    count: _urgentCount,
                    label: "Urgencia",
                    color: _ToothCondition.urgent.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _OdontogramCard(
              upperTeeth: _upperTeeth,
              lowerTeeth: _lowerTeeth,
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Historial de Tratamientos",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 17,
                        ),
                  ),
                ),
                Text(
                  "${_treatments.length} registros",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final treatment in _treatments) ...[
              _TreatmentCard(treatment: treatment),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 3),
            Text(
              "Información de ejemplo para esta vista previa.",
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

class _StatusSummaryCard extends StatelessWidget {
  const _StatusSummaryCard({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$count",
            style: TextStyle(
              color: color,
              fontSize: 21,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.ink,
                    fontSize: 10,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OdontogramCard extends StatelessWidget {
  const _OdontogramCard({
    required this.upperTeeth,
    required this.lowerTeeth,
  });

  final List<_Tooth> upperTeeth;
  final List<_Tooth> lowerTeeth;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key("odontogram-chart"),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.045),
            blurRadius: 17,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
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
                      "Dentadura permanente",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Identificación dental FDI",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.muted,
                size: 19,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _ArchLabel(label: "ARCADA SUPERIOR"),
          const SizedBox(height: 9),
          _DentalRow(teeth: upperTeeth),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border),
          ),
          const _ArchLabel(label: "ARCADA INFERIOR"),
          const SizedBox(height: 9),
          _DentalRow(teeth: lowerTeeth),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 13,
            runSpacing: 9,
            children: [
              _LegendItem(
                color: Color(0xFF25AE91),
                label: "Sano",
              ),
              _LegendItem(
                color: Color(0xFFE6A52E),
                label: "Revisión",
              ),
              _LegendItem(
                color: Color(0xFFE45763),
                label: "Urgencia",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArchLabel extends StatelessWidget {
  const _ArchLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.muted,
            fontSize: 9,
            letterSpacing: 0.8,
          ),
    );
  }
}

class _DentalRow extends StatelessWidget {
  const _DentalRow({required this.teeth});

  final List<_Tooth> teeth;

  @override
  Widget build(BuildContext context) {
    final leftSide = teeth.take(8).toList();
    final rightSide = teeth.skip(8).toList();

    return Row(
      children: [
        Expanded(child: _ToothGroup(teeth: leftSide)),
        const SizedBox(width: 8),
        Expanded(child: _ToothGroup(teeth: rightSide)),
      ],
    );
  }
}

class _ToothGroup extends StatelessWidget {
  const _ToothGroup({required this.teeth});

  final List<_Tooth> teeth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final tooth in teeth)
          Expanded(
            child: _ToothCell(tooth: tooth),
          ),
      ],
    );
  }
}

class _ToothCell extends StatelessWidget {
  const _ToothCell({required this.tooth});

  final _Tooth tooth;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(17, 22),
          painter: _ToothPainter(color: tooth.condition.color),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "${tooth.number}",
            style: TextStyle(
              color: tooth.condition.color,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToothPainter extends CustomPainter {
  const _ToothPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final tooth = Path()
      ..moveTo(size.width * 0.5, size.height * 0.1)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.1,
        size.width * 0.27,
        size.height * 0.23,
        size.width * 0.14,
        size.height * 0.19,
      )
      ..cubicTo(
        size.width * -0.01,
        size.height * 0.16,
        size.width * 0.02,
        size.height * 0.43,
        size.width * 0.15,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.71,
        size.width * 0.22,
        size.height * 0.95,
        size.width * 0.39,
        size.height * 0.93,
      )
      ..cubicTo(
        size.width * 0.47,
        size.height * 0.91,
        size.width * 0.45,
        size.height * 0.73,
        size.width * 0.5,
        size.height * 0.69,
      )
      ..cubicTo(
        size.width * 0.55,
        size.height * 0.73,
        size.width * 0.53,
        size.height * 0.91,
        size.width * 0.61,
        size.height * 0.93,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.95,
        size.width * 0.76,
        size.height * 0.71,
        size.width * 0.85,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.98,
        size.height * 0.43,
        size.width * 1.01,
        size.height * 0.16,
        size.width * 0.86,
        size.height * 0.19,
      )
      ..cubicTo(
        size.width * 0.73,
        size.height * 0.23,
        size.width * 0.66,
        size.height * 0.1,
        size.width * 0.5,
        size.height * 0.1,
      )
      ..close();

    canvas.drawPath(
      tooth,
      Paint()
        ..color = color.withValues(alpha: 0.13)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      tooth,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.55
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ToothPainter oldDelegate) => oldDelegate.color != color;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.ink,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  const _TreatmentCard({required this.treatment});

  final _Treatment treatment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: treatment.tint.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(treatment.icon, color: treatment.tint, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        treatment.treatment,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 13,
                                ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      treatment.date,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  treatment.doctor,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  treatment.detail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 10,
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

enum _ToothCondition {
  healthy,
  review,
  urgent;

  Color get color => switch (this) {
        _ToothCondition.healthy => const Color(0xFF25AE91),
        _ToothCondition.review => const Color(0xFFE6A52E),
        _ToothCondition.urgent => const Color(0xFFE45763),
      };
}

class _Tooth {
  const _Tooth(this.number, this.condition);

  final int number;
  final _ToothCondition condition;
}

class _Treatment {
  const _Treatment({
    required this.date,
    required this.doctor,
    required this.treatment,
    required this.detail,
    required this.icon,
    required this.tint,
  });

  final String date;
  final String doctor;
  final String treatment;
  final String detail;
  final IconData icon;
  final Color tint;
}
