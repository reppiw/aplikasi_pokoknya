# Unity Project — Spatial Social Hub

Place the Unity project here. The Flutter app embeds it via `flutter_unity_widget`.

## Key responsibilities
- Render the isometric office (Phase 1: hardcoded rooms; Phase 2: dynamic colliders from Firestore)
- Handle joystick input from Flutter and move the local avatar
- Detect room entry/exit via invisible colliders → send message to Flutter bridge
- Synchronise remote avatars using Unity Relay (Unity Netcode for GameObjects)
- Spawn "ghost" avatars for offline users at coordinates received from Flutter on load
- Implement client-side interpolation (lerp) for remote avatars at 10 Hz tick rate
- Stop broadcasting movement packets after 3 s of joystick idle

## Bridge message format (Flutter ↔ Unity)
Use JSON strings passed through `postMessage` / `onUnityMessage`.

### Flutter → Unity
```json
{ "type": "LOAD_AVATARS", "avatars": [ { "userId": "...", "x": 0, "y": 0, "roomId": "...", "isOnline": false } ] }
{ "type": "LOAD_ROOMS",   "rooms":   [ { "id": "...", "name": "...", "width": 5, "height": 3 } ] }
```

### Unity → Flutter
```json
{ "type": "ROOM_ENTERED", "roomId": "..." }
{ "type": "APP_MINIMISED", "x": 12, "y": 4, "roomId": "..." }
```
