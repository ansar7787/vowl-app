import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/tts_voice_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TtsVoicePreset', () {
    test('fromId returns matching preset or fallback', () {
      expect(
        TtsVoicePreset.fromId('friendly_teacher'),
        equals(TtsVoicePreset.friendlyTeacher),
      );
      expect(
        TtsVoicePreset.fromId('clear_guide'),
        equals(TtsVoicePreset.clearGuide),
      );
      expect(
        TtsVoicePreset.fromId('british_accent'),
        equals(TtsVoicePreset.britishAccent),
      );
      expect(
        TtsVoicePreset.fromId('system_default'),
        equals(TtsVoicePreset.systemDefault),
      );
      expect(
        TtsVoicePreset.fromId('unknown_id'),
        equals(TtsVoicePreset.friendlyTeacher),
      );
      expect(
        TtsVoicePreset.fromId(null),
        equals(TtsVoicePreset.friendlyTeacher),
      );
    });

    test('getSampleSentence returns non-empty friendly text for all presets', () {
      for (final preset in TtsVoicePreset.values) {
        final sample = TtsVoiceHelper.getSampleSentence(preset);
        expect(sample, isNotEmpty);
        expect(sample.contains('Hello'), isTrue);
      }
    });
  });

  group('TtsVoiceHelper persistence', () {
    test('savePreset and getSavedPreset round-trip via SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});

      // Defaults to friendlyTeacher when not set
      expect(
        await TtsVoiceHelper.getSavedPreset(),
        equals(TtsVoicePreset.friendlyTeacher),
      );

      // Save clearGuide
      await TtsVoiceHelper.savePreset(TtsVoicePreset.clearGuide);
      expect(
        await TtsVoiceHelper.getSavedPreset(),
        equals(TtsVoicePreset.clearGuide),
      );

      // Save britishAccent
      await TtsVoiceHelper.savePreset(TtsVoicePreset.britishAccent);
      expect(
        await TtsVoiceHelper.getSavedPreset(),
        equals(TtsVoicePreset.britishAccent),
      );
    });
  });
}
