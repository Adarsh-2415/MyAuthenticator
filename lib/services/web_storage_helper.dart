// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation for persistent local storage in web browsers.
abstract class WebStorageHelper {
  static void write(String key, String value) {
    try {
      html.window.localStorage[key] = value;
    } catch (_) {}
  }

  static String? read(String key) {
    try {
      return html.window.localStorage[key];
    } catch (_) {
      return null;
    }
  }

  static void delete(String key) {
    try {
      html.window.localStorage.remove(key);
    } catch (_) {}
  }

  static void deleteAll() {
    try {
      html.window.localStorage.clear();
    } catch (_) {}
  }
}
