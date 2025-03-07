import 'package:flutter/material.dart';
import 'dart:math' as math;

class HexagonPainter extends CustomPainter {
  final String selectedFace;

  HexagonPainter({required this.selectedFace});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint selectedPaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.fill;

    final double width = size.width;
    final double height = size.height;
    final double centerX = width / 2;
    final double centerY = height / 2;
    final double radius = width / 2;

    // Create hexagon path with a flat face at the bottom
    final Path hexagonPath = Path();
    final List<Offset> vertices = [];

    // Calculate vertices for a flat-bottom hexagon
    // Starting at 0 degrees and going clockwise with 60-degree increments
    for (int i = 0; i < 6; i++) {
      // 30 degrees offset to get flat faces at top and bottom
      final double angle = (i * 60) * (math.pi / 180);
      final double x = centerX + radius * math.cos(angle);
      final double y = centerY + radius * math.sin(angle);
      vertices.add(Offset(x, y));
    }

    // Draw the hexagon
    hexagonPath.moveTo(vertices[0].dx, vertices[0].dy);
    for (int i = 1; i < 6; i++) {
      hexagonPath.lineTo(vertices[i].dx, vertices[i].dy);
    }
    hexagonPath.close();

    // Draw the base hexagon
    canvas.drawPath(hexagonPath, paint);

    // Define face positions to match the button layout
    // The face positions need to match the visual layout in reef_position_visualizer.dart
    final Map<String, List<int>> facePositions = {
      'A': [1, 2], // Bottom face (between vertices 3 and 4)
      'B': [2, 3], // Bottom-right face
      'C': [3, 4], // Top-right face
      'D': [4, 5], // Top face
      'E': [5, 0], // Top-left face
      'F': [0, 1], // Bottom-left face
    };

    if (facePositions.containsKey(selectedFace)) {
      final List<int> selectedIndices = facePositions[selectedFace]!;
      final Path selectedPath = Path();

      // Create a path for the selected face
      selectedPath.moveTo(centerX, centerY);
      selectedPath.lineTo(
        vertices[selectedIndices[0]].dx,
        vertices[selectedIndices[0]].dy,
      );
      selectedPath.lineTo(
        vertices[selectedIndices[1]].dx,
        vertices[selectedIndices[1]].dy,
      );
      selectedPath.close();

      canvas.drawPath(selectedPath, selectedPaint);
    }

    // Draw the border
    canvas.drawPath(hexagonPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate as HexagonPainter).selectedFace != selectedFace;
  }
}
