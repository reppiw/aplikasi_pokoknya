import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../office_game.dart';

/// Office layout on a 600 × 800 logical canvas:
///
///  ┌───────────────────────────────────────────────────┐
///  │  LOUNGE (free)         │  GAME ROOM               │  y: 0–340
///  │  280 × 340             │  280 × 340               │
///  ├────────────────────────┴──────────────────────────┤
///  │               CORRIDOR  (20px)                    │  y: 340–360
///  ├───────────────────────────────────────────────────┤
///  │  MEETING ROOM          │  DEEP WORK               │  y: 360–800
///  │  280 × 440             │  280 × 440               │
///  └───────────────────────────────────────────────────┘
///  Wall = 20px on all sides → inner rooms start at x:20, y:20
///
/// Phase 2: replace RectangleComponents with a flame_tiled TiledComponent
///          loaded from assets/office/office.tmx
class OfficeMap extends Component with HasGameReference {
  OfficeMap({required this.onRoomChanged});

  final void Function(String? roomId) onRoomChanged;

  // ── Room geometry (inner coordinates, wall-inset) ──────────────────────────
  static const double _wall   = 20;
  static const double _corridor = 20;
  static const double _divider  = 20;
  static const double _topH   = 340;
  static const double _botH   = 440;

  static final _rooms = <_RoomDef>[
    _RoomDef(
      id: 'free',
      rect: Rect.fromLTWH(_wall, _wall, 280, _topH - _wall),
      floorColor:  const Color(0xFF8FCB9B),
      wallColor:   const Color(0xFF5A9E6F),
      label: 'LOUNGE',
      emoji: '☕',
      furniture: [
        // sofa cluster top-left
        _Furniture(Rect.fromLTWH(30, 40, 80, 40), const Color(0xFF4A7C59), 'sofa'),
        _Furniture(Rect.fromLTWH(30, 90, 40, 40), const Color(0xFF4A7C59), 'chair'),
        _Furniture(Rect.fromLTWH(80, 90, 40, 40), const Color(0xFF4A7C59), 'chair'),
        // coffee table
        _Furniture(Rect.fromLTWH(45, 140, 50, 30), const Color(0xFF6B4E2A), 'table'),
        // plant
        _Furniture(Rect.fromLTWH(200, 30, 24, 24), const Color(0xFF2D6A35), 'plant'),
        _Furniture(Rect.fromLTWH(220, 240, 24, 24), const Color(0xFF2D6A35), 'plant'),
      ],
    ),
    _RoomDef(
      id: 'looking_for_games',
      rect: Rect.fromLTWH(_wall + 280 + _divider, _wall, 280, _topH - _wall),
      floorColor:  const Color(0xFFFFBF69),
      wallColor:   const Color(0xFFE07B00),
      label: 'GAME ROOM',
      emoji: '🎮',
      furniture: [
        // gaming desk + chair
        _Furniture(Rect.fromLTWH(320, 40, 100, 50), const Color(0xFF8B5E00), 'desk'),
        _Furniture(Rect.fromLTWH(345, 100, 50, 40), const Color(0xFFC0392B), 'chair'),
        _Furniture(Rect.fromLTWH(450, 40, 100, 50), const Color(0xFF8B5E00), 'desk'),
        _Furniture(Rect.fromLTWH(475, 100, 50, 40), const Color(0xFFC0392B), 'chair'),
        // monitor placeholder (small rect on desk)
        _Furniture(Rect.fromLTWH(330, 30, 40, 24), const Color(0xFF1A1A2E), 'monitor'),
        _Furniture(Rect.fromLTWH(460, 30, 40, 24), const Color(0xFF1A1A2E), 'monitor'),
        // plant
        _Furniture(Rect.fromLTWH(540, 250, 24, 24), const Color(0xFF2D6A35), 'plant'),
      ],
    ),
    _RoomDef(
      id: 'busy',
      rect: Rect.fromLTWH(_wall, _topH + _corridor, 280, _botH - _wall),
      floorColor:  const Color(0xFFF4A261),
      wallColor:   const Color(0xFFD4622A),
      label: 'MEETING',
      emoji: '📋',
      furniture: [
        // round meeting table
        _Furniture(Rect.fromLTWH(60, 420, 160, 100), const Color(0xFF8B4513), 'table'),
        // chairs around the table
        _Furniture(Rect.fromLTWH(70,  400, 35, 28), const Color(0xFF5C3317), 'chair'),
        _Furniture(Rect.fromLTWH(130, 400, 35, 28), const Color(0xFF5C3317), 'chair'),
        _Furniture(Rect.fromLTWH(190, 400, 35, 28), const Color(0xFF5C3317), 'chair'),
        _Furniture(Rect.fromLTWH(70,  530, 35, 28), const Color(0xFF5C3317), 'chair'),
        _Furniture(Rect.fromLTWH(130, 530, 35, 28), const Color(0xFF5C3317), 'chair'),
        _Furniture(Rect.fromLTWH(190, 530, 35, 28), const Color(0xFF5C3317), 'chair'),
        // projector screen
        _Furniture(Rect.fromLTWH(40, 375, 200, 12), const Color(0xFFEEEEEE), 'screen'),
        // plant
        _Furniture(Rect.fromLTWH(230, 730, 24, 24), const Color(0xFF2D6A35), 'plant'),
      ],
    ),
    _RoomDef(
      id: 'deep_work',
      rect: Rect.fromLTWH(_wall + 280 + _divider, _topH + _corridor, 280, _botH - _wall),
      floorColor:  const Color(0xFF74B2E0),
      wallColor:   const Color(0xFF2C6E9E),
      label: 'DEEP WORK',
      emoji: '🎧',
      furniture: [
        // 4 individual focus desks
        _Furniture(Rect.fromLTWH(330, 400, 90, 50), const Color(0xFF1A4A6E), 'desk'),
        _Furniture(Rect.fromLTWH(450, 400, 90, 50), const Color(0xFF1A4A6E), 'desk'),
        _Furniture(Rect.fromLTWH(330, 510, 90, 50), const Color(0xFF1A4A6E), 'desk'),
        _Furniture(Rect.fromLTWH(450, 510, 90, 50), const Color(0xFF1A4A6E), 'desk'),
        // monitors
        _Furniture(Rect.fromLTWH(340, 390, 36, 18), const Color(0xFF1A1A2E), 'monitor'),
        _Furniture(Rect.fromLTWH(460, 390, 36, 18), const Color(0xFF1A1A2E), 'monitor'),
        _Furniture(Rect.fromLTWH(340, 500, 36, 18), const Color(0xFF1A1A2E), 'monitor'),
        _Furniture(Rect.fromLTWH(460, 500, 36, 18), const Color(0xFF1A1A2E), 'monitor'),
        // partition dividers between desks
        _Furniture(Rect.fromLTWH(428, 395, 8, 175), const Color(0xFF1A4A6E), 'divider'),
        // plant
        _Furniture(Rect.fromLTWH(540, 750, 24, 24), const Color(0xFF2D6A35), 'plant'),
      ],
    ),
  ];

  String? _currentRoomId;

  @override
  Future<void> onLoad() async {
    // ── Outer wall / background ───────────────────────────────────────────────
    add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(kMapWidth, kMapHeight),
      paint: Paint()..color = const Color(0xFF2C2C3E),
    ));

    // ── Corridor strip ────────────────────────────────────────────────────────
    add(RectangleComponent(
      position: Vector2(0, _topH),
      size: Vector2(kMapWidth, _corridor),
      paint: Paint()..color = const Color(0xFF3A3A50),
    ));
    // Corridor label
    add(TextComponent(
      text: '— — — — — — — — — — — — — — — — — — — —',
      position: Vector2(kMapWidth / 2, _topH + _corridor / 2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF5A5A70),
          fontSize: 10,
          letterSpacing: 1,
        ),
      ),
    ));

    // ── Vertical divider between left & right columns ─────────────────────────
    add(RectangleComponent(
      position: Vector2(_wall + 280, 0),
      size: Vector2(_divider, kMapHeight),
      paint: Paint()..color = const Color(0xFF2C2C3E),
    ));

    // ── Rooms ─────────────────────────────────────────────────────────────────
    for (final room in _rooms) {
      // Floor fill
      add(RectangleComponent(
        position: Vector2(room.rect.left, room.rect.top),
        size: Vector2(room.rect.width, room.rect.height),
        paint: Paint()..color = room.floorColor.withValues(alpha: 0.35),
      ));

      // Furniture
      for (final f in room.furniture) {
        add(_FurnitureComponent(def: f));
      }

      // Room label (bottom-left of room, neo-brutalist caps)
      add(TextComponent(
        text: '${room.emoji}  ${room.label}',
        position: Vector2(room.rect.left + 12, room.rect.bottom - 28),
        textRenderer: TextPaint(
          style: TextStyle(
            color: room.wallColor,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ));

      // Room border (accent-coloured left edge, thick)
      add(RectangleComponent(
        position: Vector2(room.rect.left, room.rect.top),
        size: Vector2(5, room.rect.height),
        paint: Paint()..color = room.wallColor,
      ));
    }

    // ── Outer border ──────────────────────────────────────────────────────────
    add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(kMapWidth, kMapHeight),
      paint: Paint()
        ..color = const Color(0xFF1A1A2E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _wall,
    ));
  }

  /// Called every frame by PlayerComponent to detect room entry/exit.
  void checkPlayerRoom(Vector2 pos) {
    String? newId;
    for (final room in _rooms) {
      if (room.rect.contains(Offset(pos.x, pos.y))) {
        newId = room.id;
        break;
      }
    }
    if (newId != _currentRoomId) {
      _currentRoomId = newId;
      onRoomChanged(newId);
    }
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _RoomDef {
  const _RoomDef({
    required this.id,
    required this.rect,
    required this.floorColor,
    required this.wallColor,
    required this.label,
    required this.emoji,
    required this.furniture,
  });

  final String id;
  final Rect rect;
  final Color floorColor;
  final Color wallColor;
  final String label;
  final String emoji;
  final List<_Furniture> furniture;
}

class _Furniture {
  const _Furniture(this.rect, this.color, this.type);
  final Rect rect;
  final Color color;
  final String type;
}

class _FurnitureComponent extends PositionComponent {
  _FurnitureComponent({required this.def})
      : super(
          position: Vector2(def.rect.left, def.rect.top),
          size: Vector2(def.rect.width, def.rect.height),
        );

  final _Furniture def;

  @override
  Future<void> onLoad() async {
    // Base shape
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = def.color,
    ));

    // Plants get a round top
    if (def.type == 'plant') {
      add(CircleComponent(
        radius: size.x / 2,
        position: Vector2(0, -size.x * 0.3),
        paint: Paint()..color = const Color(0xFF3A8A40),
      ));
    }

    // Monitors get a screen glare dot
    if (def.type == 'monitor') {
      add(CircleComponent(
        radius: 3,
        position: Vector2(size.x - 8, 4),
        paint: Paint()..color = const Color(0xFF4488FF).withValues(alpha: 0.8),
      ));
    }
  }
}
