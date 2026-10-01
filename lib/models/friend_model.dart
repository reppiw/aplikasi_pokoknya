import 'dart:ui';

enum FriendStatus { online, idle, dnd, offline }

class Friend {
  final String id;
  final String name;
  final String username;
  final String avatarUrl;
  final FriendStatus status;
  final String customStatus;
  final String? activeRoomName;
  final String? activeGroupName;

  const Friend({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl = '',
    this.status = FriendStatus.offline,
    this.customStatus = '',
    this.activeRoomName,
    this.activeGroupName,
  });

  bool get isInVoiceRoom => activeRoomName != null && activeRoomName!.isNotEmpty;
}

extension FriendStatusX on FriendStatus {
  Color get color {
    switch (this) {
      case FriendStatus.online:
        return const Color(0xFF00D166);
      case FriendStatus.idle:
        return const Color(0xFFFEE75C);
      case FriendStatus.dnd:
        return const Color(0xFFED4245);
      case FriendStatus.offline:
        return const Color(0xFF747F8D);
    }
  }

  String get label {
    switch (this) {
      case FriendStatus.online:
        return 'ONLINE';
      case FriendStatus.idle:
        return 'IDLE';
      case FriendStatus.dnd:
        return 'DND';
      case FriendStatus.offline:
        return 'OFFLINE';
    }
  }
}