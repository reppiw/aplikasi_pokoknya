import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../game/components/office_map.dart' show kMapCols, kMapRows, kTileSize;
import '../../models/furniture.dart';
import '../../models/room.dart';
import '../../services/database_service.dart';
import '../../widgets/neo_pressable.dart';

/// Interaction mode for the free camera visual room editor.
enum _EditorMode {
  panZoom,
  edit,
}

class RoomEditorScreen extends StatefulWidget {
  const RoomEditorScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<RoomEditorScreen> createState() => _RoomEditorScreenState();
}

class _RoomEditorScreenState extends State<RoomEditorScreen> {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();
  final TransformationController _transformCtrl = TransformationController();

  List<Room> _rooms = [];
  bool _loading = true;
  bool _saving = false;

  _EditorMode _mode = _EditorMode.edit;

  // Selected entities
  String? _selectedRoomId;
  String? _selectedFurnitureId;

  // Drag tracking (for tile snapping while dragging)
  double _dragAccumX = 0;
  double _dragAccumY = 0;

  static const double _gridWidth = kMapCols * kTileSize;  // 32 * 32 = 1024
  static const double _gridHeight = kMapRows * kTileSize; // 40 * 32 = 1280

  static const _floorColors = [
    (hex: 0xFFF2DFC5, name: 'Lounge Cream'),
    (hex: 0xFFEADCCB, name: 'Sand Brown'),
    (hex: 0xFFE8D9C2, name: 'Warm Linen'),
    (hex: 0xFFE3E2CF, name: 'Sage Green'),
    (hex: 0xFFD8E2DC, name: 'Mint Fog'),
    (hex: 0xFFD0DBE5, name: 'Soft Blue'),
    (hex: 0xFFE4D5E8, name: 'Lavender'),
    (hex: 0xFFFFE5D9, name: 'Peach Warm'),
  ];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    try {
      final fetched = await _db.fetchGroupRooms(widget.groupId);
      setState(() {
        _rooms = fetched.isNotEmpty ? fetched : defaultRooms();
        if (_rooms.isNotEmpty) _selectedRoomId = _rooms.first.id;
        _loading = false;
      });
      _resetCamera();
    } catch (_) {
      setState(() {
        _rooms = defaultRooms();
        if (_rooms.isNotEmpty) _selectedRoomId = _rooms.first.id;
        _loading = false;
      });
      _resetCamera();
    }
  }

  void _resetCamera() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      final scaleX = size.width / (_gridWidth + 64);
      final scaleY = (size.height - 200) / (_gridHeight + 64);
      final scale = min(scaleX, scaleY).clamp(0.4, 1.2);

      final dx = (size.width - _gridWidth * scale) / 2;
      final dy = (size.height - 180 - _gridHeight * scale) / 2;

      _transformCtrl.value = Matrix4.diagonal3Values(scale, scale, 1.0)
        ..setTranslationRaw(dx, dy, 0.0);
      setState(() {});
    });
  }

  void _zoom(double factor) {
    final currentScale = _transformCtrl.value.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(0.25, 2.5);
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);

    final sceneCenter = _transformCtrl.toScene(center);
    final tx = center.dx - sceneCenter.dx * newScale;
    final ty = center.dy - sceneCenter.dy * newScale;
    _transformCtrl.value = Matrix4.diagonal3Values(newScale, newScale, 1.0)
      ..setTranslationRaw(tx, ty, 0.0);
    setState(() {});
  }

  Future<void> _saveRooms() async {
    setState(() => _saving = true);
    try {
      await _db.saveGroupRooms(widget.groupId, _rooms);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Layout ruangan berhasil disimpan!', style: NeoTextStyles.label),
            backgroundColor: NeoColors.ink,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e', style: NeoTextStyles.label.copyWith(color: Colors.white)),
            backgroundColor: NeoColors.accent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Room Actions ───────────────────────────────────────────────────────────

  Room? get _selectedRoom {
    final id = _selectedRoomId;
    if (id == null) return null;
    return _rooms.where((r) => r.id == id).firstOrNull;
  }

  FurnitureItem? get _selectedFurniture {
    final room = _selectedRoom;
    final fId = _selectedFurnitureId;
    if (room == null || fId == null) return null;
    return room.furnitureItems.where((f) => f.id == fId).firstOrNull;
  }

  void _addRoom() {
    final id = _uuid.v4();
    double nx = 1;
    double ny = 1;
    if (_rooms.isNotEmpty) {
      final last = _rooms.last;
      nx = (last.tileX + last.widthTiles + 1);
      ny = last.tileY;
      if (nx + 12 > kMapCols - 1) {
        nx = 1;
        ny = (last.tileY + last.heightTiles + 1);
        if (ny + 14 > kMapRows - 1) ny = 1;
      }
    }

    final newRoom = Room(
      id: id,
      name: 'Room ${_rooms.length + 1}',
      tileX: nx.clamp(1, kMapCols - 13),
      tileY: ny.clamp(1, kMapRows - 15),
      widthTiles: 12,
      heightTiles: 14,
      colorHex: 0xFFEBDDD1,
    );

    setState(() {
      _rooms.add(newRoom);
      _selectedRoomId = id;
      _selectedFurnitureId = null;
    });
  }

  void _deleteRoom(String id) {
    setState(() {
      _rooms.removeWhere((r) => r.id == id);
      if (_selectedRoomId == id) {
        _selectedRoomId = _rooms.isNotEmpty ? _rooms.first.id : null;
      }
      _selectedFurnitureId = null;
    });
  }

  void _renameRoom(Room room) {
    final ctrl = TextEditingController(text: room.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoColors.cream,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: NeoColors.ink, width: 4),
        ),
        title: Text('RENAME ROOM', style: NeoTextStyles.h3),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: NeoTextStyles.body,
          decoration: const InputDecoration(
            labelText: 'NAMA RUANGAN',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: NeoColors.ink, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('BATAL', style: NeoTextStyles.label),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                _updateRoom(room.copyWith(name: newName));
              }
              Navigator.pop(ctx);
            },
            child: Text('SIMPAN', style: NeoTextStyles.label.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _changeRoomColor(Room room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NeoColors.cream,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: NeoColors.ink, width: 4),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WARNA LANTAI RUANGAN', style: NeoTextStyles.h3),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _floorColors.map((c) {
                final isCur = room.colorHex == c.hex;
                return GestureDetector(
                  onTap: () {
                    _updateRoom(room.copyWith(colorHex: c.hex));
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(c.hex),
                      border: Border.all(
                        color: NeoColors.ink,
                        width: isCur ? 4 : 2,
                      ),
                      boxShadow: isCur ? NeoShadows.s : null,
                    ),
                    child: isCur ? const Center(child: Icon(Icons.check, color: NeoColors.ink)) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _updateRoom(Room updated) {
    final idx = _rooms.indexWhere((r) => r.id == updated.id);
    if (idx >= 0) {
      setState(() => _rooms[idx] = updated);
    }
  }

  // ── Furniture Actions ──────────────────────────────────────────────────────

  void _openFurnitureCatalog() {
    final room = _selectedRoom;
    if (room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih ruangan terlebih dahulu!', style: NeoTextStyles.label),
          backgroundColor: NeoColors.accent,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: NeoColors.cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: NeoColors.ink, width: 4),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scroll) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('KATALOG FURNITURE', style: NeoTextStyles.h3),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: NeoColors.ink),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                'Pilih furniture untuk ditambahkan ke "${room.name.toUpperCase()}".',
                style: NeoTextStyles.body.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  controller: scroll,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: FurnitureType.values.length,
                  itemBuilder: (ctx, i) {
                    final type = FurnitureType.values[i];
                    return GestureDetector(
                      onTap: () {
                        _addFurniture(room, type);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NeoColors.white,
                          border: NeoBorder.thin,
                          boxShadow: NeoShadows.s,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(type.emoji, style: const TextStyle(fontSize: 32)),
                            const SizedBox(height: 6),
                            Text(
                              type.label,
                              style: NeoTextStyles.label.copyWith(fontSize: 10),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${type.defaultWidthTiles}×${type.defaultHeightTiles}t',
                              style: NeoTextStyles.label.copyWith(fontSize: 8, color: Colors.grey[700]),
                            ),
                          ],
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

  void _addFurniture(Room room, FurnitureType type) {
    // Find an open tile in room, or default to (1, 1)
    double targetX = 1;
    double targetY = 1;
    final maxX = max(1.0, room.widthTiles - type.defaultWidthTiles - 1);
    final maxY = max(1.0, room.heightTiles - type.defaultHeightTiles - 1);

    // Place near center
    targetX = ((room.widthTiles - type.defaultWidthTiles) / 2).floorToDouble().clamp(1.0, maxX);
    targetY = ((room.heightTiles - type.defaultHeightTiles) / 2).floorToDouble().clamp(1.0, maxY);

    final item = FurnitureItem(
      id: _uuid.v4(),
      type: type,
      tileX: targetX,
      tileY: targetY,
    );

    final updated = room.copyWith(
      furnitureItems: [...room.furnitureItems, item],
    );
    _updateRoom(updated);
    setState(() {
      _selectedFurnitureId = item.id;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${type.emoji} ${type.label} ditambahkan! Kamu bisa drag langsung untuk memindahkannya.',
          style: NeoTextStyles.label,
        ),
        backgroundColor: NeoColors.ink,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteFurniture(Room room, String itemId) {
    final updated = room.copyWith(
      furnitureItems: room.furnitureItems.where((f) => f.id != itemId).toList(),
    );
    _updateRoom(updated);
    setState(() => _selectedFurnitureId = null);
  }

  // ── Drag & Manipulation Handlers ──────────────────────────────────────────

  void _onRoomDragUpdate(Room room, DragUpdateDetails details) {
    if (_mode != _EditorMode.edit) return;
    final scale = _transformCtrl.value.getMaxScaleOnAxis();
    _dragAccumX += details.delta.dx / scale;
    _dragAccumY += details.delta.dy / scale;

    final tileShiftX = (_dragAccumX / kTileSize).truncate();
    final tileShiftY = (_dragAccumY / kTileSize).truncate();

    if (tileShiftX != 0 || tileShiftY != 0) {
      _dragAccumX -= tileShiftX * kTileSize;
      _dragAccumY -= tileShiftY * kTileSize;

      final newX = (room.tileX + tileShiftX).clamp(1.0, kMapCols - room.widthTiles - 1);
      final newY = (room.tileY + tileShiftY).clamp(1.0, kMapRows - room.heightTiles - 1);

      if (newX != room.tileX || newY != room.tileY) {
        _updateRoom(room.copyWith(tileX: newX, tileY: newY));
      }
    }
  }

  void _onRoomResizeUpdate(Room room, DragUpdateDetails details) {
    if (_mode != _EditorMode.edit) return;
    final scale = _transformCtrl.value.getMaxScaleOnAxis();
    _dragAccumX += details.delta.dx / scale;
    _dragAccumY += details.delta.dy / scale;

    final tileShiftX = (_dragAccumX / kTileSize).truncate();
    final tileShiftY = (_dragAccumY / kTileSize).truncate();

    if (tileShiftX != 0 || tileShiftY != 0) {
      _dragAccumX -= tileShiftX * kTileSize;
      _dragAccumY -= tileShiftY * kTileSize;

      final newW = (room.widthTiles + tileShiftX).clamp(4.0, kMapCols - room.tileX - 1);
      final newH = (room.heightTiles + tileShiftY).clamp(4.0, kMapRows - room.tileY - 1);

      if (newW != room.widthTiles || newH != room.heightTiles) {
        _updateRoom(room.copyWith(widthTiles: newW, heightTiles: newH));
      }
    }
  }

  void _onFurnitureDragUpdate(Room room, FurnitureItem item, DragUpdateDetails details) {
    if (_mode != _EditorMode.edit) return;
    final scale = _transformCtrl.value.getMaxScaleOnAxis();
    _dragAccumX += details.delta.dx / scale;
    _dragAccumY += details.delta.dy / scale;

    final tileShiftX = (_dragAccumX / kTileSize).truncate();
    final tileShiftY = (_dragAccumY / kTileSize).truncate();

    if (tileShiftX != 0 || tileShiftY != 0) {
      _dragAccumX -= tileShiftX * kTileSize;
      _dragAccumY -= tileShiftY * kTileSize;

      final maxX = max(0.0, room.widthTiles - item.type.defaultWidthTiles);
      final maxY = max(0.0, room.heightTiles - item.type.defaultHeightTiles);

      final newX = (item.tileX + tileShiftX).clamp(0.0, maxX);
      final newY = (item.tileY + tileShiftY).clamp(0.0, maxY);

      if (newX != item.tileX || newY != item.tileY) {
        final updatedItems = room.furnitureItems.map((f) {
          if (f.id == item.id) {
            return f.copyWith(tileX: newX, tileY: newY);
          }
          return f;
        }).toList();
        _updateRoom(room.copyWith(furnitureItems: updatedItems));
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.ink,
      appBar: AppBar(
        backgroundColor: NeoColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: NeoColors.ink, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text('ROOM & MAP EDITOR', style: NeoTextStyles.h3.copyWith(fontSize: 16)),
            Text(
              _mode == _EditorMode.edit ? 'MODE: DRAG & EDIT' : 'MODE: FREE CAMERA',
              style: NeoTextStyles.label.copyWith(fontSize: 9, color: Colors.grey[700]),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: NeoColors.ink, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save_rounded, color: NeoColors.ink, size: 28),
                  tooltip: 'Simpan ke Firestore',
                  onPressed: _saveRooms,
                ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(3),
          child: Divider(height: 3, thickness: 3, color: NeoColors.ink),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: NeoColors.secondary))
          : Stack(
              children: [
                // ── 1. Interactive 2D Map Canvas (Pan & Zoom) ────────────────
                Positioned.fill(
                  child: InteractiveViewer(
                    transformationController: _transformCtrl,
                    minScale: 0.25,
                    maxScale: 2.5,
                    boundaryMargin: const EdgeInsets.all(600),
                    panEnabled: _mode == _EditorMode.panZoom,
                    scaleEnabled: true,
                    child: Center(
                      child: Container(
                        width: _gridWidth,
                        height: _gridHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9AE8B),
                          border: Border.all(color: const Color(0xFF765442), width: kTileSize),
                        ),
                        child: CustomPaint(
                          painter: _GridTilePainter(),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: _rooms.map(_buildRoomWidget).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 2. Top-Right Floating Camera Controls ────────────────────
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      _buildFloatingCircleBtn(
                        icon: Icons.zoom_in,
                        tooltip: 'Zoom In',
                        onTap: () => _zoom(1.25),
                      ),
                      const SizedBox(height: 8),
                      _buildFloatingCircleBtn(
                        icon: Icons.zoom_out,
                        tooltip: 'Zoom Out',
                        onTap: () => _zoom(0.8),
                      ),
                      const SizedBox(height: 8),
                      _buildFloatingCircleBtn(
                        icon: Icons.center_focus_strong,
                        tooltip: 'Reset Camera',
                        onTap: _resetCamera,
                      ),
                    ],
                  ),
                ),

                // ── 3. Mode Toggle (Pan/Camera vs Select/Move) ────────────────
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: NeoColors.cream,
                      border: NeoBorder.thick,
                      boxShadow: NeoShadows.s,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeTab(
                          label: 'MOVE',
                          icon: Icons.open_with_rounded,
                          active: _mode == _EditorMode.edit,
                          onTap: () => setState(() => _mode = _EditorMode.edit),
                        ),
                        _buildModeTab(
                          label: 'PAN',
                          icon: Icons.pan_tool_rounded,
                          active: _mode == _EditorMode.panZoom,
                          onTap: () => setState(() => _mode = _EditorMode.panZoom),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 4. Bottom Contextual Control Bar ─────────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomBar(),
                ),
              ],
            ),
    );
  }

  Widget _buildFloatingCircleBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: NeoColors.cream,
          border: NeoBorder.thick,
          boxShadow: NeoShadows.s,
        ),
        child: Icon(icon, color: NeoColors.ink, size: 22),
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? NeoColors.secondary : Colors.transparent,
          border: active ? NeoBorder.thin : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: NeoColors.ink),
            const SizedBox(width: 4),
            Text(label, style: NeoTextStyles.label.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ── Room & Furniture Canvas Components ────────────────────────────────────

  Widget _buildRoomWidget(Room room) {
    final isSelected = room.id == _selectedRoomId;
    final rx = room.tileX * kTileSize;
    final ry = room.tileY * kTileSize;
    final rw = room.widthTiles * kTileSize;
    final rh = room.heightTiles * kTileSize;

    return Positioned(
      left: rx,
      top: ry,
      width: rw,
      height: rh,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRoomId = room.id;
            _selectedFurnitureId = null;
          });
        },
        onPanStart: (_) {
          _dragAccumX = 0;
          _dragAccumY = 0;
        },
        onPanUpdate: (d) => _onRoomDragUpdate(room, d),
        child: Container(
          decoration: BoxDecoration(
            color: Color(room.colorHex),
            border: Border.all(
              color: isSelected ? NeoColors.accent : const Color(0xFF765442),
              width: isSelected ? 4 : 2,
            ),
            boxShadow: isSelected
                ? const [BoxShadow(color: NeoColors.ink, offset: Offset(4, 4), blurRadius: 0)]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Room name header banner
              Positioned(
                top: 4,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? NeoColors.accent : NeoColors.white.withValues(alpha: 0.85),
                    border: NeoBorder.thin,
                  ),
                  child: Text(
                    room.name.toUpperCase(),
                    style: NeoTextStyles.label.copyWith(
                      fontSize: 10,
                      color: isSelected ? Colors.white : NeoColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Placed furniture items
              ...room.furnitureItems.map((f) => _buildFurnitureWidget(room, f)),

              // Resize Handle at bottom-right corner when room is selected
              if (isSelected && _mode == _EditorMode.edit)
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: GestureDetector(
                    onPanStart: (_) {
                      _dragAccumX = 0;
                      _dragAccumY = 0;
                    },
                    onPanUpdate: (d) => _onRoomResizeUpdate(room, d),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: NeoColors.secondary,
                        border: NeoBorder.thin,
                      ),
                      child: const Icon(Icons.aspect_ratio_rounded, size: 14, color: NeoColors.ink),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFurnitureWidget(Room room, FurnitureItem item) {
    final isSelected = item.id == _selectedFurnitureId;
    final fx = item.tileX * kTileSize;
    final fy = item.tileY * kTileSize;
    final fw = item.type.defaultWidthTiles * kTileSize;
    final fh = item.type.defaultHeightTiles * kTileSize;

    return Positioned(
      left: fx,
      top: fy,
      width: fw,
      height: fh,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedRoomId = room.id;
            _selectedFurnitureId = item.id;
          });
        },
        onPanStart: (_) {
          _dragAccumX = 0;
          _dragAccumY = 0;
        },
        onPanUpdate: (d) => _onFurnitureDragUpdate(room, item, d),
        child: Container(
          decoration: BoxDecoration(
            color: Color(item.colorHex ?? item.type.defaultColorHex).withValues(alpha: 0.8),
            border: Border.all(
              color: isSelected ? Colors.blue : NeoColors.ink,
              width: isSelected ? 3 : 1.5,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.type.emoji, style: TextStyle(fontSize: min(20.0, fh * 0.5))),
              if (fh > 40 && fw > 40)
                Text(
                  item.type.label,
                  style: NeoTextStyles.label.copyWith(fontSize: 8, color: NeoColors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom Sheet / Control Bar ─────────────────────────────────────────────

  Widget _buildBottomBar() {
    final room = _selectedRoom;
    final furniture = _selectedFurniture;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: NeoColors.cream,
        border: Border(top: BorderSide(color: NeoColors.ink, width: 3)),
        boxShadow: [BoxShadow(color: NeoColors.ink, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Furniture Inspector
            if (room != null && furniture != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: Colors.blue.withValues(alpha: 0.2),
                    child: Text(
                      '${furniture.type.emoji} ${furniture.type.label.toUpperCase()} (${furniture.tileX.toInt()}, ${furniture.tileY.toInt()})',
                      style: NeoTextStyles.label.copyWith(fontSize: 11),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: NeoColors.accent),
                    tooltip: 'Hapus Furniture',
                    onPressed: () => _deleteFurniture(room, furniture.id),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ]
            // Selected Room Inspector
            else if (room != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name.toUpperCase(),
                          style: NeoTextStyles.h3.copyWith(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'POS: (${room.tileX.toInt()}, ${room.tileY.toInt()}) • SIZE: ${room.widthTiles.toInt()}×${room.heightTiles.toInt()} • ${room.furnitureItems.length} FURNITURE',
                          style: NeoTextStyles.label.copyWith(fontSize: 9, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: NeoColors.ink),
                    tooltip: 'Rename Room',
                    onPressed: () => _renameRoom(room),
                  ),
                  IconButton(
                    icon: const Icon(Icons.palette_outlined, color: NeoColors.ink),
                    tooltip: 'Ubah Warna Lantai',
                    onPressed: () => _changeRoomColor(room),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: NeoColors.accent),
                    tooltip: 'Hapus Room',
                    onPressed: () => _deleteRoom(room.id),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: NeoPressable(
                    onTap: _addRoom,
                    child: (pressed) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: NeoColors.white,
                        border: NeoBorder.thin,
                        boxShadow: pressed ? [] : NeoShadows.s,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_box_outlined, size: 18, color: NeoColors.ink),
                          const SizedBox(width: 6),
                          Text('TAMBAH ROOM', style: NeoTextStyles.label.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: NeoPressable(
                    onTap: _openFurnitureCatalog,
                    child: (pressed) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: NeoColors.secondary,
                        border: NeoBorder.thin,
                        boxShadow: pressed ? [] : NeoShadows.s,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.weekend_outlined, size: 18, color: NeoColors.ink),
                          const SizedBox(width: 6),
                          Text('KATALOG FURNITURE', style: NeoTextStyles.label.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
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

// ── Custom Tile Grid Painter ──────────────────────────────────────────────────

class _GridTilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1.0;

    // Draw vertical tile lines
    for (double x = 0; x <= size.width; x += kTileSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    // Draw horizontal tile lines
    for (double y = 0; y <= size.height; y += kTileSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
