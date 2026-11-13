import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Streams the current signed-in user's profile. Emits null when signed out.
  Stream<AppUser?> watchCurrentUser() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);
      return _userDoc(firebaseUser.uid).snapshots().map((snap) {
        if (!snap.exists || snap.data() == null) return null;
        return AppUser.fromFirestore(firebaseUser.uid, snap.data()!);
      });
    });
  }

  /// Updates only the editable profile fields (name, bio).
  /// Username and email are intentionally excluded — changing those
  /// requires separate flows (username uniqueness check, email re-auth).
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String bio,
  }) async {
    await _userDoc(uid).set(
      {
        'name': displayName.trim(),
        'bio': bio.trim(),
      },
      SetOptions(merge: true),
    );
  }
}
