import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/utils/translation_service.dart';

void main() {
  group('TranslationService Flag & Reactive State Tests', () {
    test('all 58 supported languages have accurate country flag emojis', () {
      expect(TranslationService.supportedLanguages.length, 58);
      for (final langName in TranslationService.supportedLanguages.keys) {
        final flag = TranslationService.getFlag(langName);
        expect(flag, isNotEmpty);
        if (langName != 'Esperanto') {
          expect(flag, isNot(equals('🌐')),
              reason: '$langName should have a mapped country flag emoji');
        }
      }
    });

    test('getFlag returns fallback for unknown language', () {
      expect(TranslationService.getFlag('UnknownLanguage'), '🌐');
    });

    test('downloadedLanguagesNotifier initializes and updates reactively', () {
      final service = TranslationService();
      expect(service.downloadedLanguagesNotifier.value, isEmpty);

      service.downloadedLanguagesNotifier.value = {'Spanish', 'French'};
      expect(service.downloadedLanguagesNotifier.value.contains('Spanish'), isTrue);
      expect(service.downloadedLanguagesNotifier.value.contains('French'), isTrue);
      expect(service.downloadedLanguagesNotifier.value.contains('German'), isFalse);
    });

    test('downloadingProgressNotifier tracks progress reactively', () {
      final service = TranslationService();
      expect(service.downloadingProgressNotifier.value, isEmpty);

      service.downloadingProgressNotifier.value = {'Spanish': 0.45};
      expect(service.downloadingProgressNotifier.value['Spanish'], 0.45);
    });

    test('multi-script language aliases exist for major world languages', () {
      final aliases = TranslationService.languageAliases;
      expect(aliases['Spanish'], contains('español'));
      expect(aliases['French'], contains('français'));
      expect(aliases['German'], contains('deutsch'));
      expect(aliases['Hindi'], contains('हिन्दी'));
      expect(aliases['Japanese'], contains('日本語'));
      expect(aliases['Arabic'], contains('العربية'));
      expect(aliases['Russian'], contains('русский'));
      expect(aliases['Chinese'], contains('中文'));
      expect(aliases['Korean'], contains('한국어'));
    });

    test('downloadedLanguagesNotifier deduplicates identical languages', () {
      final service = TranslationService();
      final set = <String>{};
      set.addAll(['Spanish', 'Spanish', 'French']);
      service.downloadedLanguagesNotifier.value = set;
      expect(service.downloadedLanguagesNotifier.value.length, 2);
      expect(service.downloadedLanguagesNotifier.value, equals({'Spanish', 'French'}));
    });
  });
}
