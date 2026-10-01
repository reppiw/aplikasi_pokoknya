class RoomHistoryItem {
  final String roomId;
  final String roomName;
  final String groupName;
  final DateTime joinedAt;
  final DateTime? leftAt; // Null jika saat ini masih di dalam room

  bool get isActive => leftAt == null;

  const RoomHistoryItem({
    required this.roomId,
    required this.roomName,
    required this.groupName,
    required this.joinedAt,
    this.leftAt,
  });

  RoomHistoryItem copyWith({DateTime? leftAt}) {
    return RoomHistoryItem(
      roomId: roomId,
      roomName: roomName,
      groupName: groupName,
      joinedAt: joinedAt,
      leftAt: leftAt ?? this.leftAt,
    );
  }
}