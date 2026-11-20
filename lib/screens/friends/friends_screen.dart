import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/active_room_banner.dart';
import '../chat/chat_screen.dart';

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

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final DatabaseService _db = DatabaseService();
  String get _currentUserId =>
      AuthService.instance.currentUser?.uid ?? 'demo-user-1';

  // 0 = MY FRIENDS, 1 = DISCOVER PEOPLE
  int _selectedTabIndex = 0;

  void _showSnackBar(String message, {bool isError = false}) {
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

  Future<void> _openAddFriendDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
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
              Text('ADD FRIEND', style: NeoTextStyles.h3),
              const SizedBox(height: 6),
              Text(
                'Masukkan username teman yang ingin kamu tambahkan:',
                style: NeoTextStyles.body.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: const BoxDecoration(
                  color: NeoColors.white,
                  border: NeoBorder.thick,
                ),
                child: TextField(
                  controller: controller,
                  style: NeoTextStyles.body,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'e.g. alex_rv',
                    prefixText: '@',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: NeoColors.ink, width: 2),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('BATAL', style: NeoTextStyles.label),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NeoColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        side: const BorderSide(color: NeoColors.ink, width: 2),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        final val = controller.text.trim();
                        if (val.isNotEmpty) Navigator.pop(ctx, val);
                      },
                      child: Text('TAMBAH', style: NeoTextStyles.label.copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final res = await _db.addFriendByUsername(
        currentUserId: _currentUserId,
        username: result,
      );
      _showSnackBar(res.message, isError: !res.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.cream,
      appBar: AppBar(
        backgroundColor: NeoColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'FRIENDS',
          style: NeoTextStyles.h2.copyWith(fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: _openAddFriendDialog,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: NeoColors.secondary,
                  border: NeoBorder.thin,
                  boxShadow: NeoShadows.s,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      color: NeoColors.ink,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text('ADD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(color: NeoColors.ink, height: 4),
        ),
      ),
      body: Column(
        children: [
          const ActiveRoomBanner(),

          // ── Tabs: MY FRIENDS & DISCOVER ───────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: NeoColors.ink, width: 2),
              ),
            ),
            child: Row(
              children: [
                _buildFilterChip(index: 0, label: 'MY FRIENDS'),
                const SizedBox(width: 8),
                _buildFilterChip(index: 1, label: 'DISCOVER COMMUNITY'),
              ],
            ),
          ),

          // ── Live List from Firestore ─────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: _selectedTabIndex == 0
                  ? _db.watchFriends(_currentUserId)
                  : _db.watchAllUsers(excludeUserId: _currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: NeoColors.ink),
                  );
                }

                final users = snapshot.data ?? [];

                if (users.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: NeoColors.muted,
                              border: NeoBorder.thick,
                            ),
                            child: const Icon(Icons.people_outline, size: 36, color: NeoColors.ink),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedTabIndex == 0
                                ? 'BELUM ADA TEMAN'
                                : 'BELUM ADA PENGGUNA TERDAFTAR',
                            style: NeoTextStyles.h3.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedTabIndex == 0
                                ? 'Gunakan tombol + ADD di atas untuk menambahkan teman via username.'
                                : 'Pengguna lain yang mendaftar akan muncul di sini.',
                            textAlign: TextAlign.center,
                            style: NeoTextStyles.body.copyWith(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + MediaQuery.of(context).padding.bottom + 80,
                  ),
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isMyFriend = _selectedTabIndex == 0;

                    return _FriendTile(
                      user: user,
                      isFriend: isMyFriend,
                      onChat: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(friend: user),
                          ),
                        );
                      },
                      onAddFriend: () async {
                        final res = await _db.addFriendByUsername(
                          currentUserId: _currentUserId,
                          username: user.username,
                        );
                        _showSnackBar(res.message, isError: !res.success);
                      },
                      onRemoveFriend: () async {
                        await _db.removeFriend(
                          currentUserId: _currentUserId,
                          friendId: user.id,
                        );
                        _showSnackBar('${user.displayName} dihapus dari daftar teman.');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required int index, required String label}) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? NeoColors.ink : NeoColors.white,
          border: NeoBorder.thin,
          boxShadow: isSelected ? NeoShadows.s : [],
        ),
        child: Text(
          label,
          style: NeoTextStyles.label.copyWith(
            fontSize: 11,
            color: isSelected ? NeoColors.white : NeoColors.ink,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Friend Tile
// ─────────────────────────────────────────────────────────────────────────────

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.user,
    required this.isFriend,
    required this.onChat,
    required this.onAddFriend,
    required this.onRemoveFriend,
  });

  final AppUser user;
  final bool isFriend;
  final VoidCallback onChat;
  final VoidCallback onAddFriend;
  final VoidCallback onRemoveFriend;

  @override
  Widget build(BuildContext context) {
    final name = user.displayName.isNotEmpty
        ? user.displayName
        : (user.username.isNotEmpty ? user.username : 'User');
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final accentColor = _colorFor(name);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NeoColors.white,
        border: NeoBorder.thick,
        boxShadow: NeoShadows.s,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accentColor,
              border: NeoBorder.thin,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: NeoTextStyles.h3.copyWith(fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: NeoTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.username.isNotEmpty ? '@${user.username}' : (user.bio.isNotEmpty ? user.bio : 'Offline'),
                  style: NeoTextStyles.body.copyWith(
                    fontSize: 12,
                    color: NeoColors.ink.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIconButton(
                icon: Icons.chat_bubble_outline_rounded,
                tooltip: 'Chat',
                color: NeoColors.secondary,
                onTap: onChat,
              ),
              const SizedBox(width: 8),
              if (isFriend)
                _buildIconButton(
                  icon: Icons.person_remove_outlined,
                  tooltip: 'Hapus Teman',
                  color: NeoColors.cream,
                  onTap: onRemoveFriend,
                )
              else
                _buildIconButton(
                  icon: Icons.person_add_alt_1_outlined,
                  tooltip: 'Tambah Teman',
                  color: NeoColors.accent,
                  onTap: onAddFriend,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            border: NeoBorder.thin,
            boxShadow: NeoShadows.s,
          ),
          child: Icon(icon, color: NeoColors.ink, size: 20),
        ),
      ),
    );
  }
}
