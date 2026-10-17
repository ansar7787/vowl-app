import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/ad_reward_card.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/reward_limit_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/features/profile/presentation/pages/adventure_xp_screen.dart';
import 'package:vowl/features/profile/presentation/widgets/adventure_daily_xp_chart.dart';
import 'package:vowl/features/profile/presentation/widgets/adventure_mastery_grid.dart';
import 'package:vowl/features/profile/presentation/widgets/adventure_recent_activities.dart';
import 'package:vowl/features/profile/presentation/widgets/adventure_store_section.dart';
import 'package:vowl/features/profile/presentation/widgets/adventure_total_xp_card.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockProgressionBloc
    extends MockBloc<ProgressionEvent, ProgressionState>
    implements ProgressionBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockAdService extends Mock implements AdService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockRewardLimitService extends Mock implements RewardLimitService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockProgressionBloc mockProgressionBloc;
  late MockHapticService mockHapticService;
  late MockAdService mockAdService;
  late MockAppLogger mockLogger;
  late MockRewardLimitService mockRewardLimitService;
  late StreamController<ProgressionState> progressionStateController;
  late List<String> navigatedRoutes;
  final mockLocaleService = MockLocaleService();

  const testUser = UserEntity(
    id: 'user_adv_xp_123',
    email: 'aria.xp@vowl.app',
    displayName: 'Aria XP',
    totalExp: 2645,
    coins: 850,
    streakFreezes: 1,
    hasPermanentXPBoost: false,
    dailyXpHistory: {
      '2026-10-15': 120,
      '2026-10-16': 180,
    },
    completedLevels: {
      'beginner': [1, 2, 3],
      'intermediate': [1],
    },
    recentActivities: [
      {
        'title': 'Completed Lesson 3',
        'subtitle': 'Vocabulary Quiz',
        'xpEarned': 50,
      },
      {
        'title': 'Daily Streak Bonus',
        'subtitle': '+25 XP streak reward',
        'xpEarned': 25,
      },
    ],
  );

  setUpAll(() {
    registerFallbackValue(const ProgressionClearMessageRequested());
    registerFallbackValue(const ProgressionPurchaseStreakFreezeRequested(150));
    registerFallbackValue(const ProgressionActivateDoubleXPRequested(300));
  });

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({
      'reward_limits_coins_count': 0,
    });
    navigatedRoutes = [];

    mockAuthBloc = MockAuthBloc();
    mockProgressionBloc = MockProgressionBloc();
    mockHapticService = MockHapticService();
    mockAdService = MockAdService();
    mockLogger = MockAppLogger();
    mockRewardLimitService = MockRewardLimitService();
    progressionStateController = StreamController<ProgressionState>.broadcast();

    when(() => mockAuthBloc.state)
        .thenReturn(AuthState.authenticated(testUser));
    when(() => mockProgressionBloc.state)
        .thenReturn(const ProgressionState());
    when(() => mockProgressionBloc.stream)
        .thenAnswer((_) => progressionStateController.stream);

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);

    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    when(() => mockLocaleService.tr(
          any(),
          args: any(named: 'args'),
          fallback: any(named: 'fallback'),
        )).thenAnswer((invocation) {
      final key = invocation.positionalArguments[0] as String;
      final args = (invocation.namedArguments[#args] as List<String>?) ?? [];
      final fallback = invocation.namedArguments[#fallback] as String?;
      String text = fallback ?? key;
      for (int i = 0; i < args.length; i++) {
        text = text.replaceAll('{$i}', args[i]);
      }
      return text;
    });
    initLocaleServiceReference(mockLocaleService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);

    if (di.sl.isRegistered<AdService>()) {
      di.sl.unregister<AdService>();
    }
    di.sl.registerSingleton<AdService>(mockAdService);

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
    di.sl.registerSingleton<AppLogger>(mockLogger);

    if (di.sl.isRegistered<RewardLimitService>()) {
      di.sl.unregister<RewardLimitService>();
    }
    di.sl.registerSingleton<RewardLimitService>(mockRewardLimitService);
  });

  tearDown(() {
    progressionStateController.close();
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    if (di.sl.isRegistered<AdService>()) {
      di.sl.unregister<AdService>();
    }
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
    if (di.sl.isRegistered<RewardLimitService>()) {
      di.sl.unregister<RewardLimitService>();
    }
  });

  Widget buildTestWidget({
    Size screenSize = const Size(390, 844),
    ThemeMode themeMode = ThemeMode.light,
    double textScaleFactor = 1.0,
    bool startAtRoot = false,
  }) {
    final router = GoRouter(
      initialLocation: startAtRoot ? '/' : '/adventure-xp',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/adventure-xp'),
                child: const Text('Root Route'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/adventure-xp',
          builder: (context, state) => const AdventureXPScreen(),
        ),
        GoRoute(
          path: AppRouter.kidsZoneRoute,
          builder: (context, state) {
            navigatedRoutes.add(AppRouter.kidsZoneRoute);
            return const Scaffold(body: Text('Kids Zone Screen'));
          },
        ),
        GoRoute(
          path: AppRouter.categoryGamesRoute,
          builder: (context, state) {
            final category = state.uri.queryParameters['category'] ?? '';
            navigatedRoutes.add('${AppRouter.categoryGamesRoute}?category=$category');
            return Scaffold(body: Text('Category Games: $category'));
          },
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<ProgressionBloc>.value(value: mockProgressionBloc),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MediaQuery(
          data: MediaQueryData(
            size: screenSize,
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: MaterialApp.router(
            routerConfig: router,
            themeMode: themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
          ),
        ),
      ),
    );
  }

  group('Group 1: Unauthenticated / Null User State', () {
    testWidgets('renders SizedBox.shrink when user is null', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsNothing);
      expect(find.text('Adventure XP'), findsNothing);
    });
  });

  group('Group 2: AppBar & Navigation', () {
    testWidgets('renders title and back button pops screen', (tester) async {
      await tester.pumpWidget(buildTestWidget(startAtRoot: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Root Route'));
      await tester.pumpAndSettle();

      expect(find.text('Adventure XP'), findsOneWidget);

      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Root Route'), findsOneWidget);
    });
  });

  group('Group 3: Total Experience Card', () {
    testWidgets('renders AdventureTotalXpCard with formatted XP and level info', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AdventureTotalXpCard), findsOneWidget);
      expect(find.text('TOTAL EXPERIENCE'), findsOneWidget);
      expect(find.text('2,645 XP'), findsOneWidget);
    });
  });

  group('Group 4: Daily XP History Chart', () {
    testWidgets('renders AdventureDailyXpChart with weekly total', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AdventureDailyXpChart), findsOneWidget);
      expect(find.text('DAILY XP HISTORY'), findsOneWidget);
    });
  });

  group('Group 5: Language Mastery Grid', () {
    testWidgets('renders AdventureMasteryGrid and tapping kids pushes kidsZoneRoute', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Kids'),
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdventureMasteryGrid), findsOneWidget);
      expect(find.text('Kids'), findsOneWidget);

      await tester.tap(find.text('Kids'));
      await tester.pumpAndSettle();
      expect(navigatedRoutes, contains(AppRouter.kidsZoneRoute));
    });
  });

  group('Group 6: Adventure Store Section', () {
    testWidgets('renders store offers and tapping streak shield dispatches purchase event', (tester) async {
      final userNoFreeze = testUser.copyWith(streakFreezes: 0);
      when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(userNoFreeze));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Streak Shield'),
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Streak Shield'));
      await tester.pumpAndSettle();

      expect(find.byType(AdventureStoreSection), findsOneWidget);
      expect(find.text('Streak Shield'), findsOneWidget);

      // Tap Streak Shield ScaleButton and confirm purchase
      final streakShieldButton = find.descendant(
        of: find.byType(AdventureStoreSection),
        matching: find.byType(ScaleButton),
      ).first;
      await tester.tap(streakShieldButton);
      await tester.pumpAndSettle();

      final purchaseButton = find.text('Purchase');
      if (purchaseButton.evaluate().isNotEmpty) {
        await tester.tap(purchaseButton);
        await tester.pumpAndSettle();
      }

      verify(() => mockProgressionBloc.add(
            const ProgressionPurchaseStreakFreezeRequested(150),
          )).called(1);
    });

    testWidgets('tapping Double XP dispatches activate double XP event', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Double XP'),
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Double XP'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Double XP'));
      await tester.pumpAndSettle();

      final purchaseButton = find.text('Purchase');
      if (purchaseButton.evaluate().isNotEmpty) {
        await tester.tap(purchaseButton);
        await tester.pumpAndSettle();
      }

      verify(() => mockProgressionBloc.add(
            const ProgressionActivateDoubleXPRequested(300),
          )).called(1);
    });
  });

  group('Group 7: Recent Activity', () {
    testWidgets('renders AdventureRecentActivities with activity list', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('RECENT ACTIVITY'),
        150.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdventureRecentActivities), findsOneWidget);
      expect(find.text('RECENT ACTIVITY'), findsOneWidget);
      expect(find.text('Completed Lesson 3'), findsOneWidget);
    });

    testWidgets('renders empty state when recent activities list is empty', (tester) async {
      final emptyActivityUser = testUser.copyWith(recentActivities: []);
      when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(emptyActivityUser));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('RECENT ACTIVITY'),
        150.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('No recent adventures yet.'), findsOneWidget);
    });
  });

  group('Group 8: Ad Reward Card', () {
    testWidgets('renders AdRewardCard at bottom of scrollview', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byType(AdRewardCard),
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdRewardCard), findsOneWidget);
    });
  });

  group('Group 9: ProgressionBloc Listener', () {
    testWidgets('success message triggers light haptic, snackbar, and clears message', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      progressionStateController.add(
        const ProgressionState(message: 'XP Boost Activated!'),
      );
      await tester.pumpAndSettle();

      verify(() => mockHapticService.light()).called(1);
      expect(find.text('XP Boost Activated!'), findsOneWidget);
      verify(() => mockProgressionBloc.add(
            const ProgressionClearMessageRequested(),
          )).called(1);
    });

    testWidgets('insufficient coins message shows localized error snackbar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      progressionStateController.add(
        const ProgressionState(message: 'Not enough coins'),
      );
      await tester.pumpAndSettle();

      verify(() => mockHapticService.light()).called(1);
      expect(find.text('Insufficient Vowl Coins!'), findsOneWidget);
      verify(() => mockProgressionBloc.add(
            const ProgressionClearMessageRequested(),
          )).called(1);
    });

    testWidgets('ServerFailure message logs error and displays generic error', (tester) async {
      when(() => mockLogger.error(any(), error: any(named: 'error'))).thenReturn(null);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      progressionStateController.add(
        const ProgressionState(message: 'ServerFailure: Database timeout'),
      );
      await tester.pumpAndSettle();

      verify(() => mockLogger.error(
            'Unhandled ProgressionBloc message shown as generic error',
            error: 'ServerFailure: Database timeout',
          )).called(1);
      expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
      verify(() => mockProgressionBloc.add(
            const ProgressionClearMessageRequested(),
          )).called(1);
    });
  });

  group('Group 10: Responsiveness & Themes', () {
    testWidgets('renders cleanly on compact mobile (320x568) without overflow', (tester) async {
      await tester.pumpWidget(buildTestWidget(screenSize: const Size(320, 568)));
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet viewport (800x1280) without overflow', (tester) async {
      await tester.pumpWidget(buildTestWidget(screenSize: const Size(800, 1280)));
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with 1.3x accessibility text scale', (tester) async {
      await tester.pumpWidget(buildTestWidget(textScaleFactor: 1.3));
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      await tester.pumpWidget(buildTestWidget(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in midnight theme mode', (tester) async {
      final midnightTheme = AppTheme.darkTheme.copyWith(
        scaffoldBackgroundColor: Colors.black,
      );

      final router = GoRouter(
        initialLocation: '/adventure-xp',
        routes: [
          GoRoute(
            path: '/adventure-xp',
            builder: (context, state) => const AdventureXPScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<ProgressionBloc>.value(value: mockProgressionBloc),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) => MaterialApp.router(
              routerConfig: router,
              themeMode: ThemeMode.dark,
              theme: AppTheme.lightTheme,
              darkTheme: midnightTheme,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
      expect(tester.takeException(), isNull);
    });
  });
}

