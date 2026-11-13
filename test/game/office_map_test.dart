import 'package:aplikasi_pokoknya/game/components/office_map.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all four doorways connect their neighboring rooms', () {
    expect(_pathIsWalkable([(8, 10), (24, 10)]), isTrue);
    expect(_pathIsWalkable([(8, 10), (14.5, 10), (14.5, 22), (8, 30)]), isTrue);
    expect(_pathIsWalkable([(8, 30), (24, 30)]), isTrue);
    expect(_pathIsWalkable([(24, 10), (24, 30)]), isTrue);
  });

  test('walls and map exterior remain blocked', () {
    expect(_walkableAt(16.5, 15), isFalse);
    expect(_walkableAt(22, 20), isFalse);
    expect(_walkableAt(0, 0), isFalse);
  });
}

bool _pathIsWalkable(List<(double, double)> points) {
  for (var segment = 0; segment < points.length - 1; segment++) {
    final (startX, startY) = points[segment];
    final (endX, endY) = points[segment + 1];
    final dx = endX - startX;
    final dy = endY - startY;
    final steps = ((dx.abs() + dy.abs()) * 4).ceil();
    for (var step = 0; step <= steps; step++) {
      final progress = steps == 0 ? 0.0 : step / steps;
      if (!_walkableAt(startX + dx * progress, startY + dy * progress)) {
        return false;
      }
    }
  }
  return true;
}

bool _walkableAt(double tileX, double tileY) {
  return isWalkable(Vector2(tileX * kTileSize, tileY * kTileSize));
}
