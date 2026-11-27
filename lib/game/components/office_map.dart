import 'dart:ui' show Color, Offset, Paint, Rect;

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart' show FontWeight, TextStyle;

import '../../models/furniture.dart';
import '../../models/room.dart';
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

// ── Internal room definition (derived from Room model) ────────────────────────

class _RoomDef {
  _RoomDef({required this.room});

  final Room room;

  String get id => room.id;
  String get name => room.name;
  Color get color => Color(room.colorHex);

  /// Tile-space rect (matches the original Rect.fromLTRB format).
  Rect get tileRect => Rect.fromLTWH(
        room.tileX,
        room.tileY,
        room.widthTiles,
        room.heightTiles,
      );

  /// World-space rect (pixels).
  Rect get worldRect => Rect.fromLTWH(
        room.tileX * kTileSize,
        room.tileY * kTileSize,
        room.widthTiles * kTileSize,
        room.heightTiles * kTileSize,
      );

  bool containsWorld(Vector2 pos) =>
      worldRect.contains(Offset(pos.x, pos.y));
}

// ── Walkability ───────────────────────────────────────────────────────────────

/// Returns true if [pos] is inside the interior map bounds and not blocked by any wall rect.
bool _isWalkableInternal(Vector2 pos, {required List<Rect> wallTileRects}) {
  final tx = pos.x / kTileSize;
  final ty = pos.y / kTileSize;
  if (tx < 1.0 || tx >= kMapCols - 1.0 || ty < 1.0 || ty >= kMapRows - 1.0) {
    return false;
  }
  final tp = Offset(tx, ty);
  return !wallTileRects.any((w) => w.contains(tp));
}

// ── Components ────────────────────────────────────────────────────────────────

class _WallHitbox extends PositionComponent with CollisionCallbacks {
  _WallHitbox({required Vector2 position, required Vector2 size})
      : super(position: position, size: size) {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }
}

/// The full office map: floors, walls, labels, furniture — driven by [Room] data.
///
/// Pass [rooms] from Firestore (or [defaultRooms()] as fallback).
/// Doorways and per-room perimeter walls are computed automatically.
class OfficeMap extends Component with HasGameReference<OfficeGame> {
  OfficeMap({
    required this.onRoomChanged,
    required List<Room> rooms,
  }) : _roomDefs = rooms.map((r) => _RoomDef(room: r)).toList() {
    _doorways = _computeDoorways();
    _wallTileRects = _computeWallTileRects();
  }

  final void Function(String? roomId) onRoomChanged;
  final List<_RoomDef> _roomDefs;
  late final List<Rect> _doorways;
  late final List<Rect> _wallTileRects;

  String? _currentRoomId;

  // ── Walkability (called by PlayerComponent) ─────────────────────────────────

  bool walkable(Vector2 pos) =>
      _isWalkableInternal(pos, wallTileRects: _wallTileRects);

  // ── Room detection ────────────────────────────────────────────────────────

  _RoomDef? _roomAtWorld(Vector2 pos) {
    for (final r in _roomDefs) {
      if (r.containsWorld(pos)) return r;
    }
    return null;
  }

  void checkPlayerRoom(Vector2 worldPos) {
    final newRoomId = _roomAtWorld(worldPos)?.id;
    if (newRoomId != _currentRoomId) {
      _currentRoomId = newRoomId;
      onRoomChanged(newRoomId);
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    // ── Floor fills ──────────────────────────────────────────────────────────
    for (final room in _roomDefs) {
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

    // ── Furniture ────────────────────────────────────────────────────────────
    for (final roomDef in _roomDefs) {
      _renderFurniture(roomDef);
    }

    // ── Outer border walls ───────────────────────────────────────────────────
    _addWalls();

    // ── Room dividers ────────────────────────────────────────────────────────
    _addDividers();

    // ── Room labels ──────────────────────────────────────────────────────────
    for (final room in _roomDefs) {
      final wr = room.worldRect;
      add(
        TextComponent(
          text: room.name.toUpperCase(),
          position: Vector2(wr.center.dx, wr.top + 24),
          anchor: Anchor.center,
          priority: 2,
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

  // ── Doorway computation ────────────────────────────────────────────────────

  /// Computes doorway Rects (in tile coordinates) between adjacent rooms,
  /// plus a corridor-facing doorway for any isolated room so all rooms are reachable.
  List<Rect> _computeDoorways() {
    final doorways = <Rect>[];
    final rects = _roomDefs.map((r) => r.tileRect).toList();
    final connected = List<bool>.filled(rects.length, false);

    for (var i = 0; i < rects.length; i++) {
      for (var j = i + 1; j < rects.length; j++) {
        final a = rects[i];
        final b = rects[j];

        // Shared / near-adjacent vertical edge (rooms side-by-side horizontally)
        final horizGap = a.right <= b.left ? b.left - a.right : (b.right <= a.left ? a.left - b.right : double.infinity);
        if (horizGap <= 2.5) {
          final minRight = a.right <= b.left ? a.right : b.right;
          final maxLeft = a.right <= b.left ? b.left : a.left;
          final overlapTop = a.top > b.top ? a.top : b.top;
          final overlapBottom = a.bottom < b.bottom ? a.bottom : b.bottom;
          if (overlapBottom > overlapTop + 2) {
            final midY = (overlapTop + overlapBottom) / 2;
            doorways.add(Rect.fromLTRB(
              minRight - 1.0,
              midY - 1.0,
              maxLeft + 1.0,
              midY + 1.0,
            ));
            connected[i] = true;
            connected[j] = true;
          }
        }

        // Shared / near-adjacent horizontal edge (rooms stacked vertically)
        final vertGap = a.bottom <= b.top ? b.top - a.bottom : (b.bottom <= a.top ? a.top - b.bottom : double.infinity);
        if (vertGap <= 2.5) {
          final minBottom = a.bottom <= b.top ? a.bottom : b.bottom;
          final maxTop = a.bottom <= b.top ? b.top : a.top;
          final overlapLeft = a.left > b.left ? a.left : b.left;
          final overlapRight = a.right < b.right ? a.right : b.right;
          if (overlapRight > overlapLeft + 2) {
            final midX = (overlapLeft + overlapRight) / 2;
            doorways.add(Rect.fromLTRB(
              midX - 1.0,
              minBottom - 1.0,
              midX + 1.0,
              maxTop + 1.0,
            ));
            connected[i] = true;
            connected[j] = true;
          }
        }
      }
    }

    // Ensure any isolated room (separated by a wider corridor) gets a doorway
    // facing open interior space (toward the map center).
    const mapCenterX = kMapCols / 2;
    const mapCenterY = kMapRows / 2;
    for (var i = 0; i < rects.length; i++) {
      if (connected[i]) continue;
      final r = rects[i];
      final dx = mapCenterX - r.center.dx;
      final dy = mapCenterY - r.center.dy;
      if (dx.abs() >= dy.abs()) {
        if (dx >= 0 && r.right < kMapCols - 2) {
          doorways.add(Rect.fromLTRB(r.right - 0.5, r.center.dy - 1.0, r.right + 1.5, r.center.dy + 1.0));
        } else if (r.left > 2) {
          doorways.add(Rect.fromLTRB(r.left - 1.5, r.center.dy - 1.0, r.left + 0.5, r.center.dy + 1.0));
        } else if (r.bottom < kMapRows - 2) {
          doorways.add(Rect.fromLTRB(r.center.dx - 1.0, r.bottom - 0.5, r.center.dx + 1.0, r.bottom + 1.5));
        }
      } else {
        if (dy >= 0 && r.bottom < kMapRows - 2) {
          doorways.add(Rect.fromLTRB(r.center.dx - 1.0, r.bottom - 0.5, r.center.dx + 1.0, r.bottom + 1.5));
        } else if (r.top > 2) {
          doorways.add(Rect.fromLTRB(r.center.dx - 1.0, r.top - 1.5, r.center.dx + 1.0, r.top + 0.5));
        } else if (r.right < kMapCols - 2) {
          doorways.add(Rect.fromLTRB(r.right - 0.5, r.center.dy - 1.0, r.right + 1.5, r.center.dy + 1.0));
        }
      }
    }

    return doorways;
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

    _addRect(x: 0, y: 0, w: mw, h: t);        // Top
    _addRect(x: 0, y: mh - t, w: mw, h: t);   // Bottom
    _addRect(x: 0, y: 0, w: t, h: mh);        // Left
    _addRect(x: mw - t, y: 0, w: t, h: mh);   // Right
  }

  /// Builds per-room perimeter wall rects (1 tile thick outside each room),
  /// subtracting doorway openings and other rooms' interior floors so walls
  /// never slice through adjacent or differently sized rooms.
  List<Rect> _computeWallTileRects() {
    final walls = <Rect>[];
    final roomRects = _roomDefs.map((r) => r.tileRect).toList();
    final cutouts = <Rect>[..._doorways, ...roomRects];

    for (final r in roomRects) {
      final candidates = <(bool isVertical, Rect strip)>[
        (true, Rect.fromLTRB(r.left - 1, r.top - 1, r.left, r.bottom + 1)),       // Left
        (true, Rect.fromLTRB(r.right, r.top - 1, r.right + 1, r.bottom + 1)),     // Right
        (false, Rect.fromLTRB(r.left - 1, r.top - 1, r.right + 1, r.top)),        // Top
        (false, Rect.fromLTRB(r.left - 1, r.bottom, r.right + 1, r.bottom + 1)),  // Bottom
      ];

      for (final (isVertical, strip) in candidates) {
        // Clamp to interior map bounds (outer walls are drawn by _addWalls)
        final clamped = Rect.fromLTRB(
          strip.left.clamp(1.0, kMapCols - 1.0),
          strip.top.clamp(1.0, kMapRows - 1.0),
          strip.right.clamp(1.0, kMapCols - 1.0),
          strip.bottom.clamp(1.0, kMapRows - 1.0),
        );
        if (clamped.width <= 0 || clamped.height <= 0) continue;

        walls.addAll(_subtractCutouts(clamped, cutouts, isVertical: isVertical));
      }
    }

    return walls;
  }

  List<Rect> _subtractCutouts(
    Rect strip,
    List<Rect> cutouts, {
    required bool isVertical,
  }) {
    final gaps = <({double start, double end})>[];
    for (final c in cutouts) {
      if (c.right <= strip.left ||
          c.left >= strip.right ||
          c.bottom <= strip.top ||
          c.top >= strip.bottom) {
        continue;
      }
      if (isVertical) {
        gaps.add((
          start: c.top > strip.top ? c.top : strip.top,
          end: c.bottom < strip.bottom ? c.bottom : strip.bottom,
        ));
      } else {
        gaps.add((
          start: c.left > strip.left ? c.left : strip.left,
          end: c.right < strip.right ? c.right : strip.right,
        ));
      }
    }

    if (gaps.isEmpty) return [strip];
    gaps.sort((a, b) => a.start.compareTo(b.start));

    final result = <Rect>[];
    var cursor = isVertical ? strip.top : strip.left;
    final limit = isVertical ? strip.bottom : strip.right;

    for (final g in gaps) {
      if (g.start > cursor) {
        result.add(
          isVertical
              ? Rect.fromLTRB(strip.left, cursor, strip.right, g.start)
              : Rect.fromLTRB(cursor, strip.top, g.start, strip.bottom),
        );
      }
      if (g.end > cursor) cursor = g.end;
    }
    if (cursor < limit) {
      result.add(
        isVertical
            ? Rect.fromLTRB(strip.left, cursor, strip.right, limit)
            : Rect.fromLTRB(cursor, strip.top, limit, strip.bottom),
      );
    }
    return result;
  }

  void _addDividers() {
    for (final w in _wallTileRects) {
      _addRect(
        x: w.left * kTileSize,
        y: w.top * kTileSize,
        w: w.width * kTileSize,
        h: w.height * kTileSize,
      );
    }
  }

  // ── Furniture rendering ────────────────────────────────────────────────────

  /// Renders all furniture for a room.
  /// If the room has no [FurnitureItem]s, falls back to the original
  /// hand-crafted decoration for backwards-compatible default rooms.
  void _renderFurniture(_RoomDef roomDef) {
    if (roomDef.room.furnitureItems.isNotEmpty) {
      // Data-driven furniture from Firestore
      for (final item in roomDef.room.furnitureItems) {
        final wx = roomDef.worldRect.left + item.tileX * kTileSize;
        final wy = roomDef.worldRect.top + item.tileY * kTileSize;
        FurnitureRenderer.render(
          map: this,
          type: item.type,
          x: wx,
          y: wy,
          accentColor: item.color,
        );
      }
    } else {
      // Fallback: original hardcoded decoration by room id
      _addLegacyDecor(roomDef);
    }
  }

  void _addLegacyDecor(_RoomDef room) {
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

  // ── Decor helpers (unchanged from original) ─────────────────────────────

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

  void _addRug({required double left, required double top}) {
    _addDecorRect(x: left, y: top, w: 7 * kTileSize, h: 4 * kTileSize, color: const Color(0xFF9B6651));
    _addDecorRect(x: left + 8, y: top + 8, w: 7 * kTileSize - 16, h: 4 * kTileSize - 16, color: const Color(0xFFC28B67));
    _addDecorRect(x: left + 2 * kTileSize, y: top + 10, w: 3 * kTileSize, h: 4, color: const Color(0xFFD8AA83));
    _addDecorRect(x: left + 2 * kTileSize, y: top + 4 * kTileSize - 14, w: 3 * kTileSize, h: 4, color: const Color(0xFFD8AA83));
  }

  void _addSofa({required double x, required double y, required Color color}) {
    _addDecorRect(x: x + 5, y: y + 9, w: 5 * kTileSize, h: 2 * kTileSize, color: const Color(0x553D2B26));
    _addDecorRect(x: x, y: y, w: 5 * kTileSize, h: 2.25 * kTileSize, color: const Color(0xFF765442));
    _addDecorRect(x: x + 8, y: y + 12, w: 5 * kTileSize - 16, h: 1.25 * kTileSize, color: color);
    for (final cushionX in [x + 1.3 * kTileSize, x + 3.2 * kTileSize]) {
      _addDecorRect(x: cushionX, y: y + 15, w: 1.35 * kTileSize, h: kTileSize, color: const Color(0xFFD9B99A));
      _addDecorRect(x: cushionX + 5, y: y + 19, w: 3, h: 14, color: const Color(0xFFB98868));
    }
    _addDecorRect(x: x + 3, y: y + 6, w: 12, h: 1.75 * kTileSize, color: const Color(0xFF765442));
    _addDecorRect(x: x + 5 * kTileSize - 15, y: y + 6, w: 12, h: 1.75 * kTileSize, color: const Color(0xFF765442));
  }

  void _addCoffeeTable({required double x, required double y}) {
    add(CircleComponent(position: Vector2(x, y), radius: 32, paint: Paint()..color = const Color(0xFF765442), priority: 0));
    add(CircleComponent(position: Vector2(x + 4, y + 4), radius: 27, paint: Paint()..color = const Color(0xFFD6A66F), priority: 0));
    _addDecorRect(x: x - 12, y: y - 5, w: 22, h: 13, color: const Color(0xFF9B6651));
    _addDecorRect(x: x - 10, y: y - 3, w: 18, h: 9, color: const Color(0xFFE7C79C));
    add(CircleComponent(position: Vector2(x + 13, y + 10), radius: 5, paint: Paint()..color = const Color(0xFFF4E7D1), priority: 0));
    add(CircleComponent(position: Vector2(x + 13, y + 10), radius: 2, paint: Paint()..color = const Color(0xFF9B6651), priority: 0));
  }

  void _addGamingStation({required double x, required double y, required Color accent}) {
    _addDecorRect(x: x, y: y + 2 * kTileSize, w: 4 * kTileSize, h: kTileSize, color: const Color(0xFF765442));
    _addDecorRect(x: x + 8, y: y + 2 * kTileSize + 6, w: 4 * kTileSize - 16, h: kTileSize - 12, color: const Color(0xFFD6A66F));
    _addDecorRect(x: x + kTileSize, y: y, w: 2 * kTileSize, h: 1.5 * kTileSize, color: const Color(0xFF533F3B));
    _addDecorRect(x: x + kTileSize + 5, y: y + 5, w: 2 * kTileSize - 10, h: 1.5 * kTileSize - 10, color: accent);
    _addDecorRect(x: x + kTileSize + 10, y: y + 10, w: 2 * kTileSize - 20, h: 4, color: const Color(0xFFD5C5B2));
    _addDecorRect(x: x + 2.6 * kTileSize, y: y + 1.5 * kTileSize, w: 10, h: 10, color: const Color(0xFFD6A66F));
    _addDecorRect(x: x + 1.4 * kTileSize, y: y + 2 * kTileSize - 2, w: 1.2 * kTileSize, h: 8, color: const Color(0xFF533F3B));
    _addDecorRect(x: x + 1.55 * kTileSize, y: y + 2 * kTileSize - 1, w: 1.5 * kTileSize, h: 5, color: const Color(0xFFB47A62));
    _addBeanbag(x: x + 1.5 * kTileSize, y: y + 4 * kTileSize);
  }

  void _addBeanbag({required double x, required double y}) {
    add(CircleComponent(position: Vector2(x, y), radius: 21, paint: Paint()..color = const Color(0xFF765442), priority: 0));
    add(CircleComponent(position: Vector2(x + 2, y + 2), radius: 16, paint: Paint()..color = const Color(0xFFB47A62), priority: 0));
  }

  void _addConferenceTable({required double x, required double y}) {
    _addDecorRect(x: x, y: y, w: 6 * kTileSize, h: 3 * kTileSize, color: const Color(0xFF765442));
    _addDecorRect(x: x + 7, y: y + 7, w: 6 * kTileSize - 14, h: 3 * kTileSize - 14, color: const Color(0xFFD6A66F));
    _addDecorRect(x: x + 12, y: y + 1.5 * kTileSize, w: 5 * kTileSize - 24, h: 3, color: const Color(0xFFE7C79C));
    for (var i = 0; i < 3; i++) {
      final chairX = x + (i * 2 + 1) * kTileSize;
      _addChair(x: chairX, y: y - 1.5 * kTileSize);
      _addChair(x: chairX, y: y + 3.5 * kTileSize);
    }
    for (var i = 0; i < 3; i++) {
      final deviceX = x + (i * 2 + 1.5) * kTileSize;
      _addDecorRect(x: deviceX, y: y + kTileSize, w: kTileSize, h: 18, color: const Color(0xFF687B75));
      _addDecorRect(x: deviceX + 3, y: y + kTileSize + 3, w: kTileSize - 6, h: 10, color: const Color(0xFFB9C9B8));
    }
  }

  void _addChair({required double x, required double y}) {
    add(CircleComponent(position: Vector2(x + 24, y + 20), radius: 19, paint: Paint()..color = const Color(0xFF765442), priority: 0));
    _addDecorRect(x: x + 6, y: y + 5, w: 36, h: 30, color: const Color(0xFFB47A62));
  }

  void _addWallBoard({required double x, required double y}) {
    _addDecorRect(x: x, y: y, w: 4 * kTileSize, h: 2 * kTileSize, color: const Color(0xFF765442));
    _addDecorRect(x: x + 6, y: y + 6, w: 4 * kTileSize - 12, h: 2 * kTileSize - 12, color: const Color(0xFF8C9A78));
    for (var i = 0; i < 3; i++) {
      _addDecorRect(
        x: x + 12 + i * 27, y: y + 12 + (i.isEven ? 0 : 13), w: 18, h: 14,
        color: i.isEven ? const Color(0xFFE6C47A) : const Color(0xFFD58D70),
      );
    }
  }

  void _addBookshelf({required double x, required double y}) {
    _addDecorRect(x: x, y: y, w: 2 * kTileSize, h: 6 * kTileSize, color: const Color(0xFF765442));
    const bookColors = [Color(0xFF9B6651), Color(0xFFB47A62), Color(0xFF8C9A78), Color(0xFFD6A66F)];
    for (var row = 0; row < 3; row++) {
      _addDecorRect(x: x + 4, y: y + row * 2 * kTileSize + 1.5 * kTileSize, w: 2 * kTileSize - 8, h: 5, color: const Color(0xFFCAA178));
      for (var col = 0; col < 3; col++) {
        _addDecorRect(x: x + 5 + col * 18, y: y + 8 + row * 2 * kTileSize, w: 13, h: kTileSize + 12, color: bookColors[(row + col) % bookColors.length]);
      }
    }
  }

  void _addDesk({required double x, required double y}) {
    _addDecorRect(x: x, y: y, w: 3 * kTileSize, h: 2 * kTileSize, color: const Color(0xFF765442));
    _addDecorRect(x: x + 5, y: y + 5, w: 3 * kTileSize - 10, h: 2 * kTileSize - 10, color: const Color(0xFFD6A66F));
    _addDecorRect(x: x + kTileSize, y: y + 8, w: kTileSize, h: 15, color: const Color(0xFF687B75));
    _addDecorRect(x: x + kTileSize + 4, y: y + 12, w: kTileSize - 8, h: 8, color: const Color(0xFFBDD0BE));
    _addDecorRect(x: x + kTileSize + 13, y: y + 20, w: 3, h: 5, color: const Color(0xFFD6A66F));
    _addDecorRect(x: x + 2 * kTileSize + 5, y: y + 12, w: 15, h: 10, color: const Color(0xFFE7C79C));
    _addDecorRect(x: x + 2 * kTileSize + 8, y: y + 15, w: 9, h: 2, color: const Color(0xFFB47A62));
    _addChair(x: x + 1, y: y + 2.5 * kTileSize);
  }

  void _addPlant({required double x, required double y}) {
    _addDecorRect(x: x, y: y + 18, w: kTileSize, h: kTileSize, color: const Color(0xFFA45F46));
    add(CircleComponent(position: Vector2(x + 5, y), radius: 11, paint: Paint()..color = const Color(0xFF617D52), priority: 0));
    add(CircleComponent(position: Vector2(x + 16, y + 5), radius: 10, paint: Paint()..color = const Color(0xFF79935E), priority: 0));
  }
}

// ── FurnitureRenderer ─────────────────────────────────────────────────────────

/// Static helper that delegates to [OfficeMap]'s internal draw methods.
/// This is called for data-driven furniture items placed via the room editor.
class FurnitureRenderer {
  static void render({
    required OfficeMap map,
    required FurnitureType type,
    required double x,
    required double y,
    Color accentColor = const Color(0xFF9B6651),
  }) {
    switch (type) {
      case FurnitureType.sofa:
        map._addSofa(x: x, y: y, color: accentColor);
      case FurnitureType.coffeeTable:
        map._addCoffeeTable(x: x, y: y);
      case FurnitureType.desk:
        map._addDesk(x: x, y: y);
      case FurnitureType.chair:
        map._addChair(x: x, y: y);
      case FurnitureType.bookshelf:
        map._addBookshelf(x: x, y: y);
      case FurnitureType.plant:
        map._addPlant(x: x, y: y);
      case FurnitureType.beanbag:
        map._addBeanbag(x: x, y: y);
      case FurnitureType.gamingStation:
        map._addGamingStation(x: x, y: y, accent: accentColor);
      case FurnitureType.conferenceTable:
        map._addConferenceTable(x: x, y: y);
      case FurnitureType.wallBoard:
        map._addWallBoard(x: x, y: y);
      case FurnitureType.rug:
        map._addRug(left: x, top: y);
    }
  }
}
