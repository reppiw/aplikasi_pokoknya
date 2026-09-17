import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _Particle {
  double x, y;
  double startX, startY;
  final double targetX, targetY;
  final double size;
  final Color color;
  final double seed;   // [0,1) deterministic per-particle
  final double depth;  // [0.45, 1.35)
  final double delay;  // ms
  double progress = 0; // updated each paint pass

  _Particle({
    required this.x,      required this.y,
    required this.startX, required this.startY,
    required this.targetX, required this.targetY,
    required this.size,
    required this.color,
    required this.seed,
    required this.depth,
    required this.delay,
  });
}

// ---------------------------------------------------------------------------
// Trigger mode
// ---------------------------------------------------------------------------
enum ParticleTrigger { mount, hover, click }

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Flutter port of the React Bits ParticleText component.
///
/// Samples glyph pixels from an offscreen [ui.Picture], scatters particle
/// dots, then animates them converging back to form the text.
/// Pointer repulsion, idle drift, and glow are all supported.
class ParticleText extends StatefulWidget {
  const ParticleText({
    super.key,
    this.text            = 'React Bits',
    this.particleSize    = 2.0,
    this.density         = 4,
    this.color           = Colors.white,
    this.highlightColor  = const Color(0xFF8B5CF6),
    this.scatter         = 180.0,
    this.gatherDuration  = const Duration(milliseconds: 1600),
    this.stagger         = const Duration(milliseconds: 420),
    this.pointerRepel    = 40.0,
    this.repelRadius     = 120.0,
    this.idleDrift       = 0.7,
    this.trigger         = ParticleTrigger.mount,
    this.fontSize        = 64.0,
    this.fontWeight      = FontWeight.w800,
    this.fontFamily,
    this.glow            = true,
  });

  final String       text;
  final double       particleSize;
  final int          density;
  final Color        color;
  final Color        highlightColor;
  final double       scatter;
  final Duration     gatherDuration;
  final Duration     stagger;
  final double       pointerRepel;
  final double       repelRadius;
  final double       idleDrift;
  final ParticleTrigger trigger;
  final double       fontSize;
  final FontWeight   fontWeight;
  final String?      fontFamily;
  final bool         glow;

  @override
  State<ParticleText> createState() => _ParticleTextState();
}

class _ParticleTextState extends State<ParticleText>
    with SingleTickerProviderStateMixin {
  List<_Particle> _particles = [];
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;

  bool _gathering  = false;
  double _gatherStart = 0; // ms
  bool _built      = false;

  // Pointer
  double _pointerX  = 0;
  double _pointerY  = 0;
  double _smoothPX  = 0;
  double _smoothPY  = 0;
  bool   _pointerActive = false;

  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Tick
  // -------------------------------------------------------------------------

  void _onTick(Duration elapsed) {
    _elapsed = elapsed;
    // Smooth pointer
    _smoothPX += (_pointerX - _smoothPX) * 0.18;
    _smoothPY += (_pointerY - _smoothPY) * 0.18;
    if (mounted) setState(() {});
  }

  // -------------------------------------------------------------------------
  // Particle build (async — samples the glyph raster)
  // -------------------------------------------------------------------------

  Future<void> _buildParticles(Size size) async {
    _lastSize = size;
    _built = true;

    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);

    final style = ui.TextStyle(
      color:      Colors.white,
      fontSize:   widget.fontSize,
      fontWeight: widget.fontWeight,
      fontFamily: widget.fontFamily,
    );
    final paraStyle = ui.ParagraphStyle(
      textAlign:  TextAlign.left,
      fontWeight: widget.fontWeight,
      fontSize:   widget.fontSize,
      fontFamily: widget.fontFamily,
    );
    final builder = ui.ParagraphBuilder(paraStyle)
      ..pushStyle(style)
      ..addText(widget.text);
    final para = builder.build()
      ..layout(ui.ParagraphConstraints(width: size.width));

    canvas.drawParagraph(para, Offset.zero);

    final picture = recorder.endRecording();
    final textW   = para.longestLine.ceil().clamp(1, size.width.toInt());
    final textH   = para.height.ceil().clamp(1, size.height.toInt());
    final image   = await picture.toImage(textW, textH);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    picture.dispose();

    if (byteData == null || !mounted) return;

    final bytes  = byteData.buffer.asUint8List();
    final step   = widget.density.clamp(2, 20);
    final targets = <Offset>[];

    for (int y = 0; y < textH; y += step) {
      for (int x = 0; x < textW; x += step) {
        final idx = (y * textW + x) * 4;
        final alpha = bytes[idx + 3];
        if (alpha > 40) {
          targets.add(Offset(
            size.width  / 2 - textW / 2 + x,
            size.height / 2 - textH / 2 + y,
          ));
        }
      }
    }

    if (targets.isEmpty) return;

    const maxParticles = 5200;
    final stride = math.max(1, (targets.length / maxParticles).ceil());

    final baseR  = widget.color;
    final highR  = widget.highlightColor;

    // deterministic seed — kept for future particle shuffling
    final selected = [
      for (int i = 0; i < targets.length; i += stride) targets[i]
    ];

    _particles = List.generate(selected.length, (index) {
      final target = selected[index];
      // Deterministic seed (same cheap hash as original)
      final seed  = ((index * 9301 + 49297) % 233280) / 233280.0;
      final depth = 0.45 + ((index * 233 + 97) % 1000) / 1000.0 * 0.9;
      final blend = (target.dx / size.width + (seed - 0.5) * 0.35).clamp(0.0, 1.0);
      final col   = Color.lerp(baseR, highR, blend)!;

      final angle    = seed * math.pi * 2;
      final distance = widget.scatter * (0.35 + depth * 0.75);
      final startX   = target.dx + math.cos(angle) * distance + (seed - 0.5) * widget.scatter * 0.45;
      final startY   = target.dy + math.sin(angle) * distance + (depth - 0.9) * widget.scatter * 0.45;

      return _Particle(
        x: startX, y: startY,
        startX: startX, startY: startY,
        targetX: target.dx, targetY: target.dy,
        size:  math.max(0.6, widget.particleSize * (0.75 + 0.45)),
        color: col,
        seed:  seed,
        depth: depth,
        delay: seed * widget.stagger.inMilliseconds,
      );
    });

    _pointerX = size.width  / 2;
    _pointerY = size.height / 2;
    _smoothPX = _pointerX;
    _smoothPY = _pointerY;

    _startGather();
    if (mounted) setState(() {});
  }

  void _startGather() {
    if (_particles.isEmpty) return;
    for (final p in _particles) {
      p.startX = p.x;
      p.startY = p.y;
    }
    _gatherStart = _elapsed.inMilliseconds.toDouble();
    _gathering   = true;
  }

  // -------------------------------------------------------------------------
  // Pointer handlers
  // -------------------------------------------------------------------------

  void _onPointerMove(Offset local) {
    _pointerX     = local.dx;
    _pointerY     = local.dy;
    _pointerActive = true;
  }

  void _onPointerLeave() => _pointerActive = false;

  void _onHover() {
    if (widget.trigger == ParticleTrigger.hover) _startGather();
  }

  void _onTap() {
    if (widget.trigger == ParticleTrigger.click) _startGather();
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      if (!_built || size != _lastSize) {
        // Schedule after layout; avoid calling setState during build
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _buildParticles(size),
        );
      }

      return GestureDetector(
        onTap: _onTap,
        child: MouseRegion(
          onHover: (e) {
            _onPointerMove(e.localPosition);
            _onHover();
          },
          onExit: (_) => _onPointerLeave(),
          child: Listener(
            onPointerMove:  (e) => _onPointerMove(e.localPosition),
            onPointerUp:    (_) => _onPointerLeave(),
            child: CustomPaint(
              size: size,
              painter: _ParticleTextPainter(
                particles:    _particles,
                elapsed:      _elapsed.inMilliseconds.toDouble(),
                gatherStart:  _gatherStart,
                gathering:    _gathering,
                gatherMs:     widget.gatherDuration.inMilliseconds.toDouble(),
                idleDrift:    widget.idleDrift,
                pointerActive: _pointerActive,
                smoothPX:     _smoothPX,
                smoothPY:     _smoothPY,
                pointerRepel: widget.pointerRepel,
                repelRadius:  widget.repelRadius,
                glow:         widget.glow,
                highlightColor: widget.highlightColor,
                particleSize: widget.particleSize,
                onGatherComplete: () => _gathering = false,
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

double _easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();

class _ParticleTextPainter extends CustomPainter {
  _ParticleTextPainter({
    required this.particles,
    required this.elapsed,
    required this.gatherStart,
    required this.gathering,
    required this.gatherMs,
    required this.idleDrift,
    required this.pointerActive,
    required this.smoothPX,
    required this.smoothPY,
    required this.pointerRepel,
    required this.repelRadius,
    required this.glow,
    required this.highlightColor,
    required this.particleSize,
    required this.onGatherComplete,
  });

  final List<_Particle> particles;
  final double elapsed;
  final double gatherStart;
  final bool   gathering;
  final double gatherMs;
  final double idleDrift;
  final bool   pointerActive;
  final double smoothPX, smoothPY;
  final double pointerRepel;
  final double repelRadius;
  final bool   glow;
  final Color  highlightColor;
  final double particleSize;
  final VoidCallback onGatherComplete;

  @override
  void paint(Canvas canvas, Size size) {
    bool allDone = true;

    // ── Step 1: update particle positions ──────────────────────────────────
    for (final p in particles) {
      double baseX = p.targetX;
      double baseY = p.targetY;
      double progress = 1.0;

      if (gathering) {
        final local = (elapsed - gatherStart - p.delay) / math.max(1.0, gatherMs);
        progress = local.clamp(0.0, 1.0);
        final eased = _easeOutCubic(progress);
        baseX = p.startX + (p.targetX - p.startX) * eased;
        baseY = p.startY + (p.targetY - p.startY) * eased;
        if (progress < 1.0) allDone = false;
      } else if (idleDrift > 0) {
        final t = elapsed * 0.001;
        baseX += math.sin(t * 0.9  + p.seed * 10) * idleDrift * p.depth;
        baseY += math.cos(t * 0.75 + p.depth * 10) * idleDrift * p.depth;
      }

      // Pointer repulsion
      if (pointerActive && pointerRepel > 0 && repelRadius > 0) {
        final dx = baseX - smoothPX;
        final dy = baseY - smoothPY;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist > 0 && dist < repelRadius) {
          final force = math.pow(1 - dist / repelRadius, 2) * pointerRepel;
          baseX += (dx / dist) * force;
          baseY += (dy / dist) * force;
        }
      }

      // Lerp particle toward target
      p.x += (baseX - p.x) * 0.22;
      p.y += (baseY - p.y) * 0.22;
      p.progress = progress;
    }

    // ── Step 2: glow pass (blurred, drawn underneath) ──────────────────────
    if (glow) {
      final glowPaint = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
        ..style = PaintingStyle.fill;

      canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
      for (final p in particles) {
        final alpha = ((0.35 + p.progress * 0.65) * 0.45).clamp(0.0, 1.0);
        glowPaint.color = highlightColor.withValues(alpha: alpha);
        canvas.drawCircle(Offset(p.x, p.y), p.size * 1.8, glowPaint);
      }
      canvas.restore();
    }

    // ── Step 3: crisp particle pass (on top, no blur) ──────────────────────
    final sharpPaint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final alpha = (0.35 + p.progress * 0.65).clamp(0.0, 1.0);
      sharpPaint.color = p.color.withValues(alpha: alpha);

      if (p.size <= 2.1) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(p.x, p.y),
            width:  p.size,
            height: p.size,
          ),
          sharpPaint,
        );
      } else {
        canvas.drawCircle(Offset(p.x, p.y), p.size / 2, sharpPaint);
      }
    }

    if (gathering && allDone) onGatherComplete();
  }

  @override
  bool shouldRepaint(_ParticleTextPainter old) => true;
}
