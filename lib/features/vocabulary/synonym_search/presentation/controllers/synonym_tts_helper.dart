import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';

/// Defensive wrapper around the DI-registered [TtsService] singleton.
///
/// Ensures Learn, Practice, and Mastery screens share the app's configured
/// [TtsService] instance (instead of spawning new native engines) and stops
/// any active [TtsSpeakerButtonWidget] session cleanly before speaking or leaving.
class SynonymTtsHelper {
  const SynonymTtsHelper._();

  static TtsService? _resolve() {
    try {
      return di.sl.isRegistered<TtsService>() ? di.sl<TtsService>() : null;
    } catch (_) {
      return null;
    }
  }

  static void preWarm() {
    try {
      _resolve()?.preWarm();
    } catch (_) {}
  }

  static void stopAll() {
    try {
      TtsSpeakerButtonWidget.stopAll();
      _resolve()?.stop();
    } catch (_) {}
  }

  static void speak(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      TtsSpeakerButtonWidget.stopAll();
      _resolve()?.speak(trimmed);
    } catch (_) {}
  }
}
