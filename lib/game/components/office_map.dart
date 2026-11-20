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

// ── Walkability (now stateless — takes room list at call site) ────────────────

/// Returns true if [pos] is inside any room (world pixels) or a doorway gap.
/// [rooms] is derived from the same list passed to [OfficeMap].
bool _isWalkableInternal(Vector2 pos, {List<_RoomDef>? rooms, List<Rect>? doorways}) {
  if (rooms != null) {
    for (final r in rooms) {
      if (r.containsWorld(pos)) return true;
    }
  }
  if (doorways != null) {
    final tp = Offset(pos.x / kTileSize, pos.y / kTileSize);
    return doorways.any((d) => d.contains(tp));
  }
  return false;
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
/// Doorways are computed automatically between adjacent rooms.
class OfficeMap extends Component with HasGameReference<OfficeGame> {
  OfficeMap({
    required this.onRoomChanged,
    required List<Room> rooms,
  }) : _roomDefs = rooms.map((r) => _RoomDef(room: r)).toList();

  final void Function(String? roomId) onRoomChanged;
  final List<_RoomDef> _roomDefs;
  late final List<Rect> _doorways;

  String? _currentRoomId;

  // ── Walkability (called by PlayerComponent) ─────────────────────────────────

  bool walkable(Vector2 pos) =>
      _isWalkableInternal(pos, rooms: _roomDefs, doorways: _doorways);

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
    _doorways = _computeDoorways();

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

  /// Computes doorway Rects (in tile coordinates) between all adjacent rooms.
  /// A doorway spans 2 tiles wide/tall at the midpoint of the shared edge.
  List<Rect> _computeDoorways() {
    final doorways = <Rect>[];
    final rects = _roomDefs.map((r) => r.tileRect).toList();

    for (var i = 0; i < rects.length; i++) {
      for (var j = i + 1; j < rects.length; j++) {
        final a = rects[i];
        final b = rects[j];

        // Shared vertical edge (rooms side-by-side horizontally)
        if ((a.right - b.left).abs() < 2 || (b.right - a.left).abs() < 2) {
          final sharedX = (a.right - b.left).abs() < 2 ? a.right : b.right;
          final overlapTop = a.top > b.top ? a.top : b.top;
          final overlapBottom = a.bottom < b.bottom ? a.bottom : b.bottom;
          if (overlapBottom > overlapTop + 2) {
            final midY = (overlapTop + overlapBottom) / 2;
            doorways.add(Rect.fromLTRB(
              sharedX - 1, midY - 1, sharedX + 1, midY + 1,
            ));
          }
        }

        // Shared horizontal edge (rooms stacked vertically)
        if ((a.bottom - b.top).abs() < 2 || (b.bottom - a.top).abs() < 2) {
          final sharedY = (a.bottom - b.top).abs() < 2 ? a.bottom : b.bottom;
          final overlapLeft = a.left > b.left ? a.left : b.left;
          final overlapRight = a.right < b.right ? a.right : b.right;
          if (overlapRight > overlapLeft + 2) {
            final midX = (overlapLeft + overlapRight) / 2;
            doorways.add(Rect.fromLTRB(
              midX - 1, sharedY - 1, midX + 1, sharedY + 1,
            ));
          }
        }
      }
    }

    // If we got no computed doorways (e.g. rooms don't touch), fall back to
    // the classic 4-room doorways for backwards compatibility.
    if (doorways.isEmpty) {
      return const <Rect>[
        Rect.fromLTRB(15, 9, 17, 11),
        Rect.fromLTRB(15, 29, 17, 31),
        Rect.fromLTRB(14, 19, 16, 21),
        Rect.fromLTRB(24, 19, 26, 21),
      ];
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

  void _addDividers() {
    final mw = kMapWidth;
    final mh = kMapHeight;
    const t = kWallThick;

    // Build a set of unique room-boundary X and Y lines (in tile coords),
    // then draw walls along those lines with gaps for doorways.
    //
    // For the classic 4-room layout and any 2×2 grid this correctly places
    // vertical and horizontal dividers.

    // Collect unique interior vertical edges (right edges of rooms that are
    // not the map outer boundary).
    final vEdges = <double>{};
    final hEdges = <double>{};
    for (final r in _roomDefs) {
      final tr = r.tileRect;
      if (tr.right < kMapCols - 1) vEdges.add(tr.right);
      if (tr.bottom < kMapRows - 1) hEdges.add(tr.bottom);
    }

    // Draw each vertical divider, with gaps where doorways are.
    for (final vx in vEdges) {
      final worldX = vx * kTileSize;
      // Find doorways that cross this vertical line.
      final hGaps = _doorways
          .where((d) => (d.left * kTileSize <= worldX) &&
              (d.right * kTileSize >= worldX + t))
          .map((d) => (top: d.top * kTileSize, bottom: d.bottom * kTileSize))
          .toList();

      _drawSegmentedLine(
        isVertical: true,
        axis: worldX,
        startPerp: t,
        endPerp: mh - t,
        thickness: t,
        gaps: hGaps,
      );
    }

    // Draw each horizontal divider.
    for (final hy in hEdges) {
      final worldY = hy * kTileSize;
      final vGaps = _doorways
          .where((d) => (d.top * kTileSize <= worldY) &&
              (d.bottom * kTileSize >= worldY + t))
          .map((d) => (top: d.left * kTileSize, bottom: d.right * kTileSize))
          .toList();

      _drawSegmentedLine(
        isVertical: false,
        axis: worldY,
        startPerp: t,
        endPerp: mw - t,
        thickness: t,
        gaps: vGaps,
      );
    }
  }

  void _drawSegmentedLine({
    required bool isVertical,
    required double axis,
    required double startPerp,
    required double endPerp,
    required double thickness,
    required List<({double top, double bottom})> gaps,
  }) {
    // Sort gaps by start position
    final sortedGaps = List.of(gaps)
      ..sort((a, b) => a.top.compareTo(b.top));

    var cursor = startPerp;
    for (final gap in sortedGaps) {
      if (gap.top > cursor) {
        final len = gap.top - cursor;
        if (isVertical) {
          _addRect(x: axis, y: cursor, w: thickness, h: len);
        } else {
          _addRect(x: cursor, y: axis, w: len, h: thickness);
        }
      }
      cursor = gap.bottom;
    }
    if (cursor < endPerp) {
      final len = endPerp - cursor;
      if (isVertical) {
        _addRect(x: axis, y: cursor, w: thickness, h: len);
      } else {
        _addRect(x: cursor, y: axis, w: len, h: thickness);
      }
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
