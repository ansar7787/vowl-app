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
import 'package:vowl/features/home/presentation/widgets/unified_stats_row.dart';

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
    UserEntity? user,
    int? globalRank,
    bool isLoading = false,
    bool isRankLoading = false,
    ThemeMode themeMode = ThemeMode.dark,
    double width = 393,
    double height = 852,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: user == null || isLoading
                ? const UnifiedStatsRow.shimmer()
                : UnifiedStatsRow(
                    user: user,
                    globalRank: globalRank,
                    isLoading: isLoading,
                    isRankLoading: isRankLoading,
                  ),
          ),
        ),
        GoRoute(
          path: AppRouter.streakRoute,
          builder: (context, _) {
            navigatedRoutes.add(AppRouter.streakRoute);
            return const Scaffold(body: Text('Streak Screen'));
          },
        ),
        GoRoute(
          path: AppRouter.questCoinsRoute,
          builder: (context, _) {
            navigatedRoutes.add(AppRouter.questCoinsRoute);
            return const Scaffold(body: Text('Coins Screen'));
          },
        ),
        GoRoute(
          path: AppRouter.trophyRoomRoute,
          builder: (context, _) {
            navigatedRoutes.add(AppRouter.trophyRoomRoute);
            return const Scaffold(body: Text('Trophy Room Screen'));
          },
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
      designSize: const Size(393, 852),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp.router(
        routerConfig: router,
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      ),
    );
  }

  final testUser = UserEntity(
    id: 'user_telemetry_123',
    email: 'test@vowl.app',
    displayName: 'Alex Rivers',
    currentStreak: 18,
    coins: 1500,
    totalExp: 3200,
    badges: ['pioneer', 'streak_master'],
    recentActivities: [],
    completedLevels: {
      'flashcards': [1, 2, 3],
    },
  );

  testWidgets('renders UnifiedStatsRow with active user metrics and rank', (
    tester,
  ) async {
    await tester.pumpWidget(createSubject(user: testUser, globalRank: 4));
    await tester.pumpAndSettle();

    // Check values
    expect(find.text('18'), findsOneWidget); // Streak
    expect(find.text('1.5k'), findsOneWidget); // Coins formatted (1450 >= 1000)
    expect(find.text('2'), findsOneWidget); // Badges count
    expect(find.text('#4'), findsOneWidget); // Global Rank

    // Check labels
    expect(find.text('STREAK'), findsOneWidget);
    expect(find.text('COINS'), findsOneWidget);
    expect(find.text('BADGES'), findsOneWidget);
    expect(find.text('Rank'), findsOneWidget);
  });

  testWidgets('renders dash when globalRank is null', (tester) async {
    await tester.pumpWidget(createSubject(user: testUser, globalRank: null));
    await tester.pumpAndSettle();

    expect(find.text('—'), findsOneWidget);
  });

  testWidgets(
    'tapping each of the 4 stats triggers haptics and navigates to correct route',
    (tester) async {
      // 1. Streak navigation
      await tester.pumpWidget(createSubject(user: testUser, globalRank: 4));
      await tester.pumpAndSettle();

      await tester.tap(find.text('STREAK'));
      await tester.pumpAndSettle();
      expect(navigatedRoutes.contains(AppRouter.streakRoute), isTrue);
      verify(() => mockHapticService.selection()).called(1);

      // 2. Coins navigation
      navigatedRoutes.clear();
      await tester.pumpWidget(createSubject(user: testUser, globalRank: 4));
      await tester.pumpAndSettle();

      await tester.tap(find.text('COINS'));
      await tester.pumpAndSettle();
      expect(navigatedRoutes.contains(AppRouter.questCoinsRoute), isTrue);

      // 3. Badges navigation
      navigatedRoutes.clear();
      await tester.pumpWidget(createSubject(user: testUser, globalRank: 4));
      await tester.pumpAndSettle();

      await tester.tap(find.text('BADGES'));
      await tester.pumpAndSettle();
      expect(navigatedRoutes.contains(AppRouter.trophyRoomRoute), isTrue);

      // 4. Rank navigation
      navigatedRoutes.clear();
      await tester.pumpWidget(createSubject(user: testUser, globalRank: 4));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rank'));
      await tester.pumpAndSettle();
      expect(navigatedRoutes.contains(AppRouter.leaderboardRoute), isTrue);
    },
  );

  testWidgets(
    'renders shimmer skeleton cleanly when isLoading or user is null',
    (tester) async {
      await tester.pumpWidget(createSubject(user: null, isLoading: true));
      await tester.pump();

      expect(find.byType(UnifiedStatsRow), findsOneWidget);
      // Values should not be present in shimmer
      expect(find.text('18'), findsNothing);
      expect(find.text('STREAK'), findsNothing);
    },
  );

  testWidgets('renders cleanly on small screen (320dp) without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 2, 568 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      createSubject(user: testUser, globalRank: 12, width: 320, height: 568),
    );
    await tester.pumpAndSettle();

    expect(find.byType(UnifiedStatsRow), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders cleanly in Light mode', (tester) async {
    await tester.pumpWidget(
      createSubject(user: testUser, globalRank: 1, themeMode: ThemeMode.light),
    );
    await tester.pumpAndSettle();

    expect(find.byType(UnifiedStatsRow), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
