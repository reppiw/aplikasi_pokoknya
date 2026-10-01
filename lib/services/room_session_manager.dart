import 'package:flutter/foundation.dart';
import '../models/room.dart';
import '../../models/room_history_item.dart';

class ActiveRoomSession {
  final Room room;
  final String groupName;
  final DateTime joinedAt;

  ActiveRoomSession({
    required this.room,
    required this.groupName,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();
}

class RoomSessionManager extends ChangeNotifier {
  static final RoomSessionManager _instance = RoomSessionManager._internal();
  factory RoomSessionManager() => _instance;
  RoomSessionManager._internal();

  RoomHistoryItem? _activeRoom;
  final List<RoomHistoryItem> _history = [];

  RoomHistoryItem? get activeRoom => _activeRoom;
  List<RoomHistoryItem> get history => List.unmodifiable(_history);

  bool isInRoom(String roomId) => _activeRoom?.roomId == roomId;

  /// Masuk ke room baru. Jika sedang di room lain, otomatis keluar dari room sebelumnya.
  void joinRoom({required String roomId, required String roomName, required String groupName}) {
    // Jika sudah di room ini, tidak perlu lakukan apa-apa
    if (_activeRoom?.roomId == roomId) return;

    final now = DateTime.now();

    // 1. Jika sedang di room lain, keluarkan dulu & catat jam keluarya
    if (_activeRoom != null) {
      leaveCurrentRoom();
    }

    // 2. Buat sesi room baru
    final newSession = RoomHistoryItem(
      roomId: roomId,
      roomName: roomName,
      groupName: groupName,
      joinedAt: now,
    );

    _activeRoom = newSession;
    _history.insert(0, newSession);
    notifyListeners();
  }

  /// Keluar dari room yang sedang aktif
  void leaveCurrentRoom() {
    if (_activeRoom == null) return;

    final now = DateTime.now();
    final index = _history.indexWhere((item) => item.roomId == _activeRoom!.roomId && item.isActive);

    if (index >= 0) {
      _history[index] = _history[index].copyWith(leftAt: now);
    }

    _activeRoom = null;
    notifyListeners();
  }
}