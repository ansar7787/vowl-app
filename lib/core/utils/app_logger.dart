import 'package:flutter/foundation.dart';

/// Thin logging abstraction that decouples call sites from any specific
/// logging backend.
///
/// ### Dependency injection
/// [AppLogger] is registered as a `LazyRegistration` in `di_core.dart`.
/// Inject it via the constructor of any service that needs structured logging:
/// ```dart
/// class MyService {
///   final AppLogger _log;
///   MyService(this._log);
///
///   void doWork() {
///     _log.debug('Starting work', tag: 'MyService');
///   }
/// }
/// ```
///
/// ### Swapping implementations
/// Development uses [DebugAppLogger] (coloured console output).
/// Production should use a crash-reporting backend — see [ProductionAppLogger]
/// stub below for the recommended Crashlytics implementation.
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

// ---------------------------------------------------------------------------
// Debug implementation — registered in development via di_core.dart
// ---------------------------------------------------------------------------

/// Writes structured, colour-coded log lines to the Flutter debug console.
///
/// Colours use ANSI escape codes and render correctly in most modern
/// terminals (Android Studio, VS Code, macOS Terminal). On Windows cmd.exe
/// without ANSI enabled they appear as raw escape sequences; use Windows
/// Terminal or VS Code instead.
///
/// This implementation is a no-op in release builds because [debugPrint]
/// compiles out when `assert`s are disabled, but the method bodies still
/// execute. For zero-overhead in production, use [ProductionAppLogger].
class DebugAppLogger implements AppLogger {
  const DebugAppLogger();

  static const _reset = '\x1B[0m';
  static const _cyan = '\x1B[36m';
  static const _yellow = '\x1B[33m';
  static const _red = '\x1B[31m';

  @override
  void debug(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('$_cyan[${tag ?? 'APP'}] $message$_reset');
    }
  }

  @override
  void warning(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('$_yellow[${tag ?? 'APP'}][WARN] $message$_reset');
    }
  }

  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (kDebugMode) {
      debugPrint('$_red[${tag ?? 'APP'}][ERROR] $message$_reset');
      if (error != null) debugPrint('  Cause: $error');
      if (stackTrace != null) debugPrint('  Stack:\n$stackTrace');
    }
  }
}

// ---------------------------------------------------------------------------
// Production stub — swap in via di_core.dart before shipping
// ---------------------------------------------------------------------------

/// Production logger backed by Firebase Crashlytics.
///
/// ### Setup
/// 1. Ensure `firebase_crashlytics` is in pubspec.yaml.
/// 2. In `di_core.dart`, replace:
///    ```dart
///    sl.registerLazySingleton<AppLogger>(() => const DebugAppLogger());
///    ```
///    with:
///    ```dart
///    sl.registerLazySingleton<AppLogger>(() => const ProductionAppLogger());
///    ```
///
/// Warnings and debug lines are logged as Crashlytics non-fatal breadcrumbs.
/// Errors are recorded as non-fatal exceptions with full stack traces.
///
/// This class is intentionally commented out to avoid importing
/// firebase_crashlytics in files that don't need it. Uncomment and move
/// to its own file when integrating.
//
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
//
// class ProductionAppLogger implements AppLogger {
//   const ProductionAppLogger();
//
//   @override
//   void debug(String message, {String? tag}) {
//     FirebaseCrashlytics.instance.log('[${tag ?? 'APP'}] $message');
//   }
//
//   @override
//   void warning(String message, {String? tag}) {
//     FirebaseCrashlytics.instance.log('[${tag ?? 'APP'}][WARN] $message');
//   }
//
//   @override
//   void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
//     FirebaseCrashlytics.instance.log('[${tag ?? 'APP'}][ERROR] $message');
//     if (error != null) {
//       FirebaseCrashlytics.instance.recordError(
//         error,
//         stackTrace,
//         reason: message,
//         fatal: false,
//       );
//     }
//   }
// }
