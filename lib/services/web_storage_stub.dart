/// Stub implementation for non-web platforms (Android / iOS).
abstract class WebStorageHelper {
  static void write(String key, String value) {}
  static String? read(String key) => null;
  static void delete(String key) {}
  static void deleteAll() {}
}
