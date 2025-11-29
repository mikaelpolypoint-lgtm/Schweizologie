import 'package:flutter/material.dart';
import '../models/city.dart';

class CitySign extends StatelessWidget {
  final City city;
  final String label;
  final bool isDragging;

  const CitySign({
    super.key,
    required this.city,
    required this.label,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    // Swiss Hiking Sign Style
    // Yellow background, Black text, Arrow shape (simulated with container for now)
    
    return Transform.rotate(
      angle: isDragging ? -0.05 : 0,
      child: Container(
        width: 200,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD100), // Swiss Hiking Yellow
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: isDragging ? 12 : 4,
              offset: isDragging ? const Offset(0, 8) : const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Arrow Tip Decoration (Right side)
            Positioned(
              right: -10,
              top: 20,
              child: Transform.rotate(
                angle: 0.785, // 45 degrees
                child: Container(
                  width: 40,
                  height: 40,
                  color: const Color(0xFFFFD100),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          city.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto', // Standard clear font
                          ),
                        ),
                        Text(
                          "${city.canton} • ${city.population > 0 ? '${(city.population / 1000).toStringAsFixed(1)}k' : ''}",
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on, size: 16, color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
