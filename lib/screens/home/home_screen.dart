import 'package:flutter/material.dart';
import '../../widgets/particle_text/particle_text_widget.dart';

/// Dummy data for the "popular groups" cards.
const _kGroups = [
  _GroupData('The Late Night Crew',   '12 online', '🌙'),
  _GroupData('Valorant Grinders',     '8 online',  '🎮'),
  _GroupData('Study Bunker',          '5 online',  '📚'),
  _GroupData('Weekend Warriors',      '20 online', '⚔️'),
  _GroupData('Chill Vibes Only',      '3 online',  '🎵'),
];

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

          // ── 2. Dark scrim so content is always readable ───────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // ── 3. Scrollable page content ────────────────────────────────────
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── App title (ParticleText) ───────────────────────────────
                SliverToBoxAdapter(
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

                // ── Search bar ────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  sliver: SliverToBoxAdapter(
                    child: _SearchBar(controller: _searchController),
                  ),
                ),

                // ── "Popular Groups" heading ──────────────────────────────
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Popular Groups',
                      style: TextStyle(
                        color:       Colors.white,
                        fontSize:    20,
                        fontWeight:  FontWeight.w700,
                        shadows: [
                          Shadow(blurRadius: 8, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Group cards (horizontal scroll) ───────────────────────
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection:  Axis.horizontal,
                      padding:          const EdgeInsets.symmetric(horizontal: 20),
                      itemCount:        _kGroups.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, i) =>
                          _GroupCard(data: _kGroups[i]),
                    ),
                  ),
                ),

                // ── Bottom padding so the nav bar doesn't cover content ───
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color:        Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText:      'Search groups or friends…',
          hintStyle:     TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          prefixIcon:    Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
          border:        InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Group Card
// ─────────────────────────────────────────────────────────────────────────────

class _GroupData {
  const _GroupData(this.name, this.status, this.emoji);
  final String name, status, emoji;
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.data});
  final _GroupData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:  MainAxisAlignment.spaceBetween,
          children: [
            Text(data.emoji, style: const TextStyle(fontSize: 32)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  maxLines:  2,
                  overflow:  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data.status,
                      style: TextStyle(
                        color:    Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
