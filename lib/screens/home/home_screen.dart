import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/string_utils.dart';
import '../../models/group.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/grid_background.dart';
import '../../widgets/particle_text/particle_text_widget.dart';
import '../group/group_menu_screen.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final DatabaseService _db = DatabaseService();

  String get _currentUserId =>
      AuthService.instance.currentUser?.uid ?? 'demo-user-1';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── 1. Background image ───────────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/Homepage_Background.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ── 2. Semi-transparent cream overlay (Neo-brutalism canvas) ──────
          Positioned.fill(
            child: ColoredBox(
              color: NeoColors.cream.withValues(alpha: 0.82),
            ),
          ),

          // ── 3. Grid texture overlay ───────────────────────────────────────
          Positioned.fill(
            child: const GridBackground(alpha: 0.06),
          ),

          // ── 4. Scrollable content ─────────────────────────────────────────
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Hero title area ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _HeroHeader(searchController: _searchController),
                ),

                // ── Popular / Hot Public Groups ────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeading(
                      label: 'POPULAR',
                      title: 'Hot Groups',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: StreamBuilder<List<Group>>(
                    stream: _db.watchPublicGroups(),
                    builder: (context, snapshot) {
                      final groups = snapshot.data ?? [];
                      if (groups.isEmpty) {
                        return const _EmptyGroupRow(
                          message: 'NO PUBLIC GROUPS YET',
                        );
                      }
                      return _GroupRow(groups: groups);
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 36)),

                // ── My Groups / For You ─────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeading(
                      label: 'YOURS',
                      title: 'My Groups',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: StreamBuilder<List<Group>>(
                    stream: _db.watchUserGroups(_currentUserId),
                    builder: (context, snapshot) {
                      final groups = snapshot.data ?? [];
                      if (groups.isEmpty) {
                        return const _EmptyGroupRow(
                          message: 'JOIN OR CREATE A GROUP IN THE GROUPS TAB',
                        );
                      }
                      return _GroupRow(groups: groups);
                    },
                  ),
                ),

                // ── Bottom padding ─────────────────────────────────────────
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero header: particle title + search bar
// ─────────────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.searchController});
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.rotate(
                angle: -0.06,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: NeoColors.accent,
                    border: NeoBorder.thick,
                    boxShadow: NeoShadows.s,
                  ),
                  child: Text(
                    'LIVE',
                    style: NeoTextStyles.label.copyWith(
                      color: NeoColors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _NeoIconButton(
                icon: Icons.notifications_outlined,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Particle text logo ─────────────────────────────────────────
          SizedBox(
            height: 120,
            child: ParticleText(
              text: 'KOBOTED',
              fontSize: 64,
              fontWeight: FontWeight.w700,
              color: NeoColors.ink,
              highlightColor: NeoColors.accent,
              scatter: 160,
              gatherDuration: const Duration(milliseconds: 1600),
              stagger: const Duration(milliseconds: 380),
              pointerRepel: 40,
              repelRadius: 110,
              idleDrift: 0.6,
              particleSize: 2.2,
              glow: false,
              trigger: ParticleTrigger.mount,
            ),
          ),

          const SizedBox(height: 16),

          _SearchBar(controller: searchController),
        ],
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: NeoColors.white,
          border: NeoBorder.thick,
          boxShadow: _focused ? NeoShadows.m : NeoShadows.s,
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.search_rounded, color: NeoColors.ink, size: 22),
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                style: NeoTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Search groups, rooms, members…',
                  hintStyle: NeoTextStyles.body.copyWith(
                    color: NeoColors.ink.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: NeoColors.ink),
                  onPressed: widget.controller.clear,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label, required this.title});
  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: NeoColors.secondary,
            border: NeoBorder.thick,
            boxShadow: NeoShadows.s,
          ),
          child: Text(
            label,
            style: NeoTextStyles.label.copyWith(fontSize: 10),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: NeoTextStyles.h3),
      ],
    );
  }
}

class _GroupRow extends StatefulWidget {
  const _GroupRow({required this.groups});
  final List<Group> groups;

  @override
  State<_GroupRow> createState() => _GroupRowState();
}

class _GroupRowState extends State<_GroupRow> {
  late final ScrollController _controller;
  bool _atEnd = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    final atEnd = _controller.position.pixels >=
        _controller.position.maxScrollExtent - 24;
    if (atEnd != _atEnd) setState(() => _atEnd = atEnd);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Stack(
        children: [
          ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.groups.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _GroupCard(group: widget.groups[i]),
          ),
          if (!_atEnd)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 48,
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.transparent, NeoColors.cream],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyGroupRow extends StatelessWidget {
  const _EmptyGroupRow({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeoColors.white,
        border: NeoBorder.thick,
        boxShadow: NeoShadows.s,
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: NeoColors.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: NeoTextStyles.label.copyWith(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatefulWidget {
  const _GroupCard({required this.group});
  final Group group;

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final initials = initialsFor(widget.group.name);
    final accentColor = _colorFor(widget.group.name);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupMenuScreen(
                groupId: widget.group.id,
                initialGroup: widget.group,
              ),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 152,
          transform: _pressed
              ? Matrix4.translationValues(4.0, 4.0, 0)
              : _hovered
                  ? Matrix4.translationValues(-2.0, -2.0, 0)
                  : Matrix4.identity(),
          decoration: BoxDecoration(
            color: NeoColors.cream,
            border: NeoBorder.thick,
            boxShadow: _pressed
                ? []
                : _hovered
                    ? NeoShadows.l
                    : NeoShadows.m,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accentColor,
                    border: NeoBorder.thick,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: NeoTextStyles.h3.copyWith(
                      fontSize: 15,
                      letterSpacing: 0.5,
                      color: NeoColors.ink,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  widget.group.name.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: NeoTextStyles.body.copyWith(
                    fontSize: 12,
                    height: 1.25,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00D166),
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: NeoColors.ink, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '#${widget.group.joinCode}',
                        style: NeoTextStyles.label.copyWith(
                          fontSize: 9,
                          letterSpacing: 1.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${widget.group.memberIds.length}',
                      style: NeoTextStyles.label.copyWith(fontSize: 9),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.people_outline_rounded, size: 11, color: NeoColors.ink),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NeoIconButton extends StatefulWidget {
  const _NeoIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_NeoIconButton> createState() => _NeoIconButtonState();
}

class _NeoIconButtonState extends State<_NeoIconButton> {
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
        width: 44,
        height: 44,
        transform: _pressed
            ? Matrix4.translationValues(3.0, 3.0, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: NeoColors.white,
          border: NeoBorder.thick,
          boxShadow: _pressed ? [] : NeoShadows.s,
        ),
        child: Icon(widget.icon, color: NeoColors.ink, size: 22),
      ),
    );
  }
}
