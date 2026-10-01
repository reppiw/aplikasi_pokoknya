import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Virtual joystick rendered in the HUD (viewport space, not world space).
///
/// Wraps Flame's built-in JoystickComponent with Neo-Brutalist styling.
/// Added to camera.viewport so it stays fixed on screen regardless of
/// camera movement.
class JoystickController extends JoystickComponent {
  JoystickController()
      : super(
          knob: CircleComponent(
            radius: 20,
            paint: Paint()..color = const Color(0xFF1A1A2E).withValues(alpha: 0.85),
          ),
          background: CircleComponent(
            radius: 48,
            paint: Paint()
              ..color = const Color(0xFFF5F0E8).withValues(alpha: 0.75)
              ..style = PaintingStyle.fill,
          ),
          margin: const EdgeInsets.only(left: 32, bottom: 48),
        );
}
