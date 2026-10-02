import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'components/office_map.dart';
import 'components/player_component.dart';
import 'components/ghost_component.dart';
import 'components/joystick_controller.dart';
import '../models/avatar_state.dart';
import '../services/room_session_manager.dart';

/// Root Flame game. Mounted inside OfficeScreen via GameWidget.
class OfficeGame extends FlameGame {
  OfficeGame({
    required this.username,
    this.initialAvatarStates = const [],
  }) : super(
          // Use the device's real pixel dimensions — no letterboxing.
          camera: CameraComponent(),
        );

  final String username;
  final List<AvatarState> initialAvatarStates;

  /// Notified whenever the local player enters/leaves a room.
  final ValueNotifier<String?> activeRoomNotifier = ValueNotifier(null);

  late final PlayerComponent _player;
  late final JoystickController _joystick;
  final Map<String, GhostComponent> _ghosts = {};

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    // Tell Flame to look in assets/ directly instead of assets/images/
    images.prefix = 'assets/';

    // 1. Office map
    final map = OfficeMap(onRoomChanged: _onRoomChanged);
    await world.add(map);

    // 2. Player — start at grid (3, 3) in the Lounge
    _player = PlayerComponent(
      username: username,
      startPosition: isoToWorld(3, 3),
    );
    await world.add(_player);

    // 3. Camera follows player with gentle smoothing so it glides rather than snaps.
    //    maxSpeed is in world units/s; scale by zoom so it feels consistent
    //    regardless of how zoomed in we are.
    const targetTilesAcross = 5.0;
    final shortSide = size.x < size.y ? size.x : size.y;
    final zoom = shortSide / (targetTilesAcross * kTileW);
    camera.viewfinder.zoom = zoom;
    // At this zoom, ~3 tiles/s in screen space is a comfortable follow speed.
    camera.follow(_player, maxSpeed: 3 * kTileW / zoom);

    // 4. Joystick in HUD/viewport space
    _joystick = JoystickController();
    await camera.viewport.add(_joystick);
    _player.joystick = _joystick;

    // 5. Initial ghost avatars
    for (final state in initialAvatarStates) {
      await _spawnGhost(state);
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Called by OfficeScreen when Firebase sends updated avatar states.
  Future<void> updateGhosts(List<AvatarState> states) async {
    for (final state in states) {
      if (state.userId == username) continue;
      final existing = _ghosts[state.userId];
      if (existing != null) {
        existing.updateState(state);
      } else {
        await _spawnGhost(state);
      }
    }
    final activeIds = states.map((s) => s.userId).toSet();
    for (final id in _ghosts.keys.where((id) => !activeIds.contains(id)).toList()) {
      _ghosts[id]?.removeFromParent();
      _ghosts.remove(id);
    }
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _spawnGhost(AvatarState state) async {
    if (state.userId == username) return;
    final ghost = GhostComponent(state: state);
    _ghosts[state.userId] = ghost;
    await world.add(ghost);
  }

  void _onRoomChanged(String? roomId) {
    activeRoomNotifier.value = roomId;
    final sm = RoomSessionManager();
    if (roomId != null) {
      sm.joinRoom(
        roomId: roomId,
        roomName: _roomDisplayName(roomId),
        groupName: 'office',
      );
    } else {
      sm.leaveCurrentRoom();
    }
  }

  String _roomDisplayName(String roomId) => const {
        'deep_work':         'Deep Work Zone',
        'looking_for_games': 'Game Room',
        'busy':              'Meeting Room',
        'free':              'Lounge',
      }[roomId] ?? roomId;
}
