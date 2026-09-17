import 'package:flutter/material.dart';

/// Phase 2 — group admins define room names, sizes, and status tags here.
/// Flutter writes the config to Firestore; Unity fetches it and draws
/// invisible colliders at runtime.
class RoomEditorScreen extends StatelessWidget {
  const RoomEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: drag-to-resize room tiles, name fields, status-tag picker.
    return const Scaffold(
      body: Center(child: Text('Room Editor (Phase 2)')),
    );
  }
}
