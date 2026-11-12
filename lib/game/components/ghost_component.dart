import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/avatar_state.dart';
import 'player_component.dart';

/// Remote user's avatar — a colored circle with their userId as label.
///
/// Position is smoothly interpolated toward the latest Firebase value.
/// Offline ghosts fade out and gently float up and down.
class GhostComponent extends PositionComponent {
  GhostComponent({required AvatarState state})
      : _state = state,
        super(
          position: Vector2(state.x, state.y),
          size: Vector2.all(PlayerComponent.kAvatarRadius * 2),
          anchor: Anchor.center,
        );

  AvatarState _state;

  late CircleComponent _circle;
  late TextComponent   _label;

  late Vector2 _targetPosition;
  double _floatTimer = 0;

  /// Fraction of gap closed per second for remote-player smoothing.
  static const _lerpSpeed = 8.0;

  /// Reusable scratch vector.
  final Vector2 _scratch = Vector2.zero();

  @override
  Future<void> onLoad() async {
    _targetPosition = position.clone();

    final color = _colorFor(_state.userId);

    _circle = CircleComponent(
      radius: PlayerComponent.kAvatarRadius,
      paint: Paint()..color = color.withValues(alpha: _state.isOnline ? 0.85 : 0.35),
      anchor: Anchor.center,
      position: Vector2.all(PlayerComponent.kAvatarRadius),
    );
    add(_circle);

    _label = TextComponent(
      text: _state.userId,
      anchor: Anchor.bottomCenter,
      position: Vector2(PlayerComponent.kAvatarRadius, -4),
      textRenderer: TextPaint(
        style: TextStyle(
          color: _state.isOnline
              ? const Color(0xFF88DDFF)
              : const Color(0xFFAAAAAA),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          shadows: const [Shadow(color: Color(0xFF000000), blurRadius: 4)],
        ),
      ),
    );
    add(_label);
  }

  /// Called by OfficeGame when a fresh AvatarState arrives for this user.
  void updateState(AvatarState newState) {
    _state = newState;
    _targetPosition = Vector2(newState.x, newState.y);
    final color = _colorFor(newState.userId);
    _circle.paint.color =
        color.withValues(alpha: newState.isOnline ? 0.85 : 0.35);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Smooth lerp toward latest Firebase position.
    _scratch
      ..setFrom(_targetPosition)
      ..sub(position)
      ..scale((_lerpSpeed * dt).clamp(0.0, 1.0));
    position.add(_scratch);

    // Offline float animation.
    if (!_state.isOnline) {
      _floatTimer += dt * 1.8;
      _circle.position = Vector2(
        PlayerComponent.kAvatarRadius,
        PlayerComponent.kAvatarRadius + 3 * math.sin(_floatTimer),
      );
    }
  }

  /// Deterministically assign a color from userId hash.
  static Color _colorFor(String userId) {
    const palette = [
      Color(0xFFE05C5C), // red
      Color(0xFFE08C2A), // orange
      Color(0xFF5CB85C), // green
      Color(0xFF5BBFBF), // teal
      Color(0xFF5B7FE0), // blue
      Color(0xFFA05CE0), // purple
      Color(0xFFE05CA0), // pink
    ];
    final hash = userId.codeUnits.fold(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }
}
