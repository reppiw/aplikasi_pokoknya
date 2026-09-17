import 'package:flutter/material.dart';
import '../../widgets/particle_text/particle_text_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

class _GroupData {
  const _GroupData(this.name, this.status, this.memberCount);
  final String name;
  final String status;
  final int    memberCount;
}

const _kPopularGroups = [
  _GroupData('The Late Night Crew',  '12 online', 24),
  _GroupData('Valorant Grinders',    '8 online',  15),
  _GroupData('Study Bunker',         '5 online',  31),
  _GroupData('Weekend Warriors',     '20 online', 40),
  _GroupData('Chill Vibes Only',     '3 online',  11),
];

const _kRecommendedGroups = [
  _GroupData('Deep Work Zone',       '2 online',  9),
  _GroupData('Movie Night Club',     '6 online',  18),
  _GroupData('Morning Runners',      '4 online',  22),
  _GroupData('Indie Dev Hangout',    '7 online',  13),
  _GroupData('Book Club',            '1 online',  8),
];

// Palette used to assign accent colors deterministically from the group name.
const _kAccentPalette = [
  Color(0xFF6366F1), // indigo
  Color(0xFFEC4899), // pink
  Color(0xFF10B981), // emerald
  Color(0xFFF59E0B), // amber
  Color(0xFF3B82F6), // blue
  Color(0xFFEF4444), // red
  Color(0xFF8B5CF6), // violet
  Color(0xFF14B8A6), // teal
];

Color _accentFor(String name) =>
    _kAccentPalette[name.codeUnits.fold(0, (a, b) => a + b) %
        _kAccentPalette.length];

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

          // ── 2. Dark scrim ─────────────────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.62),
                    Colors.black.withValues(alpha: 0.38),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // ── 3. Scrollable content ─────────────────────────────────────────
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Title ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      height: 200,
                      child: ParticleText(
                        text:           'Koboted',
                        fontSize:       72,
                        fontWeight:     FontWeight.w800,
                        color:          Colors.white,
                        highlightColor: const Color(0xFFEAB308),
                        scatter:        140,
                        gatherDuration: const Duration(milliseconds: 1800),
                        stagger:        const Duration(milliseconds: 400),
                        pointerRepel:   35,
                        repelRadius:    100,
                        idleDrift:      0.5,
                        particleSize:   2.0,
                        glow:           true,
                        trigger:        ParticleTrigger.mount,
                      ),
                    ),
                  ),
                ),

                // ── Search bar ────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverToBoxAdapter(
                    child: _SearchBar(controller: _searchController),
                  ),
                ),

                // ── Popular Groups ────────────────────────────────────────
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeading('Popular Groups'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _GroupRow(groups: _kPopularGroups),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 28)),

                // ── Recommended Groups ────────────────────────────────────
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeading('Recommended For You'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _GroupRow(groups: _kRecommendedGroups),
                ),

                // ── Bottom padding for nav bar ────────────────────────────
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section heading
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color:      Colors.white,
        fontSize:   18,
        fontWeight: FontWeight.w700,
        shadows: [Shadow(blurRadius: 8, color: Colors.black87)],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontally scrolling group row with fade-out scroll hint
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
      final atEnd = _controller.offset >=
          _controller.position.maxScrollExtent - 8;
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
      height: 180,
      child: Stack(
        children: [
          // Card list
          ListView.separated(
            controller:      _controller,
            scrollDirection: Axis.horizontal,
            padding:         const EdgeInsets.symmetric(horizontal: 20),
            itemCount:       widget.groups.length,
            separatorBuilder: (_, index) => const SizedBox(width: 12),
            itemBuilder: (context, i) =>
                _GroupCard(data: widget.groups[i]),
          ),

          // Right-edge fade + chevron scroll hint
          if (!_atEnd)
            Positioned(
              right: 0, top: 0, bottom: 0,
              width: 56,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Gradient fade
                    ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        begin: Alignment.centerLeft,
                        end:   Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: Container(
                        width: 56,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Chevron icon
          if (!_atEnd)
            Positioned(
              right: 6,
              top:   0,
              bottom: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color:        Colors.white.withValues(alpha: 0.15),
                      shape:        BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size:  18,
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
// Group card
// ─────────────────────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.data});
  final _GroupData data;

  @override
  Widget build(BuildContext context) {
    final accent   = _accentFor(data.name);
    final initials = _initialsFor(data.name);

    return Container(
      width: 148,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color:        Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Initials avatar ──────────────────────────────────────────
            Container(
              width:  46,
              height: 46,
              decoration: BoxDecoration(
                color:        accent.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accent.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  color:      accent,
                  fontSize:   16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const Spacer(),

            // ── Name ─────────────────────────────────────────────────────
            Text(
              data.name,
              maxLines:  2,
              overflow:  TextOverflow.ellipsis,
              style: const TextStyle(
                color:      Colors.white,
                fontSize:   13,
                fontWeight: FontWeight.w600,
                height:     1.3,
              ),
            ),

            const SizedBox(height: 6),

            // ── Status row ───────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  data.status,
                  style: TextStyle(
                    color:    Colors.white.withValues(alpha: 0.65),
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.people_outline_rounded,
                  size:  12,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 3),
                Text(
                  '${data.memberCount}',
                  style: TextStyle(
                    color:    Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color:        Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText:  'Search groups or friends…',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          border:         InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
