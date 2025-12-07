import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A reusable widget that provides a grid paper background pattern
/// Used consistently across the app for a cohesive design
class GridBackground extends StatelessWidget {
  final Widget child;
  final Color? gridColor;
  final double gridSize;
  final Color? backgroundColor;

  const GridBackground({
    super.key,
    required this.child,
    this.gridColor,
    this.gridSize = 40.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background color
        if (backgroundColor != null)
          Positioned.fill(
            child: ColoredBox(color: backgroundColor!),
          ),
        // Grid pattern
        Positioned.fill(
          child: CustomPaint(
            painter: GridPatternPainter(
              gridColor: gridColor ?? AppColors.gridDark,
              gridSize: gridSize,
            ),
          ),
        ),
        // Content
        child,
      ],
    );
  }
}

/// Custom painter for drawing the grid pattern
class GridPatternPainter extends CustomPainter {
  final Color gridColor;
  final double gridSize;

  GridPatternPainter({
    required this.gridColor,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withValues(alpha: 0.08)
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    // Avoid drawing border lines on the very edge to prevent frame outlines.
    final double verticalLimit = size.width - gridSize;
    final double horizontalLimit = size.height - gridSize;

    // Draw vertical lines inside the frame.
    for (double x = gridSize; x < verticalLimit; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines inside the frame.
    for (double y = gridSize; y < horizontalLimit; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
