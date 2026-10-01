import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../../models/room.dart';
import '../services/room_session_manager.dart';
import '../../screens/room_editor/room_detail_screen.dart';

class ActiveRoomBanner extends StatelessWidget {
  const ActiveRoomBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Menggunakan ListenableBuilder karena RoomSessionManager turunan ChangeNotifier
    return ListenableBuilder(
      listenable: RoomSessionManager(), // Memanggil singleton via factory constructor
      builder: (context, child) {
        final sessionManager = RoomSessionManager();
        final activeRoom = sessionManager.activeRoom;

        // Jika tidak ada room aktif, sembunyikan banner
        if (activeRoom == null) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          color: NeoColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.volume_up_rounded, color: NeoColors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ACTIVE IN: ${activeRoom.roomName.toUpperCase()}',
                  style: NeoTextStyles.label.copyWith(
                    color: NeoColors.white,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomDetailScreen(
                        room: Room(
                          id: activeRoom.roomId,
                          name: activeRoom.roomName,
                          statusTag: RoomStatusTag.free,
                        ),
                        groupName: activeRoom.groupName,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: NeoColors.white,
                    border: NeoBorder.thin,
                  ),
                  child: Text(
                    'REJOIN',
                    style: NeoTextStyles.label.copyWith(
                      color: NeoColors.ink,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}