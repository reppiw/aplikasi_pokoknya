import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'joystick_controller.dart';
import 'office_map.dart';

/// The local user's avatar using Kenney Human sprites.
///
/// Animations:
///   idle  → Human_0_Idle0.png          (single frame)
///   walk  → Human_0_Run0–9.png         (10 frames, ~12fps)
class PlayerComponent extends PositionComponent with HasGameReference {
  PlayerComponent({
    required this.username,
    required Vector2 startPosition,
  }) : super(
          position: startPosition,
          anchor: Anchor.bottomCenter,
        );

  final String username;
  JoystickController? joystick;

  /// Cached reference to the map — set once in [onLoad], avoids a
  /// [whereType] scan every frame.
  OfficeMap? _map;

  /// Top speed in world units per second.
  static const _speed = 200.0;

  /// How quickly velocity ramps up to full speed (units/s²).
  static const _acceleration = 1200.0;

  /// How quickly velocity bleeds off when input is released (units/s²).
  static const _friction = 1000.0;

  static const _fps = 12.0; // animation frames per second

  late final SpriteAnimationComponent _sprite;
  late final SpriteAnimation _idleAnim;
  late final SpriteAnimation _walkAnim;
  late final TextComponent   _label;

  bool _isWalking = false;

  /// Current velocity in world space (pixels per second).
  final Vector2 _velocity = Vector2.zero();

  /// Reusable scratch vector — avoids a heap allocation in [update].
  final Vector2 _scratch = Vector2.zero();

  @override
  Future<void> onLoad() async {
    // ── Load idle (single frame) ────────────────────────────────────────────
    final idleImage = await game.images.load('Characters/Human/Human_0_Idle0.png');
    _idleAnim = SpriteAnimation.spriteList(
      [Sprite(idleImage)],
      stepTime: 1.0,
      loop: true,
    );

    // ── Load walk (10 frames) ───────────────────────────────────────────────
    final walkFrames = await Future.wait(
      List.generate(10, (i) => game.images.load('Characters/Human/Human_0_Run$i.png')),
    );
    _walkAnim = SpriteAnimation.spriteList(
      walkFrames.map(Sprite.new).toList(),
      stepTime: 1.0 / _fps,
      loop: true,
    );

    // ── Sprite component ────────────────────────────────────────────────────
    _sprite = SpriteAnimationComponent(
      animation: _idleAnim,
      size: Vector2(kTileW, kTileH),      // 128 × 256 — matches tile scale
      anchor: Anchor.bottomCenter,
    );
    add(_sprite);

    // ── Username label ──────────────────────────────────────────────────────
    _label = TextComponent(
      text: username,
      anchor: Anchor.bottomCenter,
      position: Vector2(0, -kTileH + 20), // float above sprite head
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Color(0xFF000000), blurRadius: 4),
          ],
        ),
      ),
    );
    add(_label);

    // Cache the map reference once so update() doesn't scan world.children
    // every frame.
    _map = game.world.children.whereType<OfficeMap>().firstOrNull;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final j = joystick;
    final bool hasInput =
        j != null && j.direction != JoystickDirection.idle;

    if (hasInput) {
      final jx = j!.relativeDelta.x;
      final jy = j.relativeDelta.y;

      // ── Quantize to the 4 isometric axes ──────────────────────────────────
      //
      // isoToWorld basis (from office_map.dart):
      //   +col (NE): world ( +kTileW/2,  +kTileH/8 )  — screen right-down
      //   +row (SE): world ( -kTileW/2,  +kTileH/8 )  — screen left-down
      //
      // Joystick screen axes: jx = right (+1), jy = down (+1).
      //
      // To find which iso axis the stick is pointing along, project onto
      // each iso basis direction (normalised):
      //
      //   col unit in screen = ( +1,  +0.5 ) / |…| → dot = jx + 0.5*jy
      //   row unit in screen = ( -1,  +0.5 ) / |…| → dot = -jx + 0.5*jy
      //
      // The dominant projection wins; its sign picks the direction.
      final dotCol =  jx + 0.5 * jy; // positive = NE, negative = SW
      final dotRow = -jx + 0.5 * jy; // positive = SE, negative = NW

      double snapJx, snapJy;
      if (dotCol.abs() >= dotRow.abs()) {
        // Move along col axis (NE / SW)
        snapJx = dotCol.sign;
        snapJy = 0.0;
      } else {
        // Move along row axis (SE / NW)
        snapJx = 0.0;
        snapJy = dotRow.sign;
      }

      // Convert snapped iso-axis direction back to world-space velocity.
      // Isometric world basis (2:1 ratio, matching isoToWorld in office_map):
      //   col step: (+kTileW/2, +kTileH/8)
      //   row step: (-kTileW/2, +kTileH/8)
      final targetVx = (snapJx - snapJy) * _speed;
      final targetVy = (snapJx + snapJy) * _speed * (kTileH / 8) / (kTileW / 2);

      // Accelerate toward the target velocity each frame.
      _velocity.x = _moveToward(_velocity.x, targetVx, _acceleration * dt);
      _velocity.y = _moveToward(_velocity.y, targetVy, _acceleration * dt);

      // Flip sprite based on snapped horizontal intent.
      if (snapJx < 0) {
        _sprite.scale.x = -1; // facing left  (SW or NW)
      } else if (snapJx > 0) {
        _sprite.scale.x =  1; // facing right (NE or SE)
      }
      // For pure row-axis moves (snapJx == 0) keep whatever facing we had.
    } else {
      // No input — bleed off velocity with friction, but skip entirely if
      // already stopped to avoid unnecessary math every idle frame.
      if (_velocity.x != 0.0 || _velocity.y != 0.0) {
        _velocity.x = _moveToward(_velocity.x, 0, _friction * dt);
        _velocity.y = _moveToward(_velocity.y, 0, _friction * dt);
      }
    }

    final bool moving = _velocity.length2 > 1.0;
    _setWalking(moving);

    if (moving) {
      // Reuse _scratch to avoid a Vector2 allocation per frame.
      _scratch.setFrom(_velocity);
      _scratch.scale(dt);
      position.add(_scratch);

      // Keep player within world bounds.
      position.x = position.x.clamp(
        -(kCols * kTileW / 2),
        kCols * kTileW / 2,
      );
      position.y = position.y.clamp(0, kRows * kTileH / 4);

      // Notify map — use cached reference, no scan needed.
      _map?.checkPlayerRoom(position);
    }
  }

  /// Moves [current] toward [target] by at most [maxDelta], without
  /// overshooting.
  static double _moveToward(double current, double target, double maxDelta) {
    final diff = target - current;
    if (diff.abs() <= maxDelta) return target;
    return current + diff.sign * maxDelta;
  }

  void _setWalking(bool walking) {
    if (_isWalking == walking) return;
    _isWalking = walking;
    _sprite.animation = walking ? _walkAnim : _idleAnim;
  }
}
