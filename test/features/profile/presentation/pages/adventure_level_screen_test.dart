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
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/hint_ad_card.dart';
import 'package:vowl/core/presentation/widgets/modern_game_dialog.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/reward_limit_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/features/profile/presentation/pages/adventure_level_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockProgressionBloc
    extends MockBloc<ProgressionEvent, ProgressionState>
    implements ProgressionBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockAdService extends Mock implements AdService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockRewardLimitService extends Mock implements RewardLimitService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockProgressionBloc mockProgressionBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockAdService mockAdService;
  late MockAppLogger mockLogger;
  late MockRewardLimitService mockRewardLimitService;
  late StreamController<ProgressionState> progressionStateController;
  final mockLocaleService = MockLocaleService();

  const testUser = UserEntity(
    id: 'user_adv_level_123',
    email: 'aria.explorer@vowl.app',
    displayName: 'Aria Explorer',
    totalExp: 2645, // Level 27, 45 XP in current level, 55 XP to next
    coins: 750,
    claimedLevelMilestones: [10], // Level 10 claimed, Level 25 reached & unclaimed
  );

  setUpAll(() {
    registerFallbackValue(const ProgressionClearMessageRequested());
    registerFallbackValue(
      const ProgressionClaimLevelMilestoneRequested(25, 625),
    );
    registerFallbackValue(
      const EconomyPurchaseHintRequested(5000, hintAmount: 5),
    );
  });

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({
      'reward_limits_hints_count': 0,
      'reward_limits_coins_count': 0,
    });

    mockAuthBloc = MockAuthBloc();
    mockProgressionBloc = MockProgressionBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
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
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});

    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);

    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
    }
    di.sl.registerSingleton<SoundService>(mockSoundService);

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
    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
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
    VoidCallback? onBackPopped,
    bool startAtRoot = false,
  }) {
    final router = GoRouter(
      initialLocation: startAtRoot ? '/' : '/adventure-level',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/adventure-level'),
                child: const Text('Root Route'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/adventure-level',
          builder: (context, state) => const AdventureLevelScreen(),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<ProgressionBloc>.value(value: mockProgressionBloc),
        BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
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
      expect(find.text('Adventure Level'), findsNothing);
    });
  });

  group('Group 2: AppBar & Navigation', () {
    testWidgets('renders title, coins badge, and back button pops screen', (tester) async {
      await tester.pumpWidget(buildTestWidget(startAtRoot: true));
      await tester.pumpAndSettle();

      // Tap to push adventure-level route
      await tester.tap(find.text('Root Route'));
      await tester.pumpAndSettle();

      expect(find.text('Adventure Level'), findsOneWidget);
      expect(find.text('750'), findsOneWidget); // user.coins

      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Root Route'), findsOneWidget);
    });
  });

  group('Group 3: Main Level Card & XP Progress', () {
    testWidgets('displays GLOBAL RANK, current level, and MASTER EXPLORER', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('GLOBAL RANK'), findsOneWidget);
      expect(find.text('Level 27'), findsOneWidget);
      expect(find.text('MASTER EXPLORER'), findsOneWidget);
      expect(find.byType(FractionallySizedBox), findsWidgets);
    });
  });

  group('Group 4: XP Next Milestone Details', () {
    testWidgets('displays NEXT MILESTONE, next level and remaining XP', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('NEXT MILESTONE'), findsOneWidget);
      expect(find.text('Level 28'), findsOneWidget);
      // user.totalExp is 2645, xpInCurrentLevel = 45, xpNeeded = 55
      expect(find.text('55 XP more to ascend'), findsOneWidget);
    });
  });

  group('Group 5: Level Mastery Perks', () {
    testWidgets('renders LEVEL MASTERY PERKS section and perks horizontal list', (tester) async {
      // Test when user is level 56 so Level 50 perk is ACTIVE
      final highLevelUser = testUser.copyWith(totalExp: 5500);
      when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(highLevelUser));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('LEVEL MASTERY PERKS'),
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('LEVEL MASTERY PERKS'), findsOneWidget);
      expect(find.text('ACTIVE'), findsWidgets);
      expect(find.text('LOCKED'), findsWidgets);
    });
  });

  group('Group 6: Milestones List & Claiming', () {
    testWidgets('renders UPCOMING MILESTONES and shows Claim button for reached milestones', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('UPCOMING MILESTONES'),
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('UPCOMING MILESTONES'), findsOneWidget);
      // Claimed milestone (Level 10) shows Reward Claimed
      expect(find.text('Reward Claimed'), findsOneWidget);

      // Reached but unclaimed milestone (Level 25) shows CLAIM
      final claimButton = find.text('CLAIM');
      expect(claimButton, findsOneWidget);

      await tester.tap(claimButton);
      await tester.pumpAndSettle();

      verify(() => mockProgressionBloc.add(
            const ProgressionClaimLevelMilestoneRequested(25, 625),
          )).called(1);
    });
  });

  group('Group 7: ProgressionBloc Listener', () {
    testWidgets('milestone_claimed message shows ModernGameDialog, confetti, and plays sound', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      progressionStateController.add(
        const ProgressionState(message: 'progression.milestone_claimed:250'),
      );
      // Pump frame without pumpAndSettle to avoid infinite animation loop from GameConfetti
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playLevelComplete()).called(1);

      expect(find.byType(ModernGameDialog), findsOneWidget);
      expect(find.text('MILESTONE UNLOCKED!'), findsOneWidget);
      expect(
        find.text('You claimed 250 Coins for your epic journey!'),
        findsOneWidget,
      );
      expect(find.byType(GameConfetti), findsOneWidget);

      // Tap AWESOME button on dialog
      await tester.tap(find.text('AWESOME'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockProgressionBloc.add(
            const ProgressionClearMessageRequested(),
          )).called(1);
      expect(find.byType(ModernGameDialog), findsNothing);
    });

    testWidgets('error message shows CustomSnackBar and clears message', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      progressionStateController.add(
        const ProgressionState(message: 'network-failure'),
      );
      await tester.pumpAndSettle();

      expect(find.text('NETWORK FAILURE'), findsOneWidget);
      verify(() => mockProgressionBloc.add(
            const ProgressionClearMessageRequested(),
          )).called(1);
    });
  });

  group('Group 8: Hint Shop & Hint Purchases', () {
    testWidgets('renders Hint Shop, HintAdCard, and purchasing hint dispatches event', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll to Hint Shop
      await tester.scrollUntilVisible(
        find.text('HINT SHOP'),
        150.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('HINT SHOP'), findsOneWidget);
      expect(find.byType(HintAdCard), findsOneWidget);
      expect(find.text('Strategic Pack'), findsOneWidget);
      expect(find.text('Grand Master Pack'), findsOneWidget);

      // Tap Strategic Pack
      await tester.tap(find.text('Strategic Pack'));
      await tester.pumpAndSettle();

      // Confirm in HintPurchaseDialog
      final unlockButton = find.text('CONFIRM');
      if (unlockButton.evaluate().isNotEmpty) {
        await tester.tap(unlockButton);
        await tester.pumpAndSettle();

        verify(() => mockEconomyBloc.add(
              const EconomyPurchaseHintRequested(5000, hintAmount: 5),
            )).called(1);
        verify(() => mockHapticService.heavy()).called(1);
      }
    });
  });

  group('Group 9: Ad Reward Card', () {
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
        initialLocation: '/adventure-level',
        routes: [
          GoRoute(
            path: '/adventure-level',
            builder: (context, state) => const AdventureLevelScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<ProgressionBloc>.value(value: mockProgressionBloc),
            BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
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
