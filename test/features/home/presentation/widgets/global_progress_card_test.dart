import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/home/presentation/widgets/global_progress_card.dart';

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
      final key = inv.positionalArguments.first as String;
      final fallback = inv.namedArguments[#fallback] as String?;
      final args = inv.namedArguments[#args] as List<dynamic>?;

      String text = fallback ?? key;
      if (args != null && args.isNotEmpty) {
        for (int i = 0; i < args.length; i++) {
          text = text.replaceAll('{$i}', args[i].toString());
          text = text.replaceAll('{}', args[i].toString());
        }
      }
      return text;
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

  UserEntity buildUser({
    int totalLevelsCompleted = 0,
  }) {
    return UserEntity(
      id: 'test_user_prog',
      email: 'test@vowl.app',
      displayName: 'Alex Progress',
      completedLevels: {
        'vocabulary': List.generate(totalLevelsCompleted, (i) => i + 1),
      },
      currentStreak: 12,
      coins: 850,
      totalExp: 2400,
    );
  }

  Widget createSubject({
    required UserEntity user,
    int? globalRank,
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
              child: GlobalProgressCard(
                user: user,
                globalRank: globalRank,
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRouter.leaderboardRoute,
          builder: (context, _) {
            navigatedRoutes.add(AppRouter.leaderboardRoute);
            return const Scaffold(body: Text('Leaderboard Screen'));
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

  Future<void> pumpSubject(
    WidgetTester tester, {
    required UserEntity user,
    int? globalRank,
    ThemeMode themeMode = ThemeMode.dark,
    double width = 390,
    double height = 844,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      createSubject(
        user: user,
        globalRank: globalRank,
        themeMode: themeMode,
        width: width,
        height: height,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('GlobalProgressCard - Visual Rendering & Mathematical Accuracy', () {
    testWidgets('renders completed levels count, total curriculum levels, and rank badge', (tester) async {
      final user = buildUser(totalLevelsCompleted: 38);
      await pumpSubject(tester, user: user, globalRank: 14);

      expect(find.text('Curriculum Mastery'), findsOneWidget);
      expect(find.text('Global Journey & Rank'), findsOneWidget);
      expect(find.text('38'), findsOneWidget);
      expect(find.textContaining('20000 Levels'), findsOneWidget);
      expect(find.text('#14'), findsOneWidget);
      expect(find.text('Rank'), findsOneWidget);
      expect(find.text('Stage 1: Foundation'), findsOneWidget);
      expect(find.text('12 to Next Target'), findsOneWidget);
    });

    testWidgets('renders unranked badge when globalRank is null', (tester) async {
      final user = buildUser(totalLevelsCompleted: 0);
      await pumpSubject(tester, user: user, globalRank: null);

      expect(find.text('0'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Unranked'), findsOneWidget);
      expect(find.text('0.0% Cleared'), findsOneWidget);
      expect(find.text('Stage 1: Foundation'), findsOneWidget);
      expect(find.text('50 to Next Target'), findsOneWidget);
    });

    testWidgets('renders advanced stage for higher completed count', (tester) async {
      final user = buildUser(totalLevelsCompleted: 250);
      await pumpSubject(tester, user: user, globalRank: 5);

      expect(find.text('250'), findsOneWidget);
      expect(find.text('#5'), findsOneWidget);
      expect(find.text('Stage 3: Advanced'), findsOneWidget);
      expect(find.text('750 to Next Target'), findsOneWidget);
    });
  });

  group('GlobalProgressCard - Interaction & Navigation', () {
    testWidgets('tapping card triggers selection haptics and navigates to /leaderboard', (tester) async {
      final user = buildUser(totalLevelsCompleted: 42);
      await pumpSubject(tester, user: user, globalRank: 8);

      final cardButton = find.byType(ScaleButton);
      expect(cardButton, findsOneWidget);

      await tester.tap(cardButton);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);
      expect(navigatedRoutes, contains('/leaderboard'));
    });
  });

  group('GlobalProgressCard - Responsive Viewports & Accessibility', () {
    testWidgets('renders without overflow on compact 320dp screen', (tester) async {
      final user = buildUser(totalLevelsCompleted: 95);
      await pumpSubject(
        tester,
        user: user,
        globalRank: 128,
        width: 320,
        height: 568,
      );

      expect(find.text('Curriculum Mastery'), findsOneWidget);
      expect(find.text('95'), findsOneWidget);
      expect(find.text('#128'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in light mode', (tester) async {
      final user = buildUser(totalLevelsCompleted: 15);
      await pumpSubject(
        tester,
        user: user,
        globalRank: 3,
        themeMode: ThemeMode.light,
      );

      expect(find.text('Curriculum Mastery'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly under 1.3x accessibility text scaling without overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() => tester.platformDispatcher.clearTextScaleFactorTestValue());

      final user = buildUser(totalLevelsCompleted: 120);
      await pumpSubject(
        tester,
        user: user,
        globalRank: 19,
        width: 320,
        height: 568,
      );

      expect(find.text('Curriculum Mastery'), findsOneWidget);
      expect(find.text('#19'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

