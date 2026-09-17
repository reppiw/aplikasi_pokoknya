// Centralised logger. Replace with a logging package (e.g. `logger`) later.
class Log {
  static void d(String tag, String message) =>
      // ignore: avoid_print
      print('[$tag] $message');
}
