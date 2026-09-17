import 'package:flutter/material.dart';
import '../../widgets/particle_text/particle_text_widget.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

class _GroupData {
  const _GroupData(this.name, this.status, this.memberCount, this.accentColor);
  final String name;
  final String status;
  final int    memberCount;
  final Color  accentColor;
}

const _kPopularGroups = [
  _GroupData('The Late Night Crew',  '12 online', 24, NeoColors.accent),
  _GroupData('Valorant Grinders',    '8 online',  15, NeoColors.secondary),
  _GroupData('Study Bunker',         '5 online',  31, NeoColors.muted),
  _GroupData('Weekend Warriors',     '20 online', 40, NeoColors.accent),
  _GroupData('Chill Vibes Only',     '3 online',  11, NeoColors.secondary),
];

const _kRecommendedGroups = [
  _GroupData('Deep Work Zone',       '2 online',  9,  NeoColors.muted),
  _GroupData('Movie Night Club',     '6 online',  18, NeoColors.accent),
  _GroupData('Morning Runners',      '4 online',  22, NeoColors.secondary),
  _GroupData('Indie Dev Hangout',    '7 online',  13, NeoColors.muted),
  _GroupData('Book Club',            '1 online',  8,  NeoColors.accent),
];

String _initialsFor(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length == 1) return words[0].substring(0, 2).toUpperCase();
  return (words[0][0] + words[1][0]).toUpperCase();
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

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
            child: CustomPaint(
              painter: _GridPatternPainter(),
            ),
          ),

          // ── 4. Scrollable content ─────────────────────────────────────────
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Hero title area ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _HeroHeader(searchController: _searchController),
                ),

                // ── Popular Groups ─────────────────────────────────────────
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
                  child: _GroupRow(groups: _kPopularGroups),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 36)),

                // ── Recommended ────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeading(
                      label: 'FOR YOU',
                      title: 'Recommended',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _GroupRow(groups: _kRecommendedGroups),
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
// Grid pattern painter (graph-paper texture)
// ─────────────────────────────────────────────────────────────────────────────

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NeoColors.ink.withValues(alpha: 0.06)
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
  bool shouldRepaint(_GridPatternPainter old) => false;
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
          // ── Top row: badge + particle title ────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rotated sticker badge
              Transform.rotate(
                angle: -0.06,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color:     NeoColors.accent,
                    border:    NeoBorder.thick,
                    boxShadow: NeoShadows.s,
                  ),
                  child: Text(
                    'LIVE',
                    style: NeoTextStyles.label.copyWith(
                      color:     NeoColors.white,
                      fontSize:  10,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Notification stub
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
              text:           'KOBOTED',
              fontSize:       64,
              fontWeight:     FontWeight.w700,
              color:          NeoColors.ink,
              highlightColor: NeoColors.accent,
              scatter:        160,
              gatherDuration: const Duration(milliseconds: 1600),
              stagger:        const Duration(milliseconds: 380),
              pointerRepel:   40,
              repelRadius:    110,
              idleDrift:      0.6,
              particleSize:   2.2,
              glow:           false,
              trigger:        ParticleTrigger.mount,
            ),
          ),

          // ── Sub-tagline ────────────────────────────────────────────────
          Transform.rotate(
            angle: 0.01,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:     NeoColors.secondary,
                border:    NeoBorder.thick,
                boxShadow: NeoShadows.s,
              ),
              child: Text(
                'YOUR SPATIAL SOCIAL HUB',
                style: NeoTextStyles.label,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Search bar ─────────────────────────────────────────────────
          _NeoSearchBar(controller: searchController),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Neo search bar
// ─────────────────────────────────────────────────────────────────────────────

class _NeoSearchBar extends StatefulWidget {
  const _NeoSearchBar({required this.controller});
  final TextEditingController controller;

  @override
  State<_NeoSearchBar> createState() => _NeoSearchBarState();
}

class _NeoSearchBarState extends State<_NeoSearchBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color:     _focused ? NeoColors.secondary : NeoColors.white,
        border:    NeoBorder.thick,
        boxShadow: _focused ? NeoShadows.m : NeoShadows.s,
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Icon(Icons.search_rounded, color: NeoColors.ink, size: 22),
          ),
          Expanded(
            child: Focus(
              onFocusChange: (f) => setState(() => _focused = f),
              child: TextField(
                controller: widget.controller,
                style: NeoTextStyles.body,
                decoration: const InputDecoration(
                  hintText:        'SEARCH GROUPS OR FRIENDS…',
                  border:          InputBorder.none,
                  enabledBorder:   InputBorder.none,
                  focusedBorder:   InputBorder.none,
                  filled:          false,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section heading with label sticker
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label, required this.title});
  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: -0.04,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:  NeoColors.muted,
              border: NeoBorder.thin,
            ),
            child: Text(label, style: NeoTextStyles.label.copyWith(fontSize: 10)),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: NeoTextStyles.h3),
        const Spacer(),
        _NeoChip(label: 'SEE ALL', onTap: () {}),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontally scrolling group row
// ─────────────────────────────────────────────────────────────────────────────

class _GroupRow extends StatefulWidget {
  const _GroupRow({required this.groups});
  final List<_GroupData> groups;

  @override
  State<_GroupRow> createState() => _GroupRowState();
}

class _GroupRowState extends State<_GroupRow> {
  final _controller = ScrollController();
  bool _atEnd = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final atEnd =
          _controller.offset >= _controller.position.maxScrollExtent - 8;
      if (atEnd != _atEnd) setState(() => _atEnd = atEnd);
    });
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
            controller:      _controller,
            scrollDirection: Axis.horizontal,
            padding:         const EdgeInsets.symmetric(horizontal: 20),
            itemCount:       widget.groups.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _GroupCard(data: widget.groups[i]),
          ),

          if (!_atEnd)
            Positioned(
              right: 0, top: 0, bottom: 0,
              width: 48,
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end:   Alignment.centerRight,
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

// ─────────────────────────────────────────────────────────────────────────────
// Group card — Neo-brutalist style
// ─────────────────────────────────────────────────────────────────────────────

class _GroupCard extends StatefulWidget {
  const _GroupCard({required this.data});
  final _GroupData data;

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFor(widget.data.name);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() { _hovered = false; _pressed = false; }),
      child: GestureDetector(
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) => setState(() => _pressed = false),
        onTapCancel: ()  => setState(() => _pressed = false),
        onTap:       () {},
        child: AnimatedContainer(
          duration:  const Duration(milliseconds: 150),
          width:     152,
          transform: _pressed
              ? Matrix4.translationValues(4.0, 4.0, 0)
              : _hovered
                  ? Matrix4.translationValues(-2.0, -2.0, 0)
                  : Matrix4.identity(),
          decoration: BoxDecoration(
            color:     NeoColors.cream,
            border:    NeoBorder.thick,
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
                // Initials block with accent background
                Container(
                  width:  46,
                  height: 46,
                  decoration: BoxDecoration(
                    color:  widget.data.accentColor,
                    border: NeoBorder.thick,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: NeoTextStyles.h3.copyWith(
                      fontSize:   15,
                      letterSpacing: 0.5,
                      color: NeoColors.ink,
                    ),
                  ),
                ),

                const Spacer(),

                // Name
                Text(
                  widget.data.name.toUpperCase(),
                  maxLines:  2,
                  overflow:  TextOverflow.ellipsis,
                  style: NeoTextStyles.body.copyWith(
                    fontSize: 12,
                    height:   1.25,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 8),

                // Status row
                Row(
                  children: [
                    Container(
                      width:  8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color:  Color(0xFF00D166),
                        shape:  BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: NeoColors.ink, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        widget.data.status.toUpperCase(),
                        style: NeoTextStyles.label.copyWith(
                          fontSize: 9,
                          letterSpacing: 1.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${widget.data.memberCount}',
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

// ─────────────────────────────────────────────────────────────────────────────
// Reusable small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _NeoChip extends StatefulWidget {
  const _NeoChip({required this.label, required this.onTap});
  final String       label;
  final VoidCallback onTap;

  @override
  State<_NeoChip> createState() => _NeoChipState();
}

class _NeoChipState extends State<_NeoChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      onTap:       widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: _pressed
            ? Matrix4.translationValues(3.0, 3.0, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:     NeoColors.secondary,
          border:    NeoBorder.thin,
          boxShadow: _pressed ? [] : NeoShadows.s,
        ),
        child: Text(widget.label, style: NeoTextStyles.label.copyWith(fontSize: 10)),
      ),
    );
  }
}

class _NeoIconButton extends StatefulWidget {
  const _NeoIconButton({required this.icon, required this.onTap});
  final IconData     icon;
  final VoidCallback onTap;

  @override
  State<_NeoIconButton> createState() => _NeoIconButtonState();
}

class _NeoIconButtonState extends State<_NeoIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      onTap:       widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: _pressed
            ? Matrix4.translationValues(3.0, 3.0, 0)
            : Matrix4.identity(),
        width:  44,
        height: 44,
        decoration: BoxDecoration(
          color:     NeoColors.white,
          border:    NeoBorder.thick,
          boxShadow: _pressed ? [] : NeoShadows.s,
        ),
        child: Icon(widget.icon, size: 20, color: NeoColors.ink),
      ),
    );
  }
}
