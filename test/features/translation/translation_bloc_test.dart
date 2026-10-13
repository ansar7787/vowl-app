import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:vowl/core/utils/translation_service.dart';
import 'package:vowl/features/translation/presentation/bloc/translation_bloc.dart';

class MockTranslationService extends Mock implements TranslationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTranslationService mockService;
  late TranslationBloc bloc;

  setUpAll(() {
    registerFallbackValue(TranslateLanguage.english);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'translation_free_remaining': 3,
      'translation_last_reset_date': DateTime.now().toIso8601String(),
    });
    mockService = MockTranslationService();
    bloc = TranslationBloc(service: mockService);
  });

  tearDown(() {
    bloc.close();
  });

  group('TranslationBloc Tests', () {
    test('initial state is correct', () {
      expect(bloc.state.status, TranslationStatus.initial);
      expect(bloc.state.sourceText, '');
      expect(bloc.state.translatedText, '');
      expect(bloc.state.currentSourceLanguage, 'English');
      expect(bloc.state.freeTranslationsRemaining, 3);
      expect(bloc.state.isTranslating, false);
      expect(bloc.state.isLimitReached, false);
    });

    test('TranslationInitRequested loads configured languages and state', () async {
      when(() => mockService.getConfiguredSourceLanguageName())
          .thenAnswer((_) async => 'English');
      when(() => mockService.getConfiguredLanguageName())
          .thenAnswer((_) async => 'Spanish');
      when(() => mockService.getDownloadedLanguageNames())
          .thenAnswer((_) async => ['Spanish']);

      bloc.add(TranslationInitRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<TranslationState>().having((s) => s.status, 'status', TranslationStatus.loading),
          isA<TranslationState>()
              .having((s) => s.status, 'status', TranslationStatus.loaded)
              .having((s) => s.currentSourceLanguage, 'source', 'English')
              .having((s) => s.currentTargetLanguage, 'target', 'Spanish')
              .having((s) => s.downloadedLanguages, 'downloaded', ['Spanish'])
              .having((s) => s.freeTranslationsRemaining, 'remaining', 3),
        ]),
      );
    });

    test('TranslationTextChanged with empty text resets translated text', () async {
      bloc.add(const TranslationTextChanged(''));

      await expectLater(
        bloc.stream,
        emits(
          isA<TranslationState>()
              .having((s) => s.sourceText, 'sourceText', '')
              .having((s) => s.translatedText, 'translatedText', '')
              .having((s) => s.isTranslating, 'isTranslating', false),
        ),
      );
    });

    test('TranslationTextChanged translates when text >= 2 characters', () async {
      when(() => mockService.getConfiguredSourceLanguageName())
          .thenAnswer((_) async => 'English');
      when(() => mockService.getConfiguredLanguageName())
          .thenAnswer((_) async => 'Spanish');
      when(() => mockService.getDownloadedLanguageNames())
          .thenAnswer((_) async => ['Spanish']);
      when(() => mockService.translate(
            'Hello',
            sourceLanguage: any(named: 'sourceLanguage'),
            targetLanguage: any(named: 'targetLanguage'),
          )).thenAnswer((_) async => 'Hola');

      bloc.add(TranslationInitRequested());
      await pumpEventQueue();

      bloc.add(const TranslationTextChanged('Hello', isPremium: true));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<TranslationState>()
              .having((s) => s.sourceText, 'sourceText', 'Hello')
              .having((s) => s.isTranslating, 'isTranslating', true),
          isA<TranslationState>()
              .having((s) => s.translatedText, 'translatedText', 'Hola')
              .having((s) => s.isTranslating, 'isTranslating', false),
        ]),
      );
    });

    test('TranslationSwapLanguages swaps source and target languages', () async {
      when(() => mockService.getConfiguredSourceLanguageName())
          .thenAnswer((_) async => 'English');
      when(() => mockService.getConfiguredLanguageName())
          .thenAnswer((_) async => 'Spanish');
      when(() => mockService.getDownloadedLanguageNames())
          .thenAnswer((_) async => ['Spanish']);
      when(() => mockService.setLanguages(
            source: any(named: 'source'),
            target: any(named: 'target'),
          )).thenAnswer((_) async {});
      when(() => mockService.translate(
            any(),
            sourceLanguage: any(named: 'sourceLanguage'),
            targetLanguage: any(named: 'targetLanguage'),
          )).thenAnswer((_) async => 'Hello');

      bloc.add(TranslationInitRequested());
      await pumpEventQueue();

      bloc.add(const TranslationSwapLanguages(isPremium: true));

      await expectLater(
        bloc.stream,
        emits(
          isA<TranslationState>()
              .having((s) => s.currentSourceLanguage, 'source', 'Spanish')
              .having((s) => s.currentTargetLanguage, 'target', 'English'),
        ),
      );
    });

    test('TranslationAdWatched resets remaining tokens and limit', () async {
      bloc.add(TranslationAdWatched());

      await expectLater(
        bloc.stream,
        emits(
          isA<TranslationState>()
              .having((s) => s.freeTranslationsRemaining, 'remaining', 3)
              .having((s) => s.isLimitReached, 'limitReached', false),
        ),
      );
    });
  });
}

