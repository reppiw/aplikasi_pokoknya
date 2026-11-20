import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'components/office_map.dart';
import 'components/player_component.dart';
import 'components/ghost_component.dart';
import 'components/joystick_controller.dart';
import '../models/avatar_state.dart';
import '../models/room.dart';
import '../services/room_session_manager.dart';

/// Root Flame game — top-down 2D office.
/// Mounted inside OfficeScreen via GameWidget.
class OfficeGame extends FlameGame {
  OfficeGame({
    required this.username,
    required List<Room> rooms,
    this.initialAvatarStates = const [],
    this.initialPosition,
    this.onAvatarStateChanged,
  })  : _rooms = rooms.isNotEmpty ? rooms : defaultRooms(),
        super(camera: CameraComponent());

  final String username;
  final List<Room> _rooms;
  final List<AvatarState> initialAvatarStates;
  final Vector2? initialPosition;

  /// Callback fired whenever the local player's position or current room changes.
  final void Function(Vector2 position, String? roomId)? onAvatarStateChanged;

  /// Notified whenever the local player enters/leaves a room.
  final ValueNotifier<String?> activeRoomNotifier = ValueNotifier(null);

  late final PlayerComponent _player;
  final Map<String, GhostComponent> _ghosts = {};
  List<AvatarState>? _pendingAvatarStates;
  bool _isReady = false;

  Vector2 get playerPosition => _player.position;

  @override
  Color backgroundColor() => const Color(0xFFC9AE8B);

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';

    // 1. Office map (rooms + walls + labels + furniture)
    final map = OfficeMap(
      onRoomChanged: _onRoomChanged,
      rooms: _rooms,
    );
    await world.add(map);

    // 2. Determine start position:
    //    Prefer explicit initialPosition, then saved avatar, then first room centre.
    final firstRoom = _rooms.first;
    final defaultStart = Vector2(
      (firstRoom.tileX + firstRoom.widthTiles / 2) * kTileSize,
      (firstRoom.tileY + firstRoom.heightTiles / 2) * kTileSize,
    );

    Vector2 startPos = initialPosition ?? defaultStart;
    final savedSelf =
        initialAvatarStates.where((s) => s.userId == username).firstOrNull;
    if (savedSelf != null && initialPosition == null) {
      startPos = Vector2(savedSelf.x, savedSelf.y);
    }

    _player = PlayerComponent(
      username: username,
      startPosition: startPos,
      onPositionChanged: (pos) {
        onAvatarStateChanged?.call(pos, activeRoomNotifier.value);
      },
    );
    await world.add(_player);

    // 3. Camera: zoom so ~12 tiles fit across the shorter screen dimension.
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
    if (_isReady) {
      onAvatarStateChanged?.call(_player.position, roomId);
    }
  }

  /// Look up the display name for a room id by searching the loaded rooms list.
  String _roomDisplayName(String roomId) {
    for (final r in _rooms) {
      if (r.id == roomId) return r.name;
    }
    // Legacy fallback
    return const {
      'deep_work': 'Deep Work Zone',
      'looking_for_games': 'Game Room',
      'busy': 'Meeting Room',
      'free': 'Lounge',
    }[roomId] ?? roomId;
  }
}
