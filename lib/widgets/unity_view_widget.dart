import 'package:flutter/material.dart';

/// Placeholder for the Unity embedded view.
///
/// flutter_unity_widget is temporarily removed due to jcenter() incompatibility
/// with AGP 9+. This widget will be replaced with UnityWidget(...) once a
/// compatible package version is available and the Unity project is ready.
class UnityViewWidget extends StatelessWidget {
  const UnityViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Text(
          'Unity View\n(not yet integrated)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}
