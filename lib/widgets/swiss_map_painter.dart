import 'package:flutter/material.dart';
import '../models/city.dart';

class SwissMapPainter extends CustomPainter {
  final List<City> visitedCities;
  final Color pathColor;
  final Color dotColor;

  SwissMapPainter({
    required this.visitedCities,
    this.pathColor = const Color(0xFFD52B1E),
    this.dotColor = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (visitedCities.isEmpty) return;

    final paintPath = Paint()
      ..color = pathColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final paintDot = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    // Swiss Bounding Box (Tight Fit)
    const minLat = 45.82;
    const maxLat = 47.81;
    const minLng = 5.96;
    const maxLng = 10.50;

    Offset getOffset(City city) {
      // Normalize to 0..1 within the bounding box
      final normX = (city.longitude - minLng) / (maxLng - minLng);
      final normY = (city.latitude - minLat) / (maxLat - minLat);
      
      // Map to full canvas size
      // Invert Y because canvas Y grows downwards
      final x = normX * size.width;
      final y = size.height - (normY * size.height);
      
      return Offset(x, y);
    }

    // Draw Path
    if (visitedCities.length > 1) {
      final path = Path();
      path.moveTo(getOffset(visitedCities.first).dx, getOffset(visitedCities.first).dy);
      for (int i = 1; i < visitedCities.length; i++) {
        final offset = getOffset(visitedCities[i]);
        path.lineTo(offset.dx, offset.dy);
      }
      canvas.drawPath(path, paintPath);
    }

    // Draw Dots
    for (final city in visitedCities) {
      canvas.drawCircle(getOffset(city), 3.0, paintDot);
    }
    
    // Highlight Start (Green) and End (Red)
    final paintStart = Paint()..color = Colors.green;
    final paintEnd = Paint()..color = const Color(0xFFD52B1E);
    
    canvas.drawCircle(getOffset(visitedCities.first), 5.0, paintStart);
    canvas.drawCircle(getOffset(visitedCities.last), 5.0, paintEnd);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
