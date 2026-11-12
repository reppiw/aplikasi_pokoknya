import 'dart:ui' show Color, Offset, Paint, Rect;

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart' show FontWeight, TextStyle;

import '../office_game.dart';

// ── Map constants ─────────────────────────────────────────────────────────────

/// Pixel size of one tile in world space.
const double kTileSize = 32.0;

/// Map dimensions in tiles.
const int kMapCols = 32;
const int kMapRows = 40;

/// Total map size in world pixels.
double get kMapWidth  => kMapCols * kTileSize;
double get kMapHeight => kMapRows * kTileSize;

/// Wall thickness in world pixels.
const double kWallThick = kTileSize;

// ── Room definitions ──────────────────────────────────────────────────────────

class _RoomDef {
  const _RoomDef({
    required this.id,
    required this.name,
    required this.rect,     // in tile units (left, top, right, bottom)
    required this.color,
  });

  final String id;
  final String name;
  final Rect   rect;        // tile-space rect
  final Color  color;

  /// World-space rect (pixels).
  Rect get worldRect => Rect.fromLTWH(
    rect.left   * kTileSize,
    rect.top    * kTileSize,
    rect.width  * kTileSize,
    rect.height * kTileSize,
  );

  bool containsWorld(Vector2 pos) => worldRect.contains(Offset(pos.x, pos.y));
}

// Divider is at tile col 16 (vertical) and tile row 20 (horizontal).
// Each room occupies one quadrant of the 32×40 map.
const _rooms = <_RoomDef>[
  _RoomDef(
    id: 'free',
    name: 'Lounge',
    rect: Rect.fromLTRB(1, 1, 15, 19),
    color: Color(0xFFFFF0E0),
  ),
  _RoomDef(
    id: 'looking_for_games',
    name: 'Game Room',
    rect: Rect.fromLTRB(17, 1, 31, 19),
    color: Color(0xFFEBE0FF),
  ),
  _RoomDef(
    id: 'busy',
    name: 'Meeting Room',
    rect: Rect.fromLTRB(1, 21, 15, 39),
    color: Color(0xFFE0EEFF),
  ),
  _RoomDef(
    id: 'deep_work',
    name: 'Deep Work',
    rect: Rect.fromLTRB(17, 21, 31, 39),
    color: Color(0xFFE0F5E8),
  ),
];

_RoomDef? _roomAtWorld(Vector2 pos) {
  for (final r in _rooms) {
    if (r.containsWorld(pos)) return r;
  }
  return null;
}

// ── Walkability ───────────────────────────────────────────────────────────────

/// Returns true if [pos] is inside the walkable area of the map
/// (i.e. inside a room, not in a wall or divider tile).
bool isWalkable(Vector2 pos) => _roomAtWorld(pos) != null;

// ── Components ────────────────────────────────────────────────────────────────

/// Invisible solid wall used for collision detection.
class _WallHitbox extends PositionComponent with CollisionCallbacks {
  _WallHitbox({required Vector2 position, required Vector2 size})
      : super(position: position, size: size) {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }
}

/// The full office map: floors, walls, labels — no isometric math.
class OfficeMap extends Component with HasGameReference<OfficeGame> {
  OfficeMap({required this.onRoomChanged});

  final void Function(String? roomId) onRoomChanged;

  String? _currentRoomId;

  @override
  Future<void> onLoad() async {
    // ── Floor fills ──────────────────────────────────────────────────────────
    for (final room in _rooms) {
      final wr = room.worldRect;
      add(RectangleComponent(
        position: Vector2(wr.left, wr.top),
        size:     Vector2(wr.width, wr.height),
        paint:    Paint()..color = room.color,
        priority: 0,
      ));
    }

    // ── Outer border walls ───────────────────────────────────────────────────
    _addWalls();

    // ── Room dividers ────────────────────────────────────────────────────────
    _addDividers();

    // ── Room labels ──────────────────────────────────────────────────────────
    for (final room in _rooms) {
      final wr = room.worldRect;
      add(TextComponent(
        text: room.name.toUpperCase(),
        position: Vector2(wr.center.dx, wr.center.dy),
        anchor: Anchor.center,
        priority: 1,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0x55000000),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ));
    }
  }

  // ── Wall helpers ─────────────────────────────────────────────────────────

  void _addRect({
    required double x,
    required double y,
    required double w,
    required double h,
    Color color = const Color(0xFF2D2D2D),
    bool solid = true,
  }) {
    add(RectangleComponent(
      position: Vector2(x, y),
      size: Vector2(w, h),
      paint: Paint()..color = color,
      priority: 1,
    ));
    if (solid) {
      add(_WallHitbox(position: Vector2(x, y), size: Vector2(w, h)));
    }
  }

  void _addWalls() {
    final mw = kMapWidth;
    final mh = kMapHeight;
    const t  = kWallThick;

    // Top
    _addRect(x: 0, y: 0, w: mw, h: t);
    // Bottom
    _addRect(x: 0, y: mh - t, w: mw, h: t);
    // Left
    _addRect(x: 0, y: 0, w: t, h: mh);
    // Right
    _addRect(x: mw - t, y: 0, w: t, h: mh);
  }

  void _addDividers() {
    final mw = kMapWidth;
    final mh = kMapHeight;
    const t  = kWallThick;

    // Vertical divider at col 16 — two segments with a door gap in the middle.
    final vx = 16 * kTileSize;
    final vDoorTop    = 9  * kTileSize;
    final vDoorBottom = 11 * kTileSize;
    // Top segment
    _addRect(x: vx, y: t, w: t, h: vDoorTop - t);
    // Bottom segment
    _addRect(x: vx, y: vDoorBottom, w: t, h: mh - t - vDoorBottom);

    // Horizontal divider at row 20 — two segments with a door gap in the middle.
    final hy = 20 * kTileSize;
    final hDoorLeft  = 14 * kTileSize;
    final hDoorRight = 16 * kTileSize;
    // Left segment
    _addRect(x: t, y: hy, w: hDoorLeft - t, h: t);
    // Right segment
    _addRect(x: hDoorRight, y: hy, w: mw - t - hDoorRight, h: t);
  }

  // ── Room detection ────────────────────────────────────────────────────────

  void checkPlayerRoom(Vector2 worldPos) {
    final newRoomId = _roomAtWorld(worldPos)?.id;
    if (newRoomId != _currentRoomId) {
      _currentRoomId = newRoomId;
      onRoomChanged(newRoomId);
    }
  }
}
