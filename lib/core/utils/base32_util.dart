/// Generic Base32 string formatting utility functions.
abstract class Base32Util {
  /// Strips spaces and normalizes Base32 secret string.
  static String normalize(String input) {
    return input.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }
}
