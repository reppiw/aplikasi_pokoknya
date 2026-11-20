import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

import 'joystick_controller.dart';
import 'office_map.dart';

/// The local user's avatar — a colored circle with a username label.
/// Movement is 8-directional, speed-capped, with AABB wall collision
/// via Flame's CollisionDetection system.
class PlayerComponent extends PositionComponent
    with HasGameReference, CollisionCallbacks {
  PlayerComponent({
    required this.username,
    required Vector2 startPosition,
    this.onPositionChanged,
  })  : _lastSyncedPosition = startPosition.clone(),
        super(
          position: startPosition,
          size: Vector2.all(kAvatarRadius * 2),
          anchor: Anchor.center,
        );

  static const double kAvatarRadius = 14.0;
  static const double _speed        = 160.0; // px/s
  static const double _kSyncInterval = 0.2;  // 5 Hz update rate
  static const double _kMinMoveDistanceSq = 16.0; // 4 px threshold

  final String username;
  final void Function(Vector2 position)? onPositionChanged;
  JoystickController? joystick;
  OfficeMap? _map;

  final Vector2 _lastSyncedPosition;
  double _syncTimer = 0.0;
  bool _wasMoving = false;

  /// Reusable scratch vector — no heap alloc per frame.
  final Vector2 _move = Vector2.zero();

  @override
  Future<void> onLoad() async {
    // Circle body
    add(CircleComponent(
      radius: kAvatarRadius,
      paint: Paint()..color = const Color(0xFF5B4FCF),
      anchor: Anchor.center,
      position: Vector2.all(kAvatarRadius),
    ));

    // Username label above the circle
    add(TextComponent(
      text: username,
      anchor: Anchor.bottomCenter,
      position: Vector2(kAvatarRadius, -4),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFF000000), blurRadius: 4)],
        ),
      ),
    ));

    // Hitbox for collision detection
    add(CircleHitbox()..collisionType = CollisionType.active);

    // Cache map reference
    _map = game.world.children.whereType<OfficeMap>().firstOrNull;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final j = joystick;
    final isMoving = j != null && j.direction != JoystickDirection.idle;

    if (isMoving) {
      _wasMoving = true;

      // Normalize diagonal input so diagonal speed = straight speed.
      _move
        ..setFrom(j.relativeDelta)
        ..normalize()
        ..scale(_speed * dt);

      // Attempt X move, then Y move separately — allows sliding along walls.
      _tryMove(Vector2(_move.x, 0));
      _tryMove(Vector2(0, _move.y));

      _map?.checkPlayerRoom(position);

      // Throttled position sync while moving (e.g. 5 Hz)
      _syncTimer += dt;
      if (_syncTimer >= _kSyncInterval) {
        if (position.distanceToSquared(_lastSyncedPosition) >= _kMinMoveDistanceSq) {
          _lastSyncedPosition.setFrom(position);
          onPositionChanged?.call(position);
        }
        _syncTimer = 0.0;
      }
    } else if (_wasMoving) {
      // User just released joystick / stopped moving: immediately send final settled position
      _wasMoving = false;
      _syncTimer = 0.0;
      if (position.distanceToSquared(_lastSyncedPosition) >= 1.0) {
        _lastSyncedPosition.setFrom(position);
        onPositionChanged?.call(position);
      }
    }
  }

  void _tryMove(Vector2 delta) {
    final next = position + delta;
    // Keep within map bounds
    next.x = next.x.clamp(kWallThick + kAvatarRadius, kMapWidth  - kWallThick - kAvatarRadius);
    next.y = next.y.clamp(kWallThick + kAvatarRadius, kMapHeight - kWallThick - kAvatarRadius);

    // Use OfficeMap's instance walkability check (which knows the actual rooms).
    final map = _map;
    if (map != null) {
      if (map.walkable(next)) position = next;
    } else {
      // No map yet — allow movement (safe fallback, map loads async).
      position = next;
    }
  }
}
