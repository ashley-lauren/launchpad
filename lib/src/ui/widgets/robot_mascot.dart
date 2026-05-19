import 'package:flutter/material.dart';

class RobotMascot extends StatelessWidget {
  const RobotMascot({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(86, 86), painter: _RobotPainter());
  }
}

class _RobotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shell = Paint()..color = const Color(0xFF21262D);
    final cyan = Paint()..color = const Color(0xFF00D7FF);
    final green = Paint()..color = const Color(0xFF7EE787);
    final stroke = Paint()
      ..color = const Color(0xFF8B949E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final head = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .16,
        size.height * .20,
        size.width * .68,
        size.height * .56,
      ),
      const Radius.circular(14),
    );
    canvas.drawRRect(head, shell);
    canvas.drawRRect(head, stroke);
    canvas.drawCircle(Offset(size.width * .38, size.height * .46), 5, cyan);
    canvas.drawCircle(Offset(size.width * .62, size.height * .46), 5, green);
    canvas.drawLine(
      Offset(size.width * .38, size.height * .62),
      Offset(size.width * .62, size.height * .62),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * .50, size.height * .20),
      Offset(size.width * .50, size.height * .08),
      stroke,
    );
    canvas.drawCircle(Offset(size.width * .50, size.height * .06), 4, cyan);
    canvas.drawCircle(Offset(size.width * .12, size.height * .50), 4, green);
    canvas.drawCircle(Offset(size.width * .88, size.height * .50), 4, green);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
