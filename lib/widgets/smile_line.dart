import 'package:flutter/material.dart';

class SmileLinePainter extends CustomPainter {
  final Color color;

  SmileLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(
      size.width / 2, // control point x (middle)
      12, // control point y (how deep the smile curves)
      size.width, // end point x (right side)
      0, // end point y (same height as start)
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
