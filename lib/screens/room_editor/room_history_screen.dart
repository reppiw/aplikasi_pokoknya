import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/room_session_manager.dart';

class RoomHistoryScreen extends StatelessWidget {
  const RoomHistoryScreen({super.key});

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final sessionManager = RoomSessionManager();
    final history = sessionManager.history;

    return Scaffold(
      backgroundColor: NeoColors.cream,
      appBar: AppBar(
        backgroundColor: NeoColors.cream,
        elevation: 0,
        title: Text('ROOM HISTORY', style: NeoTextStyles.h2),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: Divider(height: 4, thickness: 4, color: NeoColors.ink),
        ),
      ),
      body: history.isEmpty
          ? Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: NeoColors.white,
            border: NeoBorder.thick,
            boxShadow: NeoShadows.m,
          ),
          child: Text('BELUM ADA RIWAYAT ROOM', style: NeoTextStyles.h3),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: history.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = history[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: item.isActive ? NeoColors.secondary.withValues(alpha: 0.3) : NeoColors.white,
              border: NeoBorder.thick,
              boxShadow: NeoShadows.s,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.roomName.toUpperCase(),
                        style: NeoTextStyles.h3.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'GROUP: ${item.groupName}',
                        style: NeoTextStyles.label.copyWith(fontSize: 10, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Masuk: ${_formatTime(item.joinedAt)} ${item.isActive ? "(MASIH AKTIF)" : "- Keluar: ${_formatTime(item.leftAt!)}"}',
                        style: NeoTextStyles.body.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (item.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D166),
                      border: NeoBorder.thin,
                    ),
                    child: Text('AKTIF', style: NeoTextStyles.label.copyWith(fontSize: 9)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}