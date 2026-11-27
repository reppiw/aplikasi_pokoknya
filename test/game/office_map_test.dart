import 'package:aplikasi_pokoknya/game/components/office_map.dart';
import 'package:aplikasi_pokoknya/models/room.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all four default doorways connect their neighboring rooms', () {
    final map = OfficeMap(onRoomChanged: (_) {}, rooms: defaultRooms());

    expect(_pathIsWalkable(map, [(8, 10), (24, 10)]), isTrue);
    expect(_pathIsWalkable(map, [(8, 10), (8, 30)]), isTrue);
    expect(_pathIsWalkable(map, [(8, 30), (24, 30)]), isTrue);
    expect(_pathIsWalkable(map, [(24, 10), (24, 30)]), isTrue);
  });

  test('walls and map exterior remain blocked on default map', () {
    final map = OfficeMap(onRoomChanged: (_) {}, rooms: defaultRooms());

    expect(_walkableAt(map, 16.5, 15), isFalse);
    expect(_walkableAt(map, 22, 20), isFalse);
    expect(_walkableAt(map, 0, 0), isFalse);
  });

  test('custom non-uniform rooms never slice through neighbors and stay reachable', () {
    final customRooms = [
      const Room(
        id: 'r1',
        name: 'Small Studio',
        tileX: 2,
        tileY: 2,
        widthTiles: 8,
        heightTiles: 10,
        colorHex: 0xFFF2DFC5,
      ),
      const Room(
        id: 'r2',
        name: 'Tall Hall',
        tileX: 11,
        tileY: 2,
        widthTiles: 10,
        heightTiles: 20,
        colorHex: 0xFFEADCCB,
      ),
      const Room(
        id: 'r3',
        name: 'Isolated Pod',
        tileX: 2,
        tileY: 25,
        widthTiles: 8,
        heightTiles: 8,
        colorHex: 0xFFE8D9C2,
      ),
    ];
    final map = OfficeMap(onRoomChanged: (_) {}, rooms: customRooms);

    // Tall Hall interior at y=12 (same y as Small Studio bottom wall) must remain walkable
    expect(_walkableAt(map, 15, 12.5), isTrue);
    // Small Studio <-> Tall Hall auto-doorway at midY = 7
    expect(_pathIsWalkable(map, [(6, 7), (15, 7)]), isTrue);
    // Isolated Pod center is walkable and has a corridor doorway out
    expect(_walkableAt(map, 6, 29), isTrue);
  });
}

bool _pathIsWalkable(OfficeMap map, List<(double, double)> points) {
  for (var segment = 0; segment < points.length - 1; segment++) {
    final (startX, startY) = points[segment];
    final (endX, endY) = points[segment + 1];
    final dx = endX - startX;
    final dy = endY - startY;
    final steps = ((dx.abs() + dy.abs()) * 4).ceil();
    for (var step = 0; step <= steps; step++) {
      final progress = steps == 0 ? 0.0 : step / steps;
      if (!_walkableAt(map, startX + dx * progress, startY + dy * progress)) {
        return false;
      }
    }
  }
  return true;
}

bool _walkableAt(OfficeMap map, double tileX, double tileY) {
  return map.walkable(Vector2(tileX * kTileSize, tileY * kTileSize));
}
