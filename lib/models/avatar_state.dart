/// Persisted position + room for a user — saved to Firestore and used
/// to spawn ghost avatars for other users in the Flame office.
class AvatarState {
  final String userId;
  final double x;
  final double y;
  final String roomId;
  final bool isOnline;
  final DateTime lastUpdated;

  const AvatarState({
    required this.userId,
    required this.x,
    required this.y,
    required this.roomId,
    required this.isOnline,
    required this.lastUpdated,
  });

  /// Deserialise from a Firestore document map.
  factory AvatarState.fromMap(Map<String, dynamic> map) {
    return AvatarState(
      userId: map['userId'] as String,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      roomId: map['roomId'] as String? ?? '',
      isOnline: map['isOnline'] as bool? ?? false,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        map['lastUpdated'] as int? ?? 0,
      ),
    );
  }

  /// Serialise to a Firestore document map.
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'x': x,
        'y': y,
        'roomId': roomId,
        'isOnline': isOnline,
        'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      };

  AvatarState copyWith({
    double? x,
    double? y,
    String? roomId,
    bool? isOnline,
    DateTime? lastUpdated,
  }) {
    return AvatarState(
      userId: userId,
      x: x ?? this.x,
      y: y ?? this.y,
      roomId: roomId ?? this.roomId,
      isOnline: isOnline ?? this.isOnline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
