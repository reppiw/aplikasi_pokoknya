/// Persisted position + room for a user — saved to Firestore and used
/// to spawn ghost avatars for offline users in Unity.
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
}
