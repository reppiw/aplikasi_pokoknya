// Bi-directional bridge between Flutter and the embedded Unity view.
//
// flutter_unity_widget is temporarily removed — it uses jcenter() which is
// incompatible with AGP 9+. Re-add the package and implement this service
// once the Unity project is ready and a compatible package version exists.
//
// Flutter → Unity messages (planned):
//   - Send group avatar states on load (spawn ghosts)
//   - Send room definitions for Phase 2 dynamic colliders
//
// Unity → Flutter messages (planned):
//   - User entered a room   → update status in Firestore + change FCM topic
//   - App minimised event   → persist current position to Firestore
class UnityBridgeService {
  // void sendToUnity(String gameObject, String method, String message) => ...
  // void handleUnityMessage(String message) => ...
}
