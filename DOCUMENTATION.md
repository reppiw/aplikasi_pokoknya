# Concept Document: Spatial Social Hub

## 1. The Vision
An innovative communication app that replaces traditional text channels with a visual, isometric virtual office. Friends express their current mood, availability, and intent by physically moving their avatars into designated rooms within a shared group space. 

## 2. Technical Architecture
*   **App Framework (Flutter):** Handles user authentication, group management, UI overlays, and routing push notifications.
*   **Game Environment (Unity):** Embedded via the `flutter_unity_widget` package. Renders the 3D isometric office, handles joystick input, and manages physics/colliders.
*   **Networking:** Real-time spatial synchronization and player tracking utilizing tools like `Unity.Netcode` or Photon Fusion.

## 3. Core Mechanics
*   **Spatial Status Indicators:** The office contains distinct zones. Entering specific rooms (e.g., "Looking for games!", "Busy", "Deep Work") automatically registers that user's status to the rest of the group.
*   **Contextual Broadcasting:** Users can send targeted push notifications to specific rooms. For example, pinging the "Looking for games!" room with a custom message ("Anyone up to play Valorant?") sends a notification only to the users inside that room, leaving users in the "Busy" room undisturbed.

## 4. Implementation Strategy

### 4.1 Real-Time Movement & Cost Management
To allow users to see others moving in real-time while keeping server costs minimal (or free for small groups):
*   **Networking Solutions:** Utilize Unity Relay (supports ~50 concurrent users/month free) or Photon Fusion (supports ~100 concurrent users/month free).
*   **Lower Tick Rate:** Send movement data across the network at a lower frequency (e.g., 10 times per second instead of 60).
*   **Client-Side Interpolation:** C# scripts will smoothly glide remote avatars between their last known coordinates to prevent visual stuttering.
*   **Idle Throttling:** Stop sending movement packets over the network if a player hasn't touched the joystick in 3 seconds.

### 4.2 Map & Room Generation
*   **Phase 1 (Current):** Hardcoded rooms. The isometric office, desks, and invisible room colliders are built directly in the Unity Editor to keep the app lightweight and straightforward.
*   **Phase 2 (Future):** Dynamic room-maker. Group admins will use the Flutter UI to define room names and sizes. Unity will fetch this data from the database and draw the invisible colliders at runtime.

### 4.3 Parked Avatars & Persistence
Avatars remain visible in their last known location even when a user closes the app, requiring a persistent database (like Supabase or Firebase).
*   **Saving State:** When the app is minimized, Unity sends a final message across the bridge to Flutter (e.g., "User is at coordinates [12, 4] in the Busy Room"), which Flutter writes to the database.
*   **Loading State:** When someone opens the app, Flutter fetches the group's current positions from the database.
*   **Spawning Ghosts:** Unity spawns live connected players normally, but instantiates "sleeping" or "ghost" avatars for offline users at their saved coordinates so their mood remains visible to the group.
