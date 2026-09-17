import 'package:flutter/material.dart';

/// Wraps the flutter_unity_widget UnityWidget.
/// Receives a callback so the parent (OfficeScreen) can hold the
/// UnityWidgetController and pass it to UnityBridgeService.
class UnityViewWidget extends StatelessWidget {
  const UnityViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: return UnityWidget(onUnityCreated: ..., onUnityMessage: ...)
    return const ColoredBox(
      color: Colors.black,
      child: Center(child: Text('Unity View', style: TextStyle(color: Colors.white))),
    );
  }
}
