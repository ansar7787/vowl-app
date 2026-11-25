import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
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

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
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

        expect(find.text('CONTRAST SWAP • A2'), findsOneWidget);
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
        expect(find.text('Tap Slot to Adjust'), findsOneWidget);

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

        expect(find.text('Reveal Solution'), findsOneWidget);

        // Reveal guided solution cleanly
        await tester.tap(find.text('Reveal Solution'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Next Exercise'), findsOneWidget);

        // Advance to Synonym Ladder exercise
        await tester.tap(find.text('Next Exercise'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('SYNONYM LADDER • A2'), findsOneWidget);

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
        expect(find.text('Start Mastery Blitz'), findsOneWidget);

        await tester.tap(find.text('Start Mastery Blitz'));
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

        expect(
          find.text('Unable to load Level 1 synonym practice drills.'),
          findsOneWidget,
        );
        expect(find.text('Practice Sample Drill'), findsOneWidget);
      },
    );
  });
}
