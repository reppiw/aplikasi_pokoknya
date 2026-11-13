import 'package:flutter/material.dart';

import 'group/group_list_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'friends/friends_screen.dart';
import '../core/theme/app_theme.dart';
import '../widgets/neo_pressable.dart';

/// Root scaffold with Neo-Brutalist bottom navigation bar.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const HomeScreen(),
      const FriendsScreen(),
      const GroupListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: NeoColors.cream,
      body: IndexedStack(index: _currentIndex, children: screens),
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
  const _NeoNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.home_outlined, label: 'HOME'),
    (icon: Icons.people_outline, label: 'FRIENDS'),
    (icon: Icons.group_work_outlined, label: 'GROUPS'),
    (icon: Icons.person_outline, label: 'PROFILE'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 12),
      decoration: BoxDecoration(
        color: NeoColors.cream,
        border: NeoBorder.thick,
        boxShadow: NeoShadows.l,
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final active = i == currentIndex;
          return Expanded(
            child: _NavItem(
              icon: item.icon,
              label: item.label,
              active: active,
              onTap: () => onTap(i),
              isLast: i == _items.length - 1,
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.isLast,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active ? NeoColors.secondary : NeoColors.cream;

    return NeoPressable(
      pressOffset: const Offset(2, 2),
      onTap: onTap,
      child: (pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: pressed
            ? Matrix4.translationValues(2.0, 2.0, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            right: isLast
                ? BorderSide.none
                : const BorderSide(color: NeoColors.ink, width: 4),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: NeoColors.ink, size: 22),
            const SizedBox(height: 3),
            Text(label, style: NeoTextStyles.label.copyWith(fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// (Shell no longer uses the stub screen — kept as a utility for future tabs)
// ─────────────────────────────────────────────────────────────────────────────
