import 'package:flutter/widgets.dart';

/// Mixin for game screens that need to pause/resume on app lifecycle changes.
///
/// Mix into any State that has timers, audio, or animations that should
/// pause when the app is backgrounded.
mixin AppLifecycleGameMixin<T extends StatefulWidget> on State<T> {
  AppLifecycleListener? _lifecycleListener;

  /// Override to pause game timers, audio, etc.
  void onGamePaused() {}

  /// Override to resume game timers, audio, etc.
  void onGameResumed() {}

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onStateChange: _handleStateChange,
    );
  }

  void _handleStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        onGamePaused();
      case AppLifecycleState.resumed:
        onGameResumed();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }
}
