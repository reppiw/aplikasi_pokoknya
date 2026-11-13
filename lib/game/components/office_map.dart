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
double get kMapWidth => kMapCols * kTileSize;
double get kMapHeight => kMapRows * kTileSize;

/// Wall thickness in world pixels.
const double kWallThick = kTileSize;

// ── Room definitions ──────────────────────────────────────────────────────────

class _RoomDef {
  const _RoomDef({
    required this.id,
    required this.name,
    required this.rect, // in tile units (left, top, right, bottom)
    required this.color,
  });

  final String id;
  final String name;
  final Rect rect; // tile-space rect
  final Color color;

  /// World-space rect (pixels).
  Rect get worldRect => Rect.fromLTWH(
    rect.left * kTileSize,
    rect.top * kTileSize,
    rect.width * kTileSize,
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
    color: Color(0xFFF2DFC5),
  ),
  _RoomDef(
    id: 'looking_for_games',
    name: 'Game Room',
    rect: Rect.fromLTRB(17, 1, 31, 19),
    color: Color(0xFFEADCCB),
  ),
  _RoomDef(
    id: 'busy',
    name: 'Meeting Room',
    rect: Rect.fromLTRB(1, 21, 15, 39),
    color: Color(0xFFE8D9C2),
  ),
  _RoomDef(
    id: 'deep_work',
    name: 'Deep Work',
    rect: Rect.fromLTRB(17, 21, 31, 39),
    color: Color(0xFFE3E2CF),
  ),
];

const _doorways = <Rect>[
  Rect.fromLTRB(15, 9, 17, 11),
  Rect.fromLTRB(15, 29, 17, 31),
  Rect.fromLTRB(14, 19, 16, 21),
  Rect.fromLTRB(24, 19, 26, 21),
];

_RoomDef? _roomAtWorld(Vector2 pos) {
  for (final r in _rooms) {
    if (r.containsWorld(pos)) return r;
  }
  return null;
}

// ── Walkability ───────────────────────────────────────────────────────────────

/// Returns true if [pos] is inside a room or a doorway, not in a wall.
bool isWalkable(Vector2 pos) {
  if (_roomAtWorld(pos) != null) return true;
  final tilePosition = Offset(pos.x / kTileSize, pos.y / kTileSize);
  return _doorways.any((doorway) => doorway.contains(tilePosition));
}

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
      add(
        RectangleComponent(
          position: Vector2(wr.left, wr.top),
          size: Vector2(wr.width, wr.height),
          paint: Paint()..color = room.color,
          priority: 0,
        ),
      );
    }

    _addCozyDecor();

    // ── Outer border walls ───────────────────────────────────────────────────
    _addWalls();

    // ── Room dividers ────────────────────────────────────────────────────────
    _addDividers();

    // ── Room labels ──────────────────────────────────────────────────────────
    for (final room in _rooms) {
      final wr = room.worldRect;
      add(
        TextComponent(
          text: room.name.toUpperCase(),
          position: Vector2(wr.center.dx, wr.center.dy),
          anchor: Anchor.center,
          priority: 1,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xAA664B3C),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      );
    }
  }

  // ── Wall helpers ─────────────────────────────────────────────────────────

  void _addRect({
    required double x,
    required double y,
    required double w,
    required double h,
    Color color = const Color(0xFF765442),
    bool solid = true,
  }) {
    add(
      RectangleComponent(
        position: Vector2(x, y),
        size: Vector2(w, h),
        paint: Paint()..color = color,
        priority: 1,
      ),
    );
    if (solid) {
      add(_WallHitbox(position: Vector2(x, y), size: Vector2(w, h)));
    }
  }

  void _addWalls() {
    final mw = kMapWidth;
    final mh = kMapHeight;
    const t = kWallThick;

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
    const t = kWallThick;

    // Leave door-sized gaps between both pairs of rooms on each axis.
    final vx = 16 * kTileSize;
    final verticalDoors = [
      (9 * kTileSize, 11 * kTileSize),
      (29 * kTileSize, 31 * kTileSize),
    ];
    var segmentTop = t;
    for (final (doorTop, doorBottom) in verticalDoors) {
      _addRect(x: vx, y: segmentTop, w: t, h: doorTop - segmentTop);
      segmentTop = doorBottom;
    }
    _addRect(x: vx, y: segmentTop, w: t, h: mh - t - segmentTop);

    // The existing left-hand door is kept and one is added for the right rooms.
    final hy = 20 * kTileSize;
    final horizontalDoors = [
      (14 * kTileSize, 16 * kTileSize),
      (24 * kTileSize, 26 * kTileSize),
    ];
    var segmentLeft = t;
    for (final (doorLeft, doorRight) in horizontalDoors) {
      _addRect(x: segmentLeft, y: hy, w: doorLeft - segmentLeft, h: t);
      segmentLeft = doorRight;
    }
    _addRect(x: segmentLeft, y: hy, w: mw - t - segmentLeft, h: t);
  }

  void _addCozyDecor() {
    for (final room in _rooms) {
      final left = room.worldRect.left;
      final top = room.worldRect.top;
      switch (room.id) {
        case 'free':
          _addRug(left: left + 3 * kTileSize, top: top + 8 * kTileSize);
          _addSofa(
            x: left + 2 * kTileSize,
            y: top + 3 * kTileSize,
            color: const Color(0xFF9B6651),
          );
          _addCoffeeTable(x: left + 8 * kTileSize, y: top + 9 * kTileSize);
          _addPlant(x: left + 11 * kTileSize, y: top + 15 * kTileSize);
        case 'looking_for_games':
          _addGamingStation(
            x: left + 2 * kTileSize,
            y: top + 4 * kTileSize,
            accent: const Color(0xFF8273A6),
          );
          _addGamingStation(
            x: left + 8 * kTileSize,
            y: top + 4 * kTileSize,
            accent: const Color(0xFFB36B62),
          );
          _addBeanbag(x: left + 4 * kTileSize, y: top + 12 * kTileSize);
          _addBeanbag(x: left + 9 * kTileSize, y: top + 12 * kTileSize);
        case 'busy':
          _addRug(left: left + 3 * kTileSize, top: top + 7 * kTileSize);
          _addConferenceTable(x: left + 4 * kTileSize, y: top + 8 * kTileSize);
          _addWallBoard(x: left + 5 * kTileSize, y: top + 2 * kTileSize);
          _addPlant(x: left + 11 * kTileSize, y: top + 15 * kTileSize);
        case 'deep_work':
          _addBookshelf(x: left + 11 * kTileSize, y: top + 3 * kTileSize);
          _addDesk(x: left + 2 * kTileSize, y: top + 6 * kTileSize);
          _addDesk(x: left + 7 * kTileSize, y: top + 6 * kTileSize);
          _addDesk(x: left + 2 * kTileSize, y: top + 13 * kTileSize);
          _addPlant(x: left + 10 * kTileSize, y: top + 15 * kTileSize);
        default:
          break;
      }
    }
  }

  void _addRug({required double left, required double top}) {
    _addDecorRect(
      x: left,
      y: top,
      w: 7 * kTileSize,
      h: 4 * kTileSize,
      color: const Color(0xFF9B6651),
    );
    _addDecorRect(
      x: left + 8,
      y: top + 8,
      w: 7 * kTileSize - 16,
      h: 4 * kTileSize - 16,
      color: const Color(0xFFC28B67),
    );
    _addDecorRect(
      x: left + 2 * kTileSize,
      y: top + 10,
      w: 3 * kTileSize,
      h: 4,
      color: const Color(0xFFD8AA83),
    );
    _addDecorRect(
      x: left + 2 * kTileSize,
      y: top + 4 * kTileSize - 14,
      w: 3 * kTileSize,
      h: 4,
      color: const Color(0xFFD8AA83),
    );
  }

  void _addDecorRect({
    required double x,
    required double y,
    required double w,
    required double h,
    required Color color,
  }) {
    add(
      RectangleComponent(
        position: Vector2(x, y),
        size: Vector2(w, h),
        paint: Paint()..color = color,
        priority: 0,
      ),
    );
  }

  void _addSofa({required double x, required double y, required Color color}) {
    _addDecorRect(
      x: x + 5,
      y: y + 9,
      w: 5 * kTileSize,
      h: 2 * kTileSize,
      color: const Color(0x553D2B26),
    );
    _addDecorRect(
      x: x,
      y: y,
      w: 5 * kTileSize,
      h: 2.25 * kTileSize,
      color: const Color(0xFF765442),
    );
    _addDecorRect(
      x: x + 8,
      y: y + 12,
      w: 5 * kTileSize - 16,
      h: 1.25 * kTileSize,
      color: color,
    );
    for (final cushionX in [x + 1.3 * kTileSize, x + 3.2 * kTileSize]) {
      _addDecorRect(
        x: cushionX,
        y: y + 15,
        w: 1.35 * kTileSize,
        h: kTileSize,
        color: const Color(0xFFD9B99A),
      );
      _addDecorRect(
        x: cushionX + 5,
        y: y + 19,
        w: 3,
        h: 14,
        color: const Color(0xFFB98868),
      );
    }
    _addDecorRect(
      x: x + 3,
      y: y + 6,
      w: 12,
      h: 1.75 * kTileSize,
      color: const Color(0xFF765442),
    );
    _addDecorRect(
      x: x + 5 * kTileSize - 15,
      y: y + 6,
      w: 12,
      h: 1.75 * kTileSize,
      color: const Color(0xFF765442),
    );
  }

  void _addCoffeeTable({required double x, required double y}) {
    add(
      CircleComponent(
        position: Vector2(x, y),
        radius: 32,
        paint: Paint()..color = const Color(0xFF765442),
        priority: 0,
      ),
    );
    add(
      CircleComponent(
        position: Vector2(x + 4, y + 4),
        radius: 27,
        paint: Paint()..color = const Color(0xFFD6A66F),
        priority: 0,
      ),
    );
    _addDecorRect(
      x: x - 12,
      y: y - 5,
      w: 22,
      h: 13,
      color: const Color(0xFF9B6651),
    );
    _addDecorRect(
      x: x - 10,
      y: y - 3,
      w: 18,
      h: 9,
      color: const Color(0xFFE7C79C),
    );
    add(
      CircleComponent(
        position: Vector2(x + 13, y + 10),
        radius: 5,
        paint: Paint()..color = const Color(0xFFF4E7D1),
        priority: 0,
      ),
    );
    add(
      CircleComponent(
        position: Vector2(x + 13, y + 10),
        radius: 2,
        paint: Paint()..color = const Color(0xFF9B6651),
        priority: 0,
      ),
    );
  }

  void _addGamingStation({
    required double x,
    required double y,
    required Color accent,
  }) {
    _addDecorRect(
      x: x,
      y: y + 2 * kTileSize,
      w: 4 * kTileSize,
      h: kTileSize,
      color: const Color(0xFF765442),
    );
    _addDecorRect(
      x: x + 8,
      y: y + 2 * kTileSize + 6,
      w: 4 * kTileSize - 16,
      h: kTileSize - 12,
      color: const Color(0xFFD6A66F),
    );
    _addDecorRect(
      x: x + kTileSize,
      y: y,
      w: 2 * kTileSize,
      h: 1.5 * kTileSize,
      color: const Color(0xFF533F3B),
    );
    _addDecorRect(
      x: x + kTileSize + 5,
      y: y + 5,
      w: 2 * kTileSize - 10,
      h: 1.5 * kTileSize - 10,
      color: accent,
    );
    _addDecorRect(
      x: x + kTileSize + 10,
      y: y + 10,
      w: 2 * kTileSize - 20,
      h: 4,
      color: const Color(0xFFD5C5B2),
    );
    _addDecorRect(
      x: x + 2.6 * kTileSize,
      y: y + 1.5 * kTileSize,
      w: 10,
      h: 10,
      color: const Color(0xFFD6A66F),
    );
    _addDecorRect(
      x: x + 1.4 * kTileSize,
      y: y + 2 * kTileSize - 2,
      w: 1.2 * kTileSize,
      h: 8,
      color: const Color(0xFF533F3B),
    );
    _addDecorRect(
      x: x + 1.55 * kTileSize,
      y: y + 2 * kTileSize - 1,
      w: 1.5 * kTileSize,
      h: 5,
      color: const Color(0xFFB47A62),
    );
    _addBeanbag(x: x + 1.5 * kTileSize, y: y + 4 * kTileSize);
  }

  void _addBeanbag({required double x, required double y}) {
    add(
      CircleComponent(
        position: Vector2(x, y),
        radius: 21,
        paint: Paint()..color = const Color(0xFF765442),
        priority: 0,
      ),
    );
    add(
      CircleComponent(
        position: Vector2(x + 2, y + 2),
        radius: 16,
        paint: Paint()..color = const Color(0xFFB47A62),
        priority: 0,
      ),
    );
  }

  void _addConferenceTable({required double x, required double y}) {
    _addDecorRect(
      x: x,
      y: y,
      w: 6 * kTileSize,
      h: 3 * kTileSize,
      color: const Color(0xFF765442),
    );
    _addDecorRect(
      x: x + 7,
      y: y + 7,
      w: 6 * kTileSize - 14,
      h: 3 * kTileSize - 14,
      color: const Color(0xFFD6A66F),
    );
    _addDecorRect(
      x: x + 12,
      y: y + 1.5 * kTileSize,
      w: 5 * kTileSize - 24,
      h: 3,
      color: const Color(0xFFE7C79C),
    );
    for (var i = 0; i < 3; i++) {
      final chairX = x + (i * 2 + 1) * kTileSize;
      _addChair(x: chairX, y: y - 1.5 * kTileSize);
      _addChair(x: chairX, y: y + 3.5 * kTileSize);
    }
    for (var i = 0; i < 3; i++) {
      final deviceX = x + (i * 2 + 1.5) * kTileSize;
      _addDecorRect(
        x: deviceX,
        y: y + kTileSize,
        w: kTileSize,
        h: 18,
        color: const Color(0xFF687B75),
      );
      _addDecorRect(
        x: deviceX + 3,
        y: y + kTileSize + 3,
        w: kTileSize - 6,
        h: 10,
        color: const Color(0xFFB9C9B8),
      );
    }
  }

  void _addChair({required double x, required double y}) {
    add(
      CircleComponent(
        position: Vector2(x + 24, y + 20),
        radius: 19,
        paint: Paint()..color = const Color(0xFF765442),
        priority: 0,
      ),
    );
    _addDecorRect(
      x: x + 6,
      y: y + 5,
      w: 36,
      h: 30,
      color: const Color(0xFFB47A62),
    );
  }

  void _addWallBoard({required double x, required double y}) {
    _addDecorRect(
      x: x,
      y: y,
      w: 4 * kTileSize,
      h: 2 * kTileSize,
      color: const Color(0xFF765442),
    );
    _addDecorRect(
      x: x + 6,
      y: y + 6,
      w: 4 * kTileSize - 12,
      h: 2 * kTileSize - 12,
      color: const Color(0xFF8C9A78),
    );
    for (var i = 0; i < 3; i++) {
      _addDecorRect(
        x: x + 12 + i * 27,
        y: y + 12 + (i.isEven ? 0 : 13),
        w: 18,
        h: 14,
        color: i.isEven ? const Color(0xFFE6C47A) : const Color(0xFFD58D70),
      );
    }
  }

  void _addBookshelf({required double x, required double y}) {
    _addDecorRect(
      x: x,
      y: y,
      w: 2 * kTileSize,
      h: 6 * kTileSize,
      color: const Color(0xFF765442),
    );
    const bookColors = [
      Color(0xFF9B6651),
      Color(0xFFB47A62),
      Color(0xFF8C9A78),
      Color(0xFFD6A66F),
    ];
    for (var row = 0; row < 3; row++) {
      _addDecorRect(
        x: x + 4,
        y: y + row * 2 * kTileSize + 1.5 * kTileSize,
        w: 2 * kTileSize - 8,
        h: 5,
        color: const Color(0xFFCAA178),
      );
      for (var column = 0; column < 3; column++) {
        _addDecorRect(
          x: x + 5 + column * 18,
          y: y + 8 + row * 2 * kTileSize,
          w: 13,
          h: kTileSize + 12,
          color: bookColors[(row + column) % bookColors.length],
        );
      }
    }
  }

  void _addDesk({required double x, required double y}) {
    _addDecorRect(
      x: x,
      y: y,
      w: 3 * kTileSize,
      h: 2 * kTileSize,
      color: const Color(0xFF765442),
    );
    _addDecorRect(
      x: x + 5,
      y: y + 5,
      w: 3 * kTileSize - 10,
      h: 2 * kTileSize - 10,
      color: const Color(0xFFD6A66F),
    );
    _addDecorRect(
      x: x + kTileSize,
      y: y + 8,
      w: kTileSize,
      h: 15,
      color: const Color(0xFF687B75),
    );
    _addDecorRect(
      x: x + kTileSize + 4,
      y: y + 12,
      w: kTileSize - 8,
      h: 8,
      color: const Color(0xFFBDD0BE),
    );
    _addDecorRect(
      x: x + kTileSize + 13,
      y: y + 20,
      w: 3,
      h: 5,
      color: const Color(0xFFD6A66F),
    );
    _addDecorRect(
      x: x + 2 * kTileSize + 5,
      y: y + 12,
      w: 15,
      h: 10,
      color: const Color(0xFFE7C79C),
    );
    _addDecorRect(
      x: x + 2 * kTileSize + 8,
      y: y + 15,
      w: 9,
      h: 2,
      color: const Color(0xFFB47A62),
    );
    _addChair(x: x + 1, y: y + 2.5 * kTileSize);
  }

  void _addPlant({required double x, required double y}) {
    _addDecorRect(
      x: x,
      y: y + 18,
      w: kTileSize,
      h: kTileSize,
      color: const Color(0xFFA45F46),
    );
    add(
      CircleComponent(
        position: Vector2(x + 5, y),
        radius: 11,
        paint: Paint()..color = const Color(0xFF617D52),
        priority: 0,
      ),
    );
    add(
      CircleComponent(
        position: Vector2(x + 16, y + 5),
        radius: 10,
        paint: Paint()..color = const Color(0xFF79935E),
        priority: 0,
      ),
    );
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
