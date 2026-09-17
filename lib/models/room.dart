enum RoomStatusTag { lookingForGames, busy, deepWork, free }

class Room {
  final String id;
  final String name;
  final RoomStatusTag statusTag;

  // Phase 2: dynamic size/position defined by group admin
  final double? width;
  final double? height;

  const Room({
    required this.id,
    required this.name,
    required this.statusTag,
    this.width,
    this.height,
  });
}
