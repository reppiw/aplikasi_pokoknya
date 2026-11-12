import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'components/office_map.dart';
import 'components/player_component.dart';
import 'components/ghost_component.dart';
import 'components/joystick_controller.dart';
import '../models/avatar_state.dart';
import '../services/room_session_manager.dart';

/// Root Flame game — top-down 2D office.
/// Mounted inside OfficeScreen via GameWidget.
class OfficeGame extends FlameGame {
  OfficeGame({required this.username, this.initialAvatarStates = const []})
      : super(camera: CameraComponent());

  final String username;
  final List<AvatarState> initialAvatarStates;

  /// Notified whenever the local player enters/leaves a room.
  final ValueNotifier<String?> activeRoomNotifier = ValueNotifier(null);

  late final PlayerComponent _player;
  final Map<String, GhostComponent> _ghosts = {};
  List<AvatarState>? _pendingAvatarStates;
  bool _isReady = false;

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';

    // 1. Office map (rooms + walls + labels)
    final map = OfficeMap(onRoomChanged: _onRoomChanged);
    await world.add(map);

    // 2. Player — start in the middle of the Lounge (top-left quadrant)
    _player = PlayerComponent(
      username: username,
      startPosition: Vector2(8 * kTileSize, 10 * kTileSize),
    );
    await world.add(_player);

    // 3. Camera: zoom so ~12 tiles fit across the shorter screen dimension,
    //    then follow the player smoothly.
    const targetTilesAcross = 12.0;
    final shortSide = size.x < size.y ? size.x : size.y;
    final zoom = shortSide / (targetTilesAcross * kTileSize);
    camera.viewfinder.zoom = zoom;
    camera.follow(_player, maxSpeed: 400 / zoom);

    // 4. Joystick in HUD space
    final joystick = JoystickController();
    await camera.viewport.add(joystick);
    _player.joystick = joystick;

    // 5. Initial ghosts
    for (final state in initialAvatarStates) {
      await _spawnGhost(state);
    }

    _isReady = true;
    final pending = _pendingAvatarStates;
    _pendingAvatarStates = null;
    if (pending != null) await updateGhosts(pending);
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> updateGhosts(List<AvatarState> states) async {
    if (!_isReady) {
      _pendingAvatarStates = states;
      return;
    }
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
    for (final id
        in _ghosts.keys.where((id) => !activeIds.contains(id)).toList()) {
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

  String _roomDisplayName(String roomId) =>
      const {
        'deep_work': 'Deep Work Zone',
        'looking_for_games': 'Game Room',
        'busy': 'Meeting Room',
        'free': 'Lounge',
      }[roomId] ??
      roomId;
}
