import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Virtual joystick rendered in the HUD (viewport space, not world space).
///
/// Wraps Flame's built-in JoystickComponent with Neo-Brutalist styling.
/// Added to camera.viewport so it stays fixed on screen regardless of
/// camera movement.
///
/// Positioned at horizontal center, 160 px from the bottom of the screen.
class JoystickController extends JoystickComponent {
  static const double _knobRadius  = 20.0;
  static const double _bgRadius    = 48.0;
  static const double _bottomInset = 160.0;

  JoystickController()
      : super(
          knob: CircleComponent(
            radius: _knobRadius,
            paint: Paint()..color = const Color(0xFF1A1A2E).withValues(alpha: 0.85),
          ),
          background: CircleComponent(
            radius: _bgRadius,
            paint: Paint()
              ..color = const Color(0xFFF5F0E8).withValues(alpha: 0.75)
              ..style = PaintingStyle.fill,
          ),
          // No margin — we position manually in onGameResize.
        );

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Centre horizontally, _bottomInset px above the bottom edge.
    position = Vector2(size.x / 2, size.y - _bottomInset);
  }
}
