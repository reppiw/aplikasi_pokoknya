/// Extracts up to two uppercase initials from a display name.
///
/// Examples:
///   "Alex Rivera" → "AR"
///   "Sarah"      → "SA"
///   ""           → "?"
String initialsFor(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.isEmpty || words.first.isEmpty) return '?';
  if (words.length == 1) return words[0].substring(0, 2).toUpperCase();
  return (words[0][0] + words[1][0]).toUpperCase();
}
