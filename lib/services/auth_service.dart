import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  User? get currentUser =>
      Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;

  bool get isSignedIn => currentUser != null;

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<String?> register({
    required String name,
    required String username,
    required String password,
    required int age,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    if (age < 16) {
      throw const AuthException('Kamu harus berusia minimal 16 tahun.');
    }
    if (!RegExp(r'^[a-z0-9_]{3,}$').hasMatch(normalizedUsername)) {
      throw const AuthException(
        'Username harus terdiri dari minimal 3 huruf, angka, atau garis bawah.',
      );
    }

    final credential = await _createAccount(normalizedUsername, password);
    final user = credential.user!;

    try {
      await user.updateDisplayName(name.trim());
      final firestore = FirebaseFirestore.instance;
      final usernameRef = firestore
          .collection('usernames')
          .doc(normalizedUsername);
      final profileRef = firestore.collection('users').doc(user.uid);

      await firestore.runTransaction((transaction) async {
        final usernameSnapshot = await transaction.get(usernameRef);
        if (usernameSnapshot.exists) {
          throw const AuthException('Username sudah digunakan.');
        }

        transaction.set(usernameRef, {'uid': user.uid});
        transaction.set(profileRef, {
          'uid': user.uid,
          'name': name.trim(),
          'username': normalizedUsername,
          'age': age,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseAuthException catch (error) {
      final message =
          'Akun berhasil dibuat, tetapi profil Firebase gagal diperbarui: '
          '${_authErrorMessage(error)}';
      debugPrint(message);
      return message;
    } on FirebaseException catch (error) {
      final message =
          'Akun berhasil dibuat, tetapi profil gagal disimpan: '
          '${_firestoreErrorMessage(error)}';
      debugPrint(message);
      return message;
    } on AuthException catch (error) {
      final message =
          'Akun berhasil dibuat, tetapi profil tidak dapat disimpan: '
          '${error.message}';
      debugPrint(message);
      return message;
    }
    return null;
  }

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9_]{3,}$').hasMatch(normalizedUsername)) {
      throw const AuthException('Username atau password salah.');
    }
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailForUsername(normalizedUsername),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw _authException(error);
    }
  }

  Future<UserCredential> _createAccount(
    String username,
    String password,
  ) async {
    try {
      return await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailForUsername(username),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw _authException(error);
    }
  }

  String _emailForUsername(String username) => '$username@koboted.app';

  AuthException _authException(FirebaseAuthException error) {
    debugPrint('Firebase Auth error (${error.code}): ${error.message}');
    return AuthException('${_authErrorMessage(error)} (kode: ${error.code})');
  }

  String _authErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'email-already-in-use' => 'Username sudah digunakan.',
      'operation-not-allowed' || 'configuration-not-found' =>
        'Metode Email/Password belum diaktifkan. Aktifkan di Firebase Console '
            'pada Authentication > Sign-in method.',
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' => 'Username atau password salah.',
      'weak-password' => 'Password terlalu lemah.',
      'invalid-email' =>
        'Format akun tidak valid. Periksa konfigurasi Firebase.',
      'app-not-authorized' ||
      'invalid-api-key' ||
      'api-key-not-valid' ||
      'requests-from-referer-are-blocked' =>
        'Aplikasi belum diizinkan oleh konfigurasi Firebase.',
      'network-request-failed' => 'Koneksi internet bermasalah.',
      'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi nanti.',
      _ => 'Autentikasi gagal: ${error.message ?? error.code}',
    };
  }

  String _firestoreErrorMessage(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return 'Akses database ditolak. Periksa aturan keamanan Firestore.';
    }
    if (error.code == 'unavailable') {
      return 'Database tidak dapat dijangkau. Periksa koneksi internet.';
    }
    return 'Gagal menyimpan profil: ${error.message ?? error.code}';
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}
