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
          builder: (context, _) =>
              const Scaffold(body: SingleChildScrollView(child: ToolsStrip())),
        ),
        GoRoute(
          path: AppRouter.dailyWordsRoute,
          builder: (context, _) {
            navigatedRoutes.add(AppRouter.dailyWordsRoute);
            return const Scaffold(body: Text('Daily Words Screen'));
          },
        ),
        GoRoute(
          path: AppRouter.translateRoute,
          builder: (context, _) {
            navigatedRoutes.add(AppRouter.translateRoute);
            return const Scaffold(body: Text('Translate Screen'));
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

  group('ToolsStrip Core Rendering & Architecture Tests', () {
    testWidgets(
      'renders 2 Swiss Horizon cards: Daily Words and Translate',
      (tester) async {
        await tester.pumpWidget(createSubject());
        await tester.pumpAndSettle();

        expect(find.text('Daily Words'), findsOneWidget);
        expect(find.text('5 new words today'), findsOneWidget);
        expect(find.text('TODAY'), findsOneWidget);

        expect(find.text('Translate'), findsOneWidget);
        expect(
          find.text('Offline translation for 50+ languages'),
          findsOneWidget,
        );
        expect(find.text('OFFLINE'), findsOneWidget);
      },
    );
  });

  group('ToolsStrip Navigation Tests', () {
    testWidgets('tapping Daily Words navigates to dailyWordsRoute', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Daily Words'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains(AppRouter.dailyWordsRoute));
    });

    testWidgets('tapping Translate navigates to translateRoute', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Translate'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains(AppRouter.translateRoute));
    });
  });

  group('ToolsStrip Small Screen & Accessibility Robustness', () {
    testWidgets(
      'renders cleanly on 320dp small screen (iPhone SE) without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createSubject(width: 320, height: 600));
        await tester.pumpAndSettle();

        expect(find.byType(ToolsStrip), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders cleanly with 1.3x accessibility text scale without overflow',
      (tester) async {
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
      },
    );

    testWidgets('renders cleanly in Light theme mode', (tester) async {
      await tester.pumpWidget(createSubject(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();

      expect(find.byType(ToolsStrip), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'dynamically updates when DiscoveryDeck.notifySequenceCompleted() is invoked',
      (tester) async {
        when(() => mockDailyWordsService.isTodayCompleted).thenReturn(false);
        await tester.pumpWidget(createSubject());
        await tester.pumpAndSettle();

        expect(find.text('TODAY'), findsOneWidget);

        when(() => mockDailyWordsService.isTodayCompleted).thenReturn(true);
        DiscoveryDeck.notifySequenceCompleted();
        await tester.pumpAndSettle();

        expect(find.text('COMPLETED ✓'), findsOneWidget);
      },
    );
  });
}
