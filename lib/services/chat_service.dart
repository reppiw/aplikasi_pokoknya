import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Membuat ID unik yang konsisten untuk 2 pengguna
  String getChatRoomId(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Mengirim pesan baru ke Firestore
  Future<void> sendMessage(String receiverId, String messageText) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || messageText.trim().isEmpty) return;

    final currentUserId = currentUser.uid;
    final chatRoomId = getChatRoomId(currentUserId, receiverId);
    final timestamp = FieldValue.serverTimestamp();

    final roomRef = _firestore.collection('chat_rooms').doc(chatRoomId);

    // Simpan pesan ke sub-koleksi messages
    await roomRef.collection('messages').add({
      'senderId': currentUserId,
      'text': messageText.trim(),
      'timestamp': timestamp,
    });

    // Update metadata chat room (untuk riwayat pesan terakhir)
    await roomRef.set({
      'participants': [currentUserId, receiverId],
      'lastMessage': messageText.trim(),
      'lastTimestamp': timestamp,
    }, SetOptions(merge: true));
  }

  // Stream realtime daftar pesan di dalam chat room
  Stream<QuerySnapshot> getMessages(String receiverId) {
    final currentUserId = _auth.currentUser?.uid ?? 'demo-user-1';
    final chatRoomId = getChatRoomId(currentUserId, receiverId);

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}