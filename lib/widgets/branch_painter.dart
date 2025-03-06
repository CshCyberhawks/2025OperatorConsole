import 'package:flutter/material.dart';

class BranchPainter extends CustomPainter {
  final String selectedLevel;
  final bool isAlgaeSelected;

  BranchPainter({required this.selectedLevel, this.isAlgaeSelected = false});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Paint for the main vertical pipe
    final Paint mainPipePaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill
      ..strokeWidth = 3.0;

    // Paint for the horizontal pipes
    final Paint horizontalPipePaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill
      ..strokeWidth = 3.0;

    // Paint for the selected level
    final Paint selectedPaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.fill;

    // Paint for the border
    final Paint borderPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw the main vertical pipe
    final double mainPipeWidth = width * 0.15;
    final double mainPipeLeft = (width - mainPipeWidth) / 2;
    final Rect mainPipeRect = Rect.fromLTWH(
      mainPipeLeft,
      0,
      mainPipeWidth,
      height, // Extend to full height
    );

    final RRect mainPipeRRect = RRect.fromRectAndRadius(
      mainPipeRect,
      const Radius.circular(8),
    );

    canvas.drawRRect(mainPipeRRect, mainPipePaint);
    canvas.drawRRect(mainPipeRRect, borderPaint);

    // Draw the horizontal pipes (branches)
    final double branchHeight = height * 0.12;
    final double branchWidth = width * 0.3;

    // Positions for the three branches (L2, L3, L4)
    final List<double> branchPositions = [
      height * 0.65, // L2 (bottom branch) - moved up slightly
      height * 0.35, // L3 (middle branch) - moved up slightly
      height * 0.05, // L4 (top branch) - at the very top
    ];

    // Draw each branch
    for (int i = 0; i < branchPositions.length; i++) {
      final double branchY = branchPositions[i];

      // Regular horizontal branches for all levels
      final Rect branchRect = Rect.fromLTWH(
        mainPipeLeft + mainPipeWidth,
        branchY,
        branchWidth,
        branchHeight,
      );

      final RRect branchRRect = RRect.fromRectAndRadius(
        branchRect,
        const Radius.circular(8),
      );

      // Check if this branch is selected
      final String level = 'L${i + 2}'; // L2, L3, L4
      if (level == selectedLevel && !isAlgaeSelected) {
        canvas.drawRRect(branchRRect, selectedPaint);
      } else {
        canvas.drawRRect(branchRRect, horizontalPipePaint);
      }

      canvas.drawRRect(branchRRect, borderPaint);
    }

    // Draw the tilted shelf at the bottom (L1)
    // Create a path for the tilted shelf
    final Path shelfPath = Path();

    // Starting point (attached to the main pipe)
    final double shelfStartX = mainPipeLeft + mainPipeWidth;
    final double shelfStartY = height * 0.9; // Position near bottom

    // Width and height of the shelf
    final double shelfWidth = width * 0.3;
    final double shelfHeight = height * 0.08;

    // End point (tilted downward)
    final double shelfEndX = shelfStartX + shelfWidth;
    final double shelfEndY =
        shelfStartY + shelfHeight * 0.3; // Slight tilt downward

    // Create the shelf path
    shelfPath.moveTo(shelfStartX, shelfStartY);
    shelfPath.lineTo(shelfEndX, shelfEndY);
    shelfPath.lineTo(shelfEndX, shelfEndY + shelfHeight);
    shelfPath.lineTo(shelfStartX, shelfStartY + shelfHeight);
    shelfPath.close();

    // Check if L1 is selected (the shelf)
    if (selectedLevel == 'L1' && !isAlgaeSelected) {
      canvas.drawPath(shelfPath, selectedPaint);
    } else {
      canvas.drawPath(shelfPath, horizontalPipePaint);
    }
    canvas.drawPath(shelfPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    final BranchPainter old = oldDelegate as BranchPainter;
    return old.selectedLevel != selectedLevel ||
        old.isAlgaeSelected != isAlgaeSelected;
  }
}
