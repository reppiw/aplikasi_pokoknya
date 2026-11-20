import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/avatar_state.dart';
import '../models/group.dart';
import '../models/user.dart';

class DatabaseService {
  DatabaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ── Avatars ──────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _avatarCollection(String groupId) {
    if (groupId.trim().isEmpty) {
      throw ArgumentError.value(groupId, 'groupId', 'Tidak boleh kosong.');
    }
    return _firestore.collection('groups').doc(groupId).collection('avatars');
  }

  Future<List<AvatarState>> fetchGroupAvatarStates(String groupId) async {
    final snapshot = await _avatarCollection(groupId).get();
    return snapshot.docs.map((doc) => AvatarState.fromMap(doc.data())).toList();
  }

  Stream<List<AvatarState>> watchGroupAvatarStates(String groupId) {
    return _avatarCollection(groupId).snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => AvatarState.fromMap(doc.data())).toList(),
    );
  }

  Future<void> saveAvatarState(String groupId, AvatarState state) async {
    await _avatarCollection(groupId)
        .doc(state.userId)
        .set(state.toMap(), SetOptions(merge: true));
  }

  // ── Groups ───────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _groupsCollection() =>
      _firestore.collection('groups');

  String _generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Create a new group in Firestore.
  Future<Group> createGroup({
    required String name,
    String description = '',
    required String creatorId,
    bool isPrivate = false,
  }) async {
    final docRef = _groupsCollection().doc();
    final joinCode = _generateJoinCode();

    final group = Group(
      id: docRef.id,
      name: name.trim(),
      description: description.trim(),
      joinCode: joinCode,
      ownerId: creatorId,
      adminIds: [creatorId],
      memberIds: [creatorId],
      pendingMemberIds: const [],
      isPrivate: isPrivate,
      createdAt: DateTime.now(),
    );

    await docRef.set(group.toMap());
    return group;
  }

  /// Stream groups where [userId] is an active member.
  Stream<List<Group>> watchUserGroups(String userId) {
    return _groupsCollection()
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Group.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Stream all public (open) groups for discovery.
  Stream<List<Group>> watchPublicGroups() {
    return _groupsCollection()
        .where('isPrivate', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Group.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Watch a single group document for real-time updates.
  Stream<Group?> watchGroup(String groupId) {
    return _groupsCollection().doc(groupId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Group.fromFirestore(doc.id, doc.data()!);
    });
  }

  /// Fetch a single group by ID once.
  Future<Group?> getGroup(String groupId) async {
    final doc = await _groupsCollection().doc(groupId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Group.fromFirestore(doc.id, doc.data()!);
  }

  /// Join a group using its 6-character [code].
  Future<({bool success, String message, Group? group})> joinGroupByCode({
    required String code,
    required String userId,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    final snapshot = await _groupsCollection()
        .where('joinCode', isEqualTo: cleanCode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return (
        success: false,
        message: 'Grup dengan kode "$cleanCode" tidak ditemukan.',
        group: null,
      );
    }

    final doc = snapshot.docs.first;
    final group = Group.fromFirestore(doc.id, doc.data());

    if (group.isMember(userId)) {
      return (
        success: false,
        message: 'Kamu sudah menjadi anggota grup ini!',
        group: group,
      );
    }

    if (group.isPending(userId)) {
      return (
        success: false,
        message: 'Permintaan bergabung masih menunggu persetujuan admin.',
        group: group,
      );
    }

    if (group.isPrivate) {
      await doc.reference.update({
        'pendingMemberIds': FieldValue.arrayUnion([userId]),
      });
      return (
        success: true,
        message: 'Permintaan bergabung dikirim ke admin grup.',
        group: group.copyWith(
          pendingMemberIds: [...group.pendingMemberIds, userId],
        ),
      );
    } else {
      await doc.reference.update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });
      return (
        success: true,
        message: 'Berhasil bergabung dengan grup ${group.name}!',
        group: group.copyWith(
          memberIds: [...group.memberIds, userId],
        ),
      );
    }
  }

  /// Accept a pending user's join request.
  Future<void> acceptMemberRequest({
    required String groupId,
    required String userId,
  }) async {
    await _groupsCollection().doc(groupId).update({
      'pendingMemberIds': FieldValue.arrayRemove([userId]),
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  /// Reject/decline a pending user's join request.
  Future<void> rejectMemberRequest({
    required String groupId,
    required String userId,
  }) async {
    await _groupsCollection().doc(groupId).update({
      'pendingMemberIds': FieldValue.arrayRemove([userId]),
    });
  }

  /// Promote a regular member to Admin.
  Future<void> promoteToAdmin({
    required String groupId,
    required String userId,
  }) async {
    await _groupsCollection().doc(groupId).update({
      'adminIds': FieldValue.arrayUnion([userId]),
    });
  }

  /// Demote an Admin to regular Member.
  Future<void> demoteAdmin({
    required String groupId,
    required String userId,
  }) async {
    await _groupsCollection().doc(groupId).update({
      'adminIds': FieldValue.arrayRemove([userId]),
    });
  }

  /// Update group info and privacy (Public <-> Private).
  Future<void> updateGroupSettings({
    required String groupId,
    String? name,
    String? description,
    bool? isPrivate,
  }) async {
    final Map<String, dynamic> updates = {};
    if (name != null && name.trim().isNotEmpty) {
      updates['name'] = name.trim();
    }
    if (description != null) {
      updates['description'] = description.trim();
    }
    if (isPrivate != null) {
      updates['isPrivate'] = isPrivate;
    }
    if (updates.isNotEmpty) {
      await _groupsCollection().doc(groupId).update(updates);
    }
  }

  /// Remove/kick a member from the group.
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    await _groupsCollection().doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'adminIds': FieldValue.arrayRemove([userId]),
      'pendingMemberIds': FieldValue.arrayRemove([userId]),
    });
  }

  /// Helper to fetch user profiles for a list of [userIds].
  Future<List<AppUser>> fetchUsers(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    // Firestore whereIn has a limit of 30 items per query
    final List<AppUser> users = [];
    final chunks = <List<String>>[];
    for (var i = 0; i < userIds.length; i += 30) {
      chunks.add(
        userIds.sublist(i, min(i + 30, userIds.length)),
      );
    }

    for (final chunk in chunks) {
      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      users.addAll(
        snapshot.docs.map((d) => AppUser.fromFirestore(d.id, d.data())),
      );
    }

    return users;
  }

  // ── Friends & Users ─────────────────────────────────────────────────────────

  /// Add a friend using their unique [username].
  Future<({bool success, String message, AppUser? user})> addFriendByUsername({
    required String currentUserId,
    required String username,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    if (cleanUsername.isEmpty) {
      return (success: false, message: 'Username tidak boleh kosong.', user: null);
    }

    final usernameDoc = await _firestore.collection('usernames').doc(cleanUsername).get();
    if (!usernameDoc.exists || usernameDoc.data() == null) {
      return (success: false, message: 'Pengguna "@$cleanUsername" tidak ditemukan.', user: null);
    }

    final targetUid = (usernameDoc.data()!['uid'] as String? ?? '').trim();
    if (targetUid.isEmpty) {
      return (success: false, message: 'Profil pengguna tidak valid.', user: null);
    }

    if (targetUid == currentUserId) {
      return (success: false, message: 'Kamu tidak bisa menambahkan dirimu sendiri.', user: null);
    }

    // Add target to current user's friendIds list
    await _firestore.collection('users').doc(currentUserId).set({
      'friendIds': FieldValue.arrayUnion([targetUid]),
    }, SetOptions(merge: true));

    final targetProfile = await _firestore.collection('users').doc(targetUid).get();
    final targetUser = targetProfile.exists && targetProfile.data() != null
        ? AppUser.fromFirestore(targetUid, targetProfile.data()!)
        : null;

    final displayName = targetUser?.displayName.isNotEmpty == true
        ? targetUser!.displayName
        : '@$cleanUsername';

    return (
      success: true,
      message: '$displayName berhasil ditambahkan sebagai teman!',
      user: targetUser,
    );
  }

  /// Remove a friend from the current user's friend list.
  Future<void> removeFriend({
    required String currentUserId,
    required String friendId,
  }) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'friendIds': FieldValue.arrayRemove([friendId]),
    });
  }

  /// Watch friends of [currentUserId].
  Stream<List<AppUser>> watchFriends(String currentUserId) {
    return _firestore.collection('users').doc(currentUserId).snapshots().asyncMap((snap) async {
      if (!snap.exists || snap.data() == null) return <AppUser>[];
      final friendIds = List<String>.from(snap.data()!['friendIds'] ?? []);
      if (friendIds.isEmpty) return <AppUser>[];
      return fetchUsers(friendIds);
    });
  }

  /// Watch all registered users (excluding current user), useful for discovery.
  Stream<List<AppUser>> watchAllUsers({String? excludeUserId}) {
    return _firestore.collection('users').limit(50).snapshots().map((snapshot) {
      return snapshot.docs
          .where((d) => excludeUserId == null || d.id != excludeUserId)
          .map((d) => AppUser.fromFirestore(d.id, d.data()))
          .toList();
    });
  }
}
