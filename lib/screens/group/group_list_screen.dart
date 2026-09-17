import 'package:flutter/material.dart';

class _GroupItem {
  const _GroupItem({
    required this.name,
    required this.status,
    required this.memberCount,
    required this.isJoined,
  });

  final String name;
  final String status;
  final int memberCount;
  final bool isJoined;
}

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<_GroupItem> _allGroups = const [
    _GroupItem(
      name: 'The Late Night Crew',
      status: '12 online',
      memberCount: 24,
      isJoined: true,
    ),
    _GroupItem(
      name: 'Valorant Grinders',
      status: '8 online',
      memberCount: 15,
      isJoined: true,
    ),
    _GroupItem(
      name: 'Study Bunker',
      status: '5 online',
      memberCount: 31,
      isJoined: false,
    ),
    _GroupItem(
      name: 'Weekend Warriors',
      status: '20 online',
      memberCount: 40,
      isJoined: true,
    ),
    _GroupItem(
      name: 'Deep Work Zone',
      status: '2 online',
      memberCount: 9,
      isJoined: false,
    ),
    _GroupItem(
      name: 'Movie Night Club',
      status: '6 online',
      memberCount: 18,
      isJoined: true,
    ),
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
          .where((group) => group.name.toLowerCase().contains(query))
          .take(4)
          .toList();
    });
  }

  Future<void> _createGroup() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181A2B),
          title: const Text(
            'Create new group',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Group name',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _allGroups.insert(
          0,
          _GroupItem(
            name: result,
            status: '1 online',
            memberCount: 1,
            isJoined: true,
          ),
        );
        _onSearchChanged();
      });
    }
  }

  Future<void> _joinGroup() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181A2B),
          title: const Text(
            'Join group',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter group code',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        final index = _allGroups.indexWhere(
          (group) => group.name.toLowerCase() == result.toLowerCase(),
        );

        if (index >= 0) {
          _allGroups[index] = _GroupItem(
            name: _allGroups[index].name,
            status: _allGroups[index].status,
            memberCount: _allGroups[index].memberCount + 1,
            isJoined: true,
          );
        } else {
          _allGroups.insert(
            0,
            _GroupItem(
              name: 'Joined via $result',
              status: '1 online',
              memberCount: 2,
              isJoined: true,
            ),
          );
        }
        _onSearchChanged();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleGroups = _filteredGroups.take(4).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Groups',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search groups',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _createGroup,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEAB308),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.group_add_rounded),
                      label: const Text('Create group'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _joinGroup,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.meeting_room_rounded),
                      label: const Text('Join group'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Latest Group',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: visibleGroups.isEmpty
                    ? const Center(
                        child: Text(
                          'No groups found',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 15,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: visibleGroups.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final group = visibleGroups[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.circular(18),
                              splashColor: Colors.white.withValues(alpha: 0.08),
                              highlightColor: Colors.white.withValues(alpha: 0.04),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const _MemberBubbleGroup(),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            group.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF4ADE80),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                group.status,
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.7),
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Icon(
                                                Icons.people_outline_rounded,
                                                size: 14,
                                                color: Colors.white.withValues(alpha: 0.5),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${group.memberCount}',
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.5),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberBubbleGroup extends StatelessWidget {
  const _MemberBubbleGroup();

  @override
  Widget build(BuildContext context) {
    final colors = const [
      Color(0xFF6366F1),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
    ];

    final sizes = const [20.0, 18.0, 24.0, 16.0];
    final positions = const [
      Offset(0, 0),
      Offset(18, 10),
      Offset(4, 22),
      Offset(24, 28),
    ];

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        children: List.generate(colors.length, (index) {
          return Positioned(
            left: positions[index].dx,
            top: positions[index].dy,
            child: Container(
              width: sizes[index],
              height: sizes[index],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF0F0F1A),
                  width: 2,
                ),
                color: colors[index],
              ),
            ),
          );
        }),
      ),
    );
  }
}

Color _accentFor(String name) {
  const palette = [
    Color(0xFF6366F1),
    Color(0xFFEC4899),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
  ];

  return palette[name.codeUnits.fold(0, (sum, value) => sum + value) % palette.length];
}

String _initialsFor(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length == 1) {
    return words[0].substring(0, 2).toUpperCase();
  }
  return (words[0][0] + words[1][0]).toUpperCase();
}
