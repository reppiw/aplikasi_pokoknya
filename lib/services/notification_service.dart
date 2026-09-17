// FCM (Firebase Cloud Messaging) wrapper.
// Responsibilities:
//   - Request notification permission on first launch
//   - Subscribe/unsubscribe a user to a room-topic (e.g. "group_<id>_room_<id>")
//   - Send a targeted ping to a room topic with a custom message
// TODO: implement using firebase_messaging package.
class NotificationService {
  // Future<void> subscribeToRoom(String groupId, String roomId) async => ...
  // Future<void> sendRoomPing(String groupId, String roomId, String message) async => ...
}
