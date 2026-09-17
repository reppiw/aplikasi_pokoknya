import 'package:flutter/material.dart';

/// Slide-up panel that lets the current user broadcast a custom message
/// to everyone in a specific room via FCM topic messaging.
/// Only users currently inside the target room receive the notification.
class RoomPingPanel extends StatelessWidget {
  const RoomPingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: room picker dropdown + message text field + send button.
    return const Placeholder();
  }
}
