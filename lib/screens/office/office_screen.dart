import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../game/office_game.dart';
import '../../models/avatar_state.dart';
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

class _OfficeScreenState extends State<OfficeScreen> with WidgetsBindingObserver {
  late final OfficeGame _game;
  final List<AvatarState> _avatarStates = [];
  final DatabaseService _databaseService = DatabaseService();
  StreamSubscription<List<AvatarState>>? _avatarSubscription;

  String get _effectiveGroupId => widget.groupId ?? 'default';

  double _currentX = 8 * 32.0;
  double _currentY = 10 * 32.0;
  String _currentRoomId = 'free';

  bool _isSyncing = false;
  bool _hasPendingSync = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final userId = AuthService.instance.currentUser?.uid ?? 'You';

    _game = OfficeGame(
      username: userId,
      initialAvatarStates: _avatarStates,
      onAvatarStateChanged: _onAvatarStateChanged,
    );

    // Initial presence announce
    _requestSync(isOnline: true);

    _avatarSubscription = _databaseService
        .watchGroupAvatarStates(_effectiveGroupId)
        .listen(
          (states) {
            _avatarStates
              ..clear()
              ..addAll(states);
            _game.updateGhosts(states);
          },
          onError: (Object error, StackTrace stackTrace) {
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
      return;
    }
    _isSyncing = true;
    _saveAvatarState(isOnline: isOnline).whenComplete(() {
      _isSyncing = false;
      if (_hasPendingSync && mounted) {
        _hasPendingSync = false;
        _requestSync(isOnline: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      // Mark offline when app is minimized or backgrounded
      _saveAvatarState(isOnline: false);
    } else if (state == AppLifecycleState.resumed) {
      // Mark online when returning to foreground
      _requestSync(isOnline: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _avatarSubscription?.cancel();
    // Mark user offline upon exiting office
    _saveAvatarState(isOnline: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.ink,
      body: Stack(
        children: [
          // ── 1. Flame game ─────────────────────────────────────────────────
          Positioned.fill(child: GameWidget<OfficeGame>(game: _game)),

          // ── 2. Top bar ────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(game: _game, groupName: widget.groupName),
          ),

          // ── 3. Room banner (slides in below the top bar when entering a room) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _RoomBanner(game: _game),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: NeoColors.accent,
              border: NeoBorder.thin,
            ),
            child: Text(
              groupName?.toUpperCase() ?? 'OFFICE',
              style: NeoTextStyles.label,
            ),
          ),
          const Spacer(),
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
  const _RoomBanner({required this.game});

  final OfficeGame game;

  @override
  State<_RoomBanner> createState() => _RoomBannerState();
}

class _RoomBannerState extends State<_RoomBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Offset> _slide;
  String? _roomId;

  static const _roomMeta = {
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
      begin: const Offset(0, -1), // slides in from above
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

    final meta =
        _roomMeta[_roomId] ??
        (label: _roomId!.toUpperCase(), color: NeoColors.muted, emoji: '📍');

    // Measure the top bar height (status bar + ~52px for the bar itself) + 12px breathing room
    final topPad = MediaQuery.of(context).padding.top + 52 + 12;

    return SlideTransition(
      position: _slide,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topPad), // push banner below the top bar
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'YOU ENTERED',
                      style: NeoTextStyles.label.copyWith(fontSize: 9),
                    ),
                    Text(meta.label, style: NeoTextStyles.h3),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
