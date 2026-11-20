import 'dart:ui' show Color;

// ── Furniture Type Enum ───────────────────────────────────────────────────────

/// All available furniture pieces in the catalog.
/// Each type maps 1-to-1 with a hand-drawn renderer in [FurnitureRenderer].
enum FurnitureType {
  sofa,
  coffeeTable,
  desk,
  chair,
  bookshelf,
  plant,
  beanbag,
  gamingStation,
  conferenceTable,
  wallBoard,
  rug;

  /// Human-readable label for UI display.
  String get label => switch (this) {
        sofa => 'Sofa',
        coffeeTable => 'Coffee Table',
        desk => 'Desk',
        chair => 'Chair',
        bookshelf => 'Bookshelf',
        plant => 'Plant',
        beanbag => 'Beanbag',
        gamingStation => 'Gaming Station',
        conferenceTable => 'Conference Table',
        wallBoard => 'Whiteboard',
        rug => 'Rug',
      };

  /// Emoji for quick visual reference in the catalog UI.
  String get emoji => switch (this) {
        sofa => '🛋️',
        coffeeTable => '☕',
        desk => '🖥️',
        chair => '🪑',
        bookshelf => '📚',
        plant => '🪴',
        beanbag => '🫘',
        gamingStation => '🎮',
        conferenceTable => '📋',
        wallBoard => '📝',
        rug => '🟫',
      };

  /// Default width in tiles when first placed.
  int get defaultWidthTiles => switch (this) {
        sofa => 5,
        coffeeTable => 2,
        desk => 3,
        chair => 2,
        bookshelf => 2,
        plant => 1,
        beanbag => 2,
        gamingStation => 4,
        conferenceTable => 6,
        wallBoard => 4,
        rug => 7,
      };

  /// Default height in tiles when first placed.
  int get defaultHeightTiles => switch (this) {
        sofa => 3,
        coffeeTable => 2,
        desk => 2,
        chair => 2,
        bookshelf => 6,
        plant => 2,
        beanbag => 2,
        gamingStation => 6,
        conferenceTable => 3,
        wallBoard => 2,
        rug => 4,
      };

  /// Default accent color for this furniture type.
  int get defaultColorHex => switch (this) {
        sofa => 0xFF9B6651,
        coffeeTable => 0xFF765442,
        desk => 0xFFD6A66F,
        chair => 0xFFB47A62,
        bookshelf => 0xFF765442,
        plant => 0xFF617D52,
        beanbag => 0xFFB47A62,
        gamingStation => 0xFF8273A6,
        conferenceTable => 0xFF765442,
        wallBoard => 0xFF8C9A78,
        rug => 0xFF9B6651,
      };
}

// ── Furniture Item (placed instance) ──────────────────────────────────────────

/// A single piece of furniture placed inside a room.
/// Coordinates are in tile units, relative to the room's top-left corner.
class FurnitureItem {
  final String id;
  final FurnitureType type;

  /// Position within the room (tile offset from room origin).
  final double tileX;
  final double tileY;

  /// Optional accent color override (ARGB int). Null = use type default.
  final int? colorHex;

  const FurnitureItem({
    required this.id,
    required this.type,
    required this.tileX,
    required this.tileY,
    this.colorHex,
  });

  Color get color => Color(colorHex ?? type.defaultColorHex);

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'tileX': tileX,
        'tileY': tileY,
        if (colorHex != null) 'colorHex': colorHex,
      };

  factory FurnitureItem.fromMap(Map<String, dynamic> map) {
    return FurnitureItem(
      id: map['id'] as String? ?? '',
      type: FurnitureType.values.firstWhere(
        (t) => t.name == (map['type'] as String? ?? ''),
        orElse: () => FurnitureType.plant,
      ),
      tileX: (map['tileX'] as num?)?.toDouble() ?? 0,
      tileY: (map['tileY'] as num?)?.toDouble() ?? 0,
      colorHex: map['colorHex'] as int?,
    );
  }

  FurnitureItem copyWith({
    String? id,
    FurnitureType? type,
    double? tileX,
    double? tileY,
    int? colorHex,
  }) =>
      FurnitureItem(
        id: id ?? this.id,
        type: type ?? this.type,
        tileX: tileX ?? this.tileX,
        tileY: tileY ?? this.tileY,
        colorHex: colorHex ?? this.colorHex,
      );
}
