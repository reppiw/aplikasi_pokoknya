import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Graph-paper grid texture used across multiple Neo-Brutalist screens.
///
/// Draws a grid of thin lines at [step] intervals with the given [alpha].
/// Wrap in a `Positioned.fill` or size as needed.
class GridBackground extends StatelessWidget {
  const GridBackground({
    super.key,
    this.step = 40.0,
    this.alpha = 0.05,
  });

  /// Spacing between grid lines in logical pixels.
  final double step;

  /// Opacity of the grid lines (0–1).
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(step: step, alpha: alpha),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.step, required this.alpha});

  final double step;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NeoColors.ink.withValues(alpha: alpha)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => step != old.step || alpha != old.alpha;
}
