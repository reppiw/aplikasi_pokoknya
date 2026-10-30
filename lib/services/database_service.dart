import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/avatar_state.dart';

class DatabaseService {
  DatabaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
}
