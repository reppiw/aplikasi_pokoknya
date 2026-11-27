import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../game/components/office_map.dart' show kMapCols, kMapRows;
import '../models/furniture.dart';
import '../models/room.dart';

/// Service that calls the Groq API to generate office room layouts from
/// a free-form user prompt.
///
/// The API key must be injected at build/run time via
/// `--dart-define=GROQ_API_KEY=...`.
class GroqService {
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');

  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _model = 'openai/gpt-oss-120b';

  static const _uuid = Uuid();

  bool get hasKey => _apiKey.isNotEmpty;

  // ── Available furniture types (for the system prompt) ───────────────────────

  static final List<String> _furnitureTypeNames =
      FurnitureType.values.map((t) => t.name).toList();

  static final Map<String, FurnitureType> _furnitureTypeLookup = {
    for (final t in FurnitureType.values) t.name: t,
  };

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Sends the user's [prompt] (and optional [roomCount]) to the Groq LLM,
  /// which returns a JSON array of room definitions. The result is parsed into
  /// a list of [Room] objects ready for the room editor and the game map.
  Future<List<Room>> generateRooms(String prompt, {int? roomCount}) async {
    if (!hasKey) {
      throw Exception(
          'Groq API key is missing. Provide it via --dart-define=GROQ_API_KEY.');
    }

    final systemPrompt = _buildSystemPrompt(roomCount: roomCount);

    final body = jsonEncode({
      'model': _model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.7,
      'max_tokens': 8192,
      'response_format': {'type': 'json_object'},
    });

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Groq API error ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        json['choices'][0]['message']['content'] as String;

    debugPrint('Groq raw response:\n$content');

    return _parseRooms(content);
  }

  // ── System prompt construction ─────────────────────────────────────────────

  String _buildSystemPrompt({int? roomCount}) {
    final roomCountInstruction = roomCount != null && roomCount > 0
        ? 'Generate exactly $roomCount rooms.'
        : 'Generate a reasonable number of rooms (2-6).';

    return '''
You are an office layout generator for a 2D tile-based virtual office app.

GRID CONSTRAINTS:
- The map is 32 columns x 40 rows (tiles). Each tile = 32px.
- Room tileX must be >= 1 and room tileX + widthTiles <= 31.
- Room tileY must be >= 1 and room tileY + heightTiles <= 39.
- Minimum room size: 6 wide x 6 tall. Maximum: 16 wide x 20 tall.
- Rooms must NOT overlap. Leave at least 1 tile gap between rooms for walls/doors.

AVAILABLE FURNITURE TYPES (use these exact names):
${_furnitureTypeNames.join(', ')}

Each furniture type has a size (width x height in tiles):
- sofa: 5x3
- coffeeTable: 2x2
- desk: 3x2
- chair: 2x2
- bookshelf: 2x6
- plant: 1x2
- beanbag: 2x2
- gamingStation: 4x6
- conferenceTable: 6x3
- wallBoard: 4x2
- rug: 7x4

FURNITURE PLACEMENT RULES:
- Furniture tileX and tileY are relative to the room's top-left corner.
- Furniture must fit within the room bounds (tileX + furnitureWidth <= room.widthTiles, same for Y).
- Leave at least 1 tile from the room edge for walkability.

AVAILABLE FLOOR COLORS (pick from these hex values):
0xFFF2DFC5 (Lounge Cream), 0xFFEADCCB (Sand Brown), 0xFFE8D9C2 (Warm Linen),
0xFFE3E2CF (Sage Green), 0xFFD8E2DC (Mint Fog), 0xFFD0DBE5 (Soft Blue),
0xFFE4D5E8 (Lavender), 0xFFFFE5D9 (Peach Warm)

$roomCountInstruction

Respond with ONLY valid JSON in this exact format:
{
  "rooms": [
    {
      "name": "Room Name",
      "tileX": 1,
      "tileY": 1,
      "widthTiles": 14,
      "heightTiles": 18,
      "colorHex": 4293918661,
      "furniture": [
        {
          "type": "desk",
          "tileX": 2,
          "tileY": 3
        }
      ]
    }
  ]
}

IMPORTANT:
- colorHex must be a decimal integer, NOT a hex string. Example: 0xFFF2DFC5 = 4293918661.
- Give each room a creative, descriptive name that matches the user's prompt.
- Place furniture thoughtfully — desks near walls, sofas in social areas, plants in corners.
- Make the layout feel natural, not just a grid of identical rooms.
''';
  }

  // ── Response parsing ───────────────────────────────────────────────────────

  List<Room> _parseRooms(String content) {
    try {
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final roomsJson = parsed['rooms'] as List<dynamic>;

      final rooms = <Room>[];
      for (final rj in roomsJson) {
        final rMap = rj as Map<String, dynamic>;

        final tileX = ((rMap['tileX'] as num?)?.toDouble() ?? 1)
            .clamp(1.0, kMapCols - 5.0);
        final tileY = ((rMap['tileY'] as num?)?.toDouble() ?? 1)
            .clamp(1.0, kMapRows - 5.0);
        final widthTiles = ((rMap['widthTiles'] as num?)?.toDouble() ?? 10)
            .clamp(4.0, kMapCols - 1.0 - tileX);
        final heightTiles = ((rMap['heightTiles'] as num?)?.toDouble() ?? 10)
            .clamp(4.0, kMapRows - 1.0 - tileY);

        // Parse furniture for this room, clamped within room bounds.
        final furnitureJson = rMap['furniture'] as List<dynamic>? ?? [];
        final furniture = <FurnitureItem>[];
        for (final fj in furnitureJson) {
          final fMap = fj as Map<String, dynamic>;
          final typeName = fMap['type'] as String? ?? '';
          final fType = _furnitureTypeLookup[typeName];
          if (fType == null) continue; // Skip unknown furniture types.
          if (fType.defaultWidthTiles > widthTiles ||
              fType.defaultHeightTiles > heightTiles) {
            continue; // Skip furniture larger than the room.
          }

          final maxFx = max(0.0, widthTiles - fType.defaultWidthTiles);
          final maxFy = max(0.0, heightTiles - fType.defaultHeightTiles);
          final fx = ((fMap['tileX'] as num?)?.toDouble() ?? 1).clamp(0.0, maxFx);
          final fy = ((fMap['tileY'] as num?)?.toDouble() ?? 1).clamp(0.0, maxFy);

          furniture.add(FurnitureItem(
            id: _uuid.v4(),
            type: fType,
            tileX: fx,
            tileY: fy,
          ));
        }

        rooms.add(Room(
          id: _uuid.v4(),
          name: rMap['name'] as String? ?? 'Room',
          tileX: tileX,
          tileY: tileY,
          widthTiles: widthTiles,
          heightTiles: heightTiles,
          colorHex: _parseColorHex(rMap['colorHex']),
          furnitureItems: furniture,
        ));
      }

      if (rooms.isEmpty) {
        throw FormatException('AI returned an empty rooms list.');
      }

      return rooms;
    } catch (e) {
      debugPrint('Failed to parse Groq response: $e');
      debugPrint('Raw content: $content');
      throw Exception(
          'Could not parse AI response into rooms. The model may have returned '
          'an unexpected format. Please try again.');
    }
  }

  int _parseColorHex(dynamic raw) {
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final cleaned = raw.trim().replaceFirst('#', '').replaceFirst('0x', '');
      final parsed = int.tryParse(cleaned, radix: 16);
      if (parsed != null) {
        return cleaned.length <= 6 ? (0xFF000000 | parsed) : parsed;
      }
    }
    return 0xFFF2DFC5;
  }
}
