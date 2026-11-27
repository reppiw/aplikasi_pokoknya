import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/string_utils.dart';
import '../../models/group.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/active_room_banner.dart';
import '../../widgets/grid_background.dart';
import '../../widgets/neo_pressable.dart';
import 'group_menu_screen.dart';

const _kPalette = [
  NeoColors.accent,
  NeoColors.secondary,
  NeoColors.muted,
  NeoColors.accent,
  NeoColors.muted,
  NeoColors.secondary,
];

Color _colorFor(String name) =>
    _kPalette[name.codeUnits.fold(0, (a, b) => a + b) % _kPalette.length];

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _db = DatabaseService();

  String get _currentUserId =>
      AuthService.instance.currentUser?.uid ?? 'demo-user-1';

  String _searchQuery = '';
  int _tabIndex = 0; // 0 = My Groups, 1 = Explore Public

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: NeoTextStyles.label.copyWith(color: NeoColors.white),
        ),
        backgroundColor: isError ? NeoColors.accent : NeoColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: NeoColors.ink, width: 3),
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    final controller = TextEditingController();
    String? result;
    try {
      result = await _showNeoDialog(
        context: context,
        title: 'CREATE GROUP',
        hint: 'Group name…',
        action: 'CREATE',
        controller: controller,
      );
    } finally {
      controller.dispose();
    }

    if (result != null && result.isNotEmpty && mounted) {
      try {
        final group = await _db.createGroup(
          name: result,
          creatorId: _currentUserId,
        );
        _showSnackBar('Grup "${group.name}" dibuat! Kode: ${group.joinCode}');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupMenuScreen(
                groupId: group.id,
                initialGroup: group,
              ),
            ),
          );
        }
      } catch (e) {
        _showSnackBar('Gagal membuat grup: $e', isError: true);
      }
    }
  }

  Future<void> _joinGroup() async {
    final controller = TextEditingController();
    String? result;
    try {
      result = await _showNeoDialog(
        context: context,
        title: 'JOIN GROUP',
        hint: 'Enter 6-char group code…',
        action: 'JOIN',
        controller: controller,
      );
    } finally {
      controller.dispose();
    }

    if (result != null && result.isNotEmpty && mounted) {
      try {
        final res = await _db.joinGroupByCode(
          code: result,
          userId: _currentUserId,
        );
        _showSnackBar(res.message, isError: !res.success);

        if (res.success && res.group != null && !res.group!.isPrivate && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupMenuScreen(
                groupId: res.group!.id,
                initialGroup: res.group,
              ),
            ),
          );
        }
      } catch (e) {
        _showSnackBar('Gagal bergabung: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/Homepage_Background.jpg', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: ColoredBox(color: NeoColors.cream.withValues(alpha: 0.88)),
        ),
        Positioned.fill(
          child: const GridBackground(alpha: 0.05),
        ),

        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ActiveRoomBanner(),

              // ── Header ───────────────────────────────────────────────────
              _GroupsHeader(
                searchController: _searchController,
                onCreateGroup: _createGroup,
                onJoinGroup: _joinGroup,
              ),

              // ── Tab selector ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    _FilterTab(
                      label: 'MY GROUPS',
                      active: _tabIndex == 0,
                      onTap: () => setState(() => _tabIndex = 0),
                    ),
                    const SizedBox(width: 10),
                    _FilterTab(
                      label: 'DISCOVER',
                      active: _tabIndex == 1,
                      onTap: () => setState(() => _tabIndex = 1),
                    ),
                  ],
                ),
              ),

              // ── Groups Stream ─────────────────────────────────────────────
              Expanded(
                child: StreamBuilder<List<Group>>(
                  stream: _tabIndex == 0
                      ? _db.watchUserGroups(_currentUserId)
                      : _db.watchPublicGroups(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: NeoColors.ink),
                      );
                    }

                    final groups = snapshot.data ?? [];
                    final filtered = _searchQuery.isEmpty
                        ? groups
                        : groups
                            .where((g) =>
                                g.name.toLowerCase().contains(_searchQuery) ||
                                g.joinCode.toLowerCase().contains(_searchQuery))
                            .toList();

                    if (filtered.isEmpty) {
                      return _EmptyState(
                        message: _tabIndex == 0
                            ? 'BELUM BERGABUNG DI GRUP MANAPUN'
                            : 'TIDAK ADA GRUP DITEMUKAN',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final group = filtered[index];
                        return _GroupListTile(
                          group: group,
                          currentUserId: _currentUserId,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Tab
// ─────────────────────────────────────────────────────────────────────────────

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? NeoColors.secondary : NeoColors.white,
          border: NeoBorder.thick,
          boxShadow: active ? NeoShadows.s : [],
        ),
        child: Text(
          label,
          style: NeoTextStyles.label.copyWith(fontSize: 12),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header section
// ─────────────────────────────────────────────────────────────────────────────

class _GroupsHeader extends StatefulWidget {
  const _GroupsHeader({
    required this.searchController,
    required this.onCreateGroup,
    required this.onJoinGroup,
  });

  final TextEditingController searchController;
  final VoidCallback onCreateGroup;
  final VoidCallback onJoinGroup;

  @override
  State<_GroupsHeader> createState() => _GroupsHeaderState();
}

class _GroupsHeaderState extends State<_GroupsHeader> {
  bool _searchFocused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: NeoColors.cream,
        border: Border(bottom: BorderSide(color: NeoColors.ink, width: 4)),
        boxShadow: [BoxShadow(color: NeoColors.ink, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Transform.rotate(
                angle: -0.04,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: NeoColors.muted,
                    border: NeoBorder.thin,
                  ),
                  child: Text('SOCIAL', style: NeoTextStyles.label.copyWith(fontSize: 9)),
                ),
              ),
              const SizedBox(width: 10),
              Text('Groups', style: NeoTextStyles.h2),
            ],
          ),
          const SizedBox(height: 14),

          // Search bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: NeoColors.white,
              border: NeoBorder.thick,
              boxShadow: _searchFocused ? NeoShadows.s : [],
            ),
            child: Focus(
              onFocusChange: (focused) => setState(() => _searchFocused = focused),
              child: TextField(
                controller: widget.searchController,
                style: NeoTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Search groups or code…',
                  hintStyle: NeoTextStyles.body.copyWith(
                    color: NeoColors.ink.withValues(alpha: 0.4),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: NeoColors.ink, size: 22),
                  suffixIcon: widget.searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: NeoColors.ink, size: 18),
                          onPressed: () => widget.searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _NeoButton(
                  label: 'CREATE GROUP',
                  color: NeoColors.accent,
                  icon: Icons.add_rounded,
                  onTap: widget.onCreateGroup,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NeoButton(
                  label: 'JOIN VIA CODE',
                  color: NeoColors.secondary,
                  icon: Icons.vpn_key_outlined,
                  onTap: widget.onJoinGroup,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Group list tile
// ─────────────────────────────────────────────────────────────────────────────

class _GroupListTile extends StatelessWidget {
  const _GroupListTile({
    required this.group,
    required this.currentUserId,
  });

  final Group group;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final initials = initialsFor(group.name);
    final isJoined = group.isMember(currentUserId);
    final accentColor = _colorFor(group.name);

    return NeoPressable(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupMenuScreen(
              groupId: group.id,
              initialGroup: group,
            ),
          ),
        );
      },
      child: (pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: pressed
            ? Matrix4.translationValues(4.0, 4.0, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: NeoColors.white,
          border: NeoBorder.thick,
          boxShadow: pressed ? [] : NeoShadows.m,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accentColor,
                border: NeoBorder.thick,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: NeoTextStyles.h3.copyWith(fontSize: 16),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name.toUpperCase(),
                          style: NeoTextStyles.bodyLarge.copyWith(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isJoined)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: NeoColors.secondary,
                            border: NeoBorder.thin,
                          ),
                          child: Text(
                            group.isOwner(currentUserId)
                                ? 'OWNER'
                                : (group.isAdmin(currentUserId) ? 'ADMIN' : 'JOINED'),
                            style: NeoTextStyles.label.copyWith(fontSize: 9),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: NeoColors.cream,
                          border: NeoBorder.thin,
                        ),
                        child: Text(
                          '#${group.joinCode}',
                          style: NeoTextStyles.label.copyWith(fontSize: 9),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.people_outline_rounded, size: 14, color: NeoColors.ink),
                      const SizedBox(width: 4),
                      Text(
                        '${group.memberIds.length} MEMBERS',
                        style: NeoTextStyles.label.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: NeoColors.ink,
                border: NeoBorder.thin,
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: NeoColors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Neo button
// ─────────────────────────────────────────────────────────────────────────────

class _NeoButton extends StatelessWidget {
  const _NeoButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeoPressable(
      onTap: onTap,
      child: (pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: pressed
            ? Matrix4.translationValues(2.0, 2.0, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          border: NeoBorder.thick,
          boxShadow: pressed ? [] : NeoShadows.s,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: NeoColors.ink),
            const SizedBox(width: 8),
            Text(
              label,
              style: NeoTextStyles.label.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.message = 'NO GROUPS FOUND'});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: NeoColors.white,
          border: NeoBorder.thick,
          boxShadow: NeoShadows.m,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NeoColors.muted,
                border: NeoBorder.thick,
              ),
              child: const Icon(Icons.group_off_outlined, size: 32, color: NeoColors.ink),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: NeoTextStyles.h3.copyWith(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Neo dialog helper
// ─────────────────────────────────────────────────────────────────────────────

Future<String?> _showNeoDialog({
  required BuildContext context,
  required String title,
  required String hint,
  required String action,
  required TextEditingController controller,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: NeoColors.cream,
            border: NeoBorder.thick,
            boxShadow: NeoShadows.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: NeoTextStyles.h3),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: NeoColors.white,
                  border: NeoBorder.thick,
                ),
                child: TextField(
                  controller: controller,
                  style: NeoTextStyles.body,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _NeoButton(
                      label: 'CANCEL',
                      color: NeoColors.white,
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NeoButton(
                      label: action,
                      color: NeoColors.accent,
                      icon: Icons.check_rounded,
                      onTap: () {
                        final val = controller.text.trim();
                        if (val.isNotEmpty) Navigator.pop(ctx, val);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
