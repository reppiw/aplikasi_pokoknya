import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/auth_service.dart';
import 'edit_profile_screen.dart';
import '../../widgets/grid_background.dart';
import '../../widgets/neo_pressable.dart';

class _ProfileStat {
  const _ProfileStat(this.label, this.value, this.accentColor);
  final String label, value;
  final Color accentColor;
}

// Stats are still placeholders — will be replaced when groups/friends are wired.
List<_ProfileStat> _buildStats() => const [
  _ProfileStat('GROUPS', '-', NeoColors.accent),
  _ProfileStat('FRIENDS', '-', NeoColors.secondary),
  _ProfileStat('STATUS', 'ON', NeoColors.muted),
];

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _privateAccount = false;
  bool _allowDirectMessages = true;

  Future<void> _openEditProfile(AppUser currentUser) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: currentUser),
      ),
    );
    // No local setState needed — the StreamProvider will emit the updated
    // profile automatically after EditProfileScreen writes to Firestore.
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: NeoColors.cream,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: NeoColors.ink, width: 4),
          borderRadius: BorderRadius.zero,
        ),
        title: Text('SIGN OUT?', style: NeoTextStyles.h3),
        content: Text(
          'You will be redirected to the login screen.',
          style: NeoTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('CANCEL', style: NeoTextStyles.button),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoColors.accent,
              foregroundColor: NeoColors.white,
              side: const BorderSide(color: NeoColors.ink, width: 3),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('YES, SIGN OUT'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await AuthService.instance.signOut();
    }
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: NeoColors.cream,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: NeoColors.ink, width: 4),
            borderRadius: BorderRadius.zero,
          ),
          title: Text('NOTIFICATIONS', style: NeoTextStyles.h3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text('Push Notifications', style: NeoTextStyles.body),
                value: _pushNotifications,
                activeThumbColor: NeoColors.secondary,
                onChanged: (val) {
                  setDialogState(() => _pushNotifications = val);
                  setState(() {});
                },
              ),
              const Divider(color: NeoColors.ink, thickness: 2),
              SwitchListTile(
                title: Text('Email Notifications', style: NeoTextStyles.body),
                value: _emailNotifications,
                activeThumbColor: NeoColors.secondary,
                onChanged: (val) {
                  setDialogState(() => _emailNotifications = val);
                  setState(() {});
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoColors.secondary,
                foregroundColor: NeoColors.ink,
                side: const BorderSide(color: NeoColors.ink, width: 3),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: NeoColors.cream,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: NeoColors.ink, width: 4),
            borderRadius: BorderRadius.zero,
          ),
          title: Text('PRIVACY & SAFETY', style: NeoTextStyles.h3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text('Private Account', style: NeoTextStyles.body),
                subtitle: const Text('Only friends can view your activity'),
                value: _privateAccount,
                activeThumbColor: NeoColors.secondary,
                onChanged: (val) {
                  setDialogState(() => _privateAccount = val);
                  setState(() {});
                },
              ),
              const Divider(color: NeoColors.ink, thickness: 2),
              SwitchListTile(
                title: Text('Allow Direct Messages', style: NeoTextStyles.body),
                subtitle: const Text('Receive messages from group members'),
                value: _allowDirectMessages,
                activeThumbColor: NeoColors.secondary,
                onChanged: (val) {
                  setDialogState(() => _allowDirectMessages = val);
                  setState(() {});
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoColors.secondary,
                foregroundColor: NeoColors.ink,
                side: const BorderSide(color: NeoColors.ink, width: 3),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoColors.cream,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: NeoColors.ink, width: 4),
          borderRadius: BorderRadius.zero,
        ),
        title: Text('HELP & SUPPORT', style: NeoTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need assistance or facing issues?', style: NeoTextStyles.body),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: NeoColors.white,
                border: NeoBorder.thin,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: support@campus.ac.id',
                      style: NeoTextStyles.label.copyWith(fontSize: 10)),
                  const SizedBox(height: 4),
                  Text('App Version: v1.0.0',
                      style: NeoTextStyles.label.copyWith(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoColors.secondary,
              foregroundColor: NeoColors.ink,
              side: const BorderSide(color: NeoColors.ink, width: 3),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: NeoColors.cream,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: NeoColors.cream,
        body: Center(
          child: Text('Failed to load profile: $error', style: NeoTextStyles.body),
        ),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            backgroundColor: NeoColors.cream,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildContent(user);
      },
    );
  }

  Widget _buildContent(AppUser user) {
    final stats = _buildStats();
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/Homepage_Background.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: ColoredBox(color: NeoColors.cream.withValues(alpha: 0.88)),
        ),
        Positioned.fill(child: const GridBackground(alpha: 0.05)),
        SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _PageHeading()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _ProfileCard(user: user, stats: stats),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _MenuSection(
                    title: 'ACCOUNT',
                    items: [
                      _MenuItem(
                        Icons.edit_outlined,
                        'Edit Profile',
                        NeoColors.secondary,
                        () => _openEditProfile(user),
                      ),
                      _MenuItem(
                        Icons.notifications_outlined,
                        'Notifications',
                        NeoColors.muted,
                        () => _showNotificationsDialog(context),
                      ),
                      _MenuItem(
                        Icons.lock_outline,
                        'Privacy & Safety',
                        NeoColors.accent,
                        () => _showPrivacyDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _MenuSection(
                    title: 'SUPPORT',
                    items: [
                      _MenuItem(
                        Icons.help_outline,
                        'Help & Support',
                        NeoColors.muted,
                        () => _showHelpDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _SignOutButton(onTap: () => _confirmSignOut(context)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        color: NeoColors.cream,
        border: Border(bottom: BorderSide(color: NeoColors.ink, width: 4)),
        boxShadow: [BoxShadow(color: NeoColors.ink, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Transform.rotate(
            angle: -0.04,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: NeoColors.muted,
                border: NeoBorder.thin,
              ),
              child: Text(
                'YOU',
                style: NeoTextStyles.label.copyWith(fontSize: 9),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('Profile', style: NeoTextStyles.h2),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.stats});
  final AppUser user;
  final List<_ProfileStat> stats;

  @override
  Widget build(BuildContext context) {
    final initials = user.displayName.trim().isEmpty
        ? '?'
        : user.displayName.trim()[0].toUpperCase();

    const double avatarSize = 72.0;
    const double bandHeight = 80.0;
    const double avatarOverlap = avatarSize / 2;

    return Container(
      decoration: BoxDecoration(
        color: NeoColors.cream,
        border: NeoBorder.thick,
        boxShadow: NeoShadows.l,
      ),
      child: Column(
        children: [
          SizedBox(
            height: bandHeight + avatarOverlap,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: bandHeight,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: NeoColors.secondary,
                      border: Border(
                        bottom: BorderSide(color: NeoColors.ink, width: 4),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: bandHeight - avatarOverlap,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        color: NeoColors.accent,
                        border: NeoBorder.thick,
                        boxShadow: NeoShadows.s,
                      ),
                      alignment: Alignment.center,
                      child: user.avatarUrl.isNotEmpty
                          ? ClipRect(
                        child: Image.network(
                          user.avatarUrl,
                          fit: BoxFit.cover,
                          width: avatarSize,
                          height: avatarSize,
                        ),
                      )
                          : Text(
                        initials,
                        style: NeoTextStyles.h2.copyWith(
                          fontSize: 32,
                          color: NeoColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              children: [
                Text(
                  user.displayName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: NeoTextStyles.h3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: NeoColors.muted,
                    border: NeoBorder.thin,
                  ),
                  child: Text(
                    user.username.isNotEmpty
                        ? '@${user.username}'.toUpperCase()
                        : '@${user.id}'.toUpperCase(),
                    style: NeoTextStyles.label.copyWith(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: NeoColors.ink, width: 4)),
            ),
            child: Row(
              children: stats.map((stat) {
                final isLast = stats.last == stat;
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: stat.accentColor,
                      border: Border(
                        right: isLast
                            ? BorderSide.none
                            : const BorderSide(color: NeoColors.ink, width: 4),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          stat.value,
                          style: NeoTextStyles.h3.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stat.label,
                          style: NeoTextStyles.label.copyWith(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  _MenuItem(this.icon, this.label, this.accentColor, this.onTap);
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});
  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: NeoColors.ink,
              border: NeoBorder.thin,
            ),
            child: Text(
              title,
              style: NeoTextStyles.label.copyWith(
                color: NeoColors.white,
                fontSize: 9,
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: NeoBorder.thick,
            boxShadow: NeoShadows.m,
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _MenuRow(item: items[i]),
                if (i < items.length - 1)
                  const Divider(height: 0, thickness: 4, color: NeoColors.ink),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});
  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return NeoPressable(
      onTap: item.onTap,
      child: (pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: pressed ? NeoColors.secondary : NeoColors.cream,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.accentColor,
                border: NeoBorder.thin,
              ),
              child: Icon(item.icon, size: 18, color: NeoColors.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label.toUpperCase(),
                style: NeoTextStyles.body.copyWith(fontSize: 13),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: NeoColors.ink),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: NeoColors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeoPressable(
      onTap: onTap,
      child: (pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: pressed
            ? Matrix4.translationValues(4.0, 4.0, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: NeoColors.accent,
          border: NeoBorder.thick,
          boxShadow: pressed ? [] : NeoShadows.m,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, size: 20, color: NeoColors.white),
            const SizedBox(width: 10),
            Text(
              'SIGN OUT',
              style: NeoTextStyles.button.copyWith(color: NeoColors.white),
            ),
          ],
        ),
      ),
    );
  }
}