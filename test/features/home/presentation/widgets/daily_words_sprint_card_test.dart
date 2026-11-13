import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/daily_words/data/services/daily_words_service.dart';
import 'package:vowl/features/home/presentation/widgets/daily_words_sprint_card.dart';
import 'package:vowl/features/home/presentation/widgets/discovery_deck.dart';

class MockDailyWordsService extends Mock implements DailyWordsService {}

class MockHapticService extends Mock implements HapticService {}

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDailyWordsService mockDailyWordsService;
  late MockHapticService mockHapticService;
  late MockLocaleService mockLocaleService;
  late List<String> navigatedRoutes;

  setUp(() {
    navigatedRoutes = [];
    mockDailyWordsService = MockDailyWordsService();
    mockHapticService = MockHapticService();
    mockLocaleService = MockLocaleService();

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockDailyWordsService.isTodayCompleted).thenReturn(false);
    when(() => mockDailyWordsService.currentDay).thenReturn(1);

    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));
    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (inv) =>
          inv.namedArguments[#fallback] as String? ??
          inv.positionalArguments.first as String,
    );

    if (di.sl.isRegistered<DailyWordsService>()) {
      di.sl.unregister<DailyWordsService>();
    }
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }

    di.sl.registerSingleton<DailyWordsService>(mockDailyWordsService);
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
  });

  tearDown(() {
    if (di.sl.isRegistered<DailyWordsService>()) {
      di.sl.unregister<DailyWordsService>();
    }
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
  });

  Widget createSubject({
    ThemeMode themeMode = ThemeMode.dark,
    double width = 393,
    double height = 852,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: DailyWordsSprintCard(),
            ),
          ),
        ),
        GoRoute(
          path: AppRouter.dailyWordsRoute,
          builder: (context, state) {
            navigatedRoutes.add(AppRouter.dailyWordsRoute);
            return const Scaffold(body: Text('Daily Words Screen'));
          },
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: Size(width, height),
      builder: (context, _) => MaterialApp.router(
        routerConfig: router,
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      ),
    );
  }

  group('DailyWordsSprintCard Core Rendering', () {
    testWidgets('renders pending state with TODAY badge and Start action', (
      tester,
    ) async {
      when(() => mockDailyWordsService.isTodayCompleted).thenReturn(false);

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('Daily Words'), findsOneWidget);
      expect(find.text('10 new words today'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chevron_forward), findsOneWidget);
    });

    testWidgets('renders completed state with COMPLETED ✓ badge and checkmark', (
      tester,
    ) async {
      when(() => mockDailyWordsService.isTodayCompleted).thenReturn(true);

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('COMPLETED ✓'), findsOneWidget);
      expect(find.text('Daily Words'), findsOneWidget);
      expect(find.text('All 10 words mastered today!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('Start'), findsNothing);
    });
  });

  group('DailyWordsSprintCard Interactions', () {
    testWidgets('tap triggers haptic feedback and navigates to dailyWordsRoute', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DailyWordsSprintCard));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);
      expect(navigatedRoutes, contains(AppRouter.dailyWordsRoute));
      expect(find.text('Daily Words Screen'), findsOneWidget);
    });

    testWidgets(
      'rebuilds and updates state when DiscoveryDeck.dailyCompletionNotifier fires',
      (tester) async {
        when(() => mockDailyWordsService.isTodayCompleted).thenReturn(false);

        await tester.pumpWidget(createSubject());
        await tester.pumpAndSettle();

        expect(find.text('TODAY'), findsOneWidget);

        // Simulate daily words completion
        when(() => mockDailyWordsService.isTodayCompleted).thenReturn(true);
        DiscoveryDeck.dailyCompletionNotifier.value++;

        await tester.pumpAndSettle();

        expect(find.text('COMPLETED ✓'), findsOneWidget);
        expect(find.text('All 10 words mastered today!'), findsOneWidget);
      },
    );
  });

  group('DailyWordsSprintCard Viewports & Themes', () {
    testWidgets('renders on compact 320dp width without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(width: 320, height: 600));
      await tester.pumpAndSettle();

      expect(find.byType(DailyWordsSprintCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in light mode without error', (tester) async {
      await tester.pumpWidget(createSubject(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();

      expect(find.byType(DailyWordsSprintCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
