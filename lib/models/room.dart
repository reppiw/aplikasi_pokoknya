import 'package:cloud_firestore/cloud_firestore.dart';
import 'furniture.dart';

// ── Room Status Tag ───────────────────────────────────────────────────────────

enum RoomStatusTag {
  free,
  lookingForGames,
  busy,
  deepWork,
  custom;

  String get label => switch (this) {
        free => 'Lounge',
        lookingForGames => 'Game Room',
        busy => 'Meeting Room',
        deepWork => 'Deep Work',
        custom => 'Custom',
      };

  String get emoji => switch (this) {
        free => '☕',
        lookingForGames => '🎮',
        busy => '📋',
        deepWork => '🎧',
        custom => '📍',
      };

  /// The legacy string ID used in Firestore avatar states and office_map room IDs.
  String get legacyId => switch (this) {
        free => 'free',
        lookingForGames => 'looking_for_games',
        busy => 'busy',
        deepWork => 'deep_work',
        custom => 'custom',
      };

  static RoomStatusTag fromLegacyId(String id) => switch (id) {
        'free' => RoomStatusTag.free,
        'looking_for_games' => RoomStatusTag.lookingForGames,
        'busy' => RoomStatusTag.busy,
        'deep_work' => RoomStatusTag.deepWork,
        _ => RoomStatusTag.custom,
      };
}

// ── Room ─────────────────────────────────────────────────────────────────────

/// A room definition used both for Firestore persistence and
/// as the data source for the Flame [OfficeMap] renderer.
///
/// Coordinates ([tileX], [tileY], [widthTiles], [heightTiles]) are in
/// tile units (1 tile = 32 px in world space).
class Room {
  final String id;
  final String name;
  final RoomStatusTag statusTag;

  /// Left edge of the room in tile units (column index).
  final double tileX;

  /// Top edge of the room in tile units (row index).
  final double tileY;

  final double widthTiles;
  final double heightTiles;

  /// Floor colour as an ARGB integer (e.g. 0xFFF2DFC5).
  final int colorHex;

  /// Furniture placed inside this room.
  final List<FurnitureItem> furnitureItems;

  const Room({
    required this.id,
    required this.name,
    required this.statusTag,
    required this.tileX,
    required this.tileY,
    required this.widthTiles,
    required this.heightTiles,
    this.colorHex = 0xFFF2DFC5,
    this.furnitureItems = const [],
  });

  // ── Serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'statusTag': statusTag.name,
        'tileX': tileX,
        'tileY': tileY,
        'widthTiles': widthTiles,
        'heightTiles': heightTiles,
        'colorHex': colorHex,
        'furnitureItems': furnitureItems.map((f) => f.toMap()).toList(),
      };

  factory Room.fromFirestore(String docId, Map<String, dynamic> map) {
    final rawFurniture = map['furnitureItems'];
    final furniture = rawFurniture is List
        ? rawFurniture
            .whereType<Map<String, dynamic>>()
            .map(FurnitureItem.fromMap)
            .toList()
        : <FurnitureItem>[];

    return Room(
      id: docId,
      name: map['name'] as String? ?? 'Room',
      statusTag: RoomStatusTag.values.firstWhere(
        (t) => t.name == (map['statusTag'] as String? ?? ''),
        orElse: () => RoomStatusTag.custom,
      ),
      tileX: (map['tileX'] as num?)?.toDouble() ?? 1,
      tileY: (map['tileY'] as num?)?.toDouble() ?? 1,
      widthTiles: (map['widthTiles'] as num?)?.toDouble() ?? 14,
      heightTiles: (map['heightTiles'] as num?)?.toDouble() ?? 18,
      colorHex: (map['colorHex'] as int?) ?? 0xFFF2DFC5,
      furnitureItems: furniture,
    );
  }

  factory Room.fromDocumentSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Room.fromFirestore(doc.id, doc.data() ?? {});
  }

  Room copyWith({
    String? id,
    String? name,
    RoomStatusTag? statusTag,
    double? tileX,
    double? tileY,
    double? widthTiles,
    double? heightTiles,
    int? colorHex,
    List<FurnitureItem>? furnitureItems,
  }) =>
      Room(
        id: id ?? this.id,
        name: name ?? this.name,
        statusTag: statusTag ?? this.statusTag,
        tileX: tileX ?? this.tileX,
        tileY: tileY ?? this.tileY,
        widthTiles: widthTiles ?? this.widthTiles,
        heightTiles: heightTiles ?? this.heightTiles,
        colorHex: colorHex ?? this.colorHex,
        furnitureItems: furnitureItems ?? this.furnitureItems,
      );
}

// ── Default layout (matches the original hardcoded OfficeMap) ─────────────────

/// Returns the 4-room default layout used when no custom rooms exist in Firestore.
/// Tile coordinates match the original hardcoded _rooms in office_map.dart exactly.
List<Room> defaultRooms() => [
      const Room(
        id: 'free',
        name: 'Lounge',
        statusTag: RoomStatusTag.free,
        tileX: 1,
        tileY: 1,
        widthTiles: 14,
        heightTiles: 18,
        colorHex: 0xFFF2DFC5,
        furnitureItems: [],
      ),
      const Room(
        id: 'looking_for_games',
        name: 'Game Room',
        statusTag: RoomStatusTag.lookingForGames,
        tileX: 17,
        tileY: 1,
        widthTiles: 14,
        heightTiles: 18,
        colorHex: 0xFFEADCCB,
        furnitureItems: [],
      ),
      const Room(
        id: 'busy',
        name: 'Meeting Room',
        statusTag: RoomStatusTag.busy,
        tileX: 1,
        tileY: 21,
        widthTiles: 14,
        heightTiles: 18,
        colorHex: 0xFFE8D9C2,
        furnitureItems: [],
      ),
      const Room(
        id: 'deep_work',
        name: 'Deep Work',
        statusTag: RoomStatusTag.deepWork,
        tileX: 17,
        tileY: 21,
        widthTiles: 14,
        heightTiles: 18,
        colorHex: 0xFFE3E2CF,
        furnitureItems: [],
      ),
    ];
