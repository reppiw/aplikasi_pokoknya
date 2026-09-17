import 'package:flutter/material.dart';

class OfficeScreen extends StatelessWidget {
  const OfficeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Main screen layout:
    //   - UnityViewWidget (full screen, behind everything)
    //   - JoystickOverlay (bottom left)
    //   - RoomPingPanel (bottom right or slide-up sheet)
    //   - UserAvatarOverlay (HUD nameplate / status chips)
    return const Scaffold(
      body: Center(child: Text('Office — Unity view goes here')),
    );
  }
}
