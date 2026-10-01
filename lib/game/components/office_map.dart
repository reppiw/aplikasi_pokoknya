import 'package:flame/components.dart';

import '../office_game.dart';

// ── Isometric grid constants ──────────────────────────────────────────────────
//
// Each Kenney tile PNG is 256×512px.
// The visible diamond sits in the top 256×128px (2:1 ratio).
// We use those as our tile step values when converting grid → screen.
//
//   screenX = (col - row) * kTileStepX
//   screenY = (col + row) * kTileStepY
//
// Origin (0,0) is the top-most diamond tip of the grid.

const double kTileStepX = 128.0; // half of tile width  (256/2)
const double kTileStepY = 64.0;  // quarter of tile PNG  (256/4)

// Rendered sprite size — we scale the 256×512 PNG down to keep the world
// manageable on a phone screen.
const double kTileW = 128.0;
const double kTileH = 256.0;

// Grid dimensions
const int kCols = 16;
const int kRows = 20;

/// Converts isometric grid coordinates to world-space screen position.
/// The returned position is the top-left corner for a kTileW×kTileH sprite.
Vector2 isoToWorld(int col, int row) {
  return Vector2(
    (col - row) * (kTileW / 2),
    (col + row) * (kTileH / 8),
  );
}

/// Room zones in grid coordinates (col, row) — used for player detection.
/// Each zone is defined as a list of (col, row) cells.
const _roomZones = {
  'free':              _Rect(0, 0, 7, 7),   // Lounge — top-left
  'looking_for_games': _Rect(9, 0, 15, 7),  // Game Room — top-right
  'busy':              _Rect(0, 9, 7, 19),  // Meeting — bottom-left
  'deep_work':         _Rect(9, 9, 15, 19), // Deep Work — bottom-right
};

class OfficeMap extends Component with HasGameReference<OfficeGame> {
  OfficeMap({required this.onRoomChanged});

  final void Function(String? roomId) onRoomChanged;

  String? _currentRoomId;

  // Loaded sprites cached here so we don't reload per-cell
  late final Map<String, Sprite> _sprites;

  @override
  Future<void> onLoad() async {
    // ── Pre-load all tile sprites we'll use ─────────────────────────────────
    _sprites = {
      'floor_N':       Sprite(await game.images.load('Isometric/floor_N.png')),
      'floor_E':       Sprite(await game.images.load('Isometric/floor_E.png')),
      'wall_N':        Sprite(await game.images.load('Isometric/wall_N.png')),
      'wall_E':        Sprite(await game.images.load('Isometric/wall_E.png')),
      'wallCorner_N':  Sprite(await game.images.load('Isometric/wallCorner_N.png')),
      'wallCorner_E':  Sprite(await game.images.load('Isometric/wallCorner_E.png')),
      'wallCorner_S':  Sprite(await game.images.load('Isometric/wallCorner_S.png')),
      'wallCorner_W':  Sprite(await game.images.load('Isometric/wallCorner_W.png')),
      'doorOpen_N':    Sprite(await game.images.load('Isometric/doorOpen_N.png')),
      'doorOpen_E':    Sprite(await game.images.load('Isometric/doorOpen_E.png')),
      'doorClosed_N':  Sprite(await game.images.load('Isometric/doorClosed_N.png')),
      'doorClosed_E':  Sprite(await game.images.load('Isometric/doorClosed_E.png')),
      'block_N':       Sprite(await game.images.load('Isometric/block_N.png')),
      'crate_N':       Sprite(await game.images.load('Isometric/crate_N.png')),
      'crate_E':       Sprite(await game.images.load('Isometric/crate_E.png')),
      'fence_N':       Sprite(await game.images.load('Isometric/fence_N.png')),
      'fence_E':       Sprite(await game.images.load('Isometric/fence_E.png')),
    };

    // ── Build the map ────────────────────────────────────────────────────────
    await _buildFloor();
    await _buildWalls();
    await _buildRoomDividers();
    await _buildFurniture();
  }

  // ── Floor ──────────────────────────────────────────────────────────────────

  Future<void> _buildFloor() async {
    for (int row = 0; row < kRows; row++) {
      for (int col = 0; col < kCols; col++) {
        // Alternate N/E orientations for a checker-like floor texture
        final tileName = (col + row).isEven ? 'floor_N' : 'floor_E';
        _addTile(tileName, col, row, priority: 0);
      }
    }
  }

  // ── Outer walls ────────────────────────────────────────────────────────────

  Future<void> _buildWalls() async {
    // Top-left corner
    _addTile('wallCorner_N', 0, 0, priority: 10);

    // Top edge — wall_N along row=0 (north face)
    for (int col = 1; col < kCols - 1; col++) {
      // Door openings at room centres
      if (col == 4 || col == 12) {
        _addTile('doorOpen_N', col, 0, priority: 10);
      } else {
        _addTile('wall_N', col, 0, priority: 10);
      }
    }

    // Top-right corner
    _addTile('wallCorner_E', kCols - 1, 0, priority: 10);

    // Right edge — wall_E along col=kCols-1
    for (int row = 1; row < kRows - 1; row++) {
      if (row == 4 || row == 14) {
        _addTile('doorOpen_E', kCols - 1, row, priority: 10);
      } else {
        _addTile('wall_E', kCols - 1, row, priority: 10);
      }
    }

    // Bottom-right corner
    _addTile('wallCorner_S', kCols - 1, kRows - 1, priority: 10);

    // Bottom edge — wall_N (south face, mirrored) along row=kRows-1
    for (int col = kCols - 2; col > 0; col--) {
      _addTile('wall_N', col, kRows - 1, priority: 10);
    }

    // Bottom-left corner
    _addTile('wallCorner_W', 0, kRows - 1, priority: 10);

    // Left edge — wall_E (west face) along col=0
    for (int row = kRows - 2; row > 0; row--) {
      if (row == 4 || row == 14) {
        _addTile('doorOpen_E', 0, row, priority: 10);
      } else {
        _addTile('wall_E', 0, row, priority: 10);
      }
    }
  }

  // ── Room dividers (internal walls with door gaps) ──────────────────────────

  Future<void> _buildRoomDividers() async {
    // Vertical divider at col=8 (between left/right rooms)
    for (int row = 1; row < kRows - 1; row++) {
      if (row == 4 || row == 14) {
        _addTile('doorOpen_E', 8, row, priority: 10);
      } else {
        _addTile('fence_E', 8, row, priority: 10);
      }
    }

    // Horizontal divider at row=8 (between top/bottom rooms)
    for (int col = 1; col < kCols - 1; col++) {
      if (col == 4 || col == 12) {
        _addTile('doorOpen_N', col, 8, priority: 10);
      } else {
        _addTile('fence_N', col, 8, priority: 10);
      }
    }
  }

  // ── Furniture / props ──────────────────────────────────────────────────────

  Future<void> _buildFurniture() async {
    // Lounge (top-left) — crate cluster as sofa stand-in
    _addTile('crate_N', 2, 2, priority: 20);
    _addTile('crate_E', 3, 2, priority: 20);
    _addTile('crate_N', 2, 3, priority: 20);
    _addTile('block_N', 5, 5, priority: 20);

    // Game Room (top-right) — blocks as gaming desks
    _addTile('block_N', 10, 2, priority: 20);
    _addTile('block_N', 12, 2, priority: 20);
    _addTile('crate_N', 11, 4, priority: 20);
    _addTile('crate_E', 13, 4, priority: 20);

    // Meeting Room (bottom-left) — crates around a block "table"
    _addTile('block_N', 3, 13, priority: 20);
    _addTile('crate_N', 2, 12, priority: 20);
    _addTile('crate_E', 4, 12, priority: 20);
    _addTile('crate_N', 2, 14, priority: 20);
    _addTile('crate_E', 4, 14, priority: 20);

    // Deep Work (bottom-right) — 4 individual desk blocks
    _addTile('block_N', 10, 11, priority: 20);
    _addTile('block_N', 12, 11, priority: 20);
    _addTile('block_N', 10, 14, priority: 20);
    _addTile('block_N', 12, 14, priority: 20);
  }

  // ── Tile placement helper ──────────────────────────────────────────────────

  void _addTile(String spriteName, int col, int row, {int priority = 0}) {
    final sprite = _sprites[spriteName];
    if (sprite == null) return;

    final pos = isoToWorld(col, row);
    add(SpriteComponent(
      sprite: sprite,
      position: pos,
      size: Vector2(kTileW, kTileH),
      priority: priority + row, // painter's sort: higher row = drawn on top
    ));
  }

  // ── Room detection ─────────────────────────────────────────────────────────

  /// Convert world position back to approximate grid coordinates,
  /// then check which room zone contains that cell.
  void checkPlayerRoom(Vector2 worldPos) {
    // Inverse of isoToWorld:
    //   col = (x / (kTileW/2) + y / (kTileH/8)) / 2
    //   row = (y / (kTileH/8) - x / (kTileW/2)) / 2
    final fx = worldPos.x / (kTileW / 2);
    final fy = worldPos.y / (kTileH / 8);
    final col = ((fx + fy) / 2).round();
    final row = ((fy - fx) / 2).round();

    String? newRoomId;
    for (final entry in _roomZones.entries) {
      if (entry.value.contains(col, row)) {
        newRoomId = entry.key;
        break;
      }
    }

    if (newRoomId != _currentRoomId) {
      _currentRoomId = newRoomId;
      onRoomChanged(newRoomId);
    }
  }
}

// ── Simple grid rectangle helper ──────────────────────────────────────────────

class _Rect {
  const _Rect(this.c1, this.r1, this.c2, this.r2);
  final int c1, r1, c2, r2;
  bool contains(int col, int row) =>
      col >= c1 && col <= c2 && row >= r1 && row <= r2;
}
