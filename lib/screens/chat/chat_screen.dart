import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.friend});
  final AppUser friend;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final String _currentUserId =
      FirebaseAuth.instance.currentUser?.uid ?? 'demo-user-1';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    _messageController.clear();
    _chatService.sendMessage(widget.friend.id, text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.cream,
      appBar: AppBar(
        backgroundColor: NeoColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: NeoColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: NeoColors.accent,
                border: NeoBorder.thin,
              ),
              alignment: Alignment.center,
              child: Text(
                widget.friend.displayName.isNotEmpty
                    ? widget.friend.displayName[0].toUpperCase()
                    : '?',
                style: NeoTextStyles.h3.copyWith(
                  color: NeoColors.white,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friend.displayName.toUpperCase(),
                    style: NeoTextStyles.h3.copyWith(fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ONLINE',
                    style: NeoTextStyles.label.copyWith(
                      fontSize: 9,
                      color: NeoColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: Divider(height: 4, thickness: 4, color: NeoColors.ink),
        ),
      ),
      body: Column(
        children: [
          // Daftar Pesan Realtime
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.friend.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: NeoColors.ink),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: NeoColors.muted,
                        border: NeoBorder.thin,
                      ),
                      child: Text(
                        'SAY HELLO TO ${widget.friend.displayName.toUpperCase()}!',
                        style: NeoTextStyles.label.copyWith(fontSize: 10),
                      ),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data =
                    messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _currentUserId;
                    final text = data['text'] ?? '';

                    return _MessageBubble(text: text, isMe: isMe);
                  },
                );
              },
            ),
          ),

          // Input Bar Pengirim Pesan
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: const BoxDecoration(
              color: NeoColors.cream,
              border: Border(top: BorderSide(color: NeoColors.ink, width: 4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: NeoTextStyles.body,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: NeoColors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: NeoColors.ink, width: 3),
                        borderRadius: BorderRadius.zero,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: NeoColors.ink, width: 4),
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _handleSend,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: NeoColors.secondary,
                      border: NeoBorder.thick,
                      boxShadow: NeoShadows.s,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: NeoColors.ink,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.text, required this.isMe});
  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? NeoColors.secondary : NeoColors.white,
          border: NeoBorder.thick,
          boxShadow: NeoShadows.s,
        ),
        child: Text(
          text,
          style: NeoTextStyles.body.copyWith(
            color: NeoColors.ink,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}