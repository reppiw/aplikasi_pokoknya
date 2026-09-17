import 'package:flutter/material.dart';
import 'group/group_list_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import '../core/theme/app_theme.dart';

/// Root scaffold with Neo-Brutalist bottom navigation bar.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    _StubScreen(label: 'FRIENDS',  icon: Icons.people_outline),
    GroupListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: NeoColors.cream,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _NeoNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Neo-Brutalist Bottom Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────

class _NeoNavBar extends StatelessWidget {
  const _NeoNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.home_outlined,       label: 'HOME'),
    (icon: Icons.people_outline,      label: 'FRIENDS'),
    (icon: Icons.group_work_outlined, label: 'GROUPS'),
    (icon: Icons.person_outline,      label: 'PROFILE'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 12),
      decoration: BoxDecoration(
        color:  NeoColors.cream,
        border: NeoBorder.thick,
        boxShadow: NeoShadows.l,
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final item   = _items[i];
          final active = i == currentIndex;
          return Expanded(
            child: _NavItem(
              icon:    item.icon,
              label:   item.label,
              active:  active,
              onTap:   () => onTap(i),
              isLast:  i == _items.length - 1,
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.isLast,
  });

  final IconData icon;
  final String   label;
  final bool     active;
  final bool     isLast;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.active ? NeoColors.secondary : NeoColors.cream;

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      onTap:       widget.onTap,
      child: AnimatedContainer(
        duration:  const Duration(milliseconds: 100),
        transform: _pressed
            ? Matrix4.translationValues(2.0, 2.0, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            right: widget.isLast
                ? BorderSide.none
                : const BorderSide(color: NeoColors.ink, width: 4),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              color: NeoColors.ink,
              size:  22,
            ),
            const SizedBox(height: 3),
            Text(
              widget.label,
              style: NeoTextStyles.label.copyWith(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stub screen
// ─────────────────────────────────────────────────────────────────────────────

class _StubScreen extends StatelessWidget {
  const _StubScreen({required this.label, required this.icon});
  final String   label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset(
            'assets/Homepage_Background.jpg',
            fit: BoxFit.cover,
          ),
        ),
        // Cream overlay
        Positioned.fill(
          child: ColoredBox(color: NeoColors.cream.withValues(alpha: 0.82)),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color:     NeoColors.cream,
              border:    NeoBorder.thick,
              boxShadow: NeoShadows.l,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:  NeoColors.muted,
                    border: NeoBorder.thick,
                  ),
                  child: Icon(icon, size: 40, color: NeoColors.ink),
                ),
                const SizedBox(height: 20),
                Text(label, style: NeoTextStyles.h2),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:  NeoColors.secondary,
                    border: NeoBorder.thin,
                  ),
                  child: Text(
                    'COMING SOON',
                    style: NeoTextStyles.label,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
