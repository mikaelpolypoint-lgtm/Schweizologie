import 'dart:math';
import 'package:flutter/material.dart';

class ContourMapBackground extends StatelessWidget {
  final Widget child;

  const ContourMapBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: const Color(0xFFF0EAD6)), // Cream background
        CustomPaint(
          painter: _ContourPainter(),
          size: Size.infinite,
        ),
        child,
      ],
    );
  }
}

class _ContourPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD3CFC2).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final random = Random(42); // Fixed seed for consistent pattern

    for (int i = 0; i < 15; i++) {
      final path = Path();
      double startY = random.nextDouble() * size.height;
      path.moveTo(0, startY);

      double currentX = 0;
      double currentY = startY;

      while (currentX < size.width) {
        final controlX = currentX + random.nextDouble() * 100 + 50;
        final controlY = currentY + (random.nextDouble() - 0.5) * 100;
        final endX = currentX + random.nextDouble() * 200 + 100;
        final endY = currentY + (random.nextDouble() - 0.5) * 150;

        path.quadraticBezierTo(controlX, controlY, endX, endY);
        currentX = endX;
        currentY = endY;
      }
      canvas.drawPath(path, paint);
    }
    
    // Draw some closed loops (hills)
    for (int i = 0; i < 5; i++) {
       final path = Path();
       double centerX = random.nextDouble() * size.width;
       double centerY = random.nextDouble() * size.height;
       double radius = random.nextDouble() * 100 + 50;
       
       path.addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));
       // Inner loop
       path.addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius * 0.7));
       
       canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
