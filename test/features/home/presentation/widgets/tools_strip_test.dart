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
import 'package:vowl/features/home/presentation/widgets/tools_strip.dart';

class MockHapticService extends Mock implements HapticService {}

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;
  late MockLocaleService mockLocaleService;
  late List<String> navigatedRoutes;

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    mockHapticService = MockHapticService();
    mockLocaleService = MockLocaleService();
    navigatedRoutes = [];

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));
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
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
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

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
            textScaler: TextScaler.linear(textScale),
          ),
          child: MaterialApp.router(
            routerConfig: router,
            themeMode: themeMode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
          ),
        );
      },
    );
  }

  group('Piece 8: ToolsStrip Core Rendering & Architecture Tests', () {
    testWidgets('renders Swiss cards: Kids Zone and Daily Words', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Kids Zone'), findsOneWidget);
      expect(find.text('Fun learning games'), findsOneWidget);
      expect(find.text('KIDS'), findsOneWidget);

      expect(find.text('Daily Words'), findsOneWidget);
      expect(find.text('5 new words today'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
    });

    testWidgets('renders 2x2 Bento grid with all 4 superpower tools', (tester) async {
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

      // Cell 3: Translate
      expect(find.text('Translate'), findsOneWidget);
      expect(find.text('50+ Languages'), findsOneWidget);
      expect(find.text('OFFLINE'), findsOneWidget);

      // Cell 4: Word Games
      expect(find.text('Word Games'), findsOneWidget);
      expect(find.text('Snap & Mixer'), findsOneWidget);
      expect(find.text('GAMES'), findsOneWidget);
    });

    testWidgets('renders sleek 32px Directory capsule pill trigger', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Directory (7 Tools)'), findsOneWidget);
    });
  });

  group('Piece 8: ToolsStrip Navigation & Modal Sheet Tests', () {
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

    testWidgets('tapping Translate navigates to translateRoute', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Translate'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains(AppRouter.translateRoute));
    });

    testWidgets('tapping Word Games opens bottom sheet with Word Snap & Word Mixer', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Word Games'));
      await tester.pumpAndSettle();

      expect(find.text('Brain Word Games'), findsOneWidget);
      expect(find.text('Word Snap'), findsOneWidget);
      expect(find.text('Word Mixer'), findsOneWidget);

      // Tap Word Snap in sheet
      await tester.tap(find.text('Word Snap'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains(AppRouter.wordSnapRoute));
    });

    testWidgets('tapping Word Mixer in Word Games sheet navigates to wordMixerRoute', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Word Games'));
      await tester.pumpAndSettle();

      // Tap Word Mixer in sheet
      await tester.tap(find.text('Word Mixer'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains(AppRouter.wordMixerRoute));
    });

    testWidgets('tapping Directory pill opens Tools Directory sheet showing all 7 tools', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Directory (7 Tools)'));
      await tester.pumpAndSettle();

      expect(find.text('Tools & Utilities (7)'), findsOneWidget);
      // All 7 tools listed in directory
      expect(find.text('Kids Zone'), findsWidgets);
      expect(find.text('Daily Words'), findsWidgets);
      expect(find.text('Photo Vocab'), findsWidgets);
      expect(find.text('Scan & Learn'), findsWidgets);
      expect(find.text('Translate'), findsWidgets);
      expect(find.text('Word Snap'), findsWidgets);
      expect(find.text('Word Mixer'), findsWidgets);
      expect(find.text('Browse 100+ Games & Full App Catalog'), findsOneWidget);
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
  });
}

