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
import 'package:vowl/features/vocabulary/synonym_search/presentation/pages/synonym_search_learn_screen.dart';

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
        expect(find.text('Tested 0/2'), findsOneWidget);

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

        // Tap first makeover slot to swap big -> large
        await tester.ensureVisible(find.byKey(const Key('makeover_slot_0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('makeover_slot_0')));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Natural Fit'), findsOneWidget);
        expect(find.text('Tested 1/2'), findsOneWidget);

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
        expect(find.text('Go to Practice'), findsOneWidget);

        // Test Previous returns to Pair 1
        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Big'), findsWidgets);

        // Advance back to final pair and pushReplacement to Practice
        await tester.tap(find.text('Next Pair'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Go to Practice'));
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

      expect(
        find.text('Unable to load Level 1 synonym studio data.'),
        findsOneWidget,
      );
      expect(find.text('Continue with Sample'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
