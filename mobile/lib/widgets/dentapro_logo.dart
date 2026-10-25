import "dart:ui" as ui;

import "package:flutter/material.dart";

import "../app_theme.dart";

class DentaproLogo extends StatelessWidget {
  const DentaproLogo({super.key, this.markSize = 94, this.wordmarkSize = 31});

  final double markSize;
  final double wordmarkSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Dentapro",
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DentaproMark(size: markSize),
            const SizedBox(height: 5),
            Text(
              "Dentapro",
              style: TextStyle(
                color: AppColors.navy,
                fontSize: wordmarkSize,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DentaproMark extends StatelessWidget {
  const DentaproMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _ToothMarkPainter());
  }
}

class _ToothMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 64;
    final scaleY = size.height / 64;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final outline = Path()
      ..moveTo(19, 7)
      ..cubicTo(11, 4, 5, 10, 6, 19)
      ..cubicTo(7, 31, 13, 46, 19, 55)
      ..cubicTo(22, 59, 25, 56, 27, 49)
      ..cubicTo(29, 42, 30, 35, 32, 35)
      ..cubicTo(35, 35, 36, 43, 39, 51)
      ..cubicTo(41, 57, 45, 59, 48, 53)
      ..cubicTo(54, 43, 59, 28, 58, 18)
      ..cubicTo(58, 9, 51, 4, 43, 7)
      ..cubicTo(38, 9, 35, 12, 32, 12)
      ..cubicTo(28, 12, 24, 9, 19, 7)
      ..close();

    final gradient = ui.Gradient.linear(
      const Offset(5, 8),
      const Offset(59, 54),
      const [AppColors.navy, AppColors.cyan, AppColors.teal],
      const [0, 0.58, 1],
    );
    final toothPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(outline, toothPaint);

    final check = Path()
      ..moveTo(23, 32)
      ..lineTo(30, 39)
      ..lineTo(43, 25);
    final checkPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(22, 27),
        const Offset(44, 40),
        const [AppColors.blue, AppColors.teal],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(check, checkPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
