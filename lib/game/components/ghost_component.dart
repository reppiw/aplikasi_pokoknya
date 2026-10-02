import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/avatar_state.dart';
import '../office_game.dart';
import 'office_map.dart';

/// Ghost avatar for another user using a different Human colour variant.
///
/// Colour variants 1–7 are assigned by hashing the userId so each
/// user consistently gets the same character skin.
///
/// Visual rules:
///   isOnline  → 85% opacity, idle animation
///   !isOnline → 35% opacity, gentle sine-wave float
class GhostComponent extends PositionComponent with HasGameReference<OfficeGame> {
  GhostComponent({required this._state})
      : super(anchor: Anchor.bottomCenter);

  AvatarState _state;

  late SpriteAnimationComponent _sprite;
  late TextComponent _label;

  double _floatTimer = 0;

  /// World-space position we are interpolating toward (updated by Firebase).
  late Vector2 _targetPosition;

  /// Fraction of the gap closed per second for remote-player smoothing.
  /// Higher = snappier, lower = laggier. 8 feels responsive without teleporting.
  static const _lerpSpeed = 8.0;

  @override
  Future<void> onLoad() async {
    position = Vector2(_state.x, _state.y);
    _targetPosition = position.clone();

    final variant = _variantFor(_state.userId);

    // Uses game.images so the prefix override ('assets/') applies
    final idleImg = await game.images
        .load('Characters/Human/Human_${variant}_Idle0.png');
    final idleAnim = SpriteAnimation.spriteList(
      [Sprite(idleImg)],
      stepTime: 1.0,
      loop: true,
    );

    _sprite = SpriteAnimationComponent(
      animation: idleAnim,
      size: Vector2(kTileW, kTileH),
      anchor: Anchor.bottomCenter,
    );
    _sprite.opacity = _state.isOnline ? 0.85 : 0.35;
    add(_sprite);

    _label = TextComponent(
      text: _state.userId,
      anchor: Anchor.bottomCenter,
      position: Vector2(0, -kTileH + 20),
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
    // Store the target; update() will interpolate smoothly toward it.
    _targetPosition = Vector2(newState.x, newState.y);
    _sprite.opacity = newState.isOnline ? 0.85 : 0.35;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Smoothly chase the latest Firebase position.
    position += (_targetPosition - position) * (_lerpSpeed * dt).clamp(0.0, 1.0);

    if (!_state.isOnline) {
      _floatTimer += dt * 1.8;
      _sprite.position = Vector2(0, -4 + 4 * math.sin(_floatTimer));
    }
  }

  /// Deterministically assign colour variant 1–7 from userId hash.
  /// Variant 0 is reserved for the local player.
  static int _variantFor(String userId) {
    final hash = userId.codeUnits.fold(0, (a, b) => a + b);
    return (hash % 7) + 1;
  }
}
