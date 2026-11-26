import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/synonym_search/data/datasources/synonym_weak_words_store.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/pages/synonym_search_learn_screen.dart';

class _MockTtsService extends Mock implements TtsService {}

class _DelayedAssetBundle extends CachingAssetBundle {
  final String payload;
  final Duration delay;
  final bool shouldThrow;

  _DelayedAssetBundle({
    required this.payload,
    this.delay = Duration.zero,
    this.shouldThrow = false,
  });

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (shouldThrow) {
      throw StateError('Asset load failed');
    }
    return payload;
  }

  @override
  Future<ByteData> load(String key) async {
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(payload)));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({});
    await SynonymWeakWordsStore.resetForTest();
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Widget wrapScreen(Widget screen) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, _) =>
          MaterialApp(theme: AppTheme.lightTheme, home: screen),
    );
  }

  group('SynonymSearchLearnScreen', () {
    testWidgets(
      'shows GameShimmerLoading (never CircularProgressIndicator) then renders Level 1 JSON',
      (tester) async {
        final raw = File(
          'assets/curriculum/vocabulary/synonymSearch_learn_1_10.json',
        ).readAsStringSync();
        final delayedBundle = _DelayedAssetBundle(
          payload: raw,
          delay: const Duration(milliseconds: 80),
        );

        await tester.pumpWidget(
          wrapScreen(
            SynonymSearchLearnScreen(level: 1, assetBundle: delayedBundle),
          ),
        );
        await tester.pump();

        expect(find.byType(GameShimmerLoading), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.pump(const Duration(milliseconds: 120));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Big'), findsWidgets);
        expect(find.text('Large'), findsWidgets);
        expect(find.text('Checked 0/2'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
      },
    );

    testWidgets(
      'taps makeover slot for live swap verdict, checks cousin preview, supports Previous and Go to Practice',
      (tester) async {
        String? pushedLocation;
        final item1 = SynonymLearnItem.fallback(1);
        final item2 = SynonymLearnItem(
          id: 'L1_PAIR_2',
          level: 1,
          cefr: 'A2',
          difficulty: 1,
          pairTitle: 'Happy ↔ Glad',
          baseWord: 'Happy',
          synonym: 'Glad',
          partOfSpeech: 'Adjective',
          coreMeaning: 'Pleased about something.',
          whyDifferent: 'Glad often precedes "to" or "that".',
          makeovers: const [
            SynonymMakeoverScenario(
              situationTag: 'Polite Reply',
              beforeSentence: 'I am ___ to help you today.',
              targetSlotWord: 'happy',
              swappedWord: 'glad',
              isNaturalSwap: true,
              earVerdict: 'Natural & Warm — glad to help sounds effortless.',
              spokenSentence: 'I am glad to help you today.',
            ),
          ],
          cousinWords: const [
            SynonymCousinWord(
              word: 'Cheerful',
              ipa: '/ˈtʃɪrfəl/',
              toneTag: 'Bright',
              miniContext: 'A cheerful greeting started our morning.',
            ),
          ],
        );

        final router = GoRouter(
          initialLocation: '/learn',
          routes: [
            GoRoute(
              path: '/learn',
              builder: (_, _) => SynonymSearchLearnScreen(
                level: 1,
                initialItems: [item1, item2],
              ),
            ),
            GoRoute(
              path: '/practice',
              builder: (_, state) {
                pushedLocation = state.uri.toString();
                return const Scaffold(body: Text('Practice Route'));
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            builder: (context, _) => MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: router,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Toggle Read aloud chip
        expect(find.text('Read aloud'), findsOneWidget);
        await tester.ensureVisible(
          find.byKey(const Key('learn_auto_speak_toggle')),
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('learn_auto_speak_toggle')));
        await tester.pump();
        expect(find.text('Read aloud on'), findsOneWidget);

        // Soft gate blocks advancement before trying an example
        expect(find.text('Check 1 Example'), findsOneWidget);

        // Tap first makeover slot to swap big -> large
        await tester.ensureVisible(find.byKey(const Key('makeover_slot_0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('makeover_slot_0')));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Sounds natural'), findsWidgets);
        expect(find.text('Checked 1/2'), findsOneWidget);
        expect(find.text('Next Pair'), findsOneWidget);

        // Tap cousin chip
        await tester.ensureVisible(find.byKey(const Key('cousin_chip_0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('cousin_chip_0')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('A huge crowd cheered outside.'), findsOneWidget);

        // Navigate to Pair 2 and verify Previous icon button appears
        await tester.tap(find.text('Next Pair'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Happy'), findsWidgets);
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
        expect(find.text('Check 1 Example'), findsOneWidget);

        // Predict natural on Pair 2 to unlock Start Practice
        await tester.ensureVisible(find.byKey(const Key('predict_natural_0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('predict_natural_0')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Start Practice'), findsOneWidget);

        // Test Previous returns to Pair 1
        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Big'), findsWidgets);

        // Advance back to final pair and pushReplacement to Practice
        await tester.tap(find.text('Next Pair'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Start Practice'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          pushedLocation,
          '/practice?category=vocabulary&gameType=synonymSearch&level=1',
        );
        expect(find.text('Practice Route'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
      },
    );

    testWidgets('shows GameErrorView when bundle load fails cleanly', (
      tester,
    ) async {
      final failingBundle = _DelayedAssetBundle(
        payload: '{}',
        shouldThrow: true,
      );

      await tester.pumpWidget(
        wrapScreen(
          SynonymSearchLearnScreen(level: 1, assetBundle: failingBundle),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Could not load Level 1 lessons.'), findsOneWidget);
      expect(find.text('Use Sample Lesson'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets(
      'Read aloud uses DI TtsService on toggle, sentence swap, and related word tap',
      (tester) async {
        await di.sl.reset();
        final mockTts = _MockTtsService();
        when(
          () => mockTts.isSpeakingNotifier,
        ).thenReturn(ValueNotifier<bool>(false));
        when(() => mockTts.isSpeaking).thenReturn(false);
        when(
          () => mockTts.preWarm(locale: any(named: 'locale')),
        ).thenAnswer((_) async {});
        when(() => mockTts.stop()).thenAnswer((_) async {});
        when(
          () => mockTts.speak(
            any(),
            rate: any(named: 'rate'),
            locale: any(named: 'locale'),
          ),
        ).thenAnswer((_) async {});
        di.sl.registerSingleton<TtsService>(mockTts);
        addTearDown(() async => di.sl.reset());

        await tester.pumpWidget(
          wrapScreen(
            SynonymSearchLearnScreen(
              level: 1,
              initialItems: [SynonymLearnItem.fallback(1)],
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        verify(() => mockTts.preWarm(locale: any(named: 'locale'))).called(1);

        await tester.ensureVisible(
          find.byKey(const Key('learn_auto_speak_toggle')),
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('learn_auto_speak_toggle')));
        await tester.pump();
        verify(
          () => mockTts.speak(any(that: contains('Big. Large.'))),
        ).called(1);

        await tester.ensureVisible(find.byKey(const Key('makeover_slot_0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('makeover_slot_0')));
        await tester.pump();
        verify(
          () =>
              mockTts.speak('The depot stores a large amount of winter stock.'),
        ).called(1);

        await tester.ensureVisible(find.byKey(const Key('cousin_chip_0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('cousin_chip_0')));
        await tester.pump();
        verify(
          () => mockTts.speak('Huge. A huge crowd cheered outside.'),
        ).called(1);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
        verify(() => mockTts.stop()).called(greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      'appends 1 review pair from SynonymWeakWordsStore when prior misses exist',
      (tester) async {
        await SynonymWeakWordsStore.recordWeakPair(
          level: 1,
          baseWord: 'Big',
          synonym: 'Large',
        );
        final raw1_10 = File(
          'assets/curriculum/vocabulary/synonymSearch_learn_1_10.json',
        ).readAsStringSync();
        final bundle = _DelayedAssetBundle(payload: raw1_10);

        await tester.pumpWidget(
          wrapScreen(SynonymSearchLearnScreen(level: 2, assetBundle: bundle)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Level 2 has 3 pairs + 1 injected weak review pair from Level 1 -> (1/4)
        expect(find.text('Word Examples (1/4)'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
  });
}
