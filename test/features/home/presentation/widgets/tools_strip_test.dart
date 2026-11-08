import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/daily_words/data/services/daily_words_service.dart';
import 'package:vowl/features/home/presentation/widgets/discovery_deck.dart';
import 'package:vowl/features/home/presentation/widgets/tools_strip.dart';

class MockHapticService extends Mock implements HapticService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockDailyWordsService extends Mock implements DailyWordsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;
  late MockLocaleService mockLocaleService;
  late MockDailyWordsService mockDailyWordsService;
  late List<String> navigatedRoutes;

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    mockHapticService = MockHapticService();
    mockLocaleService = MockLocaleService();
    mockDailyWordsService = MockDailyWordsService();
    navigatedRoutes = [];

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));
    when(() => mockDailyWordsService.isTodayCompleted).thenReturn(false);
    when(() => mockDailyWordsService.currentDay).thenReturn(1);
    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer((inv) {
      final key = inv.positionalArguments.first as String;
      final fallback = inv.namedArguments[#fallback] as String?;
      return fallback ?? key;
    });

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);

    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    initLocaleServiceReference(mockLocaleService);

    if (di.sl.isRegistered<DailyWordsService>()) {
      di.sl.unregister<DailyWordsService>();
    }
    di.sl.registerSingleton<DailyWordsService>(mockDailyWordsService);
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    if (di.sl.isRegistered<DailyWordsService>()) {
      di.sl.unregister<DailyWordsService>();
    }
  });

  Widget createSubject({
    ThemeMode themeMode = ThemeMode.dark,
    double width = 390,
    double height = 844,
    double textScale = 1.0,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => const Scaffold(
            body: SingleChildScrollView(
              child: ToolsStrip(),
            ),
          ),
        ),
        GoRoute(
          path: AppRouter.kidsZoneRoute,
          builder: (context, _) {
            navigatedRoutes.add(AppRouter.kidsZoneRoute);
            return const Scaffold(body: Text('Kids Zone Screen'));
          },
        ),
        GoRoute(
          path: AppRouter.dailyWordsRoute,
          builder: (context, _) {
            navigatedRoutes.add(AppRouter.dailyWordsRoute);
            return const Scaffold(body: Text('Daily Words Screen'));
          },
        ),
        GoRoute(
          path: AppRouter.photoVocabularyRoute,
          builder: (context, _) {
            navigatedRoutes.add(AppRouter.photoVocabularyRoute);
            return const Scaffold(body: Text('Photo Vocab Screen'));
          },
        ),
        GoRoute(
          path: AppRouter.scanAndLearnRoute,
          builder: (context, _) {
            navigatedRoutes.add(AppRouter.scanAndLearnRoute);
            return const Scaffold(body: Text('Scan & Learn Screen'));
          },
        ),
        GoRoute(
          path: AppRouter.translateRoute,
          builder: (context, _) {
            navigatedRoutes.add(AppRouter.translateRoute);
            return const Scaffold(body: Text('Translate Screen'));
          },
        ),
        GoRoute(
          path: AppRouter.wordSnapRoute,
          builder: (context, _) {
            navigatedRoutes.add(AppRouter.wordSnapRoute);
            return const Scaffold(body: Text('Word Snap Screen'));
          },
        ),
        GoRoute(
          path: AppRouter.wordMixerRoute,
          builder: (context, _) {
            navigatedRoutes.add(AppRouter.wordMixerRoute);
            return const Scaffold(body: Text('Word Mixer Screen'));
          },
        ),
      ],
    );

    return MediaQuery(
      data: MediaQueryData(
        size: Size(width, height),
        textScaler: TextScaler.linear(textScale),
      ),
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        builder: (context, child) {
          return MaterialApp.router(
            routerConfig: router,
            themeMode: themeMode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
          );
        },
      ),
    );
  }

  group('Piece 8: ToolsStrip Core Rendering & Architecture Tests', () {
    testWidgets('renders 3 Swiss Horizon cards: Kids Zone, Daily Words, and Translate', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Kids Zone'), findsOneWidget);
      expect(find.text('Fun learning games'), findsOneWidget);
      expect(find.text('KIDS'), findsOneWidget);

      expect(find.text('Daily Words'), findsOneWidget);
      expect(find.text('5 new words today'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);

      expect(find.text('Translate'), findsOneWidget);
      expect(find.text('Offline translation for 50+ languages'), findsOneWidget);
      expect(find.text('OFFLINE'), findsOneWidget);
    });

    testWidgets('renders 2-column Bento row: Photo Vocab & Scan & Learn', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Cell 1: Photo Vocab
      expect(find.text('Photo Vocab'), findsOneWidget);
      expect(find.text('AI Camera'), findsOneWidget);
      expect(find.text('AI VISION'), findsOneWidget);

      // Cell 2: Scan & Learn
      expect(find.text('Scan & Learn'), findsOneWidget);
      expect(find.text('Text Reader'), findsOneWidget);
      expect(find.text('OCR SCAN'), findsOneWidget);
    });

    testWidgets('renders Arcade Vault strip with 2 speed word games hidden', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('ARCADE VAULT'), findsOneWidget);
      expect(find.text('2 GAMES'), findsOneWidget);
      expect(find.text('Speed vocabulary & anagram challenges'), findsOneWidget);
      expect(find.text('Unfold +2'), findsOneWidget);
    });
  });

  group('Piece 8: ToolsStrip Navigation & Inline Expansion Tests', () {
    testWidgets('tapping Kids Zone navigates to kidsZoneRoute', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kids Zone'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains(AppRouter.kidsZoneRoute));
    });

    testWidgets('tapping Daily Words navigates to dailyWordsRoute', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Daily Words'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains(AppRouter.dailyWordsRoute));
    });

    testWidgets('tapping Translate navigates to translateRoute', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Translate'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains(AppRouter.translateRoute));
    });

    testWidgets('tapping Photo Vocab navigates to photoVocabularyRoute', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Photo Vocab'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains(AppRouter.photoVocabularyRoute));
    });

    testWidgets('tapping Scan & Learn navigates to scanAndLearnRoute', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan & Learn'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains(AppRouter.scanAndLearnRoute));
    });

    testWidgets('tapping Unfold +2 expands and reveals inline bento cells for Word Snap and Word Mixer', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Tap unfold
      await tester.tap(find.text('Unfold +2'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Fold'), findsOneWidget);

      // Now Word Snap and Word Mixer exist as expanded bento sub-cells
      expect(find.text('Word Snap'), findsOneWidget);
      expect(find.text('Word Mixer'), findsOneWidget);
      expect(find.text('MEMORY MATCH'), findsOneWidget);
      expect(find.text('ANAGRAM SPRINT'), findsOneWidget);

      // Tap Fold to collapse
      await tester.ensureVisible(find.text('Fold'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fold'));
      await tester.pumpAndSettle();
      expect(find.text('Unfold +2'), findsOneWidget);

      // Re-unfold and tap Word Snap to test navigation
      await tester.tap(find.text('Unfold +2'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Word Snap'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Word Snap'));
      await tester.pumpAndSettle();
      expect(navigatedRoutes, contains(AppRouter.wordSnapRoute));
    });
  });

  group('Piece 8: ToolsStrip Small Screen & Accessibility Robustness', () {
    testWidgets('renders cleanly on 320dp small screen (iPhone SE) without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createSubject(width: 320, height: 600));
      await tester.pumpAndSettle();

      expect(find.byType(ToolsStrip), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with 1.3x accessibility text scale without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createSubject(width: 320, height: 600, textScale: 1.3),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ToolsStrip), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in Light theme mode', (tester) async {
      await tester.pumpWidget(createSubject(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();

      expect(find.byType(ToolsStrip), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dynamically updates when DiscoveryDeck.notifySequenceCompleted() is invoked', (tester) async {
      when(() => mockDailyWordsService.isTodayCompleted).thenReturn(false);
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('TODAY'), findsOneWidget);

      when(() => mockDailyWordsService.isTodayCompleted).thenReturn(true);
      DiscoveryDeck.notifySequenceCompleted();
      await tester.pumpAndSettle();

      expect(find.text('COMPLETED ✓'), findsOneWidget);
    });
  });
}

