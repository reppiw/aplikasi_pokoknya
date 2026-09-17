import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Animated gradient wave overlay.
///
/// Draws layered sine waves using pure Flutter Canvas — no GLSL shader needed,
/// works on all Android/iOS devices regardless of Impeller support.
///
/// Props mirror the original React Bits GradientWaves component.
class GradientWaves extends StatefulWidget {
  const GradientWaves({
    super.key,
    this.horizonColor     = const Color(0xFF5227FF),
    this.waveColor        = const Color(0xFFFF9FFC),
    this.crestColor       = Colors.white,
    this.speed            = 0.4,
    this.amplitude        = 2.5,
    this.waveScale        = 0.6,
    this.waveRatio        = 0.9,
    this.swell            = 35.0,
    this.turbulence       = 20.0,
    this.tilt             = 1.11,
    this.zoom             = 1.0,
    this.height           = 5.5,
    this.fogDepth         = 15.0,
    this.detail           = WaveDetail.medium,
    this.brightness       = 1.0,
    this.opacity          = 1.0,
    this.mouseInteraction = true,
    this.parallaxStrength = 0.5,
    this.grain            = true,
    this.grainIntensity   = 0.05,
  });

  final Color      horizonColor;
  final Color      waveColor;
  final Color      crestColor;
  final double     speed;
  final double     amplitude;
  final double     waveScale;
  final double     waveRatio;
  final double     swell;
  final double     turbulence;
  final double     tilt;
  final double     zoom;
  final double     height;
  final double     fogDepth;
  final WaveDetail detail;
  final double     brightness;
  final double     opacity;
  final bool       mouseInteraction;
  final double     parallaxStrength;
  final bool       grain;
  final double     grainIntensity;

  @override
  State<GradientWaves> createState() => _GradientWavesState();
}

enum WaveDetail { low, medium, high }

class _GradientWavesState extends State<GradientWaves>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _time = 0;

  double _mouseX = 0.5, _mouseY = 0.5;
  double _targetX = 0.5, _targetY = 0.5;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _time = elapsed.inMicroseconds / 1e6;
      _mouseX += 0.05 * (_targetX - _mouseX);
      _mouseY += 0.05 * (_targetY - _mouseY);
      if (mounted) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  int get _layerCount {
    switch (widget.detail) {
      case WaveDetail.low:    return 4;
      case WaveDetail.high:   return 10;
      case WaveDetail.medium: return 6;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return MouseRegion(
        onHover: (e) {
          if (!widget.mouseInteraction) return;
          _targetX = (e.localPosition.dx / size.width).clamp(0.0, 1.0);
          _targetY = (e.localPosition.dy / size.height).clamp(0.0, 1.0);
        },
        onExit: (_) { _targetX = 0.5; _targetY = 0.5; },
        child: Listener(
          onPointerMove: (e) {
            if (!widget.mouseInteraction) return;
            _targetX = (e.localPosition.dx / size.width).clamp(0.0, 1.0);
            _targetY = (e.localPosition.dy / size.height).clamp(0.0, 1.0);
          },
          child: CustomPaint(
            size: size,
            painter: _WavesPainter(
              time:         _time,
              mouseX:       _mouseX,
              mouseY:       _mouseY,
              widget:       widget,
              layerCount:   _layerCount,
            ),
          ),
        ),
      );
    });
  }
}

class _WavesPainter extends CustomPainter {
  _WavesPainter({
    required this.time,
    required this.mouseX,
    required this.mouseY,
    required this.widget,
    required this.layerCount,
  });

  final double       time;
  final double       mouseX;
  final double       mouseY;
  final GradientWaves widget;
  final int          layerCount;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = time * widget.speed;

    // ── Background gradient (horizon → transparent) ──────────────────────
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end:   Alignment.bottomCenter,
        colors: [
          widget.horizonColor.withValues(alpha: widget.opacity * 0.85),
          widget.horizonColor.withValues(alpha: widget.opacity * 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // ── Wave layers (back → front) ────────────────────────────────────────
    // Parallax offset from pointer
    final parallaxX = widget.mouseInteraction
        ? (mouseX - 0.5) * widget.parallaxStrength * w * 0.04
        : 0.0;

    for (int layer = 0; layer < layerCount; layer++) {
      final progress = layer / (layerCount - 1).clamp(1, layerCount);

      // Depth: back layers near horizon (top), front near bottom
      final depthY = h * (0.25 + progress * 0.6);

      // Colour interpolation: horizon → wave → crest
      final Color col;
      if (progress < 0.5) {
        col = Color.lerp(
          widget.horizonColor,
          widget.waveColor,
          progress * 2,
        )!;
      } else {
        col = Color.lerp(
          widget.waveColor,
          widget.crestColor,
          (progress - 0.5) * 2,
        )!;
      }

      // Fog: back layers are more transparent
      final fogAlpha = (progress * (widget.fogDepth / 15.0))
          .clamp(0.0, 1.0) * widget.opacity * widget.brightness;

      // Wave shape parameters vary per layer
      final freq1 = widget.waveScale * (0.5 + progress * 0.8) / 80.0;
      final freq2 = widget.waveScale * widget.waveRatio * (0.4 + progress * 0.6) / 50.0;
      final amp   = widget.amplitude * (4 + progress * 18);
      final phase1 = t * (0.8 + layer * 0.15) + layer * 1.3;
      final phase2 = t * (0.5 + layer * 0.1)  + layer * 2.1;

      // Swell distortion
      final swellOffset = widget.swell * 0.3 *
          math.sin(t * 0.3 + layer * 0.7);
      // Turbulence (vertical wobble of the horizon line)
      final turbOffset = widget.turbulence * 0.2 *
          math.cos(t * 0.2 + layer * 1.1);

      final path = Path();
      path.moveTo(0, h);

      for (double x = 0; x <= w + 2; x += 2) {
        final xp = x + parallaxX * (1 - progress);
        final y = depthY + turbOffset
            + math.sin(xp * freq1 + phase1 + swellOffset) * amp
            + math.sin(xp * freq2 + phase2) * amp * 0.5;
        if (x == 0) {
          path.lineTo(0, y);
        } else {
          path.lineTo(x, y);
        }
      }

      path.lineTo(w, h);
      path.close();

      final paint = Paint()
        ..color = col.withValues(alpha: fogAlpha)
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavesPainter old) => true;
}
