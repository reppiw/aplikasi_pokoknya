enum GroupMemberRole {
  owner,
  admin,
  member;

  String get label {
    switch (this) {
      case GroupMemberRole.owner:
        return 'OWNER';
      case GroupMemberRole.admin:
        return 'ADMIN';
      case GroupMemberRole.member:
        return 'MEMBER';
    }
  }
}

class Group {
  final String id;
  final String name;
  final String description;
  final String joinCode;
  final String ownerId;
  final List<String> adminIds;
  final List<String> memberIds;
  final List<String> pendingMemberIds;
  final bool isPrivate;
  final DateTime? createdAt;

  const Group({
    required this.id,
    required this.name,
    this.description = '',
    required this.joinCode,
    required this.ownerId,
    required this.adminIds,
    required this.memberIds,
    this.pendingMemberIds = const [],
    this.isPrivate = false,
    this.createdAt,
  });

  bool isOwner(String userId) => ownerId == userId;
  bool isAdmin(String userId) => ownerId == userId || adminIds.contains(userId);
  bool isMember(String userId) => memberIds.contains(userId);
  bool isPending(String userId) => pendingMemberIds.contains(userId);

  GroupMemberRole roleOf(String userId) {
    if (isOwner(userId)) return GroupMemberRole.owner;
    if (isAdmin(userId)) return GroupMemberRole.admin;
    return GroupMemberRole.member;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'joinCode': joinCode,
      'ownerId': ownerId,
      'adminIds': adminIds,
      'memberIds': memberIds,
      'pendingMemberIds': pendingMemberIds,
      'isPrivate': isPrivate,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory Group.fromFirestore(String id, Map<String, dynamic> data) {
    return Group(
      id: id,
      name: (data['name'] as String? ?? '').trim(),
      description: (data['description'] as String? ?? '').trim(),
      joinCode: (data['joinCode'] as String? ?? '').trim().toUpperCase(),
      ownerId: (data['ownerId'] as String? ?? '').trim(),
      adminIds: List<String>.from(data['adminIds'] ?? []),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      pendingMemberIds: List<String>.from(data['pendingMemberIds'] ?? []),
      isPrivate: data['isPrivate'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? joinCode,
    String? ownerId,
    List<String>? adminIds,
    List<String>? memberIds,
    List<String>? pendingMemberIds,
    bool? isPrivate,
    DateTime? createdAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      joinCode: joinCode ?? this.joinCode,
      ownerId: ownerId ?? this.ownerId,
      adminIds: adminIds ?? this.adminIds,
      memberIds: memberIds ?? this.memberIds,
      pendingMemberIds: pendingMemberIds ?? this.pendingMemberIds,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
