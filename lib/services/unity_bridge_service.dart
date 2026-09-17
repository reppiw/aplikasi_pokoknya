// Bi-directional bridge between Flutter and the embedded Unity view.
//
// Flutter → Unity messages:
//   - Send group avatar states on load (spawn ghosts)
//   - Send room definitions for Phase 2 dynamic colliders
//
// Unity → Flutter messages:
//   - User entered a room   → update status in Firestore + change FCM topic subscription
//   - App minimised event   → persist current position to Firestore
//
// Uses the flutter_unity_widget package's postMessage / onUnityMessage callbacks.
// TODO: implement message routing logic.
class UnityBridgeService {
  // void sendToUnity(String gameObject, String method, String message) => ...
  // void handleUnityMessage(String message) => ...
}
