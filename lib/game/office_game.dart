import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';

import 'components/office_map.dart';
import 'components/player_component.dart';
import 'components/ghost_component.dart';
import 'components/joystick_controller.dart';
import '../models/avatar_state.dart';
import '../services/room_session_manager.dart';

/// The world is a fixed 600×800 logical canvas.
/// Flame scales it to fill whatever screen it runs on.
const kMapWidth  = 600.0;
const kMapHeight = 800.0;

/// Root Flame game. Mounted inside OfficeScreen via GameWidget.
class OfficeGame extends FlameGame {
  OfficeGame({
    required this.username,
    this.initialAvatarStates = const [],
  }) : super(
          camera: CameraComponent.withFixedResolution(
            width:  kMapWidth,
            height: kMapHeight,
          ),
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
    // 1. Office map fills the world
    final map = OfficeMap(onRoomChanged: _onRoomChanged);
    await world.add(map);

    // 2. Local player — starts in the Lounge (top-left quadrant centre)
    _player = PlayerComponent(
      username: username,
      startPosition: Vector2(150, 200),
    );
    await world.add(_player);

    // 3. Camera follows the player, clamped to map bounds
    camera.follow(_player);
    camera.setBounds(
      Rectangle.fromLTWH(0, 0, kMapWidth, kMapHeight),
    );

    // 4. Virtual joystick — lives in HUD (viewport) space, not world space
    _joystick = JoystickController();
    await camera.viewport.add(_joystick);
    _player.joystick = _joystick;

    // 5. Spawn initial ghosts
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
    final toRemove = _ghosts.keys.where((id) => !activeIds.contains(id)).toList();
    for (final id in toRemove) {
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
