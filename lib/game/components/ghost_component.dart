import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/avatar_state.dart';

/// A ghost avatar representing another user's last known position.
///
/// Visual rules:
///   isOnline  → semi-transparent blue tint, subtle pulse animation
///   !isOnline → grey, faded, gentle float animation
///
/// Phase 2: replace CircleComponent with a SpriteComponent using the
///           character sprite sheet with a different tint/shader.
class GhostComponent extends PositionComponent {
  GhostComponent({required this.state})
      : super(
          position: Vector2(state.x, state.y),
          size: Vector2.all(32),
          anchor: Anchor.center,
        );

  AvatarState state;

  late CircleComponent _body;
  late TextComponent _label;

  // Float animation state (for offline ghosts)
  double _floatTimer = 0;
  static const _floatAmplitude = 3.0;
  static const _floatSpeed = 2.0;

  @override
  Future<void> onLoad() async {
    _body = CircleComponent(
      radius: 14,
      paint: _paintFor(state),
      anchor: Anchor.center,
    );
    add(_body);

    _label = TextComponent(
      text: state.userId,
      anchor: Anchor.bottomCenter,
      position: Vector2(0, -16),
      textRenderer: TextPaint(
        style: TextStyle(
          color: state.isOnline
              ? const Color(0xFF4488FF)
              : const Color(0xFF888888),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    add(_label);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!state.isOnline) {
      // Gentle vertical float for offline ghosts
      _floatTimer += dt * _floatSpeed;
      _body.position = Vector2(
        0,
        _floatAmplitude * (0 - 1) * (_floatTimer % (2 * 3.14159)).abs() /
                3.14159 +
            _floatAmplitude,
      );
    }
  }

  /// Called by OfficeGame when a new AvatarState arrives for this user.
  void updateState(AvatarState newState) {
    state = newState;
    // Animate to new position
    position = Vector2(newState.x, newState.y);
    _body.paint = _paintFor(newState);
  }

  static Paint _paintFor(AvatarState state) {
    return Paint()
      ..color = state.isOnline
          ? const Color(0xFF6CB4FF).withValues(alpha: 0.75)
          : const Color(0xFFAAAAAA).withValues(alpha: 0.4);
  }
}
