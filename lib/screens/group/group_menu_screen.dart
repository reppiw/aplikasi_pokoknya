import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../models/group.dart';
import '../../models/user.dart';
import '../../services/database_service.dart';
import '../../widgets/neo_pressable.dart';
import '../office/office_screen.dart';
import '../room_editor/room_editor_screen.dart';

class GroupMenuScreen extends StatefulWidget {
  const GroupMenuScreen({
    super.key,
    required this.groupId,
    this.initialGroup,
  });

  final String groupId;
  final Group? initialGroup;

  @override
  State<GroupMenuScreen> createState() => _GroupMenuScreenState();
}

class _GroupMenuScreenState extends State<GroupMenuScreen> {
  final DatabaseService _db = DatabaseService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  final Map<String, AppUser> _userProfiles = {};

  void _loadUserProfiles(List<String> userIds) async {
    final missingIds = userIds.where((id) => !_userProfiles.containsKey(id)).toList();
    if (missingIds.isEmpty) return;

    try {
      final users = await _db.fetchUsers(missingIds);
      if (mounted) {
        setState(() {
          for (final u in users) {
            _userProfiles[u.id] = u;
          }
        });
      }
    } catch (_) {}
  }

  void _copyJoinCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kode grup $code berhasil disalin!', style: NeoTextStyles.label),
        backgroundColor: NeoColors.ink,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: NeoTextStyles.label.copyWith(color: isError ? Colors.white : NeoColors.ink),
        ),
        backgroundColor: isError ? NeoColors.accent : NeoColors.secondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleLeaveGroup(Group group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoColors.cream,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: NeoColors.ink, width: 4),
        ),
        title: Text('KELUAR DARI GRUP?', style: NeoTextStyles.h3),
        content: Text(
          'Apakah kamu yakin ingin keluar dari grup "${group.name}"?',
          style: NeoTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('BATAL', style: NeoTextStyles.label),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              side: const BorderSide(color: NeoColors.ink, width: 2),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('KELUAR', style: NeoTextStyles.label.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _db.removeMember(groupId: group.id, userId: _currentUserId);
        if (mounted) {
          _showSnackBar('Kamu telah keluar dari grup.');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) _showSnackBar('Gagal keluar dari grup: $e', isError: true);
      }
    }
  }

  Future<void> _togglePrivacy(Group group) async {
    final nextState = !group.isPrivate;
    final nextLabel = nextState ? 'PRIVAT' : 'PUBLIK';
    final desc = nextState
        ? 'Grup privat hanya bisa dimasuki via kode undangan dan memerlukan persetujuan admin.'
        : 'Grup publik dapat dilihat dan dimasuki langsung oleh semua pengguna.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoColors.cream,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: NeoColors.ink, width: 4),
        ),
        title: Text('UBAH MENJADI $nextLabel?', style: NeoTextStyles.h3),
        content: Text(desc, style: NeoTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('BATAL', style: NeoTextStyles.label),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoColors.secondary,
              foregroundColor: NeoColors.ink,
              elevation: 0,
              side: const BorderSide(color: NeoColors.ink, width: 2),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('UBAH', style: NeoTextStyles.label),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _db.updateGroupSettings(groupId: group.id, isPrivate: nextState);
        _showSnackBar('Status grup diubah menjadi $nextLabel.');
      } catch (e) {
        _showSnackBar('Gagal mengubah status: $e', isError: true);
      }
    }
  }

  Future<void> _showEditGroupDialog(Group group) async {
    final nameCtrl = TextEditingController(text: group.name);
    final descCtrl = TextEditingController(text: group.description);
    bool isPrivate = group.isPrivate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: NeoColors.cream,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: NeoColors.ink, width: 4),
          ),
          title: Text('EDIT GROUP INFO', style: NeoTextStyles.h3),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GROUP NAME', style: NeoTextStyles.label.copyWith(fontSize: 11)),
                const SizedBox(height: 6),
                Container(
                  decoration: const BoxDecoration(
                    color: NeoColors.white,
                    border: NeoBorder.thin,
                  ),
                  child: TextField(
                    controller: nameCtrl,
                    style: NeoTextStyles.body,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('DESCRIPTION', style: NeoTextStyles.label.copyWith(fontSize: 11)),
                const SizedBox(height: 6),
                Container(
                  decoration: const BoxDecoration(
                    color: NeoColors.white,
                    border: NeoBorder.thin,
                  ),
                  child: TextField(
                    controller: descCtrl,
                    style: NeoTextStyles.body,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => setDialogState(() => isPrivate = !isPrivate),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPrivate ? NeoColors.accent.withValues(alpha: 0.25) : NeoColors.white,
                      border: NeoBorder.thin,
                    ),
                    child: Row(
                      children: [
                        Icon(isPrivate ? Icons.lock : Icons.public, color: NeoColors.ink),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isPrivate ? 'PRIVATE GROUP' : 'PUBLIC GROUP', style: NeoTextStyles.label),
                              Text(
                                isPrivate ? 'Hanya bisa join via kode' : 'Bisa dilihat di tab Discover',
                                style: NeoTextStyles.body.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isPrivate,
                          activeThumbColor: NeoColors.accent,
                          onChanged: (val) => setDialogState(() => isPrivate = val),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('BATAL', style: NeoTextStyles.label),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                side: const BorderSide(color: NeoColors.ink, width: 2),
              ),
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                if (newName.isNotEmpty) {
                  await _db.updateGroupSettings(
                    groupId: group.id,
                    name: newName,
                    description: descCtrl.text.trim(),
                    isPrivate: isPrivate,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (mounted) {
                    _showSnackBar('Informasi grup berhasil diperbarui.');
                  }
                }
              },
              child: Text('SIMPAN', style: NeoTextStyles.label.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Group?>(
      stream: _db.watchGroup(widget.groupId),
      initialData: widget.initialGroup,
      builder: (context, snapshot) {
        final group = snapshot.data;

        if (group == null) {
          return Scaffold(
            backgroundColor: NeoColors.cream,
            appBar: AppBar(
              backgroundColor: NeoColors.cream,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: NeoColors.ink),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: NeoColors.ink),
            ),
          );
        }

        final allRelevantUserIds = [
          ...group.memberIds,
          ...group.pendingMemberIds,
        ];
        _loadUserProfiles(allRelevantUserIds);

        final isUserOwner = group.isOwner(_currentUserId);
        final isUserAdmin = group.isAdmin(_currentUserId);
        final userRole = group.roleOf(_currentUserId);

        return Scaffold(
          backgroundColor: NeoColors.cream,
          appBar: AppBar(
            backgroundColor: NeoColors.cream,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: NeoColors.ink, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('GROUP HUB', style: NeoTextStyles.h3),
            centerTitle: true,
            actions: [
              if (isUserAdmin)
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: NeoColors.ink),
                  tooltip: 'Group Settings',
                  onPressed: () => _showEditGroupDialog(group),
                ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(4),
              child: Divider(height: 4, thickness: 4, color: NeoColors.ink),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Group Header Card ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: NeoColors.white,
                  border: NeoBorder.thick,
                  boxShadow: NeoShadows.l,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(group.name.toUpperCase(), style: NeoTextStyles.h2),
                              if (group.description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  group.description,
                                  style: NeoTextStyles.body.copyWith(
                                    color: NeoColors.ink.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isUserOwner
                                ? NeoColors.accent
                                : (isUserAdmin ? NeoColors.secondary : NeoColors.muted),
                            border: NeoBorder.thin,
                          ),
                          child: Text(
                            userRole.label,
                            style: NeoTextStyles.label.copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 2, thickness: 2, color: NeoColors.ink),
                    const SizedBox(height: 14),

                    // Join Code & Info Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        InkWell(
                          onTap: () => _copyJoinCode(group.joinCode),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: NeoColors.secondary,
                              border: NeoBorder.thin,
                              boxShadow: NeoShadows.s,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.copy, size: 16, color: NeoColors.ink),
                                const SizedBox(width: 6),
                                Text(
                                  'CODE: ${group.joinCode}',
                                  style: NeoTextStyles.label.copyWith(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: NeoColors.cream,
                            border: NeoBorder.thin,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline, size: 16, color: NeoColors.ink),
                              const SizedBox(width: 6),
                              Text(
                                '${group.memberIds.length} MEMBERS',
                                style: NeoTextStyles.label.copyWith(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: isUserAdmin ? () => _togglePrivacy(group) : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: group.isPrivate ? NeoColors.accent.withValues(alpha: 0.3) : NeoColors.cream,
                              border: NeoBorder.thin,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  group.isPrivate ? Icons.lock_outline : Icons.public,
                                  size: 16,
                                  color: NeoColors.ink,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  group.isPrivate ? 'PRIVATE' : 'PUBLIC',
                                  style: NeoTextStyles.label.copyWith(fontSize: 13),
                                ),
                                if (isUserAdmin) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.swap_horiz, size: 14, color: NeoColors.ink),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Action Buttons ────────────────────────────────────────────────
              NeoPressable(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OfficeScreen(
                        groupId: group.id,
                        groupName: group.name,
                      ),
                    ),
                  );
                },
                child: (pressed) => AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  transform: pressed
                      ? Matrix4.translationValues(4.0, 4.0, 0)
                      : Matrix4.identity(),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: NeoColors.accent,
                    border: NeoBorder.thick,
                    boxShadow: pressed ? [] : NeoShadows.m,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.door_sliding_outlined, color: Colors.white, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        'ENTER VIRTUAL OFFICE',
                        style: NeoTextStyles.h3.copyWith(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),

              if (isUserAdmin) ...[
                const SizedBox(height: 12),
                NeoPressable(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoomEditorScreen(groupId: group.id),
                      ),
                    );
                  },
                  child: (pressed) => AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    transform: pressed
                        ? Matrix4.translationValues(2.0, 2.0, 0)
                        : Matrix4.identity(),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: NeoColors.secondary,
                      border: NeoBorder.thick,
                      boxShadow: pressed ? [] : NeoShadows.s,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.dashboard_customize_outlined, color: NeoColors.ink, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'EDIT OFFICE ROOMS',
                          style: NeoTextStyles.h3.copyWith(color: NeoColors.ink, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Pending Requests (Admin/Owner only) ───────────────────────────
              if (isUserAdmin && group.pendingMemberIds.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NeoColors.secondary.withValues(alpha: 0.25),
                    border: NeoBorder.thick,
                    boxShadow: NeoShadows.s,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.pending_actions, color: NeoColors.ink),
                          const SizedBox(width: 8),
                          Text(
                            'JOIN REQUESTS (${group.pendingMemberIds.length})',
                            style: NeoTextStyles.h3.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...group.pendingMemberIds.map((userId) {
                        final user = _userProfiles[userId];
                        final name = user?.displayName.isNotEmpty == true
                            ? user!.displayName
                            : (user?.username.isNotEmpty == true ? user!.username : 'User $userId');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: NeoColors.white,
                            border: NeoBorder.thin,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: NeoColors.muted,
                                child: Text(
                                  name[0].toUpperCase(),
                                  style: NeoTextStyles.label,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(name, style: NeoTextStyles.body),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                                onPressed: () async {
                                  await _db.acceptMemberRequest(groupId: group.id, userId: userId);
                                  _showSnackBar('Permintaan $name diterima.');
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: NeoColors.accent, size: 28),
                                onPressed: () async {
                                  await _db.rejectMemberRequest(groupId: group.id, userId: userId);
                                  _showSnackBar('Permintaan ditolak.');
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Member Roster ────────────────────────────────────────────────
              Text(
                'MEMBERS (${group.memberIds.length})',
                style: NeoTextStyles.h3.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: group.memberIds.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final memberId = group.memberIds[index];
                  final user = _userProfiles[memberId];
                  final isSelf = memberId == _currentUserId;
                  final memberRole = group.roleOf(memberId);

                  final name = user?.displayName.isNotEmpty == true
                      ? user!.displayName
                      : (user?.username.isNotEmpty == true
                          ? user!.username
                          : (isSelf ? 'You' : 'Member'));

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: NeoColors.white,
                      border: NeoBorder.thin,
                      boxShadow: NeoShadows.s,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: memberRole == GroupMemberRole.owner
                                ? NeoColors.accent
                                : (memberRole == GroupMemberRole.admin
                                    ? NeoColors.secondary
                                    : NeoColors.cream),
                            border: NeoBorder.thin,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: NeoTextStyles.h3.copyWith(fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    name,
                                    style: NeoTextStyles.bodyLarge.copyWith(fontSize: 16),
                                  ),
                                  if (isSelf) ...[
                                    const SizedBox(width: 6),
                                    Text('(YOU)', style: NeoTextStyles.label.copyWith(fontSize: 12, color: Colors.grey)),
                                  ],
                                ],
                              ),
                              if (user?.bio.isNotEmpty == true) ...[
                                const SizedBox(height: 2),
                                Text(
                                  user!.bio,
                                  style: NeoTextStyles.body.copyWith(fontSize: 12, color: Colors.grey[700]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: memberRole == GroupMemberRole.owner
                                ? NeoColors.accent
                                : (memberRole == GroupMemberRole.admin
                                    ? NeoColors.secondary
                                    : NeoColors.cream),
                            border: NeoBorder.thin,
                          ),
                          child: Text(
                            memberRole.label,
                            style: NeoTextStyles.label.copyWith(fontSize: 10),
                          ),
                        ),
                        if (isUserAdmin && !group.isOwner(memberId) && !isSelf) ...[
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: NeoColors.ink),
                            color: NeoColors.cream,
                            shape: const RoundedRectangleBorder(
                              side: BorderSide(color: NeoColors.ink, width: 2),
                            ),
                            onSelected: (action) async {
                              if (action == 'promote') {
                                await _db.promoteToAdmin(groupId: group.id, userId: memberId);
                                _showSnackBar('$name sekarang menjadi Admin.');
                              } else if (action == 'demote') {
                                await _db.demoteAdmin(groupId: group.id, userId: memberId);
                                _showSnackBar('$name diturunkan menjadi Member.');
                              } else if (action == 'kick') {
                                await _db.removeMember(groupId: group.id, userId: memberId);
                                _showSnackBar('$name dikeluarkan dari grup.');
                              }
                            },
                            itemBuilder: (ctx) => [
                              if (memberRole == GroupMemberRole.member)
                                const PopupMenuItem(
                                  value: 'promote',
                                  child: Text('Jadikan Admin'),
                                )
                              else if (memberRole == GroupMemberRole.admin && isUserOwner)
                                const PopupMenuItem(
                                  value: 'demote',
                                  child: Text('Turunkan jadi Member'),
                                ),
                              const PopupMenuItem(
                                value: 'kick',
                                child: Text('Keluarkan (Kick)', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // ── Leave Group Button ───────────────────────────────────────────
              if (!isUserOwner) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: NeoColors.accent, width: 3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  icon: const Icon(Icons.exit_to_app, color: NeoColors.accent),
                  label: Text(
                    'LEAVE GROUP',
                    style: NeoTextStyles.label.copyWith(color: NeoColors.accent),
                  ),
                  onPressed: () => _handleLeaveGroup(group),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}
