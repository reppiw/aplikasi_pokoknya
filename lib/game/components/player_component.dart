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

  static const _speed    = 80.0;  // world units per second
  static const _fps      = 12.0;  // animation frames per second

  late final SpriteAnimationComponent _sprite;
  late final SpriteAnimation _idleAnim;
  late final SpriteAnimation _walkAnim;
  late final TextComponent   _label;

  bool _isWalking = false;

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
  }

  @override
  void update(double dt) {
    super.update(dt);

    final j = joystick;
    if (j == null || j.direction == JoystickDirection.idle) {
      _setWalking(false);
      return;
    }

    _setWalking(true);

    // Move in isometric space: joystick X maps to iso-right (↗), Y to iso-down (↘)
    // We combine screen-space joystick input into world movement along iso axes.
    final jx = j.relativeDelta.x;
    final jy = j.relativeDelta.y;

    // Isometric basis vectors (normalised):
    //   iso-right  = (+1,  +0.5) in screen space  (moving along col axis)
    //   iso-down   = (-1,  +0.5) in screen space  (moving along row axis)
    final dx = (jx - jy) * (kTileW / 2) * _speed * dt / 100;
    final dy = (jx + jy) * (kTileH / 8) * _speed * dt / 100;

    position += Vector2(dx, dy);

    // Keep player within world bounds (rough clamp)
    position.x = position.x.clamp(
      -(kCols * kTileW / 2),
      kCols * kTileW / 2,
    );
    position.y = position.y.clamp(0, kRows * kTileH / 4);

    // Flip sprite horizontally based on horizontal movement direction
    if (jx < -0.1) {
      _sprite.scale.x = -1; // facing left
    } else if (jx > 0.1) {
      _sprite.scale.x = 1;  // facing right
    }

    // Notify map to check room
    final map = game.world.children.whereType<OfficeMap>().firstOrNull;
    map?.checkPlayerRoom(position);
  }

  void _setWalking(bool walking) {
    if (_isWalking == walking) return;
    _isWalking = walking;
    _sprite.animation = walking ? _walkAnim : _idleAnim;
  }
}
