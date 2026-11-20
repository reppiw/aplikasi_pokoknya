import 'package:cloud_firestore/cloud_firestore.dart';
import 'furniture.dart';

// ── Room ─────────────────────────────────────────────────────────────────────

/// A room definition used both for Firestore persistence and
/// as the data source for the Flame [OfficeMap] renderer.
///
/// Coordinates ([tileX], [tileY], [widthTiles], [heightTiles]) are in
/// tile units (1 tile = 32 px in world space).
class Room {
  final String id;
  final String name;

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
        tileX: 1,
        tileY: 1,
        widthTiles: 14,
        heightTiles: 18,
        colorHex: 0xFFF2DFC5,
        furnitureItems: [
          FurnitureItem(id: 'lounge_sofa_1', type: FurnitureType.sofa, tileX: 2, tileY: 3),
          FurnitureItem(id: 'lounge_table', type: FurnitureType.coffeeTable, tileX: 5, tileY: 3),
          FurnitureItem(id: 'lounge_sofa_2', type: FurnitureType.sofa, tileX: 8, tileY: 3),
          FurnitureItem(id: 'lounge_rug', type: FurnitureType.rug, tileX: 3, tileY: 7),
          FurnitureItem(id: 'lounge_plant_1', type: FurnitureType.plant, tileX: 11, tileY: 2),
          FurnitureItem(id: 'lounge_beanbag', type: FurnitureType.beanbag, tileX: 10, tileY: 13),
          FurnitureItem(id: 'lounge_plant_2', type: FurnitureType.plant, tileX: 2, tileY: 14),
        ],
      ),
      const Room(
        id: 'looking_for_games',
        name: 'Game Room',
        tileX: 17,
        tileY: 1,
        widthTiles: 14,
        heightTiles: 18,
        colorHex: 0xFFEADCCB,
        furnitureItems: [
          FurnitureItem(id: 'game_station_1', type: FurnitureType.gamingStation, tileX: 2, tileY: 3),
          FurnitureItem(id: 'game_station_2', type: FurnitureType.gamingStation, tileX: 7, tileY: 3),
          FurnitureItem(id: 'game_sofa', type: FurnitureType.sofa, tileX: 3, tileY: 9),
          FurnitureItem(id: 'game_beanbag', type: FurnitureType.beanbag, tileX: 10, tileY: 3),
          FurnitureItem(id: 'game_plant', type: FurnitureType.plant, tileX: 11, tileY: 14),
        ],
      ),
      const Room(
        id: 'busy',
        name: 'Meeting Room',
        tileX: 1,
        tileY: 21,
        widthTiles: 14,
        heightTiles: 18,
        colorHex: 0xFFE8D9C2,
        furnitureItems: [
          FurnitureItem(id: 'meeting_board', type: FurnitureType.wallBoard, tileX: 4, tileY: 1),
          FurnitureItem(id: 'meeting_table', type: FurnitureType.conferenceTable, tileX: 4, tileY: 5),
          FurnitureItem(id: 'meeting_chair_1', type: FurnitureType.chair, tileX: 2, tileY: 5),
          FurnitureItem(id: 'meeting_chair_2', type: FurnitureType.chair, tileX: 2, tileY: 7),
          FurnitureItem(id: 'meeting_chair_3', type: FurnitureType.chair, tileX: 10, tileY: 5),
          FurnitureItem(id: 'meeting_chair_4', type: FurnitureType.chair, tileX: 10, tileY: 7),
          FurnitureItem(id: 'meeting_plant', type: FurnitureType.plant, tileX: 11, tileY: 14),
        ],
      ),
      const Room(
        id: 'deep_work',
        name: 'Deep Work',
        tileX: 17,
        tileY: 21,
        widthTiles: 14,
        heightTiles: 18,
        colorHex: 0xFFE3E2CF,
        furnitureItems: [
          FurnitureItem(id: 'deep_desk_1', type: FurnitureType.desk, tileX: 2, tileY: 3),
          FurnitureItem(id: 'deep_chair_1', type: FurnitureType.chair, tileX: 3, tileY: 5),
          FurnitureItem(id: 'deep_desk_2', type: FurnitureType.desk, tileX: 7, tileY: 3),
          FurnitureItem(id: 'deep_chair_2', type: FurnitureType.chair, tileX: 8, tileY: 5),
          FurnitureItem(id: 'deep_bookshelf_1', type: FurnitureType.bookshelf, tileX: 2, tileY: 12),
          FurnitureItem(id: 'deep_bookshelf_2', type: FurnitureType.bookshelf, tileX: 6, tileY: 12),
          FurnitureItem(id: 'deep_plant', type: FurnitureType.plant, tileX: 11, tileY: 14),
        ],
      ),
    ];
