import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../game/office_game.dart';
import '../../game/components/office_map.dart';
import '../../models/avatar_state.dart';

/// The virtual office screen — hosts the Flame game inside a Flutter scaffold.
///
/// Flutter UI layers (bottom to top):
///   1. GameWidget          ← Flame renders here (fills the screen)
///   2. Room banner overlay ← shows current room, slides in from top
///   3. Exit button         ← top-right, returns to shell
class OfficeScreen extends StatefulWidget {
  const OfficeScreen({super.key, this.groupName});

  /// The name of the group whose office is being opened.
  /// Shown in the top bar. Falls back to 'OFFICE' if null.
  final String? groupName;

  @override
  State<OfficeScreen> createState() => _OfficeScreenState();
}

class _OfficeScreenState extends State<OfficeScreen> {
  late final OfficeGame _game;

  @override
  void initState() {
    super.initState();

    // TODO: replace with real username from AuthService / Firebase once
    // backend is wired. For now use a placeholder.
    final username = 'You'; // AuthService.instance.currentUser?.username ?? 'You'

    _game = OfficeGame(
      username: username,
      // TODO: pass real AvatarStates from Firestore snapshot
      initialAvatarStates: _demoGhosts(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.ink,
      body: Stack(
        children: [
          // ── 1. Flame game ─────────────────────────────────────────────────
          Positioned.fill(
            child: GameWidget<OfficeGame>(game: _game),
          ),

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

  /// Demo ghost data so the office isn't empty while Firebase is not yet wired.
  List<AvatarState> _demoGhosts() {
    // Place ghosts at real grid positions using isoToWorld
    final alex    = isoToWorld(2, 2);  // Lounge
    final sarah   = isoToWorld(11, 3); // Game Room
    final rico    = isoToWorld(11, 13);// Deep Work
    final jessica = isoToWorld(3, 13); // Meeting Room
    return [
      AvatarState(userId: 'alex_rv',    x: alex.x,    y: alex.y,
          roomId: 'free',              isOnline: true,
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 2))),
      AvatarState(userId: 'sarah_ui',   x: sarah.x,   y: sarah.y,
          roomId: 'looking_for_games', isOnline: false,
          lastUpdated: DateTime.now().subtract(const Duration(hours: 1))),
      AvatarState(userId: 'ricopratama',x: rico.x,    y: rico.y,
          roomId: 'deep_work',         isOnline: true,
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 10))),
      AvatarState(userId: 'jess_t',     x: jessica.x, y: jessica.y,
          roomId: 'busy',              isOnline: false,
          lastUpdated: DateTime.now().subtract(const Duration(hours: 3))),
    ];
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
                  const Icon(Icons.exit_to_app_rounded,
                      size: 16, color: NeoColors.ink),
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
    'looking_for_games': (label: 'GAME ROOM', color: Color(0xFFFFD6A5), emoji: '🎮'),
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

    final meta = _roomMeta[_roomId] ??
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
                    Text('YOU ENTERED',
                        style: NeoTextStyles.label.copyWith(fontSize: 9)),
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
