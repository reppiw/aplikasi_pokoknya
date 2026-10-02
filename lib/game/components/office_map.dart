import 'dart:ui' show BlendMode, Color, ColorFilter, Paint;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../office_game.dart';

// ── Isometric grid constants ──────────────────────────────────────────────────
//
// Each Kenney tile PNG is 256×512px, rendered at half size (128×256).
// The visible floor diamond is the top 128×64px of the rendered sprite (2:1).
//
//   worldX = (col - row) * kTileStepX
//   worldY = (col + row) * kTileStepY
//
// isoToWorld() returns the TOP-LEFT corner of the tile's sprite.

const double kTileW = 128.0;
const double kTileH = 256.0;

// Derived from the sprite size so there is one source of truth.
const double kTileStepX = kTileW / 2; // 64 — half the diamond width
const double kTileStepY = kTileH / 8; // 32 — half the diamond height

// Grid dimensions
const int kCols = 16;
const int kRows = 20;

/// When true, walls that face the camera (south/east outer walls and the two
/// interior dividers) use half-height pieces so they don't hide the rooms
/// behind them. Set to false to get the original full-height look.
const bool kCutawayWalls = true;

/// Converts isometric grid coordinates to world-space screen position.
/// The returned position is the top-left corner for a kTileW×kTileH sprite.
Vector2 isoToWorld(int col, int row) {
  return Vector2(
    (col - row) * kTileStepX,
    (col + row) * kTileStepY,
  );
}

/// Exact inverse of [isoToWorld]: returns the nearest grid cell for a world
/// position, using the same convention (position = tile sprite's top-left).
(int col, int row) worldToGrid(Vector2 p) {
  final fx = p.x / kTileStepX; // col - row
  final fy = p.y / kTileStepY; // col + row
  return (((fx + fy) / 2).round(), ((fy - fx) / 2).round());
}

// ── Layout constants (single source of truth) ────────────────────────────────
//
// Doors are defined once and shared by the outer walls and the dividers, so the
// openings always line up and form straight corridors through the building.

const int _dividerCol = 8; // vertical divider between west and east rooms
const int _dividerRow = 8; // horizontal divider between north and south rooms

/// Door columns: openings in the horizontal divider AND the north/south walls.
const List<int> _doorCols = [4, 12];

/// Door rows: openings in the vertical divider AND the west/east walls.
const List<int> _doorRows = [4, 14];

/// Start index of each 3-tile window group (left / middle / right).
const List<int> _northWindows = [1, 5, 9];
const List<int> _sideWindows = [1, 5, 10, 15];

// ── Rooms ────────────────────────────────────────────────────────────────────

class _Room {
  const _Room(this.id, this.name, this.c1, this.r1, this.c2, this.r2, this.tint);

  final String id; // status id reported through onRoomChanged
  final String name;
  final int c1, r1, c2, r2;
  final Color tint; // subtle floor tint so rooms read as distinct spaces

  bool contains(int col, int row) =>
      col >= c1 && col <= c2 && row >= r1 && row <= r2;
}

const _rooms = <_Room>[
  _Room('free', 'Lounge', 1, 1, _dividerCol - 1, _dividerRow - 1,
      Color(0xFFFFF0E0)),
  _Room('looking_for_games', 'Game Room', _dividerCol + 1, 1, kCols - 2,
      _dividerRow - 1, Color(0xFFEBE0FF)),
  _Room('busy', 'Meeting Room', 1, _dividerRow + 1, _dividerCol - 1, kRows - 2,
      Color(0xFFE0EEFF)),
  _Room('deep_work', 'Deep Work', _dividerCol + 1, _dividerRow + 1, kCols - 2,
      kRows - 2, Color(0xFFE0F5E8)),
];

_Room? _roomAt(int col, int row) {
  for (final room in _rooms) {
    if (room.contains(col, row)) return room;
  }
  return null;
}

// ── Tile placement records ───────────────────────────────────────────────────

/// Draw layers. Within the same iso depth (col + row) a later layer draws on
/// top of an earlier one.
enum _Layer { floor, wall, decor, prop }

class _Placement {
  const _Placement(this.sprite, this.col, this.row, this.layer, {this.tint});

  final String sprite;
  final int col, row;
  final _Layer layer;
  final Color? tint;

  /// Painter's-algorithm priority for isometric rendering.
  /// Floors always sit below everything else; everything else is sorted by
  /// iso depth (col + row) first, then by layer.
  int get priority => layer == _Layer.floor
      ? col + row
      : 100 + (col + row) * 4 + layer.index;
}

// ─────────────────────────────────────────────────────────────────────────────

class OfficeMap extends Component with HasGameReference<OfficeGame> {
  OfficeMap({required this.onRoomChanged});

  final void Function(String? roomId) onRoomChanged;

  String? _currentRoomId;

  final List<_Placement> _placements = [];
  final Set<int> _solid = {}; // row * kCols + col of blocked cells
  final Map<Color, Paint> _tintPaints = {};

  @override
  Future<void> onLoad() async {
    // 1. Describe the whole layout (synchronous, no assets needed yet).
    _buildFloor();
    _buildOuterWalls();
    _buildRoomDividers();
    _buildLounge();
    _buildGameRoom();
    _buildMeetingRoom();
    _buildDeepWork();

    // 2. Load only the sprites the layout actually uses, in parallel.
    final sprites = await _loadSprites({for (final p in _placements) p.sprite});

    // 3. Turn placements into components.
    final components = <Component>[];
    for (final p in _placements) {
      final sprite = sprites[p.sprite];
      if (sprite == null) continue;

      components.add(SpriteComponent(
        sprite: sprite,
        position: isoToWorld(p.col, p.row),
        size: Vector2(kTileW, kTileH),
        priority: p.priority,
        paint: p.tint == null ? null : _paintFor(p.tint!),
      ));
    }
    addAll(components);
    _placements.clear();
  }

  // ── Sprite loading ─────────────────────────────────────────────────────────

  Future<Sprite?> _tryLoadSprite(String name) async {
    try {
      return Sprite(await game.images.load('Isometric/$name.png'));
    } catch (_) {
      if (kDebugMode) {
        debugPrint('OfficeMap: missing sprite "Isometric/$name.png"');
      }
      return null;
    }
  }

  Future<Map<String, Sprite>> _loadSprites(Set<String> names) async {
    final list = names.toList();
    final results = await Future.wait(list.map(_tryLoadSprite));
    return {
      for (var i = 0; i < list.length; i++)
        if (results[i] != null) list[i]: results[i]!,
    };
  }

  Paint _paintFor(Color tint) => _tintPaints.putIfAbsent(
        tint,
        () => Paint()..colorFilter = ColorFilter.mode(tint, BlendMode.modulate),
      );

  // ── Placement helpers ──────────────────────────────────────────────────────

  void _place(
    String sprite,
    int col,
    int row,
    _Layer layer, {
    bool solid = false,
    Color? tint,
  }) {
    assert(
      col >= 0 && col < kCols && row >= 0 && row < kRows,
      'Tile out of grid: $sprite @ ($col, $row)',
    );
    _placements.add(_Placement(sprite, col, row, layer, tint: tint));
    if (solid) _solid.add(row * kCols + col);
  }

  void _wall(String sprite, int col, int row, {bool solid = true}) =>
      _place(sprite, col, row, _Layer.wall, solid: solid);

  /// Blocking furniture.
  void _prop(String sprite, int col, int row) =>
      _place(sprite, col, row, _Layer.prop, solid: true);

  /// Furniture the player can walk onto (chairs).
  void _chair(String sprite, int col, int row) =>
      _place(sprite, col, row, _Layer.prop);

  /// Flat markers (room signs) — never block movement.
  void _decor(String sprite, int col, int row) =>
      _place(sprite, col, row, _Layer.decor);

  // ── Floor ──────────────────────────────────────────────────────────────────

  void _buildFloor() {
    for (int row = 0; row < kRows; row++) {
      for (int col = 0; col < kCols; col++) {
        // Subtle checker using the two floor orientations.
        final tile = (col + row).isEven ? 'floor_N' : 'floor_E';
        _place(tile, col, row, _Layer.floor, tint: _roomAt(col, row)?.tint);
      }
    }
  }

  // ── Walls ──────────────────────────────────────────────────────────────────

  /// Returns the window piece for index [i] if it falls inside a 3-tile window
  /// group starting at any of [starts]; otherwise null.
  String? _windowPiece(int i, List<int> starts, String suffix) {
    for (final s in starts) {
      if (i == s) return 'windowLeft_$suffix';
      if (i == s + 1) return 'windowMiddle_$suffix';
      if (i == s + 2) return 'windowRight_$suffix';
    }
    return null;
  }

  /// Builds one straight run of wall.
  ///
  /// [alongCols] true  → runs along the columns at a fixed [fixed] row  (suffix N)
  /// [alongCols] false → runs along the rows at a fixed [fixed] column (suffix E)
  ///
  /// [doors]     openings along the run.
  /// [doorways]  use the arched doorway set (dividers) instead of plain doors.
  /// [half]      use half-height wall pieces; doors become empty gaps.
  void _wallRun({
    required bool alongCols,
    required int fixed,
    required int from,
    required int to,
    List<int> doors = const [],
    bool doorways = false,
    List<int> windowStarts = const [],
    bool half = false,
  }) {
    final s = alongCols ? 'N' : 'E';

    for (int i = from; i <= to; i++) {
      final col = alongCols ? i : fixed;
      final row = alongCols ? fixed : i;

      if (doors.contains(i)) {
        if (doorways) {
          _wall('doorwayBottom_$s', col, row, solid: false);
        } else if (!half) {
          _wall('doorOpen_$s', col, row, solid: false);
        }
        // Half walls: the door is simply a gap.
        continue;
      }

      // Tile immediately before an arched opening — the doorway jamb.
      if (doorways && doors.contains(i + 1)) {
        _wall('doorway_$s', col, row);
        continue;
      }

      final window = half ? null : _windowPiece(i, windowStarts, s);
      _wall(window ?? (half ? 'wallHalf_$s' : 'wall_$s'), col, row);
    }
  }

  void _buildOuterWalls() {
    // Corners
    _wall('wallCorner_N', 0, 0);
    _wall('wallCorner_E', kCols - 1, 0);
    _wall('wallCorner_S', kCols - 1, kRows - 1);
    _wall('wallCorner_W', 0, kRows - 1);

    // Back walls (north + west): always full height, with windows and doors.
    _wallRun(
      alongCols: true,
      fixed: 0,
      from: 1,
      to: kCols - 2,
      doors: _doorCols,
      windowStarts: _northWindows,
    );
    _wallRun(
      alongCols: false,
      fixed: 0,
      from: 1,
      to: kRows - 2,
      doors: _doorRows,
      windowStarts: _sideWindows,
    );

    // Front walls (south + east): cut away so they don't hide the floor.
    _wallRun(
      alongCols: true,
      fixed: kRows - 1,
      from: 1,
      to: kCols - 2,
      doors: _doorCols,
      windowStarts: _northWindows,
      half: kCutawayWalls,
    );
    _wallRun(
      alongCols: false,
      fixed: kCols - 1,
      from: 1,
      to: kRows - 2,
      doors: _doorRows,
      windowStarts: _sideWindows,
      half: kCutawayWalls,
    );
  }

  // Interior dividers. Both include the (8, 8) junction tile, so the two walls
  // overlap there and form a proper cross.
  void _buildRoomDividers() {
    _wallRun(
      alongCols: false,
      fixed: _dividerCol,
      from: 1,
      to: kRows - 2,
      doors: _doorRows,
      doorways: true,
      half: kCutawayWalls,
    );
    _wallRun(
      alongCols: true,
      fixed: _dividerRow,
      from: 1,
      to: kCols - 2,
      doors: _doorCols,
      doorways: true,
      half: kCutawayWalls,
    );
  }

  // ── Furniture ──────────────────────────────────────────────────────────────

  // Lounge (cols 1–7, rows 1–7)
  // A comfortable corner seating area: column pillars + slab benches + crates.
  void _buildLounge() {
    // Corner columns as décor pillars
    _prop('column_N', 2, 2);
    _prop('column_N', 6, 2);
    _prop('column_N', 2, 6);

    // Slab benches along the north-west walls
    for (int col = 3; col <= 5; col++) {
      _prop('slab_N', col, 2);
    }
    for (int row = 3; row <= 5; row++) {
      _prop('slab_E', 2, row);
    }

    // Central low table
    _prop('slabHalf_N', 4, 4);
    _prop('slabHalf_E', 5, 4);

    // A crate stack in the corner as storage
    _prop('crate_N', 6, 6);
    _prop('crate_E', 6, 5);

    // Room sign
    _decor('arrowWall_N', 3, 1);
  }

  // Game Room (cols 9–14, rows 1–7)
  // Arcade stations: column pairs as cabinet stands, blocks as screens/seats.
  void _buildGameRoom() {
    // Station 1 — top cluster
    _prop('columnCorner_N', 10, 2);
    _prop('columnCorner_E', 11, 2);
    _prop('block_N', 10, 3);
    _prop('blockHalf_N', 11, 3);

    // Station 2
    _prop('columnCorner_N', 13, 2);
    _prop('columnCorner_E', 14, 2);
    _prop('block_E', 13, 3);
    _prop('blockHalf_E', 14, 3);

    // Station 3 — lower cluster
    _prop('columnCorner_S', 10, 5);
    _prop('columnCorner_W', 11, 5);
    _prop('block_N', 10, 6);
    _prop('blockHalf_N', 11, 6);

    // Central crate for props
    _prop('crate_N', 12, 4);

    // Pole lights
    _prop('pole_N', 9, 1);
    _prop('pole_E', 14, 6);

    // Room sign
    _decor('arrowWall_E', 14, 1);
  }

  // Meeting Room (cols 1–7, rows 9–18)
  // Long conference table with chairs (blockHalf) around it.
  void _buildMeetingRoom() {
    // Table surface — two slab rows
    for (int col = 3; col <= 6; col++) {
      _prop('slab_N', col, 12);
      _prop('slab_N', col, 13);
    }
    // Head-of-table end
    _prop('slabHalf_E', 2, 12);
    _prop('slabHalf_E', 2, 13);

    // Chairs on both long sides of the table (walkable so players can sit)
    for (int col = 3; col <= 6; col++) {
      _chair('blockHalf_N', col, 11);
      _chair('blockHalf_S', col, 14);
    }

    // Whiteboard / presentation wall — slabs on west wall
    _prop('slab_E', 1, 10);
    _prop('slab_E', 1, 11);

    // Corner columns for structure
    _prop('column_N', 2, 10);
    _prop('column_N', 6, 16);

    // Room sign
    _decor('arrowWall_S', 4, 17);
  }

  // Deep Work Zone (cols 9–14, rows 9–18)
  // Individual desk pods: slab desk + lamp + chair each, with a low partition
  // between the left and right columns of desks.
  void _buildDeepWork() {
    const desks = [
      (10, 10), (13, 10),
      (10, 13), (13, 13),
      (10, 16), (13, 16),
    ];

    for (final (col, row) in desks) {
      _prop('slab_N', col, row); // desk surface
      _prop('slabHalf_E', col + 1, row); // desk extension
      _prop('pole_N', col, row - 1); // standing lamp
      _chair('blockHalf_W', col, row + 1); // chair
    }

    // Partitions between the pods. They only sit on desk rows, so the gaps in
    // between stay open as walkways (and the divider door at col 12 stays
    // reachable).
    for (final row in const [10, 13, 16]) {
      _prop('fence_E', 12, row);
    }

    // Room sign
    _decor('arrowWall_W', 9, 17);
  }

  // ── Collision ──────────────────────────────────────────────────────────────

  /// True if the grid cell is inside the map and not blocked by a wall or by
  /// solid furniture. Doorway openings and chairs are walkable.
  bool isWalkable(int col, int row) =>
      col >= 0 &&
      col < kCols &&
      row >= 0 &&
      row < kRows &&
      !_solid.contains(row * kCols + col);

  // ── Room detection ─────────────────────────────────────────────────────────

  void checkPlayerRoom(Vector2 worldPos) {
    final (col, row) = worldToGrid(worldPos);
    final newRoomId = _roomAt(col, row)?.id;

    if (newRoomId != _currentRoomId) {
      _currentRoomId = newRoomId;
      onRoomChanged(newRoomId);
    }
  }
}