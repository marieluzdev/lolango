import 'package:flutter/foundation.dart';

class AppLogger {
  static void d(String message) {
    if (kDebugMode) print('[DEBUG] $message');
  }

  static void i(String message) {
    if (kDebugMode) print('[INFO] $message');
  }

  static void w(String message) {
    if (kDebugMode) print('[WARN] $message');
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('[ERROR] $message');
      if (error != null) print('Error: $error');
      if (stackTrace != null) print('Stack: $stackTrace');
    }
  }
}
