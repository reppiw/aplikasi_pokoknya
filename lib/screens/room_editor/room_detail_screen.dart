import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/room.dart';
import '../../services/room_session_manager.dart';

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({
    super.key,
    required this.room,
    required this.groupName,
    this.roomDescription = 'Suara/Obrolan Santai & Diskusi Tim. Tetap Sopan!',
    this.totalMembers = 24,
    this.onlineMembers = 8,
  });

  final Room room;
  final String groupName;
  final String roomDescription;
  final int totalMembers;
  final int onlineMembers;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  // Simulasi daftar member yang aktif/online di room ini (ala Discord Voice Channel)
  final List<Map<String, String>> _activeMembers = [
    {'name': 'Alex', 'role': 'HOST', 'status': 'speaking'},
    {'name': 'Sarah', 'role': 'MEMBER', 'status': 'muted'},
    {'name': 'Rico', 'role': 'MEMBER', 'status': 'active'},
    {'name': 'Jessica', 'role': 'MEMBER', 'status': 'muted'},
  ];

  @override
  Widget build(BuildContext context) {
    final sessionManager = RoomSessionManager();
    final isCurrentlyInThisRoom = sessionManager.isInRoom(widget.room.id);

    return Scaffold(
      backgroundColor: NeoColors.cream,
      appBar: AppBar(
        backgroundColor: NeoColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: NeoColors.ink, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.groupName.toUpperCase(),
          style: NeoTextStyles.h3.copyWith(fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: NeoColors.ink),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(color: NeoColors.ink, height: 4),
        ),
      ),
      body: Stack(
        children: [
          // Content Scrollable
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. HEADER ROOM & TAG STATUS ──────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Speaker ala Discord
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NeoColors.secondary,
                        border: NeoBorder.thick,
                        boxShadow: NeoShadows.s,
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        color: NeoColors.ink,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.room.name.toUpperCase(),
                            style: NeoTextStyles.h2.copyWith(fontSize: 22),
                          ),
                          const SizedBox(height: 4),
                          // Badge Jumlah Online & Total Member
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00D166), // Hijau khas Discord
                                  shape: BoxShape.circle,
                                  border: Border.fromBorderSide(
                                    BorderSide(color: NeoColors.ink, width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.onlineMembers} ONLINE',
                                style: NeoTextStyles.label.copyWith(fontSize: 10),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.people_alt_rounded,
                                size: 14,
                                color: NeoColors.ink,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.totalMembers} MEMBERS',
                                style: NeoTextStyles.label.copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── 2. DESKRIPSI / TOPIK ROOM ────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: NeoColors.white,
                    border: NeoBorder.thick,
                    boxShadow: NeoShadows.s,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: NeoColors.ink),
                          const SizedBox(width: 6),
                          Text('ROOM TOPIC', style: NeoTextStyles.label.copyWith(fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.roomDescription,
                        style: NeoTextStyles.body.copyWith(fontSize: 13, height: 1.3),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── 3. ANGGOTA AKTIF DI DALAM VOICE ROOM ─────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ACTIVE IN VOICE (${_activeMembers.length})', style: NeoTextStyles.h3.copyWith(fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: NeoColors.muted,
                        border: NeoBorder.thin,
                      ),
                      child: Text('LIVE', style: NeoTextStyles.label.copyWith(fontSize: 9)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Daftar Member yang sedang nyambung
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _activeMembers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final member = _activeMembers[index];
                    final isSpeaking = member['status'] == 'speaking';
                    final isMuted = member['status'] == 'muted';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: NeoColors.white,
                        border: Border.all(
                          color: isSpeaking ? const Color(0xFF00D166) : NeoColors.ink,
                          width: isSpeaking ? 3 : 2,
                        ),
                        boxShadow: NeoShadows.s,
                      ),
                      child: Row(
                        children: [
                          // Avatar Member
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: NeoColors.secondary,
                              border: NeoBorder.thin,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              member['name']![0].toUpperCase(),
                              style: NeoTextStyles.h3.copyWith(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Nama & Role
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member['name']!,
                                  style: NeoTextStyles.body.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                if (member['role'] == 'HOST')
                                  Text(
                                    'ROOM HOST',
                                    style: NeoTextStyles.label.copyWith(fontSize: 8, color: NeoColors.accent),
                                  ),
                              ],
                            ),
                          ),
                          // Mic Status Icon
                          Icon(
                            isMuted
                                ? Icons.mic_off_rounded
                                : (isSpeaking ? Icons.graphic_eq_rounded : Icons.mic_rounded),
                            color: isMuted ? NeoColors.accent : (isSpeaking ? const Color(0xFF00D166) : NeoColors.ink),
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── 4. FLOATING BOTTOM BAR (TOMBOL JOIN / LEAVE ROOM) ──────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: NeoColors.cream,
                border: Border(top: BorderSide(color: NeoColors.ink, width: 4)),
                boxShadow: [BoxShadow(color: NeoColors.ink, offset: Offset(0, -4))],
              ),
              child: isCurrentlyInThisRoom
                  ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeoColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: NeoColors.ink, width: 3),
                    borderRadius: BorderRadius.zero,
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  setState(() {
                    sessionManager.leaveCurrentRoom();
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.call_end_rounded, color: NeoColors.white),
                    const SizedBox(width: 10),
                    Text(
                      'LEAVE VOICE ROOM',
                      style: NeoTextStyles.button.copyWith(color: NeoColors.white),
                    ),
                  ],
                ),
              )
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D166), // Hijau Connect
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: NeoColors.ink, width: 3),
                    borderRadius: BorderRadius.zero,
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  setState(() {
                    sessionManager.joinRoom(
                      roomId: widget.room.id,
                      roomName: widget.room.name,
                      groupName: widget.groupName,
                    );
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.headset_mic_rounded, color: NeoColors.ink),
                    const SizedBox(width: 10),
                    Text(
                      'JOIN VOICE ROOM',
                      style: NeoTextStyles.button.copyWith(color: NeoColors.ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}