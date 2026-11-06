import 'package:flutter/material.dart';

/// A wrapper that provides the Neo-Brutalist press animation:
/// translates the child by [pressOffset] on tap-down and restores on release.
///
/// Uses a [builder] so callers can customise the inner decoration based on
/// the [pressed] state (e.g. toggling shadows, changing colours).
///
/// Example:
/// ```dart
/// NeoPressable(
///   onTap: () => print('tapped'),
///   child: (pressed) => AnimatedContainer(
///     duration: const Duration(milliseconds: 100),
///     transform: pressed
///         ? Matrix4.translationValues(4, 4, 0)
///         : Matrix4.identity(),
///     decoration: BoxDecoration(
///       color: NeoColors.cream,
///       border: NeoBorder.thick,
///       boxShadow: pressed ? [] : NeoShadows.m,
///     ),
///     child: Text('PRESS ME'),
///   ),
/// )
/// ```
class NeoPressable extends StatefulWidget {
  const NeoPressable({
    super.key,
    required this.onTap,
    required this.child,
    this.pressOffset = const Offset(4, 4),
    this.enableFeedback = true,
  });

  /// Called when the user taps the widget.
  final VoidCallback? onTap;

  /// Builds the child widget, receiving the current [pressed] state.
  final Widget Function(bool pressed) child;

  /// How far to translate the child on press (x, y).
  final Offset pressOffset;

  /// Whether to provide haptic/semantic feedback on tap.
  final bool enableFeedback;

  @override
  State<NeoPressable> createState() => _NeoPressableState();
}

class _NeoPressableState extends State<NeoPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: widget.child(_pressed),
    );
  }
}
