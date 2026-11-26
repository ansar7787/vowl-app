import 'dart:async';

import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';

/// Defensive wrapper around the DI-registered [TtsService] singleton.
///
/// Pre-warms both the default English voice and any translated native-language
/// locale asynchronously so budget devices avoid first-tap synthesis stalls.
class SynonymTtsHelper {
  const SynonymTtsHelper._();

  static TtsService? _resolve() {
    try {
      return di.sl.isRegistered<TtsService>() ? di.sl<TtsService>() : null;
    } catch (_) {
      return null;
    }
  }

  /// Pre-warms the native TTS engine non-blockingly for [locale].
  static void preWarm({String? locale = 'en-US'}) {
    try {
      final service = _resolve();
      if (service == null) return;
      final normalized = locale?.trim();
      unawaited(
        service.preWarm(
          locale: (normalized != null && normalized.isNotEmpty)
              ? normalized
              : 'en-US',
        ),
      );
    } catch (_) {}
  }

  static void stopAll() {
    try {
      TtsSpeakerButtonWidget.stopAll();
      _resolve()?.stop();
    } catch (_) {}
  }

  static void speak(String text, {String? locale}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      TtsSpeakerButtonWidget.stopAll();
      _resolve()?.speak(trimmed, locale: locale);
    } catch (_) {}
  }
}
