import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../models/furniture.dart';
import '../../models/room.dart';
import '../../services/database_service.dart';
import '../../widgets/neo_pressable.dart';

/// Room Editor — group admins can add, rename, resize, recolour, and furnish
/// rooms, then save the layout to Firestore for the virtual office.
class RoomEditorScreen extends StatefulWidget {
  const RoomEditorScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<RoomEditorScreen> createState() => _RoomEditorScreenState();
}

class _RoomEditorScreenState extends State<RoomEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  List<Room> _rooms = [];
  bool _loading = true;
  bool _saving = false;

  // Currently selected room for the furniture panel.
  String? _selectedRoomId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRooms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    try {
      final fetched = await _db.fetchGroupRooms(widget.groupId);
      setState(() {
        _rooms = fetched.isNotEmpty ? fetched : defaultRooms();
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _rooms = defaultRooms();
        _loading = false;
      });
    }
  }

  Future<void> _saveRooms() async {
    setState(() => _saving = true);
    try {
      await _db.saveGroupRooms(widget.groupId, _rooms);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Layout tersimpan!', style: NeoTextStyles.label),
            backgroundColor: NeoColors.ink,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e', style: NeoTextStyles.label),
            backgroundColor: NeoColors.accent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Room CRUD ──────────────────────────────────────────────────────────────

  void _addRoom() {
    final id = _uuid.v4();
    // Place new room to the right of the last room, or at a default position.
    double nextX = 1;
    double nextY = 1;
    if (_rooms.isNotEmpty) {
      final last = _rooms.last;
      nextX = last.tileX + last.widthTiles + 1;
      nextY = last.tileY;
      // Wrap to next row if we'd go off-map
      if (nextX + 14 > 31) {
        nextX = 1;
        nextY = last.tileY + last.heightTiles + 1;
      }
    }
    setState(() {
      _rooms.add(Room(
        id: id,
        name: 'Room Baru',
        statusTag: RoomStatusTag.custom,
        tileX: nextX,
        tileY: nextY,
        widthTiles: 12,
        heightTiles: 16,
        colorHex: 0xFFEBDDD1,
      ));
      _selectedRoomId = id;
    });
  }

  void _deleteRoom(String roomId) {
    setState(() {
      _rooms.removeWhere((r) => r.id == roomId);
      if (_selectedRoomId == roomId) _selectedRoomId = null;
    });
  }

  void _updateRoom(Room updated) {
    setState(() {
      final idx = _rooms.indexWhere((r) => r.id == updated.id);
      if (idx >= 0) _rooms[idx] = updated;
    });
  }

  // ── Furniture ──────────────────────────────────────────────────────────────

  void _addFurnitureToRoom(String roomId, FurnitureType type) {
    final roomIdx = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIdx < 0) return;

    final room = _rooms[roomIdx];
    final item = FurnitureItem(
      id: _uuid.v4(),
      type: type,
      tileX: 1,
      tileY: 1,
    );

    setState(() {
      _rooms[roomIdx] = room.copyWith(
        furnitureItems: [...room.furnitureItems, item],
      );
    });
  }

  void _removeFurnitureFromRoom(String roomId, String itemId) {
    final roomIdx = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIdx < 0) return;

    final room = _rooms[roomIdx];
    setState(() {
      _rooms[roomIdx] = room.copyWith(
        furnitureItems: room.furnitureItems.where((f) => f.id != itemId).toList(),
      );
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.cream,
      appBar: AppBar(
        backgroundColor: NeoColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: NeoColors.ink, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('EDIT ROOMS', style: NeoTextStyles.h3),
        centerTitle: true,
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: NeoColors.ink,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save_outlined, color: NeoColors.ink, size: 26),
                  tooltip: 'Simpan Layout',
                  onPressed: _saveRooms,
                ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48 + 4),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelStyle: NeoTextStyles.label,
                labelColor: NeoColors.ink,
                indicatorColor: NeoColors.accent,
                indicatorWeight: 4,
                tabs: const [
                  Tab(text: 'ROOMS'),
                  Tab(text: 'FURNITURE'),
                ],
              ),
              Container(height: 4, color: NeoColors.ink),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: NeoColors.ink))
          : TabBarView(
              controller: _tabController,
              children: [
                _RoomsTab(
                  rooms: _rooms,
                  selectedRoomId: _selectedRoomId,
                  onSelectRoom: (id) => setState(() => _selectedRoomId = id),
                  onAddRoom: _addRoom,
                  onDeleteRoom: _deleteRoom,
                  onUpdateRoom: _updateRoom,
                ),
                _FurnitureTab(
                  rooms: _rooms,
                  selectedRoomId: _selectedRoomId,
                  onSelectRoom: (id) {
                    setState(() => _selectedRoomId = id);
                    _tabController.animateTo(1);
                  },
                  onAddFurniture: _addFurnitureToRoom,
                  onRemoveFurniture: _removeFurnitureFromRoom,
                ),
              ],
            ),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              backgroundColor: NeoColors.secondary,
              foregroundColor: NeoColors.ink,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: NeoColors.ink, width: 3),
              ),
              onPressed: _addRoom,
              icon: const Icon(Icons.add),
              label: Text('TAMBAH ROOM', style: NeoTextStyles.label),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rooms Tab
// ─────────────────────────────────────────────────────────────────────────────

class _RoomsTab extends StatelessWidget {
  const _RoomsTab({
    required this.rooms,
    required this.selectedRoomId,
    required this.onSelectRoom,
    required this.onAddRoom,
    required this.onDeleteRoom,
    required this.onUpdateRoom,
  });

  final List<Room> rooms;
  final String? selectedRoomId;
  final void Function(String id) onSelectRoom;
  final VoidCallback onAddRoom;
  final void Function(String id) onDeleteRoom;
  final void Function(Room updated) onUpdateRoom;

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dashboard_customize_outlined, size: 64, color: NeoColors.muted),
            const SizedBox(height: 16),
            Text('Belum ada room.', style: NeoTextStyles.body),
            const SizedBox(height: 8),
            Text('Tekan tombol + untuk menambahkan.', style: NeoTextStyles.label),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: rooms.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final room = rooms[index];
        final isSelected = room.id == selectedRoomId;
        return _RoomCard(
          room: room,
          isSelected: isSelected,
          onTap: () => onSelectRoom(room.id),
          onDelete: () => onDeleteRoom(room.id),
          onUpdate: onUpdateRoom,
        );
      },
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onUpdate,
  });

  final Room room;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(Room) onUpdate;

  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: room.name);
    RoomStatusTag selectedTag = room.statusTag;
    int colorHex = room.colorHex;

    final colorOptions = [
      (hex: 0xFFF2DFC5, label: 'Cream'),
      (hex: 0xFFEADCCB, label: 'Sand'),
      (hex: 0xFFE8D9C2, label: 'Linen'),
      (hex: 0xFFE3E2CF, label: 'Sage'),
      (hex: 0xFFCFE2CF, label: 'Mint'),
      (hex: 0xFFCFCFE6, label: 'Lavender'),
      (hex: 0xFFE6CFCF, label: 'Rose'),
      (hex: 0xFFCFE0E6, label: 'Sky'),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: NeoColors.cream,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: NeoColors.ink, width: 4),
          ),
          title: Text('EDIT ROOM', style: NeoTextStyles.h3),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NAMA ROOM', style: NeoTextStyles.label.copyWith(fontSize: 11)),
                const SizedBox(height: 6),
                Container(
                  decoration: const BoxDecoration(color: NeoColors.white, border: NeoBorder.thin),
                  child: TextField(
                    controller: nameCtrl,
                    style: NeoTextStyles.body,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('STATUS TAG', style: NeoTextStyles.label.copyWith(fontSize: 11)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: RoomStatusTag.values.map((tag) {
                    final sel = tag == selectedTag;
                    return GestureDetector(
                      onTap: () => setDlg(() => selectedTag = tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? NeoColors.accent : NeoColors.white,
                          border: NeoBorder.thin,
                        ),
                        child: Text(
                          '${tag.emoji} ${tag.label}',
                          style: NeoTextStyles.label.copyWith(
                            fontSize: 11,
                            color: sel ? NeoColors.white : NeoColors.ink,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Text('WARNA LANTAI', style: NeoTextStyles.label.copyWith(fontSize: 11)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colorOptions.map((opt) {
                    final sel = opt.hex == colorHex;
                    return GestureDetector(
                      onTap: () => setDlg(() => colorHex = opt.hex),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(opt.hex),
                          border: Border.all(
                            color: NeoColors.ink,
                            width: sel ? 4 : 2,
                          ),
                          boxShadow: sel ? NeoShadows.s : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('BATAL', style: NeoTextStyles.label),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoColors.accent,
                foregroundColor: NeoColors.white,
                elevation: 0,
                side: const BorderSide(color: NeoColors.ink, width: 2),
              ),
              onPressed: () {
                final newName = nameCtrl.text.trim();
                if (newName.isNotEmpty) {
                  onUpdate(room.copyWith(
                    name: newName,
                    statusTag: selectedTag,
                    colorHex: colorHex,
                  ));
                }
                Navigator.pop(ctx);
              },
              child: Text('SIMPAN', style: NeoTextStyles.label.copyWith(color: NeoColors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color(room.colorHex),
          border: Border.all(
            color: NeoColors.ink,
            width: isSelected ? 4 : 2,
          ),
          boxShadow: isSelected ? NeoShadows.m : NeoShadows.s,
        ),
        child: Row(
          children: [
            // Colour swatch
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(room.colorHex),
                border: NeoBorder.thin,
              ),
              child: Center(
                child: Text(room.statusTag.emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.name.toUpperCase(), style: NeoTextStyles.bodyLarge.copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    '${room.statusTag.label}  •  ${room.widthTiles.toInt()}×${room.heightTiles.toInt()} tiles  •  ${room.furnitureItems.length} furniture',
                    style: NeoTextStyles.label.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: NeoColors.ink),
              onPressed: () => _showEditDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: NeoColors.accent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Furniture Tab
// ─────────────────────────────────────────────────────────────────────────────

class _FurnitureTab extends StatelessWidget {
  const _FurnitureTab({
    required this.rooms,
    required this.selectedRoomId,
    required this.onSelectRoom,
    required this.onAddFurniture,
    required this.onRemoveFurniture,
  });

  final List<Room> rooms;
  final String? selectedRoomId;
  final void Function(String id) onSelectRoom;
  final void Function(String roomId, FurnitureType type) onAddFurniture;
  final void Function(String roomId, String itemId) onRemoveFurniture;

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return Center(
        child: Text('Tambahkan room terlebih dahulu.', style: NeoTextStyles.body),
      );
    }

    final selectedRoom = selectedRoomId != null
        ? rooms.firstWhere((r) => r.id == selectedRoomId, orElse: () => rooms.first)
        : rooms.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Room selector ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          color: NeoColors.white,
          child: Row(
            children: [
              Text('ROOM:', style: NeoTextStyles.label),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: const BoxDecoration(
                    color: NeoColors.cream,
                    border: NeoBorder.thin,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRoom.id,
                      style: NeoTextStyles.body,
                      items: rooms.map((r) => DropdownMenuItem(
                        value: r.id,
                        child: Text(r.name, style: NeoTextStyles.body),
                      )).toList(),
                      onChanged: (id) {
                        if (id != null) onSelectRoom(id);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(height: 3, color: NeoColors.ink),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Catalog ──────────────────────────────────────────────────
              Text('KATALOG FURNITURE', style: NeoTextStyles.h3.copyWith(fontSize: 16)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FurnitureType.values.map((type) {
                  return NeoPressable(
                    onTap: () => onAddFurniture(selectedRoom.id, type),
                    child: (pressed) => AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      transform: pressed
                          ? Matrix4.translationValues(2, 2, 0)
                          : Matrix4.identity(),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: pressed ? NeoColors.secondary : NeoColors.white,
                        border: NeoBorder.thin,
                        boxShadow: pressed ? [] : NeoShadows.s,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(type.emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(type.label, style: NeoTextStyles.label.copyWith(fontSize: 9)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ── Placed furniture ─────────────────────────────────────────
              Row(
                children: [
                  Text(
                    'FURNITURE DI "${selectedRoom.name.toUpperCase()}"',
                    style: NeoTextStyles.h3.copyWith(fontSize: 14),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(
                      color: NeoColors.muted,
                      border: NeoBorder.thin,
                    ),
                    child: Text(
                      '${selectedRoom.furnitureItems.length}',
                      style: NeoTextStyles.label,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (selectedRoom.furnitureItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: NeoColors.white,
                    border: NeoBorder.thin,
                  ),
                  child: Center(
                    child: Text(
                      'Belum ada furniture.\nTap item di katalog untuk menambahkan.',
                      textAlign: TextAlign.center,
                      style: NeoTextStyles.body.copyWith(
                        color: NeoColors.ink.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                )
              else
                ...selectedRoom.furnitureItems.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: NeoColors.white,
                    border: NeoBorder.thin,
                    boxShadow: [BoxShadow(color: NeoColors.ink, offset: Offset(2, 2))],
                  ),
                  child: Row(
                    children: [
                      Text(item.type.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.type.label, style: NeoTextStyles.body),
                            Text(
                              'Posisi: (${item.tileX.toInt()}, ${item.tileY.toInt()})',
                              style: NeoTextStyles.label.copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: NeoColors.accent),
                        onPressed: () => onRemoveFurniture(selectedRoom.id, item.id),
                      ),
                    ],
                  ),
                )),
            ],
          ),
        ),
      ],
    );
  }
}
