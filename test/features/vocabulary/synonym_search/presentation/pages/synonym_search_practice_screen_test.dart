import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/vocabulary/synonym_search/data/datasources/synonym_weak_words_store.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/pages/synonym_search_practice_screen.dart';

class _TestPracticeBundle extends CachingAssetBundle {
  final String payload;
  final Duration delay;
  final bool shouldThrow;

  _TestPracticeBundle({
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
      throw StateError('Practice asset failure');
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

  Future<void> tapWithScroll(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('SynonymSearchPracticeScreen', () {
    testWidgets(
      'displays GameShimmerLoading while loading then renders interleaved exercises',
      (tester) async {
        final raw = File(
          'assets/curriculum/vocabulary/synonymSearch_practice_1_10.json',
        ).readAsStringSync();
        final bundle = _TestPracticeBundle(
          payload: raw,
          delay: const Duration(milliseconds: 80),
        );

        await tester.pumpWidget(
          wrapScreen(
            SynonymSearchPracticeScreen(level: 1, assetBundle: bundle),
          ),
        );
        await tester.pump();

        expect(find.byType(GameShimmerLoading), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.pump(const Duration(milliseconds: 120));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Choose the word • A2'), findsOneWidget);
        expect(find.text('Big'), findsOneWidget);
        expect(find.text('Large'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
      },
    );

    testWidgets(
      'supports wrong retry, guided reveal after 2 misses, ladder solving, and route completion',
      (tester) async {
        String? pushedRoute;
        final exercises = SynonymPracticeQuest.fallbackExercises(1);

        final router = GoRouter(
          initialLocation: '/practice',
          routes: [
            GoRoute(
              path: '/practice',
              builder: (_, _) => SynonymSearchPracticeScreen(
                level: 1,
                initialExercises: exercises,
              ),
            ),
            GoRoute(
              path: '/game',
              builder: (_, state) {
                pushedRoute = state.uri.toString();
                return const Scaffold(body: Text('Mastery Blitz Route'));
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

        // Miss #1: place Large into slot 0 (needs Big), Big into slot 1 (needs Large)
        await tapWithScroll(
          tester,
          find.byKey(const Key('contrast_bank_word_1')),
        );
        await tapWithScroll(
          tester,
          find.byKey(const Key('contrast_bank_word_0')),
        );

        await tester.tap(find.text('Check Answer'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Tap a blank to change it'), findsOneWidget);

        // Clear slot 0 & re-assign wrong word for Miss #2 -> test 1-tap Swap button too
        await tapWithScroll(tester, find.byKey(const Key('contrast_slot_0')));
        await tapWithScroll(
          tester,
          find.byKey(const Key('contrast_bank_word_1')),
        );
        await tapWithScroll(
          tester,
          find.byKey(const Key('contrast_swap_both_btn')),
        );
        await tapWithScroll(
          tester,
          find.byKey(const Key('contrast_swap_both_btn')),
        );
        await tester.tap(find.text('Check Answer'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Show Answer'), findsOneWidget);

        // Reveal guided solution cleanly
        await tester.tap(find.text('Show Answer'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Next Question'), findsOneWidget);

        // Advance to Word order exercise
        await tester.tap(find.text('Next Question'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Word order • A2'), findsOneWidget);

        // Place ordered ladder: shuffledWords = ['Massive', 'Big', 'Huge']
        await tapWithScroll(
          tester,
          find.byKey(const Key('ladder_bank_word_1')),
        ); // Big
        await tapWithScroll(
          tester,
          find.byKey(const Key('ladder_bank_word_2')),
        ); // Huge
        await tapWithScroll(
          tester,
          find.byKey(const Key('ladder_bank_word_0')),
        ); // Massive

        await tester.tap(find.text('Check Answer'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Start Challenge'), findsOneWidget);

        await tester.tap(find.text('Start Challenge'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          pushedRoute,
          '/game?category=vocabulary&gameType=synonymSearch&level=1',
        );
        expect(find.text('Mastery Blitz Route'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
      },
    );

    testWidgets(
      'shows GameErrorView with sample drill fallback on load failure',
      (tester) async {
        final failing = _TestPracticeBundle(payload: '{}', shouldThrow: true);
        await tester.pumpWidget(
          wrapScreen(
            SynonymSearchPracticeScreen(level: 1, assetBundle: failing),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Could not load Level 1 practice.'), findsOneWidget);
        expect(find.text('Use Sample Practice'), findsOneWidget);
      },
    );

    testWidgets(
      'Hint button reveals coaching hint and pre-fills first anchor slot once',
      (tester) async {
        final exercises = SynonymPracticeQuest.fallbackExercises(1);
        await tester.pumpWidget(
          wrapScreen(
            SynonymSearchPracticeScreen(level: 1, initialExercises: exercises),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final hintFinder = find.byTooltip('Hint');
        expect(hintFinder, findsOneWidget);
        await tester.tap(hintFinder);
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text(exercises.first.hint), findsOneWidget);

        // Second tap keeps hint visible because button disables once active.
        await tester.tap(hintFinder);
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text(exercises.first.hint), findsOneWidget);
      },
    );

    testWidgets(
      'Hint repairs an incorrect placement in slot 0 with the correct word',
      (tester) async {
        final exercises = SynonymPracticeQuest.fallbackExercises(1);
        final wrongWordIndex = exercises.first.pairWords.indexWhere(
          (w) =>
              w.toLowerCase() !=
              exercises.first.slots[0].correctWord.toLowerCase(),
        );
        await tester.pumpWidget(
          wrapScreen(
            SynonymSearchPracticeScreen(level: 1, initialExercises: exercises),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tapWithScroll(
          tester,
          find.byKey(Key('contrast_bank_word_$wrongWordIndex')),
        );
        await tester.tap(find.byTooltip('Hint'));
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text(exercises.first.hint), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('contrast_slot_0')),
            matching: find.text(exercises.first.slots[0].correctWord),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'appends due weak-word contrast review drill from prior levels when stored',
      (tester) async {
        await SynonymWeakWordsStore.recordWeakPair(
          level: 1,
          baseWord: 'Big',
          synonym: 'Large',
        );
        final raw1_10 = File(
          'assets/curriculum/vocabulary/synonymSearch_practice_1_10.json',
        ).readAsStringSync();
        final bundle = _TestPracticeBundle(payload: raw1_10);

        await tester.pumpWidget(
          wrapScreen(
            SynonymSearchPracticeScreen(level: 2, assetBundle: bundle),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 6 drills for Level 2 + 1 due review drill from Level 1 = 7 total steps (1/7)
        final scaffold = tester.widget<PracticePhaseScaffold>(
          find.byType(PracticePhaseScaffold),
        );
        expect(scaffold.totalExercises, 7);
        final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.value, closeTo(1 / 7, 0.001));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
      },
    );

    testWidgets(
      'displays Review from Level 1 banner and preserves origin level when missed',
      (tester) async {
        await SynonymWeakWordsStore.recordWeakPair(
          level: 1,
          baseWord: 'Big',
          synonym: 'Large',
        );
        final decoded =
            jsonDecode(
                  File(
                    'assets/curriculum/vocabulary/synonymSearch_practice_1_10.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        final quests = (decoded['quests'] as List).cast<Map<String, dynamic>>();
        final l1q1 = quests.firstWhere((q) => q['level'] == 1);
        final l2q1 = Map<String, dynamic>.from(
          quests.firstWhere((q) => q['level'] == 2),
        );
        l2q1['exercises'] = [(l2q1['exercises'] as List).first];
        decoded['quests'] = [l1q1, l2q1];

        final bundle = _TestPracticeBundle(payload: jsonEncode(decoded));
        await tester.pumpWidget(
          wrapScreen(
            SynonymSearchPracticeScreen(level: 2, assetBundle: bundle),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Solve L2 Q1 contrastSwap cleanly using its correct slot order.
        final l2Slots = ((l2q1['exercises'] as List).first['slots'] as List)
            .cast<Map<String, dynamic>>();
        for (final slot in l2Slots) {
          final target = slot['correctWord'] as String;
          await tapWithScroll(tester, find.text(target).last);
        }
        await tester.tap(find.text('Check Answer'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Next Question'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.byKey(const Key('practice_review_origin_banner')),
          findsOneWidget,
        );
        expect(find.text('Review from Level 1'), findsOneWidget);

        // Miss the injected L1 Big/Large review drill intentionally.
        await tapWithScroll(
          tester,
          find.byKey(const Key('contrast_bank_word_1')),
        );
        await tapWithScroll(
          tester,
          find.byKey(const Key('contrast_bank_word_0')),
        );
        await tester.tap(find.text('Check Answer'));
        await tester.pump(const Duration(milliseconds: 300));

        final stored = await SynonymWeakWordsStore.loadWeakPairs();
        final bigEntry = stored.firstWhere((e) => e.synonym == 'Large');
        expect(bigEntry.level, 1);
        expect(bigEntry.misses, 2);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
  });
}
