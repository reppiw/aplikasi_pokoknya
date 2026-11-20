/// Persisted position + room for a user — saved to Firestore and used
/// to spawn ghost avatars for other users in the Flame office.
class AvatarState {
  final String userId;
  final String username;
  final double x;
  final double y;
  final String roomId;
  final bool isOnline;
  final DateTime lastUpdated;

  const AvatarState({
    required this.userId,
    this.username = '',
    required this.x,
    required this.y,
    required this.roomId,
    required this.isOnline,
    required this.lastUpdated,
  });

  /// Considers a user truly online only if marked online AND updated within the last 2 minutes.
  /// Protects against crashes or ungraceful network disconnections.
  bool get isCurrentlyOnline =>
      isOnline &&
      DateTime.now().difference(lastUpdated) < const Duration(minutes: 2);

  /// Deserialise from a Firestore document map.
  factory AvatarState.fromMap(Map<String, dynamic> map) {
    final uid = map['userId'] as String? ?? '';
    return AvatarState(
      userId: uid,
      username: map['username'] as String? ?? (uid.isNotEmpty ? uid : 'Guest'),
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
        'username': username,
        'x': x,
        'y': y,
        'roomId': roomId,
        'isOnline': isOnline,
        'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      };

  AvatarState copyWith({
    String? userId,
    String? username,
    double? x,
    double? y,
    String? roomId,
    bool? isOnline,
    DateTime? lastUpdated,
  }) {
    return AvatarState(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      x: x ?? this.x,
      y: y ?? this.y,
      roomId: roomId ?? this.roomId,
      isOnline: isOnline ?? this.isOnline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
