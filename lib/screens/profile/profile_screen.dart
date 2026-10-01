import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user.dart';
import 'edit_profile_screen.dart';

const _kCurrentUser = AppUser(
  id: 'demo-user-1',
  displayName: 'aku nak makan',
  avatarUrl: '',
);

class _ProfileStat {
  const _ProfileStat(this.label, this.value, this.accentColor);
  final String label, value;
  final Color accentColor;
}

const _kStats = [
  _ProfileStat('GROUPS', '4', NeoColors.accent),
  _ProfileStat('FRIENDS', '23', NeoColors.secondary),
  _ProfileStat('STATUS', 'ON', NeoColors.muted),
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.user = _kCurrentUser,
    required this.onSignOut,
  });

  final AppUser user;
  final VoidCallback onSignOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // State Pengaturan Profil
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _privateAccount = false;
  bool _allowDirectMessages = true;

  // Dialog Konfirmasi Sign Out
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

    if (shouldSignOut == true) widget.onSignOut();
  }

  // ── Dialog Notifications ──────────────────────────────────────────────────
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

  // ── Dialog Privacy & Safety ───────────────────────────────────────────────
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

  // ── Dialog Help & Support ────────────────────────────────────────────────
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
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),
        SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _PageHeading()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver:
                SliverToBoxAdapter(child: _ProfileCard(user: widget.user)),
              ),

              // ── Menu: Account ─────────────────────────────────────────
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
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProfileScreen(user: widget.user),
                            ),
                          );
                        },
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

              // ── Menu: Support ─────────────────────────────────────────
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

              // ── Sign out ──────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Page heading
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Profile card
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});
  final AppUser user;

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
                    '@${user.id}'.toUpperCase(),
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
              children: _kStats.map((stat) {
                final isLast = _kStats.last == stat;
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

// ─────────────────────────────────────────────────────────────────────────────
// Menu section
// ─────────────────────────────────────────────────────────────────────────────

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

class _MenuRow extends StatefulWidget {
  const _MenuRow({required this.item});
  final _MenuItem item;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _pressed ? NeoColors.secondary : NeoColors.cream,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.item.accentColor,
                border: NeoBorder.thin,
              ),
              child: Icon(widget.item.icon, size: 18, color: NeoColors.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.item.label.toUpperCase(),
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

// ─────────────────────────────────────────────────────────────────────────────
// Sign out button
// ─────────────────────────────────────────────────────────────────────────────

class _SignOutButton extends StatefulWidget {
  const _SignOutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: _pressed
            ? Matrix4.translationValues(4.0, 4.0, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: NeoColors.accent,
          border: NeoBorder.thick,
          boxShadow: _pressed ? [] : NeoShadows.m,
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

// ─────────────────────────────────────────────────────────────────────────────
// Grid texture painter
// ─────────────────────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NeoColors.ink.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}