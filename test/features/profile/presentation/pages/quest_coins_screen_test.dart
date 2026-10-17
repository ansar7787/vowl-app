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
import 'package:vowl/core/presentation/widgets/hint_ad_card.dart';
import 'package:vowl/core/presentation/widgets/premium_store_bottom_sheet.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/coin_packs_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/payment_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/profile/presentation/pages/quest_coins_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockPaymentService extends Mock implements PaymentService {}

class MockCoinPacksService extends Mock implements CoinPacksService {}

class MockAdService extends Mock implements AdService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockLocaleService mockLocaleService;
  late MockPaymentService mockPaymentService;
  late MockCoinPacksService mockCoinPacksService;
  late MockAppLogger mockLogger;
  late MockAdService mockAdService;
  late StreamController<EconomyState> economyStateController;
  late List<String> navigatedRoutes;

  final now = DateTime.now();
  final testUser = UserEntity(
    id: 'user_vowl_coins_123',
    email: 'coins.tester@vowl.app',
    displayName: 'Coins Explorer',
    coins: 15450,
    hintCount: 7,
    coinHistory: [
      {
        'titleKey': 'coin_history.beginner_quest_reward',
        'amount': 500,
        'isEarned': true,
        'date': now.subtract(const Duration(minutes: 30)).toIso8601String(),
      },
      {
        'titleKey': 'coin_history.purchased_hint_pack',
        'amount': -750,
        'isEarned': false,
        'date': now.subtract(const Duration(hours: 3)).toIso8601String(),
      },
      {
        'titleKey': 'coin_history.ad_reward',
        'amount': 150,
        'isEarned': true,
        'date': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'titleKey': 'coin_history.streak_milestone_reward',
        'params': {'milestone': '7-day'},
        'amount': 300,
        'isEarned': true,
        'date': now.subtract(const Duration(days: 4)).toIso8601String(),
      },
      {
        'titleKey': 'coin_history.level_milestone_reward',
        'params': {'milestone': '5'},
        'amount': 250,
        'isEarned': true,
        'date': now.subtract(const Duration(days: 8)).toIso8601String(),
      },
      {
        'title': 'Legacy Raw Title',
        'amount': 50,
        'isEarned': true,
        'date': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
    ],
  );

  setUpAll(() {
    registerFallbackValue(const AuthReloadUser());
    registerFallbackValue(const EconomyPurchaseHintRequested(750, hintAmount: 5));
    registerFallbackValue(const EconomyPurchaseHintRequested(200, hintAmount: 1));
    registerFallbackValue(const EconomyPurchaseHintRequested(1000, hintAmount: 10));
  });

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({
      'reward_limits_coins_count': 0,
    });
    navigatedRoutes = [];

    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockLocaleService = MockLocaleService();
    mockPaymentService = MockPaymentService();
    mockCoinPacksService = MockCoinPacksService();
    mockLogger = MockAppLogger();
    mockAdService = MockAdService();
    economyStateController = StreamController<EconomyState>.broadcast();

    when(() => mockAuthBloc.state)
        .thenReturn(AuthState.authenticated(testUser));
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => economyStateController.stream);

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});

    when(() => mockPaymentService.init(
          onSuccess: any(named: 'onSuccess'),
          onFailure: any(named: 'onFailure'),
          onExternalWallet: any(named: 'onExternalWallet'),
        )).thenAnswer((_) {});
    when(() => mockCoinPacksService.fetchPacks()).thenAnswer((_) async => []);

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
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    initLocaleServiceReference(mockLocaleService);

    if (di.sl.isRegistered<PaymentService>()) {
      di.sl.unregister<PaymentService>();
    }
    di.sl.registerSingleton<PaymentService>(mockPaymentService);

    if (di.sl.isRegistered<CoinPacksService>()) {
      di.sl.unregister<CoinPacksService>();
    }
    di.sl.registerSingleton<CoinPacksService>(mockCoinPacksService);

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
    di.sl.registerSingleton<AppLogger>(mockLogger);

    if (di.sl.isRegistered<AdService>()) {
      di.sl.unregister<AdService>();
    }
    di.sl.registerSingleton<AdService>(mockAdService);
  });

  tearDown(() async {
    await economyStateController.close();
  });

  Widget buildTestWidget({
    Size screenSize = const Size(390, 844),
    ThemeMode themeMode = ThemeMode.light,
    double textScaleFactor = 1.0,
    bool startAtRoot = false,
  }) {
    final router = GoRouter(
      initialLocation: startAtRoot ? '/' : '/quest-coins',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/quest-coins'),
                child: const Text('Root Route'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/quest-coins',
          builder: (context, state) => const VowlCoinsScreen(),
        ),
        GoRoute(
          path: AppRouter.streakRoute,
          builder: (context, state) {
            navigatedRoutes.add(AppRouter.streakRoute);
            return const Scaffold(body: Text('Streak Screen'));
          },
        ),
        GoRoute(
          path: AppRouter.adventureXPRoute,
          builder: (context, state) {
            navigatedRoutes.add(AppRouter.adventureXPRoute);
            return const Scaffold(body: Text('Adventure XP Screen'));
          },
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
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
      when(() => mockAuthBloc.state)
          .thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Vowl Treasury'), findsNothing);
      expect(find.text('TOTAL BALANCE'), findsNothing);
    });
  });

  group('Group 2: AppBar & Navigation', () {
    testWidgets('renders title, coin badge, and back button pops screen', (tester) async {
      await tester.pumpWidget(buildTestWidget(startAtRoot: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Root Route'));
      await tester.pumpAndSettle();

      expect(find.text('Vowl Treasury'), findsOneWidget);
      expect(find.text('15,450'), findsWidgets);

      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Root Route'), findsOneWidget);
    });
  });

  group('Group 3: Coin Balance Hero Card', () {
    testWidgets('renders total balance, formatted coins, weekly earnings, and hints glance', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('TOTAL BALANCE'), findsOneWidget);
      expect(find.text('15,450'), findsWidgets);
      expect(find.text('7 hints available'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
      expect(find.textContaining('this week'), findsOneWidget);
    });

    testWidgets('hides weekly earnings pill when user has 0 earned coins in past 7 days', (tester) async {
      final userNoEarned = testUser.copyWith(coinHistory: [
        {
          'titleKey': 'coin_history.purchased_hint_pack',
          'amount': -750,
          'isEarned': false,
          'date': now.subtract(const Duration(hours: 1)).toIso8601String(),
        },
      ]);
      when(() => mockAuthBloc.state)
          .thenReturn(AuthState.authenticated(userNoEarned));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.trending_up_rounded), findsNothing);
      expect(find.textContaining('this week'), findsNothing);
    });
  });

  group('Group 4: Ways to Earn Section', () {
    testWidgets('renders Ways to Earn section with streak item, AdRewardCard, and HintAdCard', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('WAYS TO EARN'), findsOneWidget);

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Maintain Daily Streak'),
        100.0,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('Maintain Daily Streak'), findsOneWidget);
      expect(find.byType(AdRewardCard), findsOneWidget);
      expect(find.byType(HintAdCard), findsOneWidget);

      await tester.tap(find.text('Maintain Daily Streak'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes.contains(AppRouter.streakRoute), isTrue);
    });
  });

  group('Group 5: Where to Spend Section Navigation', () {
    testWidgets('tapping Streak Boosters navigates to streakRoute', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Streak Boosters'),
        100.0,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Streak Boosters'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes.contains(AppRouter.streakRoute), isTrue);
    });

    testWidgets('tapping Adventure Store navigates to adventureXPRoute', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Adventure Store'),
        100.0,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adventure Store'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes.contains(AppRouter.adventureXPRoute), isTrue);
    });
  });

  group('Group 6: Hint Store & Purchases', () {
    testWidgets('renders Hint Store packs and confirming purchase dispatches EconomyPurchaseHintRequested', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Hint Store'),
        100.0,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('1 Hint'), findsOneWidget);
      expect(find.text('5 Hints'), findsOneWidget);
      expect(find.text('10 Hints'), findsOneWidget);
      expect(find.text('BEST VALUE'), findsOneWidget);

      // Tap 5 Hints pack
      await tester.tap(find.text('5 Hints'));
      await tester.pumpAndSettle();

      // Confirmation dialog should be displayed
      expect(find.text('Unlock 5 Hints'), findsOneWidget);
      final confirmButton = find.text('CONFIRM');
      expect(confirmButton, findsOneWidget);

      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      verify(() => mockEconomyBloc.add(
            const EconomyPurchaseHintRequested(750, hintAmount: 5),
          )).called(1);
      verify(() => mockHapticService.heavy()).called(1);
    });

    testWidgets('tapping hint pack when user cannot afford triggers light haptic and error snackbar', (tester) async {
      final poorUser = testUser.copyWith(coins: 50);
      when(() => mockAuthBloc.state)
          .thenReturn(AuthState.authenticated(poorUser));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Hint Store'),
        100.0,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('Need 150 more'), findsOneWidget);

      await tester.tap(find.text('1 Hint'));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.light()).called(1);
      expect(find.text('Not enough coins'), findsOneWidget);
      verifyNever(() => mockEconomyBloc.add(any()));
    });
  });

  group('Group 7: Buy More Coins Card', () {
    testWidgets('renders Buy More Coins and tapping opens PremiumStoreBottomSheet', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Buy More Coins'),
        100.0,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('Buy More Coins'), findsOneWidget);
      expect(find.text('Get coin packs with real money'), findsOneWidget);

      await tester.tap(find.text('Buy More Coins'));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);
      expect(find.byType(PremiumStoreBottomSheet), findsOneWidget);
    });
  });

  group('Group 8: Coin History Ledger', () {
    testWidgets('renders empty state when coinHistory is empty', (tester) async {
      final emptyHistoryUser = testUser.copyWith(coinHistory: []);
      when(() => mockAuthBloc.state)
          .thenReturn(AuthState.authenticated(emptyHistoryUser));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('COIN LEDGER'),
        100.0,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('No Transactions Yet'), findsOneWidget);
      expect(find.text('Complete a quest to earn your first coins!'), findsOneWidget);
    });

    testWidgets('renders transaction items with localized titles, amounts, and relative times', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('COIN LEDGER'),
        100.0,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('COIN LEDGER'), findsOneWidget);
      expect(find.text('Beginner Discovery Quests Reward'), findsOneWidget);
      expect(find.text('Purchased Hint Pack'), findsOneWidget);
      expect(find.text('Ad Reward'), findsOneWidget);
      expect(find.text('Legacy Raw Title'), findsOneWidget);
      expect(find.text('30m ago'), findsOneWidget);
      expect(find.text('3h ago'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
    });
  });

  group('Group 9: Refresh Indicator', () {
    testWidgets('pull to refresh dispatches AuthReloadUser event', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.drag(scrollable, const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      verify(() => mockAuthBloc.add(const AuthReloadUser())).called(1);
    });
  });

  group('Group 10: Responsiveness & Themes', () {
    testWidgets('renders cleanly on compact mobile (320x568) without overflow', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        screenSize: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet viewport (800x1280) without overflow', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        screenSize: const Size(800, 1280),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with 1.3x accessibility text scale', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        textScaleFactor: 1.3,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in midnight theme mode', (tester) async {
      final midnightTheme = AppTheme.darkTheme.copyWith(
        scaffoldBackgroundColor: Colors.black,
      );

      final router = GoRouter(
        initialLocation: '/quest-coins',
        routes: [
          GoRoute(
            path: '/quest-coins',
            builder: (context, state) => const VowlCoinsScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) => MaterialApp.router(
              routerConfig: router,
              theme: midnightTheme,
              darkTheme: midnightTheme,
              themeMode: ThemeMode.dark,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
