import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'office_map.dart';

/// The local user's avatar using Kenney Human sprites.
///
/// Movement: WASD keys mapped to isometric directions —
///   W → top-left    (screen: x--, y--)
///   S → bottom-right(screen: x++, y++)
///   A → bottom-left (screen: x--, y++)
///   D → top-right   (screen: x++, y--)
///
/// Animations:
///   idle → Human_0_Idle0.png
///   walk → Human_0_Run0–9.png (10 frames at 12fps)
class PlayerComponent extends PositionComponent
    with HasGameReference, KeyboardHandler {
  PlayerComponent({
    required this.username,
    required Vector2 startPosition,
  }) : super(
          position: startPosition,
          anchor: Anchor.bottomCenter,
        );

  final String username;

  static const _speed = 200.0; // world units per second
  static const _fps   = 12.0;

  late final SpriteAnimationComponent _sprite;
  late final SpriteAnimation _idleAnim;
  late final SpriteAnimation _walkAnim;
  late final TextComponent _label;

  bool _isWalking = false;

  // Track which keys are currently held
  final _keys = <LogicalKeyboardKey>{};

  @override
  Future<void> onLoad() async {
    final idleImage =
        await game.images.load('Characters/Human/Human_0_Idle0.png');
    _idleAnim = SpriteAnimation.spriteList(
      [Sprite(idleImage)],
      stepTime: 1.0,
      loop: true,
    );

    final walkFrames = await Future.wait(
      List.generate(
          10, (i) => game.images.load('Characters/Human/Human_0_Run$i.png')),
    );
    _walkAnim = SpriteAnimation.spriteList(
      walkFrames.map(Sprite.new).toList(),
      stepTime: 1.0 / _fps,
      loop: true,
    );

    _sprite = SpriteAnimationComponent(
      animation: _idleAnim,
      size: Vector2(kTileW, kTileH),
      anchor: Anchor.bottomCenter,
    );
    add(_sprite);

    _label = TextComponent(
      text: username,
      anchor: Anchor.bottomCenter,
      position: Vector2(0, -kTileH + 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFF000000), blurRadius: 4)],
        ),
      ),
    );
    add(_label);
  }

  // ── Keyboard input ──────────────────────────────────────────────────────────

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keys
      ..clear()
      ..addAll(keysPressed);
    return false; // don't consume — let other handlers see it too
  }

  // ── Game loop ───────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);

    // Build movement vector from held keys
    double vx = 0;
    double vy = 0;

    // Isometric screen-space vectors per key:
    //   W → top-left    (-1, -0.5)
    //   S → bot-right   (+1, +0.5)
    //   A → bot-left    (-1, +0.5)
    //   D → top-right   (+1, -0.5)
    if (_keys.contains(LogicalKeyboardKey.keyW)) { vx += -1; vy += -0.5; }
    if (_keys.contains(LogicalKeyboardKey.keyS)) { vx +=  1; vy +=  0.5; }
    if (_keys.contains(LogicalKeyboardKey.keyA)) { vx += -1; vy +=  0.5; }
    if (_keys.contains(LogicalKeyboardKey.keyD)) { vx +=  1; vy += -0.5; }

    final moving = vx != 0 || vy != 0;
    _setWalking(moving);

    if (!moving) return;

    // Normalise to unit length so diagonals don't move faster than cardinals
    final length = (vx * vx + vy * vy);
    if (length > 0) {
      final mag = length < 1e-6 ? 1.0 : length;
      final invMag = 1.0 / math.sqrt(mag);
      vx *= invMag;
      vy *= invMag;
    }
    position += Vector2(vx * _speed * dt, vy * _speed * dt);

    // Clamp to map bounds
    final maxX = kCols * kTileStepX;
    final maxY = kRows * kTileStepY * 2;
    position.x = position.x.clamp(-maxX, maxX);
    position.y = position.y.clamp(-kTileH, maxY);

    // Flip sprite: moving right (D) → face right; moving left (W/A) → face left
    if (vx > 0) {
      _sprite.scale.x = 1;
    } else if (vx < 0) {
      _sprite.scale.x = -1;
    }

    // Check room
    final map = game.world.children.whereType<OfficeMap>().firstOrNull;
    map?.checkPlayerRoom(position);
  }

  void _setWalking(bool walking) {
    if (_isWalking == walking) return;
    _isWalking = walking;
    _sprite.animation = walking ? _walkAnim : _idleAnim;
  }
}
