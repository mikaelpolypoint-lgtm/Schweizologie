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

    // Swiss Bounding Box
    const minLat = 45.82;
    const maxLat = 47.81;
    const minLng = 5.96;
    const maxLng = 10.50;
    
    // Calculate Aspect Ratio of the bounding box
    // 1 deg Lat ~= 111km, 1 deg Lng (at 47N) ~= 75km
    const latDist = (maxLat - minLat) * 111;
    final lngDist = (maxLng - minLng) * 75;
    final mapAspectRatio = lngDist / latDist;

    // Determine drawing bounds to preserve aspect ratio
    double drawWidth = size.width;
    double drawHeight = size.height;
    
    if (size.width / size.height > mapAspectRatio) {
      // Canvas is wider than map -> constrain width
      drawWidth = size.height * mapAspectRatio;
    } else {
      // Canvas is taller than map -> constrain height
      drawHeight = size.width / mapAspectRatio;
    }

    final double offsetX = (size.width - drawWidth) / 2;
    final double offsetY = (size.height - drawHeight) / 2;

    Offset getOffset(City city) {
      // Normalize to 0..1 within the bounding box
      final normX = (city.longitude - minLng) / (maxLng - minLng);
      final normY = (city.latitude - minLat) / (maxLat - minLat);
      
      // Map to centered drawing bounds
      // Invert Y because canvas Y grows downwards
      final x = offsetX + (normX * drawWidth);
      final y = offsetY + (drawHeight - (normY * drawHeight));
      
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
