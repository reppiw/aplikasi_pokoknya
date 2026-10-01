import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/dummy_friends.dart';
import '../../models/friend_model.dart';
import '../../widgets/active_room_banner.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  // Filter tab yang aktif: 0 = ALL, 1 = ONLINE, 2 = PENDING
  int _selectedFilterIndex = 0;

  List<Friend> get _filteredFriends {
    if (_selectedFilterIndex == 1) {
      // Filter hanya yang online, idle, atau dnd
      return dummyFriends
          .where((f) => f.status != FriendStatus.offline)
          .toList();
    }
    // Catatan: Jika butuh tab pending, kamu bisa filter data pending di sini
    return dummyFriends;
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
          // Tombol Tambah Teman
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                // TODO: Aksi tambah teman
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: NeoColors.secondary,
                  border: NeoBorder.thin,
                  boxShadow: NeoShadows.s,
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: NeoColors.ink,
                  size: 20,
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
          // ── 1. ACTIVE ROOM BANNER (Tetap Tampil jika User Sedang Join Room) ──
          const ActiveRoomBanner(),

          // ── 2. FILTER CHIPS (ALL, ONLINE, PENDING) ──────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: NeoColors.ink, width: 2),
              ),
            ),
            child: Row(
              children: [
                _buildFilterChip(index: 0, label: 'ALL (${dummyFriends.length})'),
                const SizedBox(width: 8),
                _buildFilterChip(
                  index: 1,
                  label:
                  'ONLINE (${dummyFriends.where((f) => f.status != FriendStatus.offline).length})',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(index: 2, label: 'PENDING (2)'),
              ],
            ),
          ),

          // ── 3. FRIENDS LIST ─────────────────────────────────────────────────
          Expanded(
            child: _filteredFriends.isEmpty
                ? Center(
              child: Text(
                'NO FRIENDS FOUND',
                style: NeoTextStyles.label.copyWith(color: NeoColors.muted),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredFriends.length,
              separatorBuilder: (context, index) =>
              const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final friend = _filteredFriends[index];
                return _FriendTile(friend: friend);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required int index, required String label}) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? NeoColors.ink : NeoColors.white,
          border: NeoBorder.thin,
          boxShadow: isSelected ? null : NeoShadows.s,
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

// ── WIDGET ITEM TEMAN ────────────────────────────────────────────────────────
class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NeoColors.white,
        border: NeoBorder.thick,
        boxShadow: NeoShadows.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar + Indikator Status Dot (Green/Yellow/Red/Grey)
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: NeoColors.secondary,
                      border: NeoBorder.thin,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      friend.name[0].toUpperCase(),
                      style: NeoTextStyles.h3.copyWith(fontSize: 18),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: friend.status.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: NeoColors.ink, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Nama & Custom Status / Username
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      style: NeoTextStyles.body
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      friend.customStatus.isNotEmpty
                          ? friend.customStatus
                          : '@${friend.username}',
                      style: NeoTextStyles.body.copyWith(
                        fontSize: 12,
                        color: NeoColors.ink.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Action Buttons (Chat & Voice Call)
              Row(
                children: [
                  _buildIconButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () {
                      // TODO: Buka DM Chat
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildIconButton(
                    icon: Icons.call_outlined,
                    onTap: () {
                      // TODO: Panggil / Call
                    },
                  ),
                ],
              ),
            ],
          ),

          // Jika Teman Sedang Aktif di Voice Room (Badge ala Discord)
          if (friend.isInVoiceRoom) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: NeoColors.cream,
                border: NeoBorder.thin,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.volume_up_rounded,
                    size: 14,
                    color: Color(0xFF00D166),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'IN: ${friend.activeRoomName!.toUpperCase()} • ${friend.activeGroupName}',
                      style: NeoTextStyles.label.copyWith(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00D166),
                    ),
                    child: Text(
                      'JOIN',
                      style: NeoTextStyles.label.copyWith(
                        fontSize: 9,
                        color: NeoColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: NeoColors.cream,
          border: NeoBorder.thin,
        ),
        child: Icon(icon, size: 18, color: NeoColors.ink),
      ),
    );
  }
}