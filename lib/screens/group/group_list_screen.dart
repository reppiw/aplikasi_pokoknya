import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class _GroupItem {
  const _GroupItem({
    required this.name,
    required this.status,
    required this.memberCount,
    required this.isJoined,
    required this.accentColor,
  });

  final String name;
  final String status;
  final int    memberCount;
  final bool   isJoined;
  final Color  accentColor;
}

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

String _initialsFor(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length == 1) return words[0].substring(0, 2).toUpperCase();
  return (words[0][0] + words[1][0]).toUpperCase();
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<_GroupItem> _allGroups = [
    const _GroupItem(
      name: 'The Late Night Crew',  status: '12 online', memberCount: 24, isJoined: true,  accentColor: NeoColors.accent),
    const _GroupItem(
      name: 'Valorant Grinders',    status: '8 online',  memberCount: 15, isJoined: true,  accentColor: NeoColors.secondary),
    const _GroupItem(
      name: 'Study Bunker',         status: '5 online',  memberCount: 31, isJoined: false, accentColor: NeoColors.muted),
    const _GroupItem(
      name: 'Weekend Warriors',     status: '20 online', memberCount: 40, isJoined: true,  accentColor: NeoColors.accent),
    const _GroupItem(
      name: 'Deep Work Zone',       status: '2 online',  memberCount: 9,  isJoined: false, accentColor: NeoColors.muted),
    const _GroupItem(
      name: 'Movie Night Club',     status: '6 online',  memberCount: 18, isJoined: true,  accentColor: NeoColors.secondary),
  ];

  late List<_GroupItem> _filteredGroups;

  @override
  void initState() {
    super.initState();
    _filteredGroups = _allGroups;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredGroups = _allGroups
          .where((g) => g.name.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _createGroup() async {
    final controller = TextEditingController();
    final result = await _showNeoDialog(
      context:   context,
      title:     'CREATE GROUP',
      hint:      'Group name…',
      action:    'CREATE',
      controller: controller,
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _allGroups.insert(
          0,
          _GroupItem(
            name:        result,
            status:      '1 online',
            memberCount: 1,
            isJoined:    true,
            accentColor: _colorFor(result),
          ),
        );
        _onSearchChanged();
      });
    }
  }

  Future<void> _joinGroup() async {
    final controller = TextEditingController();
    final result = await _showNeoDialog(
      context:   context,
      title:     'JOIN GROUP',
      hint:      'Enter group code…',
      action:    'JOIN',
      controller: controller,
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        final idx = _allGroups.indexWhere(
          (g) => g.name.toLowerCase() == result.toLowerCase(),
        );
        if (idx >= 0) {
          final g = _allGroups[idx];
          _allGroups[idx] = _GroupItem(
            name:        g.name,
            status:      g.status,
            memberCount: g.memberCount + 1,
            isJoined:    true,
            accentColor: g.accentColor,
          );
        } else {
          _allGroups.insert(
            0,
            _GroupItem(
              name:        'Joined via $result',
              status:      '1 online',
              memberCount: 2,
              isJoined:    true,
              accentColor: _colorFor(result),
            ),
          );
        }
        _onSearchChanged();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset('assets/Homepage_Background.jpg', fit: BoxFit.cover),
        ),
        // Cream overlay
        Positioned.fill(
          child: ColoredBox(color: NeoColors.cream.withValues(alpha: 0.88)),
        ),
        // Grid texture
        Positioned.fill(
          child: CustomPaint(painter: _GridPainter()),
        ),

        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              _GroupsHeader(
                searchController: _searchController,
                onCreateGroup:    _createGroup,
                onJoinGroup:      _joinGroup,
              ),

              // ── Section label ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color:  NeoColors.secondary,
                        border: NeoBorder.thick,
                        boxShadow: NeoShadows.s,
                      ),
                      child: Text(
                        'LATEST',
                        style: NeoTextStyles.label.copyWith(fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Groups', style: NeoTextStyles.h3),
                  ],
                ),
              ),

              // ── Group list ───────────────────────────────────────────────
              Expanded(
                child: _filteredGroups.isEmpty
                    ? _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        itemCount: _filteredGroups.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _GroupListTile(group: _filteredGroups[index]),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header section
// ─────────────────────────────────────────────────────────────────────────────

class _GroupsHeader extends StatefulWidget {
  const _GroupsHeader({
    required this.searchController,
    required this.onCreateGroup,
    required this.onJoinGroup,
  });

  final TextEditingController searchController;
  final VoidCallback          onCreateGroup;
  final VoidCallback          onJoinGroup;

  @override
  State<_GroupsHeader> createState() => _GroupsHeaderState();
}

class _GroupsHeaderState extends State<_GroupsHeader> {
  bool _searchFocused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        color:  NeoColors.cream,
        border: Border(bottom: BorderSide(color: NeoColors.ink, width: 4)),
        boxShadow: [BoxShadow(color: NeoColors.ink, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Transform.rotate(
                angle: -0.04,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:  NeoColors.muted,
                    border: NeoBorder.thin,
                  ),
                  child: Text('SOCIAL', style: NeoTextStyles.label.copyWith(fontSize: 9)),
                ),
              ),
              const SizedBox(width: 10),
              Text('Groups', style: NeoTextStyles.h2),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color:     _searchFocused ? NeoColors.secondary : NeoColors.white,
              border:    NeoBorder.thick,
              boxShadow: _searchFocused ? NeoShadows.m : NeoShadows.s,
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.search_rounded, color: NeoColors.ink, size: 22),
                ),
                Expanded(
                  child: Focus(
                    onFocusChange: (f) => setState(() => _searchFocused = f),
                    child: TextField(
                      controller: widget.searchController,
                      style:      NeoTextStyles.body,
                      decoration: const InputDecoration(
                        hintText:       'SEARCH GROUPS…',
                        border:         InputBorder.none,
                        enabledBorder:  InputBorder.none,
                        focusedBorder:  InputBorder.none,
                        filled:         false,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _NeoButton(
                  label:   'CREATE GROUP',
                  color:   NeoColors.secondary,
                  icon:    Icons.group_add_rounded,
                  onTap:   widget.onCreateGroup,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NeoButton(
                  label:   'JOIN GROUP',
                  color:   NeoColors.muted,
                  icon:    Icons.meeting_room_rounded,
                  onTap:   widget.onJoinGroup,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Group list tile
// ─────────────────────────────────────────────────────────────────────────────

class _GroupListTile extends StatefulWidget {
  const _GroupListTile({required this.group});
  final _GroupItem group;

  @override
  State<_GroupListTile> createState() => _GroupListTileState();
}

class _GroupListTileState extends State<_GroupListTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFor(widget.group.name);

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      onTap:       () {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: _pressed
            ? Matrix4.translationValues(4.0, 4.0, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:     NeoColors.cream,
          border:    NeoBorder.thick,
          boxShadow: _pressed ? [] : NeoShadows.m,
        ),
        child: Row(
          children: [
            // Initials avatar
            Container(
              width:  52,
              height: 52,
              decoration: BoxDecoration(
                color:  widget.group.accentColor,
                border: NeoBorder.thick,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: NeoTextStyles.h3.copyWith(fontSize: 16),
              ),
            ),

            const SizedBox(width: 14),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.group.name.toUpperCase(),
                          style: NeoTextStyles.body.copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.group.isJoined)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:  NeoColors.secondary,
                            border: NeoBorder.thin,
                          ),
                          child: Text(
                            'JOINED',
                            style: NeoTextStyles.label.copyWith(fontSize: 9),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width:  8, height: 8,
                        decoration: const BoxDecoration(
                          color:  Color(0xFF00D166),
                          shape:  BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: NeoColors.ink, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.group.status.toUpperCase(),
                        style: NeoTextStyles.label.copyWith(fontSize: 9),
                      ),
                      const SizedBox(width: 14),
                      const Icon(Icons.people_outline_rounded, size: 12, color: NeoColors.ink),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.group.memberCount} MEMBERS',
                        style: NeoTextStyles.label.copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            Container(
              width:  32,
              height: 32,
              decoration: const BoxDecoration(
                color:  NeoColors.ink,
                border: NeoBorder.thin,
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: NeoColors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Neo button
// ─────────────────────────────────────────────────────────────────────────────

class _NeoButton extends StatefulWidget {
  const _NeoButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String       label;
  final Color        color;
  final IconData     icon;
  final VoidCallback onTap;

  @override
  State<_NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<_NeoButton> {
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
            ? Matrix4.translationValues(4.0, 4.0, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:     widget.color,
          border:    NeoBorder.thick,
          boxShadow: _pressed ? [] : NeoShadows.m,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 18, color: NeoColors.ink),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: NeoTextStyles.button.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin:  const EdgeInsets.all(40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color:     NeoColors.cream,
          border:    NeoBorder.thick,
          boxShadow: NeoShadows.m,
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
              child: const Icon(Icons.search_off_rounded, size: 32, color: NeoColors.ink),
            ),
            const SizedBox(height: 16),
            Text('NO GROUPS FOUND', style: NeoTextStyles.h3.copyWith(fontSize: 18)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Neo dialog helper
// ─────────────────────────────────────────────────────────────────────────────

Future<String?> _showNeoDialog({
  required BuildContext       context,
  required String             title,
  required String             hint,
  required String             action,
  required TextEditingController controller,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color:     NeoColors.cream,
            border:    NeoBorder.thick,
            boxShadow: NeoShadows.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: NeoTextStyles.h3),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color:  NeoColors.white,
                  border: NeoBorder.thick,
                ),
                child: TextField(
                  controller: controller,
                  style:      NeoTextStyles.body,
                  autofocus:  true,
                  decoration: InputDecoration(
                    hintText:       hint,
                    border:         InputBorder.none,
                    enabledBorder:  InputBorder.none,
                    focusedBorder:  InputBorder.none,
                    filled:         false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _NeoButton(
                      label: 'CANCEL',
                      color: NeoColors.white,
                      icon:  Icons.close_rounded,
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NeoButton(
                      label: action,
                      color: NeoColors.accent,
                      icon:  Icons.check_rounded,
                      onTap: () {
                        final val = controller.text.trim();
                        if (val.isNotEmpty) Navigator.pop(ctx, val);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
