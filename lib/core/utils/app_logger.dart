import 'package:flutter/foundation.dart';

/// Thin logging abstraction.
///
/// Inject [DebugAppLogger] in development/test and swap to a
/// [FirebaseCrashReporter] (or similar) in production without touching
/// any call site.
///
/// Usage:
/// ```dart
/// _logger.error('Save failed', error: e, stackTrace: st, tag: 'SpeakingBloc');
/// ```
abstract class AppLogger {
  void debug(String message, {String? tag});
  void warning(String message, {String? tag});
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  });
}

/// Default logger — writes to the Flutter debug console.
/// Replace with a crash-reporting implementation before production.
///
/// Example production implementation:
/// ```dart
/// class FirebaseAppLogger implements AppLogger {
///   @override
///   void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
///     FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
///   }
/// }
/// ```
class DebugAppLogger implements AppLogger {
  const DebugAppLogger();

  static const _reset = '\x1B[0m';
  static const _cyan = '\x1B[36m';
  static const _yellow = '\x1B[33m';
  static const _red = '\x1B[31m';

  @override
  void debug(String message, {String? tag}) {
    debugPrint('$_cyan[${tag ?? 'APP'}] $message$_reset');
  }

  @override
  void warning(String message, {String? tag}) {
    debugPrint('$_yellow[${tag ?? 'APP'}][WARN] $message$_reset');
  }

  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    debugPrint('$_red[${tag ?? 'APP'}][ERROR] $message$_reset');
    if (error != null) debugPrint('  Cause: $error');
    if (stackTrace != null) debugPrint('  Stack:\n$stackTrace');
  }
}
