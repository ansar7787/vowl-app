import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_tts_helper.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/pages/synonym_search_learn_screen.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_contrast_swap_card.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_translatable_block.dart';

class _MockTtsService extends Mock implements TtsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockTtsService mockTts;

  setUp(() async {
    await di.sl.reset();
    mockTts = _MockTtsService();
    when(
      () => mockTts.isSpeakingNotifier,
    ).thenReturn(ValueNotifier<bool>(false));
    when(() => mockTts.isSpeaking).thenReturn(false);
    when(() => mockTts.engineStatus).thenReturn(TtsEngineStatus.ready);
    when(
      () => mockTts.preWarm(
        locale: any(named: 'locale'),
        preset: any(named: 'preset'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockTts.stop()).thenAnswer((_) async {});
    when(
      () => mockTts.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
        pauseMarkers: any(named: 'pauseMarkers'),
        forcedPreset: any(named: 'forcedPreset'),
      ),
    ).thenAnswer((_) async {});
    di.sl.registerSingleton<TtsService>(mockTts);
  });

  tearDown(() async {
    await di.sl.reset();
  });

  Widget wrapScreen(Widget screen) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, _) =>
          MaterialApp(theme: AppTheme.lightTheme, home: screen),
    );
  }

  Widget wrapCard(Widget child) =>
      wrapScreen(Scaffold(body: SingleChildScrollView(child: child)));

  group('SynonymTranslatableArea & Bilingual TTS Pre-warming', () {
    test(
      'SynonymTtsHelper.preWarm warms en-US by default and target locale on demand',
      () {
        SynonymTtsHelper.preWarm();
        SynonymTtsHelper.preWarm(locale: 'es-ES');

        verify(() => mockTts.preWarm(locale: 'en-US')).called(1);
        verify(() => mockTts.preWarm(locale: 'es-ES')).called(1);
      },
    );

    testWidgets(
      'pre-warms translated locale, speaks translated audio, and toggles back to English',
      (tester) async {
        String sourceText = 'The depot stores a large amount of winter stock.';
        late StateSetter outerSetState;

        await tester.pumpWidget(
          wrapCard(
            StatefulBuilder(
              builder: (context, setState) {
                outerSetState = setState;
                return SynonymTranslatableArea(
                  textToTranslate: sourceText,
                  primaryColor: Colors.indigo,
                  builder: (context, translateAction, banner) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(sourceText)),
                          translateAction,
                        ],
                      ),
                      ?banner,
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();

        final btn = tester.widget<TranslateButtonWidget>(
          find.byType(TranslateButtonWidget),
        );
        btn.onTranslationWithLanguage?.call(
          'El depósito guarda una gran cantidad de existencias.',
          'es-ES',
        );
        await tester.pump();

        // Translated locale should be pre-warmed immediately for budget devices.
        verify(() => mockTts.preWarm(locale: 'es-ES')).called(1);
        expect(
          find.text('El depósito guarda una gran cantidad de existencias.'),
          findsOneWidget,
        );
        expect(find.text('Original (EN)'), findsOneWidget);

        // Translated speaker uses target native locale.
        final speakerFinder = find.byType(TtsSpeakerButtonWidget);
        expect(speakerFinder, findsOneWidget);
        final speakerWidget = tester.widget<TtsSpeakerButtonWidget>(
          speakerFinder,
        );
        expect(speakerWidget.locale, 'es-ES');

        await tester.tap(speakerFinder);
        await tester.pump();
        verify(
          () => mockTts.speak(
            'El depósito guarda una gran cantidad de existencias.',
            locale: 'es-ES',
          ),
        ).called(1);

        // Switching back to English re-warms en-US and keeps cached toggle ready.
        await tester.tap(find.text('Original (EN)'));
        await tester.pump();
        verify(() => mockTts.preWarm(locale: 'en-US')).called(1);
        expect(find.text('Original (EN)'), findsNothing);
        expect(find.text('Translated'), findsOneWidget);

        // One-tap toggle returns to cached translation without re-translating.
        await tester.tap(find.text('Translated'));
        await tester.pump();
        expect(
          find.text('El depósito guarda una gran cantidad de existencias.'),
          findsOneWidget,
        );

        // Changing sourceText resets translation state and drops stale callbacks.
        outerSetState(() {
          sourceText = 'Another pair explanation sentence.';
        });
        await tester.pump();
        btn.onTranslationWithLanguage?.call('Stale text', 'es-ES');
        await tester.pump();
        expect(find.text('Stale text'), findsNothing);
        expect(find.byType(TranslateButtonWidget), findsOneWidget);
        expect(find.text('Original (EN)'), findsNothing);
      },
    );

    testWidgets(
      'Learn screen & Practice cards expose translation triggers on all clue sections',
      (tester) async {
        await tester.pumpWidget(
          wrapScreen(
            SynonymSearchLearnScreen(
              level: 1,
              initialItems: [SynonymLearnItem.fallback(1)],
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        // 1 Spotlight header + 2 Makeover cards = 3 TranslateButtonWidgets initially.
        expect(find.byType(TranslateButtonWidget), findsNWidgets(3));

        // Opening a cousin word adds a 4th TranslateButtonWidget for cousin context.
        await tester.ensureVisible(find.byKey(const Key('cousin_chip_0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('cousin_chip_0')));
        await tester.pump();
        expect(find.byType(TranslateButtonWidget), findsNWidgets(4));

        // Practice Contrast Swap exposes translate buttons on prompt + 2 slot cards.
        final ex = SynonymPracticeQuest.fallbackExercises(1).first;
        await tester.pumpWidget(
          wrapCard(
            SynonymContrastSwapCard(
              exercise: ex,
              assignments: const [null, null],
              focusedSlotIndex: 0,
              hasChecked: false,
              isCorrect: false,
              showHint: true,
              shakeCount: 0,
              feedbackMessage: null,
              primaryColor: Colors.indigo,
              onTapSlot: (_) {},
              onAssignWord: (_) {},
            ),
          ),
        );
        await tester.pump();
        // 1 prompt + 2 slot sentences + 1 hint banner = 4 TranslateButtonWidgets.
        expect(find.byType(TranslateButtonWidget), findsNWidgets(4));
      },
    );
  });
}
