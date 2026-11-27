import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../game/office_game.dart';
import '../../game/components/office_map.dart';
import '../../models/avatar_state.dart';
import '../../models/room.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

/// The virtual office screen — hosts the Flame game inside a Flutter scaffold.
///
/// Flutter UI layers (bottom to top):
///   1. GameWidget          ← Flame renders here (fills the screen)
///   2. Room banner overlay ← shows current room, slides in from top
///   3. Exit button         ← top-right, returns to shell
class OfficeScreen extends StatefulWidget {
  const OfficeScreen({super.key, this.groupName, this.groupId});

  /// The name of the group whose office is being opened.
  /// Shown in the top bar. Falls back to 'OFFICE' if null.
  final String? groupName;

  /// The ID of the group for persistent presence. Defaults to 'default'.
  final String? groupId;

  @override
  State<OfficeScreen> createState() => _OfficeScreenState();
}

class _OfficeScreenState extends State<OfficeScreen>
    with WidgetsBindingObserver {
  // Game is nullable until rooms are loaded.
  OfficeGame? _game;
  List<Room> _rooms = const [];
  bool _loadingRooms = true;

  final List<AvatarState> _avatarStates = [];
  final DatabaseService _databaseService = DatabaseService();
  StreamSubscription<List<AvatarState>>? _avatarSubscription;

  String get _effectiveGroupId => widget.groupId ?? 'default';

  double _currentX = 8 * kTileSize;
  double _currentY = 10 * kTileSize;
  String _currentRoomId = 'free';
  String _currentUsername = 'You';

  bool _isSyncing = false;
  bool _hasPendingSync = false;
  bool _pendingOnlineState = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRoomsAndStart();
  }

  Future<void> _loadRoomsAndStart() async {
    final authUser = AuthService.instance.currentUser;
    final userId = authUser?.uid ?? 'guest';

    // 1. Concurrently fetch rooms, initial avatar states, and user profile
    List<Room> rooms = defaultRooms();
    List<AvatarState> initialStates = [];
    String username = '';

    try {
      final results = await Future.wait([
        _databaseService.fetchGroupRooms(_effectiveGroupId),
        _databaseService.fetchGroupAvatarStates(_effectiveGroupId),
        _databaseService.getUser(userId),
      ]);

      final fetchedRooms = results[0] as List<Room>;
      if (fetchedRooms.isNotEmpty) rooms = fetchedRooms;

      initialStates = results[1] as List<AvatarState>;

      final userProfile = results[2] as AppUser?;
      if (userProfile != null) {
        if (userProfile.username.isNotEmpty) {
          username = userProfile.username;
        } else if (userProfile.displayName.isNotEmpty) {
          username = userProfile.displayName;
        }
      }
    } catch (e) {
      debugPrint('Error loading initial office data: $e');
    }

    if (username.isEmpty) {
      final dn = authUser?.displayName;
      final em = authUser?.email;
      if (dn != null && dn.isNotEmpty) {
        username = dn;
      } else if (em != null && em.isNotEmpty) {
        username = em.split('@').first;
      } else {
        username = 'You';
      }
    }
    _currentUsername = username;

    _avatarStates
      ..clear()
      ..addAll(initialStates);

    if (!mounted) return;

    // 2. Restore spawn position: prefer saved position if still inside a room, else first room center
    final savedSelf = initialStates.where((s) => s.userId == userId).firstOrNull;
    Vector2? startPosition;

    bool isSavedInsideAnyRoom = false;
    if (savedSelf != null && savedSelf.x > 0 && savedSelf.y > 0) {
      final tx = savedSelf.x / kTileSize;
      final ty = savedSelf.y / kTileSize;
      isSavedInsideAnyRoom = rooms.any(
        (r) =>
            tx >= r.tileX &&
            tx <= r.tileX + r.widthTiles &&
            ty >= r.tileY &&
            ty <= r.tileY + r.heightTiles,
      );
    }

    if (savedSelf != null && isSavedInsideAnyRoom) {
      _currentX = savedSelf.x;
      _currentY = savedSelf.y;
      _currentRoomId = savedSelf.roomId;
      startPosition = Vector2(savedSelf.x, savedSelf.y);
    } else if (rooms.isNotEmpty) {
      final first = rooms.first;
      _currentX = (first.tileX + first.widthTiles / 2) * kTileSize;
      _currentY = (first.tileY + first.heightTiles / 2) * kTileSize;
      _currentRoomId = first.id;
      startPosition = Vector2(_currentX, _currentY);
    }

    final game = OfficeGame(
      userId: userId,
      username: _currentUsername,
      rooms: rooms,
      groupName: widget.groupName,
      initialAvatarStates: _avatarStates,
      initialPosition: startPosition,
      onAvatarStateChanged: _onAvatarStateChanged,
    );

    setState(() {
      _rooms = rooms;
      _game = game;
      _loadingRooms = false;
    });

    // 3. Sync presence now that position is correctly restored
    _requestSync(isOnline: true);

    // 4. Start live subscription for other players' ghosts
    _avatarSubscription = _databaseService
        .watchGroupAvatarStates(_effectiveGroupId)
        .listen(
          (states) {
            _avatarStates
              ..clear()
              ..addAll(states);
            game.updateGhosts(states);
          },
          onError: (Object error, StackTrace _) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal memuat data kantor: $error')),
            );
          },
        );
  }

  void _onAvatarStateChanged(Vector2 position, String? roomId) {
    _currentX = position.x;
    _currentY = position.y;
    if (roomId != null) {
      _currentRoomId = roomId;
    }
    _requestSync(isOnline: true);
  }

  Future<void> _saveAvatarState({required bool isOnline}) async {
    final userId = AuthService.instance.currentUser?.uid;
    if (userId == null) return;

    final state = AvatarState(
      userId: userId,
      username: _currentUsername,
      x: _currentX,
      y: _currentY,
      roomId: _currentRoomId,
      isOnline: isOnline,
      lastUpdated: DateTime.now(),
    );

    try {
      await _databaseService.saveAvatarState(_effectiveGroupId, state);
    } catch (e) {
      debugPrint('Failed to save avatar state: $e');
    }
  }

  void _requestSync({required bool isOnline}) {
    if (_isSyncing) {
      _hasPendingSync = true;
      _pendingOnlineState = isOnline;
      return;
    }
    _isSyncing = true;
    _saveAvatarState(isOnline: isOnline).whenComplete(() {
      _isSyncing = false;
      if (_hasPendingSync && mounted) {
        _hasPendingSync = false;
        _requestSync(isOnline: _pendingOnlineState);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _requestSync(isOnline: false);
    } else if (state == AppLifecycleState.resumed) {
      _requestSync(isOnline: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _avatarSubscription?.cancel();
    _saveAvatarState(isOnline: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRooms) {
      return const Scaffold(
        backgroundColor: NeoColors.cream,
        body: Center(child: CircularProgressIndicator(color: NeoColors.ink)),
      );
    }

    final game = _game!;
    return Scaffold(
      backgroundColor: NeoColors.ink,
      body: Stack(
        children: [
          // ── 1. Flame game ─────────────────────────────────────────────────
          Positioned.fill(child: GameWidget<OfficeGame>(game: game)),

          // ── 2. Top bar ────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(game: game, groupName: widget.groupName),
          ),

          // ── 3. Room banner (slides in below the top bar when entering a room) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _RoomBanner(game: game, rooms: _rooms),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar — office title + exit button
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.game, this.groupName});

  final OfficeGame game;
  final String? groupName;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 8),
      decoration: BoxDecoration(
        color: NeoColors.cream,
        border: const Border(
          bottom: BorderSide(color: NeoColors.ink, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: NeoColors.accent,
                  border: NeoBorder.thin,
                ),
                child: Text(
                  groupName?.toUpperCase() ?? 'OFFICE',
                  style: NeoTextStyles.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: NeoColors.cream,
                border: NeoBorder.thick,
                boxShadow: NeoShadows.s,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.exit_to_app_rounded,
                    size: 16,
                    color: NeoColors.ink,
                  ),
                  const SizedBox(width: 6),
                  Text('LEAVE', style: NeoTextStyles.label),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Room banner — animates in/out when the player enters/leaves a room
// ─────────────────────────────────────────────────────────────────────────────

class _RoomBanner extends StatefulWidget {
  const _RoomBanner({required this.game, required this.rooms});

  final OfficeGame game;
  final List<Room> rooms;

  @override
  State<_RoomBanner> createState() => _RoomBannerState();
}

class _RoomBannerState extends State<_RoomBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Offset> _slide;
  String? _roomId;

  /// Static meta for the original 4 default rooms.
  static const _defaultMeta = {
    'free': (label: 'LOUNGE', color: Color(0xFFB8E4C9), emoji: '☕'),
    'looking_for_games': (
      label: 'GAME ROOM',
      color: Color(0xFFFFD6A5),
      emoji: '🎮',
    ),
    'busy': (label: 'MEETING ROOM', color: Color(0xFFFFB3B3), emoji: '📋'),
    'deep_work': (label: 'DEEP WORK', color: Color(0xFFB3D4FF), emoji: '🎧'),
  };

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));

    widget.game.activeRoomNotifier.addListener(_onRoomChanged);
  }

  @override
  void dispose() {
    widget.game.activeRoomNotifier.removeListener(_onRoomChanged);
    _anim.dispose();
    super.dispose();
  }

  void _onRoomChanged() {
    if (!mounted) return;
    final roomId = widget.game.activeRoomNotifier.value;
    setState(() => _roomId = roomId);
    if (roomId != null) {
      _anim.forward();
    } else {
      _anim.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_roomId == null) return const SizedBox.shrink();

    final matchedRoom = widget.rooms.where((r) => r.id == _roomId).firstOrNull;
    final defaultMeta = _defaultMeta[_roomId];
    final meta = (
      label: matchedRoom != null
          ? matchedRoom.name.toUpperCase()
          : (defaultMeta?.label ?? _roomId!.toUpperCase()),
      color: defaultMeta?.color ??
          (matchedRoom != null ? Color(matchedRoom.colorHex) : NeoColors.muted),
      emoji: defaultMeta?.emoji ?? '📍',
    );

    final topPad = MediaQuery.of(context).padding.top + 52 + 12;

    return SlideTransition(
      position: _slide,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topPad),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: meta.color,
              border: NeoBorder.thick,
              boxShadow: NeoShadows.l,
            ),
            child: Row(
              children: [
                Text(meta.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'YOU ENTERED',
                        style: NeoTextStyles.label.copyWith(fontSize: 9),
                      ),
                      Text(
                        meta.label,
                        style: NeoTextStyles.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
