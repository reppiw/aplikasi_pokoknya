import 'package:flutter/material.dart';

/// On-screen virtual joystick. Sends directional input across the
/// Unity bridge. Stops sending packets after [AppConstants.idleThresholdSeconds]
/// of no movement to save bandwidth.
class JoystickOverlay extends StatelessWidget {
  const JoystickOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement with flutter_joystick or a custom GestureDetector.
    return const Placeholder();
  }
}
