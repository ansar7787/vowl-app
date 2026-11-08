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
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/home/presentation/widgets/bento_arena.dart';

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
    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));
    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer((inv) {
      final fallback = inv.namedArguments[#fallback] as String?;
      return fallback ?? (inv.positionalArguments.first as String);
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
    required UserEntity user,
    bool collapsed = true,
    ThemeMode themeMode = ThemeMode.dark,
    double width = 390,
    double height = 844,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: SingleChildScrollView(
              child: BentoArena(user: user, collapsed: collapsed),
            ),
          ),
        ),
        GoRoute(
          path: AppRouter.categoryGamesRoute,
          builder: (context, state) {
            final cat = state.uri.queryParameters['category'] ?? '';
            navigatedRoutes.add(
              '${AppRouter.categoryGamesRoute}?category=$cat',
            );
            return Scaffold(body: Text('Category Games: $cat'));
          },
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: Size(width, height),
      builder: (context, child) => MaterialApp.router(
        routerConfig: router,
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      ),
    );
  }

  Future<void> pumpSubject(
    WidgetTester tester, {
    UserEntity user = const UserEntity(
      id: 'user_123',
      email: 'learner@vowl.app',
      displayName: 'Aria',
      currentStreak: 7,
      coins: 350,
      totalExp: 1200,
      badges: ['streak_hero'],
      completedLevels: {
        'vocabulary': [1, 2, 3, 4, 5],
        'listening': [1, 2],
        'reading': [1],
      },
    ),
    bool collapsed = true,
    ThemeMode themeMode = ThemeMode.dark,
    double width = 390,
    double height = 1200,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(
      createSubject(
        user: user,
        collapsed: collapsed,
        themeMode: themeMode,
        width: width,
        height: height,
      ),
    );
    await tester.pumpAndSettle();
  }

  const baseUser = UserEntity(
    id: 'user_123',
    email: 'learner@vowl.app',
    displayName: 'Aria',
    currentStreak: 7,
    coins: 350,
    totalExp: 1200,
    badges: ['streak_hero'],
    completedLevels: {
      'vocabulary': [1, 2, 3, 4, 5],
      'listening': [1, 2],
      'reading': [1],
    },
  );

  group('BentoArena - Layout & Rendering', () {
    testWidgets('renders Hero Card for Step 1 (Vocabulary) with real stats', (
      tester,
    ) async {
      await pumpSubject(tester, user: baseUser);

      expect(find.text('Vocabulary Arena'), findsOneWidget);
      expect(find.text('Step 1 of 9'), findsOneWidget);
      expect(find.text('Curriculum Progress'), findsOneWidget);
      expect(find.text('CURRENT FOCUS'), findsOneWidget);
    });

    testWidgets(
      'renders core 2-column bento cells (Listening, Reading, Grammar, Writing)',
      (tester) async {
        await pumpSubject(tester, user: baseUser);

        expect(find.text('Listening'), findsOneWidget);
        expect(find.text('Reading'), findsOneWidget);
        expect(find.text('Grammar'), findsOneWidget);
        expect(find.text('Writing'), findsOneWidget);

        // Advanced steps should not be in grid in collapsed mode
        expect(find.text('Accent'), findsNothing);
        expect(find.text('Roleplay'), findsNothing);
      },
    );

    testWidgets(
      'renders Discipline Bubble Dock with upcoming category bubbles',
      (tester) async {
        await pumpSubject(tester, user: baseUser);

        expect(find.text('More Arenas'), findsOneWidget);
        expect(find.text('4 arenas ready to explore'), findsOneWidget);
        expect(find.text('See All 9 Categories'), findsOneWidget);

        // Bubbles for Speaking, Accent, Roleplay, Elite Mastery
        expect(find.bySemanticsLabel('Speaking discipline'), findsOneWidget);
        expect(find.bySemanticsLabel('Accent discipline'), findsOneWidget);
        expect(find.bySemanticsLabel('Roleplay discipline'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Elite Mastery discipline'),
          findsOneWidget,
        );
      },
    );
  });

  group('BentoArena - Expansion & Interaction', () {
    testWidgets(
      'tapping See All 9 Categories expands grid to show all 9 arenas and Show Less toggle',
      (tester) async {
        await pumpSubject(tester, user: baseUser);

        final expandPill = find.text('See All 9 Categories');
        expect(expandPill, findsOneWidget);

        await tester.tap(expandPill);
        await tester.pumpAndSettle();

        // Now all 9 are visible in grid
        expect(find.text('All 9 Arenas Active'), findsOneWidget);
        expect(find.text('Show Less'), findsOneWidget);
        expect(find.text('Speaking'), findsOneWidget);
        expect(find.text('Accent'), findsOneWidget);
        expect(find.text('Roleplay'), findsOneWidget);
        expect(find.text('Elite Mastery'), findsOneWidget);

        // Bubbles row is hidden during full grid expansion
        expect(find.bySemanticsLabel('Speaking discipline'), findsNothing);

        // Wait for ScaleButton 500ms debounce guard to clear
        await tester.pump(const Duration(milliseconds: 600));

        // Tap Show Less to collapse back
        final showLessFinder = find.text('Show Less');
        await tester.ensureVisible(showLessFinder);
        await tester.tap(showLessFinder);
        await tester.pumpAndSettle();

        expect(find.text('More Arenas'), findsOneWidget);
        expect(find.text('See All 9 Categories'), findsOneWidget);
        expect(find.bySemanticsLabel('Speaking discipline'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Hero Card triggers selection haptic and navigates to vocabulary',
      (tester) async {
        await pumpSubject(tester, user: baseUser);

        await tester.tap(find.text('Vocabulary Arena'));
        await tester.pumpAndSettle();

        verify(() => mockHapticService.selection()).called(1);
        expect(
          navigatedRoutes,
          contains('/category-games?category=vocabulary'),
        );
      },
    );

    testWidgets(
      'tapping a category grid cell navigates to that category route',
      (tester) async {
        await pumpSubject(tester, user: baseUser);

        await tester.tap(find.text('Listening'));
        await tester.pumpAndSettle();

        verify(() => mockHapticService.selection()).called(1);
        expect(navigatedRoutes, contains('/category-games?category=listening'));
      },
    );

    testWidgets(
      'tapping an upcoming bubble in dock navigates directly to that category',
      (tester) async {
        await pumpSubject(tester, user: baseUser);

        final eliteBubble = find.bySemanticsLabel('Elite Mastery discipline');
        await tester.tap(eliteBubble);
        await tester.pumpAndSettle();

        verify(() => mockHapticService.selection()).called(1);
        expect(
          navigatedRoutes,
          contains('/category-games?category=eliteMastery'),
        );
      },
    );
  });

  group('BentoArena - Screen Size Resilience', () {
    testWidgets('renders cleanly on compact 320dp screen without overflow', (
      tester,
    ) async {
      await pumpSubject(tester, user: baseUser, width: 320, height: 600);

      expect(tester.takeException(), isNull);
      expect(find.text('Vocabulary Arena'), findsOneWidget);
      expect(find.text('See All 9 Categories'), findsOneWidget);
    });

    testWidgets('renders cleanly in light mode', (tester) async {
      await pumpSubject(tester, user: baseUser, themeMode: ThemeMode.light);

      expect(tester.takeException(), isNull);
      expect(find.text('Vocabulary Arena'), findsOneWidget);
    });
  });
}
