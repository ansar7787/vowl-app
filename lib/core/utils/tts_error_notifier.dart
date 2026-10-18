import 'package:flutter/foundation.dart';

/// Categories of TTS errors for user-actionable messaging.
enum TtsErrorType {
  /// TTS engine not installed on device.
  noEngine,

  /// TTS engine failed to initialize.
  initFailed,

  /// TTS speak call failed at runtime.
  speakFailed,

  /// TTS timed out (engine hung/crashed).
  timeout,
}

/// A TTS error event with enough context to show actionable UI messages.
class TtsError {
  final TtsErrorType type;
  final String userMessage;
  final DateTime timestamp;

  TtsError({
    required this.type,
    required this.userMessage,
  }) : timestamp = DateTime.now();

  @override
  String toString() => 'TtsError($type: $userMessage)';
}

/// Global notifier for TTS errors that UI widgets can listen to.
///
/// This is a singleton — access via [TtsErrorNotifier.instance].
/// Widgets should listen and show snackbars/toasts when errors fire.
class TtsErrorNotifier {
  TtsErrorNotifier._();

  static final TtsErrorNotifier instance = TtsErrorNotifier._();

  final ValueNotifier<TtsError?> _errorNotifier = ValueNotifier<TtsError?>(null);

  /// Listen to this notifier for TTS error events.
  ValueNotifier<TtsError?> get errorNotifier => _errorNotifier;

  /// Reports a TTS error to all listening UI widgets.
  void report(TtsErrorType type, {String? customMessage}) {
    final message = customMessage ?? _defaultMessage(type);
    _errorNotifier.value = TtsError(type: type, userMessage: message);
  }

  /// Clears the current error (after UI has displayed it).
  void clear() {
    _errorNotifier.value = null;
  }

  static String _defaultMessage(TtsErrorType type) {
    switch (type) {
      case TtsErrorType.noEngine:
        return 'No text-to-speech engine found. Please install one from your device settings.';
      case TtsErrorType.initFailed:
        return 'Text-to-speech could not start. Try restarting the app.';
      case TtsErrorType.speakFailed:
        return 'Could not play audio. Please try again.';
      case TtsErrorType.timeout:
        return 'Audio playback timed out. Please try again.';
    }
  }
}
