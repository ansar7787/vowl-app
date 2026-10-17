import 'dart:async';
import 'dart:convert';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/presentation/feature_catalog/feature_directory_bottom_sheet.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/features/home/presentation/pages/home_screen.dart';
import 'package:vowl/features/home/presentation/widgets/bento_arena.dart';
import 'package:vowl/features/home/presentation/widgets/command_pod.dart';
import 'package:vowl/features/home/presentation/widgets/continue_learning_card.dart';
import 'package:vowl/features/home/presentation/widgets/daily_motivation_card.dart';
import 'package:vowl/features/home/presentation/widgets/discovery_deck.dart';
import 'package:vowl/features/home/presentation/widgets/global_progress_card.dart';
import 'package:vowl/features/home/presentation/widgets/home_section_header.dart';
import 'package:vowl/features/home/presentation/widgets/mystery_chest_dialog.dart';
import 'package:vowl/features/home/presentation/widgets/review_mistakes_home_card.dart';
import 'package:vowl/features/home/presentation/widgets/tools_strip.dart';
import 'package:vowl/features/home/presentation/widgets/unified_stats_row.dart';
import 'package:vowl/features/leaderboard/domain/repositories/leaderboard_repository.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockProgressionBloc extends MockBloc<ProgressionEvent, ProgressionState>
    implements ProgressionBloc {}

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

class MockHapticService extends Mock implements HapticService {}

class MockAdService extends Mock implements AdService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockProgressionBloc mockProgressionBloc;
  late MockLeaderboardRepository mockLeaderboardRepo;
  late MockHapticService mockHapticService;
  late MockAdService mockAdService;
  late MockAppLogger mockLogger;
  late ScrollController homeScrollController;
  late List<String> navigatedRoutes;
  final mockLocaleService = MockLocaleService();

  const testUser = UserEntity(
    id: 'user_123',
    email: 'learner@vowl.app',
    displayName: 'Aria Stark',
    currentStreak: 12,
    totalExp: 1400, // Level 15 (Commander tier)
    coins: 350,
    badges: ['first_win', 'streak_7'],
    completedLevels: {
      'vocabulary': [1, 2, 3],
      'listening': [1, 2],
      'reading': [1],
    },
  );

  setUpAll(() {
    try {
      initLocaleServiceReference(mockLocaleService);
    } catch (_) {}
  });

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({
      'has_seen_vowl_welcome_showcase': true,
      'notifications_enabled': false,
    });
    navigatedRoutes = [];
    reset(mockLocaleService);

    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockProgressionBloc = MockProgressionBloc();
    mockLeaderboardRepo = MockLeaderboardRepository();
    mockHapticService = MockHapticService();
    mockAdService = MockAdService();
    mockLogger = MockAppLogger();
    homeScrollController = ScrollController();

    if (di.sl.isRegistered<ScrollController>(instanceName: 'home')) {
      di.sl.unregister<ScrollController>(instanceName: 'home');
    }
    if (di.sl.isRegistered<LeaderboardRepository>()) {
      di.sl.unregister<LeaderboardRepository>();
    }
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();

    di.sl.registerSingleton<ScrollController>(
      homeScrollController,
      instanceName: 'home',
    );
    di.sl.registerSingleton<LeaderboardRepository>(mockLeaderboardRepo);
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<AdService>(mockAdService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockLogger);

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.rhythmicTick()).thenAnswer((_) async {});

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

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(testUser),
    );
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockProgressionBloc.state).thenReturn(const ProgressionState());

    when(() => mockLeaderboardRepo.getTopUsers(limit: any(named: 'limit')))
        .thenAnswer(
          (_) async => Right(
            LeaderboardResult(
              users: [testUser],
              lastUpdated: DateTime.now(),
            ),
          ),
        );
  });

  tearDown(() {
    homeScrollController.dispose();
    if (di.sl.isRegistered<ScrollController>(instanceName: 'home')) {
      di.sl.unregister<ScrollController>(instanceName: 'home');
    }
    if (di.sl.isRegistered<LeaderboardRepository>()) {
      di.sl.unregister<LeaderboardRepository>();
    }
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Widget createWidgetUnderTest({
    ThemeMode themeMode = ThemeMode.light,
    GoRouter? customRouter,
  }) {
    final router =
        customRouter ??
        GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/streak',
              builder: (context, state) {
                navigatedRoutes.add('/streak');
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
              path: '/trophy-room',
              builder: (context, state) {
                navigatedRoutes.add('/trophy-room');
                return const Scaffold(body: Text('Trophy Room'));
              },
            ),
            GoRoute(
              path: '/leaderboard',
              builder: (context, state) {
                navigatedRoutes.add('/leaderboard');
                return const Scaffold(body: Text('Leaderboard Screen'));
              },
            ),
            GoRoute(
              path: '/category-games',
              builder: (context, state) {
                final cat = state.uri.queryParameters['category'] ?? '';
                navigatedRoutes.add('/category-games?category=$cat');
                return Scaffold(body: Text('Category Games: $cat'));
              },
            ),
            GoRoute(
              path: '/library',
              builder: (context, state) {
                navigatedRoutes.add('/library');
                return const Scaffold(body: Text('Quest Library'));
              },
            ),
            GoRoute(
              path: '/quest-sequence',
              builder: (context, state) {
                final id = state.uri.queryParameters['id'] ?? '';
                navigatedRoutes.add('/quest-sequence?id=$id');
                return Scaffold(body: Text('Quest Sequence: $id'));
              },
            ),
            GoRoute(
              path: '/kids-zone',
              builder: (context, state) {
                navigatedRoutes.add('/kids-zone');
                return const Scaffold(body: Text('Kids Zone'));
              },
            ),
            GoRoute(
              path: '/review-mistakes',
              builder: (context, state) {
                navigatedRoutes.add('/review-mistakes');
                return const Scaffold(body: Text('Review Mistakes'));
              },
            ),
          ],
        );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        BlocProvider<ProgressionBloc>.value(value: mockProgressionBloc),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
        ),
      ),
    );
  }

  Future<void> pumpHomeScreen(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
    GoRouter? customRouter,
    Size surfaceSize = const Size(390, 1600),
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(
      createWidgetUnderTest(
        themeMode: themeMode,
        customRouter: customRouter,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Group 1: Authentication & Loading States', () {
    testWidgets(
      'renders HomeShimmerLoading when user is null and no error message',
      (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthState.unknown());

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.byType(HomeShimmerLoading), findsOneWidget);
        expect(find.byType(CommandPod), findsNothing);
      },
    );

    testWidgets(
      'renders error view with cloud_off icon and Try Again button when user is null and message exists',
      (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          const AuthState.unknown().copyWith(
            message: () => 'Network connectivity failure',
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Try Again button in error view dispatches AuthReloadUser to AuthBloc',
      (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          const AuthState.unknown().copyWith(
            message: () => 'Network connectivity failure',
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        await tester.tap(find.text('Try Again'));
        await tester.pump();

        verify(() => mockAuthBloc.add(const AuthReloadUser())).called(1);
      },
    );
  });

  group('Group 2: Main Home Feed Initial Layout & Hero Header', () {
    testWidgets(
      'renders hero header CommandPod with user display name and Commander rank badge',
      (tester) async {
        await pumpHomeScreen(tester);

        expect(find.byType(CommandPod), findsOneWidget);
        expect(find.text('Aria'), findsOneWidget);
        expect(find.text('15'), findsOneWidget); // Level 15 badge
        expect(find.text('COMMANDER'), findsOneWidget);
      },
    );

    testWidgets(
      'renders Rookie rank badge for a level 1 user',
      (tester) async {
        const rookieUser = UserEntity(
          id: 'user_rookie',
          email: 'rookie@vowl.app',
          displayName: 'New Learner',
          totalExp: 50, // Level 1
        );
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(rookieUser),
        );
        when(() => mockLeaderboardRepo.getTopUsers(limit: any(named: 'limit')))
            .thenAnswer(
              (_) async => Right(
                LeaderboardResult(
                  users: [rookieUser],
                  lastUpdated: DateTime.now(),
                ),
              ),
            );

        await pumpHomeScreen(tester);

        expect(find.text('ROOKIE'), findsOneWidget);
        expect(find.text('1'), findsWidgets);
      },
    );
  });

  group('Group 3: Continue Learning CTA Card', () {
    testWidgets(
      'renders ContinueLearningCard showing next uncompleted category',
      (tester) async {
        await pumpHomeScreen(tester);

        expect(find.byType(ContinueLearningCard), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
      },
    );

    testWidgets(
      'tapping ContinueLearningCard triggers selection haptics and navigates to category games route',
      (tester) async {
        await pumpHomeScreen(tester);

        await tester.tap(
          find.byType(ContinueLearningCard),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        verify(() => mockHapticService.selection()).called(1);
        expect(navigatedRoutes.length, 1);
        expect(navigatedRoutes.first, startsWith('/category-games?category='));
      },
    );
  });

  group('Group 4: Unified Stats Row', () {
    testWidgets(
      'renders all 4 stat tiles with streak, coins, badges, and rank',
      (tester) async {
        await pumpHomeScreen(tester);

        expect(find.byType(UnifiedStatsRow), findsOneWidget);
        expect(find.text('12'), findsWidgets); // Current streak
        expect(find.text('350'), findsOneWidget); // Coins
        expect(find.text('2'), findsWidgets); // Badges count
        expect(find.text('#1'), findsWidgets); // Global rank from mock repo
      },
    );

    testWidgets(
      'tapping streak stat tile navigates to /streak',
      (tester) async {
        await pumpHomeScreen(tester);

        await tester.tap(find.text('STREAK'));
        await tester.pumpAndSettle();

        expect(navigatedRoutes, contains('/streak'));
      },
    );

    testWidgets(
      'tapping coins stat tile navigates to /coins-details',
      (tester) async {
        await pumpHomeScreen(tester);

        await tester.tap(find.text('COINS'));
        await tester.pumpAndSettle();

        expect(navigatedRoutes, contains(AppRouter.questCoinsRoute));
      },
    );

    testWidgets(
      'tapping badges stat tile navigates to /trophy-room',
      (tester) async {
        await pumpHomeScreen(tester);

        await tester.tap(find.text('BADGES'));
        await tester.pumpAndSettle();

        expect(navigatedRoutes, contains('/trophy-room'));
      },
    );

    testWidgets(
      'tapping global rank stat tile navigates to /leaderboard',
      (tester) async {
        await pumpHomeScreen(tester);

        await tester.tap(find.text('Rank'));
        await tester.pumpAndSettle();

        expect(navigatedRoutes, contains('/leaderboard'));
      },
    );
  });

  group('Group 5: Leaderboard Rank Fetching & Error Resilience', () {
    testWidgets(
      'gracefully handles LeaderboardRepository failure showing fallback dash for rank',
      (tester) async {
        when(() => mockLeaderboardRepo.getTopUsers(limit: any(named: 'limit')))
            .thenAnswer(
              (_) async => const Left(ServerFailure('Connection refused')),
            );

        await pumpHomeScreen(tester);

        expect(
          find.descendant(
            of: find.byType(UnifiedStatsRow),
            matching: find.text('—'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'gracefully catches exceptions from LeaderboardRepository without failing UI',
      (tester) async {
        when(() => mockLeaderboardRepo.getTopUsers(limit: any(named: 'limit')))
            .thenThrow(Exception('Simulated crash in repository'));

        await pumpHomeScreen(tester);

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(UnifiedStatsRow),
            matching: find.text('—'),
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('Group 6: Quest Arena & BentoArena', () {
    testWidgets(
      'renders Quest Arena section header and navigates to library on See All',
      (tester) async {
        await pumpHomeScreen(tester);

        expect(find.text('QUEST ARENA'), findsOneWidget);
        expect(find.text('Pick up where you left off'), findsOneWidget);

        final seeAllButton = find.descendant(
          of: find.byType(HomeSectionHeader),
          matching: find.text('SEE ALL'),
        );
        expect(seeAllButton, findsOneWidget);

        await tester.tap(seeAllButton);
        await tester.pumpAndSettle();

        expect(navigatedRoutes, contains('/library'));
      },
    );

    testWidgets(
      'renders BentoArena in collapsed mode with See All 9 Categories toggle',
      (tester) async {
        await pumpHomeScreen(tester);

        expect(find.byType(BentoArena), findsOneWidget);
        expect(find.text('See All 9 Categories'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping See All 9 Categories toggle expands BentoArena to show all categories and Show Less',
      (tester) async {
        await pumpHomeScreen(tester);

        final expandButton = find.text('See All 9 Categories');
        await tester.tap(expandButton);
        await tester.pumpAndSettle();

        expect(find.text('Show Less'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping a category tile in BentoArena navigates to category games route',
      (tester) async {
        await pumpHomeScreen(tester);

        final firstCategoryTile = find.descendant(
          of: find.byType(BentoArena),
          matching: find.byType(ScaleButton),
        ).first;

        await tester.tap(firstCategoryTile);
        await tester.pumpAndSettle();

        expect(navigatedRoutes.length, 1);
        expect(navigatedRoutes.first, startsWith('/category-games?category='));
      },
    );
  });

  group('Group 7: Review Mistakes Card Gating', () {
    testWidgets(
      'omits ReviewMistakesHomeCard when user is in kidsModeOnly',
      (tester) async {
        const kidsUser = UserEntity(
          id: 'user_kids',
          email: 'kids@vowl.app',
          displayName: 'Junior',
          totalExp: 0,
          completedLevels: {
            'kidsAlphabet': [1, 2],
          },
        );
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(kidsUser),
        );
        when(() => mockLeaderboardRepo.getTopUsers(limit: any(named: 'limit')))
            .thenAnswer(
              (_) async => Right(
                LeaderboardResult(
                  users: [kidsUser],
                  lastUpdated: DateTime.now(),
                ),
              ),
            );

        await pumpHomeScreen(tester);

        expect(find.byType(ReviewMistakesHomeCard), findsNothing);
      },
    );

    testWidgets(
      'omits mistake card body when non-kids user has 0 mistakes in journal',
      (tester) async {
        await pumpHomeScreen(tester);

        expect(find.byType(ReviewMistakesHomeCard), findsOneWidget);
        expect(find.text('Review Mistakes'), findsNothing);
      },
    );

    testWidgets(
      'renders ReviewMistakesHomeCard and navigates to /review-mistakes when guest mistakes exist',
      (tester) async {
        final mockMistake = jsonEncode({
          'id': 'entry_1',
          'gameType': 'syllableStress',
          'question': 'Identify stress in banana',
          'userAnswer': 'ba-NA-na',
          'correctAnswer': 'ba-NA-na',
          'level': 1,
        });

        SharedPreferences.setMockInitialValues({
          'has_seen_vowl_welcome_showcase': true,
          'vowl_local_error_journal': [mockMistake],
        });

        const guestUser = UserEntity(
          id: 'local',
          email: 'guest@vowl.app',
          displayName: 'Guest Learner',
        );
        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(guestUser),
        );
        when(() => mockLeaderboardRepo.getTopUsers(limit: any(named: 'limit')))
            .thenAnswer(
              (_) async => Right(
                LeaderboardResult(
                  users: [guestUser],
                  lastUpdated: DateTime.now(),
                ),
              ),
            );

        await pumpHomeScreen(tester);

        homeScrollController.jumpTo(350);
        await tester.pumpAndSettle();

        final mistakeCard = find.byType(ReviewMistakesHomeCard);
        expect(mistakeCard, findsOneWidget);

        final tapTarget = find.descendant(
          of: mistakeCard,
          matching: find.byType(ScaleButton),
        );
        await tester.tap(tapTarget);
        await tester.pumpAndSettle();

        verify(() => mockHapticService.selection()).called(1);
        expect(navigatedRoutes, contains('/review-mistakes'));
      },
    );
  });

  group('Group 8: Global Progress Card', () {
    testWidgets(
      'renders GlobalProgressCard displaying total completed levels and navigates to leaderboard',
      (tester) async {
        await pumpHomeScreen(tester);

        homeScrollController.jumpTo(700);
        await tester.pumpAndSettle();

        final progressCard = find.byType(GlobalProgressCard);
        expect(progressCard, findsOneWidget);

        final tapTarget = find.descendant(
          of: progressCard,
          matching: find.byType(ScaleButton),
        );
        await tester.tap(tapTarget);
        await tester.pumpAndSettle();

        expect(navigatedRoutes, contains('/leaderboard'));
      },
    );
  });

  group('Group 9: Explore & Tools Strip', () {
    testWidgets(
      'renders Explore & Tools section header and ToolsStrip',
      (tester) async {
        await pumpHomeScreen(tester);

        homeScrollController.jumpTo(750);
        await tester.pumpAndSettle();

        expect(find.text('EXPLORE & TOOLS'), findsOneWidget);
        expect(find.byType(ToolsStrip), findsOneWidget);
      },
    );

    testWidgets(
      'tapping See All in Explore & Tools opens FeatureDirectoryBottomSheet',
      (tester) async {
        await pumpHomeScreen(tester);

        homeScrollController.jumpTo(750);
        await tester.pumpAndSettle();

        final seeAllButtons = find.text('SEE ALL');
        expect(seeAllButtons, findsWidgets);

        await tester.tap(seeAllButtons.last);
        await tester.pumpAndSettle();

        expect(find.byType(FeatureDirectoryBottomSheet), findsOneWidget);
      },
    );
  });

  group('Group 10: Discovery Hub Carousel', () {
    testWidgets(
      'renders Discovery Hub section header and DiscoveryDeck carousel',
      (tester) async {
        await pumpHomeScreen(tester);

        homeScrollController.jumpTo(1050);
        await tester.pumpAndSettle();

        expect(find.text('DISCOVERY HUB'), findsOneWidget);
        expect(find.byType(DiscoveryDeck), findsOneWidget);
      },
    );

    testWidgets(
      'tapping a themed quest card launches quest sequence route',
      (tester) async {
        await pumpHomeScreen(tester);

        homeScrollController.jumpTo(1050);
        await tester.pumpAndSettle();

        final discoveryDeck = find.byType(DiscoveryDeck);
        final deckCard = find.descendant(
          of: discoveryDeck,
          matching: find.byType(ScaleButton),
        ).first;

        await tester.tap(deckCard);
        await tester.pumpAndSettle();

        expect(navigatedRoutes.length, 1);
        expect(navigatedRoutes.first, startsWith('/quest-sequence?id='));
      },
    );
  });

  group('Group 11: Daily Wisdom Card', () {
    testWidgets(
      'renders DailyMotivationCard with current streak count',
      (tester) async {
        await pumpHomeScreen(tester);

        homeScrollController.jumpTo(1400);
        await tester.pumpAndSettle();

        expect(find.byType(DailyMotivationCard), findsOneWidget);
      },
    );
  });

  group('Group 12: Pull-to-Refresh Interaction', () {
    testWidgets(
      'pulling down RefreshIndicator dispatches AuthReloadUser and EconomyCheckDailyRewardRequested',
      (tester) async {
        await pumpHomeScreen(tester);

        tester
            .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
            .show();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        verify(() => mockAuthBloc.add(const AuthReloadUser())).called(1);
        verify(
          () => mockEconomyBloc.add(const EconomyCheckDailyRewardRequested()),
        ).called(greaterThanOrEqualTo(1));
      },
    );
  });

  group('Group 13: MultiBlocListener State Triggers', () {
    testWidgets(
      'dispatches EconomyCheckDailyRewardRequested on initial mount when authenticated',
      (tester) async {
        await pumpHomeScreen(tester);

        verify(
          () => mockEconomyBloc.add(const EconomyCheckDailyRewardRequested()),
        ).called(1);
      },
    );

    testWidgets(
      'dispatches EconomyResetRequested and ProgressionResetRequested on unauthenticated transition',
      (tester) async {
        final authStreamController = StreamController<AuthState>.broadcast();
        whenListen(
          mockAuthBloc,
          authStreamController.stream,
          initialState: AuthState.authenticated(testUser),
        );

        await pumpHomeScreen(tester);

        // Transition to unauthenticated
        authStreamController.add(const AuthState.unauthenticated());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        verify(
          () => mockEconomyBloc.add(const EconomyResetRequested()),
        ).called(1);
        verify(
          () => mockProgressionBloc.add(const ProgressionResetRequested()),
        ).called(1);

        await authStreamController.close();
      },
    );

    testWidgets(
      'presents MysteryChestDialog when EconomyState.isDailyRewardAvailable transitions to true',
      (tester) async {
        final economyStreamController =
            StreamController<EconomyState>.broadcast();
        whenListen(
          mockEconomyBloc,
          economyStreamController.stream,
          initialState: const EconomyState(isDailyRewardAvailable: false),
        );

        await pumpHomeScreen(tester);

        expect(find.byType(MysteryChestDialog), findsNothing);

        // Emit reward available
        economyStreamController.add(
          const EconomyState(isDailyRewardAvailable: true),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(MysteryChestDialog), findsOneWidget);

        await economyStreamController.close();
      },
    );
  });

  group('Group 14: Responsive Viewports & Accessibility', () {
    testWidgets(
      'renders without RenderFlex overflow on small mobile (320x568)',
      (tester) async {
        await pumpHomeScreen(
          tester,
          surfaceSize: const Size(320, 568),
        );

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders without issues on tablet viewport (800x1280)',
      (tester) async {
        await pumpHomeScreen(
          tester,
          surfaceSize: const Size(800, 1280),
        );

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders cleanly under 1.3x accessibility text scaling',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: createWidgetUnderTest(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders cleanly in dark theme mode',
      (tester) async {
        await pumpHomeScreen(
          tester,
          themeMode: ThemeMode.dark,
        );

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
