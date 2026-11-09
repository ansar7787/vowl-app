import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/home/presentation/widgets/home_hero_header.dart';

class MockHapticService extends Mock implements HapticService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;
  late List<String> navigatedRoutes;

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    navigatedRoutes = [];
    mockHapticService = MockHapticService();
    when(() => mockHapticService.selection()).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
  });

  Widget createSubject({
    required UserEntity user,
    ThemeMode themeMode = ThemeMode.dark,
    double width = 393,
    double height = 852,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: HomeHeroHeader(user: user),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRouter.profileRoute,
          builder: (context, state) {
            navigatedRoutes.add(AppRouter.profileRoute);
            return const Scaffold(body: Text('Profile Screen'));
          },
        ),
        GoRoute(
          path: AppRouter.streakRoute,
          builder: (context, state) {
            navigatedRoutes.add(AppRouter.streakRoute);
            return const Scaffold(body: Text('Streak Screen'));
          },
        ),
        GoRoute(
          path: AppRouter.questCoinsRoute,
          builder: (context, state) {
            navigatedRoutes.add(AppRouter.questCoinsRoute);
            return const Scaffold(body: Text('Coins Screen'));
          },
        ),
        GoRoute(
          path: AppRouter.vowlMascotRoute,
          builder: (context, state) {
            navigatedRoutes.add(AppRouter.vowlMascotRoute);
            return const Scaffold(body: Text('Mascot Screen'));
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

  const testUserCommander = UserEntity(
    id: 'user_aria',
    email: 'aria@vowl.app',
    displayName: 'Aria Stark',
    currentStreak: 14,
    totalExp: 1450, // Level 15 (Commander tier)
    coins: 1250,
  );

  testWidgets(
    'renders identity typography with user name, level 15, and habit focus line',
    (tester) async {
      await tester.pumpWidget(createSubject(user: testUserCommander));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(HomeHeroHeader), findsOneWidget);
      expect(find.textContaining('Aria Stark'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('1 lesson to reach daily goal'), findsOneWidget);
      expect(find.text('14'), findsOneWidget); // Streak
      expect(find.text('1.3k'), findsOneWidget); // Coins formatted
    },
  );

  testWidgets('renders level 1 and habit focus for a new learner', (
    tester,
  ) async {
    const rookieUser = UserEntity(
      id: 'user_rookie',
      email: 'rookie@vowl.app',
      displayName: 'John Doe',
      totalExp: 30, // Level 1
      currentStreak: 0,
      coins: 50,
    );

    await tester.pumpWidget(createSubject(user: rookieUser));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('1'), findsWidgets);
    expect(find.textContaining('John Doe'), findsOneWidget);
    expect(find.text('1 lesson to reach daily goal'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
  });

  testWidgets(
    'shows Goal completed message when user has completed activity today',
    (tester) async {
      final now = DateTime.now();
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final userWithXpToday = testUserCommander.copyWith(
        dailyXpHistory: {todayKey: 50},
      );

      await tester.pumpWidget(createSubject(user: userWithXpToday));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Daily goal completed ⭐'), findsOneWidget);
    },
  );

  testWidgets('tapping streak HUD navigates to /streak and triggers haptics', (
    tester,
  ) async {
    await tester.pumpWidget(createSubject(user: testUserCommander));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('14'));
    await tester.pumpAndSettle();

    verify(() => mockHapticService.selection()).called(1);
    expect(navigatedRoutes, contains(AppRouter.streakRoute));
  });

  testWidgets(
    'tapping coins HUD navigates to /coins-details and triggers haptics',
    (tester) async {
      await tester.pumpWidget(createSubject(user: testUserCommander));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('1.3k'));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);
      expect(navigatedRoutes, contains(AppRouter.questCoinsRoute));
    },
  );

  testWidgets('tapping avatar navigates to /profile and triggers haptics', (
    tester,
  ) async {
    await tester.pumpWidget(createSubject(user: testUserCommander));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();

    verify(() => mockHapticService.selection()).called(1);
    expect(navigatedRoutes, contains(AppRouter.profileRoute));
  });

  testWidgets(
    'tapping companion mascot pin navigates to /mascot and triggers haptics',
    (tester) async {
      await tester.pumpWidget(createSubject(user: testUserCommander));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('🦉'));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);
      expect(navigatedRoutes, contains(AppRouter.vowlMascotRoute));
    },
  );

  testWidgets(
    'renders equipped accessory badge on companion mascot pin when accessory is equipped',
    (tester) async {
      final userWithCrown = testUserCommander.copyWith(
        vowlEquippedAccessory: 'golden_crown',
      );
      await tester.pumpWidget(createSubject(user: userWithCrown));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('🦉'), findsOneWidget);
      expect(find.text('👑'), findsOneWidget);
    },
  );

  testWidgets('renders safely on small 320dp mobile screen without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 2.0, 568 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createSubject(user: testUserCommander, width: 320, height: 568),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(HomeHeroHeader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders cleanly in Light Mode without errors', (tester) async {
    await tester.pumpWidget(
      createSubject(user: testUserCommander, themeMode: ThemeMode.light),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(HomeHeroHeader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
