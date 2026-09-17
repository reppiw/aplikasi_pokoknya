// Firestore wrapper.
// Responsibilities:
//   - Read all AvatarStates for a group (on app open → spawn ghosts in Unity)
//   - Write the current user's AvatarState (on app minimise → persist position)
//   - Stream live AvatarState updates for the group
// TODO: implement using cloud_firestore package.
class DatabaseService {
  // Future<List<AvatarState>> fetchGroupAvatarStates(String groupId) async => ...
  // Future<void> saveAvatarState(AvatarState state) async => ...
}
