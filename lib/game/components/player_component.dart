import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'joystick_controller.dart';
import 'office_map.dart';

/// The local user's avatar in the office world.
///
/// Phase 1: rendered as a coloured circle with username label.
/// Phase 2: replace CircleComponent with SpriteAnimationComponent
///           once character sprite sheets are added to assets/sprites/.
class PlayerComponent extends PositionComponent with HasGameReference {
  PlayerComponent({
    required this.username,
    required Vector2 startPosition,
  }) : super(
          position: startPosition,
          size: Vector2.all(32),
          anchor: Anchor.center,
        );

  final String username;

  /// Set by OfficeGame after both player and joystick are loaded.
  JoystickController? joystick;

  static const _speed = 120.0; // pixels per second
  static const _mapBounds = Rect.fromLTWH(20, 20, 560, 760);

  late final CircleComponent _body;
  late final TextComponent _label;

  @override
  Future<void> onLoad() async {
    // Avatar circle
    _body = CircleComponent(
      radius: 16,
      paint: Paint()..color = const Color(0xFF6C63FF),
      anchor: Anchor.center,
    );
    add(_body);

    // Username label above avatar
    _label = TextComponent(
      text: username,
      anchor: Anchor.bottomCenter,
      position: Vector2(0, -18),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF1A1A2E),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0xCCF5F0E8),
        ),
      ),
    );
    add(_label);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final j = joystick;
    if (j == null || j.direction == JoystickDirection.idle) return;

    final delta = j.relativeDelta * _speed * dt;
    final next = position + delta;

    // Clamp to map bounds
    position = Vector2(
      next.x.clamp(_mapBounds.left, _mapBounds.right),
      next.y.clamp(_mapBounds.top, _mapBounds.bottom),
    );

    // Notify map to check which room we're in
    final map = game.world.children.whereType<OfficeMap>().firstOrNull;
    map?.checkPlayerRoom(position);
  }
}
