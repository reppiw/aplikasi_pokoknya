/// Extracts up to two uppercase initials from a display name.
///
/// Examples:
///   "Alex Rivera" → "AR"
///   "Sarah"      → "SA"
///   "X"          → "X"
///   ""           → "?"
String initialsFor(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.isEmpty || words.first.isEmpty) return '?';
  if (words.length == 1) {
    final w = words[0];
    // Guard: don't slice past the string length for single-char names.
    return w.substring(0, w.length.clamp(1, 2)).toUpperCase();
  }
  return (words[0][0] + words[1][0]).toUpperCase();
}
