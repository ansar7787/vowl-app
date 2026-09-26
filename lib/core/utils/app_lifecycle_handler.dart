import 'package:flutter/widgets.dart';

/// Helper to handle application lifecycle events (pausing/resuming timers, audio, etc.).
class AppLifecycleHandler {
  AppLifecycleHandler._();

  static AppLifecycleListener createListener({
    VoidCallback? onPause,
    VoidCallback? onResume,
    VoidCallback? onDetach,
  }) {
    return AppLifecycleListener(
      onStateChange: (state) {
        switch (state) {
          case AppLifecycleState.inactive:
          case AppLifecycleState.paused:
          case AppLifecycleState.hidden:
            onPause?.call();
            break;
          case AppLifecycleState.resumed:
            onResume?.call();
            break;
          case AppLifecycleState.detached:
            onDetach?.call();
            break;
        }
      },
    );
  }
}

/// Mixin for game screens or stateful widgets that need to pause/resume on app lifecycle changes.
mixin AppLifecycleGameMixin<T extends StatefulWidget> on State<T> {
  AppLifecycleListener? _lifecycleListener;

  /// Override to pause game timers, audio, etc.
  void onGamePaused() {}

  /// Override to resume game timers, audio, etc.
  void onGameResumed() {}

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleHandler.createListener(
      onPause: onGamePaused,
      onResume: onGameResumed,
    );
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }
}
