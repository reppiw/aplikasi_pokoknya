import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';

/// Root scaffold that owns the bottom navigation bar.
/// Screens other than Home and Profile are stubs for now.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    _StubScreen(label: 'Friends',  icon: Icons.people_outline),
    _StubScreen(label: 'Groups',   icon: Icons.group_work_outlined),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,          // content flows under the nav bar
      backgroundColor: const Color(0xFF0F0F1A),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating frosted-glass nav bar
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.home_outlined,       activeIcon: Icons.home_rounded,        label: 'Home'),
    (icon: Icons.people_outline,      activeIcon: Icons.people_rounded,       label: 'Friends'),
    (icon: Icons.group_work_outlined, activeIcon: Icons.group_work_rounded,   label: 'Groups'),
    (icon: Icons.person_outline,      activeIcon: Icons.person_rounded,       label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color:        Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item    = _items[i];
              final active  = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap:        () => onTap(i),
                  borderRadius: BorderRadius.circular(32),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve:    Curves.easeInOut,
                    padding:  const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          active ? item.activeIcon : item.icon,
                          color: active
                              ? const Color(0xFFEAB308)
                              : Colors.white.withValues(alpha: 0.5),
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: active
                                ? const Color(0xFFEAB308)
                                : Colors.white.withValues(alpha: 0.5),
                            fontSize:   10,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stub screen (Friends / Groups / Profile — not yet implemented)
// ─────────────────────────────────────────────────────────────────────────────

class _StubScreen extends StatelessWidget {
  const _StubScreen({required this.label, required this.icon});
  final String  label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white38),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 18),
            ),
            const SizedBox(height: 4),
            const Text(
              'Coming soon',
              style: TextStyle(color: Colors.white24, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}