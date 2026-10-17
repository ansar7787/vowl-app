import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/features/home/presentation/pages/streak_screen.dart';
import 'package:vowl/features/home/presentation/widgets/streak_boosters_shop.dart';
import 'package:vowl/features/home/presentation/widgets/streak_calendar.dart';
import 'package:vowl/features/home/presentation/widgets/streak_hero.dart';
import 'package:vowl/features/home/presentation/widgets/streak_milestones.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockProgressionBloc
    extends MockBloc<ProgressionEvent, ProgressionState>
    implements ProgressionBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAdService extends Mock implements AdService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockProgressionBloc mockProgressionBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockLocaleService mockLocaleService;
  late MockAdService mockAdService;
  late List<String> navigatedRoutes;

  final testUser = UserEntity(
    id: 'user_streak_123',
    email: 'phoenix@vowl.app',
    displayName: 'Phoenix Learner',
    currentStreak: 15,
    totalExp: 3500,
    streakFreezes: 2,
    coins: 450,
    lastLoginDate: DateTime.now(),
    claimedStreakMilestones: const [3, 7],
  );

  setUpAll(() {
    mockLocaleService = MockLocaleService();
    try {
      initLocaleServiceReference(mockLocaleService);
    } catch (_) {}
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    VowlMotion.lowAnimationModeOverride.value = true;
    navigatedRoutes = [];
    reset(mockLocaleService);

    mockAuthBloc = MockAuthBloc();
    mockProgressionBloc = MockProgressionBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockAdService = MockAdService();

    if (di.sl.isRegistered<AdService>()) {
      di.sl.unregister<AdService>();
    }
    di.sl.registerSingleton<AdService>(mockAdService);

    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));
    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer((inv) {
      final fallback = inv.namedArguments[#fallback] as String?;
      final key = inv.positionalArguments.first as String;
      final args = inv.namedArguments[#args] as List<String>?;

      String result = fallback ?? key;
      if (args != null && args.isNotEmpty) {
        for (final arg in args) {
          result = result.replaceFirst('{}', arg);
        }
      }
      return result;
    });

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(testUser),
    );
    when(() => mockProgressionBloc.state).thenReturn(
      const ProgressionState(),
    );
    when(() => mockEconomyBloc.state).thenReturn(
      const EconomyState(),
    );
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<AdService>()) {
      di.sl.unregister<AdService>();
    }
  });

  Widget createWidgetUnderTest({
    ThemeData? theme,
    List<RouteBase>? extraRoutes,
    String initialLocation = '/streak',
    GoRouter? routerConfig,
  }) {
    final router = routerConfig ??
        GoRouter(
          initialLocation: initialLocation,
          routes: [
            GoRoute(
              path: '/streak',
              builder: (context, state) => MultiBlocProvider(
                providers: [
                  BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                  BlocProvider<ProgressionBloc>.value(
                    value: mockProgressionBloc,
                  ),
                  BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
                ],
                child: const StreakScreen(),
              ),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) {
                navigatedRoutes.add('/home');
                return const Scaffold(body: Text('Home Screen'));
              },
            ),
            if (extraRoutes != null) ...extraRoutes,
          ],
        );

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          routerConfig: router,
          theme: theme ??
              ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                fontFamily: 'Outfit',
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFFF97316),
                  surface: Colors.white,
                  onSurface: Color(0xFF0F172A),
                ),
              ),
        );
      },
    );
  }

  Future<void> pumpStreakScreen(
    WidgetTester tester, {
    ThemeData? theme,
    List<RouteBase>? extraRoutes,
    String initialLocation = '/streak',
    GoRouter? routerConfig,
    Size viewportSize = const Size(390, 844),
    double textScaleFactor = 1.0,
    bool settle = true,
  }) async {
    tester.view.physicalSize = viewportSize;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(
      createWidgetUnderTest(
        theme: theme,
        extraRoutes: extraRoutes,
        initialLocation: initialLocation,
        routerConfig: routerConfig,
      ),
    );

    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('Group 1: Authentication & Loading States', () {
    testWidgets(
      'renders HomeShimmerLoading placeholder when user is null',
      (tester) async {
        when(() => mockAuthBloc.state).thenReturn(
          const AuthState.unauthenticated(),
        );

        await pumpStreakScreen(tester, settle: false);

        expect(find.byType(HomeShimmerLoading), findsOneWidget);
        expect(find.byType(CustomScrollView), findsNothing);
      },
    );

    testWidgets(
      'renders full streak screen with CustomScrollView when user is authenticated',
      (tester) async {
        await pumpStreakScreen(tester);

        expect(find.byType(StreakScreen), findsOneWidget);
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.byType(HomeShimmerLoading), findsNothing);
      },
    );
  });

  group('Group 2: Floating Glass Island AppBar & Inventory', () {
    testWidgets(
      'renders DAILY STREAK title pill, fire icon, and back button',
      (tester) async {
        await pumpStreakScreen(tester);

        expect(find.text('DAILY STREAK'), findsOneWidget);
        expect(find.byIcon(Icons.local_fire_department_rounded), findsWidgets);
        expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'tapping back button when canPop is false navigates to /home',
      (tester) async {
        await pumpStreakScreen(tester);

        final backBtnFinder = find.byWidgetPredicate(
          (w) =>
              w is ScaleButton &&
              w.child is Container &&
              find
                  .descendant(
                    of: find.byWidget(w),
                    matching: find.byIcon(Icons.arrow_back_ios_new_rounded),
                  )
                  .evaluate()
                  .isNotEmpty,
        );

        expect(backBtnFinder, findsOneWidget);
        await tester.tap(backBtnFinder);
        await tester.pumpAndSettle();

        expect(navigatedRoutes, contains('/home'));
        expect(find.text('Home Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping back button when canPop is true pops the route',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/initial',
          routes: [
            GoRoute(
              path: '/initial',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => context.push('/streak'),
                    child: const Text('Open Streak'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/streak',
              builder: (context, state) => MultiBlocProvider(
                providers: [
                  BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                  BlocProvider<ProgressionBloc>.value(
                    value: mockProgressionBloc,
                  ),
                  BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
                ],
                child: const StreakScreen(),
              ),
            ),
          ],
        );

        await pumpStreakScreen(
          tester,
          routerConfig: router,
          initialLocation: '/initial',
        );

        await tester.tap(find.text('Open Streak'));
        await tester.pumpAndSettle();
        expect(find.text('DAILY STREAK'), findsOneWidget);

        final backBtnFinder = find.byWidgetPredicate(
          (w) =>
              w is ScaleButton &&
              w.child is Container &&
              find
                  .descendant(
                    of: find.byWidget(w),
                    matching: find.byIcon(Icons.arrow_back_ios_new_rounded),
                  )
                  .evaluate()
                  .isNotEmpty,
        );

        await tester.tap(backBtnFinder);
        await tester.pumpAndSettle();

        expect(find.text('Open Streak'), findsOneWidget);
        expect(find.text('DAILY STREAK'), findsNothing);
      },
    );

    testWidgets(
      'renders streak freeze inventory chip with shield icon and freeze count',
      (tester) async {
        await pumpStreakScreen(tester);

        expect(find.byIcon(Icons.shield_rounded), findsWidgets);
        expect(find.text('x2'), findsOneWidget);
      },
    );
  });

  group('Group 3: Streak Hero Widget', () {
    testWidgets(
      'renders StreakHero with day count, DAY STREAK label, and status text',
      (tester) async {
        await pumpStreakScreen(tester);

        expect(find.byType(StreakHero), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(StreakHero),
            matching: find.text('15'),
          ),
          findsOneWidget,
        );
        expect(find.text('DAY STREAK'), findsOneWidget);
        expect(find.text('UNSTOPPABLE!'), findsOneWidget);
      },
    );
  });

  group('Group 4: Streak Calendar & Week View', () {
    testWidgets(
      'renders StreakCalendar with THIS WEEK title and day nodes',
      (tester) async {
        await pumpStreakScreen(tester);

        expect(find.byType(StreakCalendar), findsOneWidget);
        expect(find.text('THIS WEEK'), findsOneWidget);
      },
    );
  });

  group('Group 5: Streak Milestones & Milestone Rewards', () {
    testWidgets(
      'renders StreakMilestones section and computes reward nodes',
      (tester) async {
        await pumpStreakScreen(tester);

        expect(find.byType(StreakMilestones), findsOneWidget);
        expect(find.text('STREAK MILESTONES'), findsOneWidget);
      },
    );

    testWidgets(
      'displays SnackBar when progression message indicates milestone claimed',
      (tester) async {
        whenListen(
          mockProgressionBloc,
          Stream.fromIterable([
            const ProgressionState(message: 'progression.milestone_claimed'),
          ]),
          initialState: const ProgressionState(),
        );

        await pumpStreakScreen(tester);

        expect(find.text('Milestone Claimed!'), findsOneWidget);
      },
    );
  });

  group('Group 6: Streak Boosters Shop & Economy', () {
    testWidgets(
      'renders StreakBoostersShop with booster cards',
      (tester) async {
        await pumpStreakScreen(tester);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        expect(find.byType(StreakBoostersShop), findsOneWidget);
        expect(find.text('STREAK BOOSTERS'), findsOneWidget);
      },
    );
  });

  group('Group 7: Earn More Coins & Ad Reward Card', () {
    testWidgets(
      'renders EARN MORE COINS header and AdRewardCard in streak screen',
      (tester) async {
        await pumpStreakScreen(tester);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        expect(find.text('EARN MORE COINS'), findsOneWidget);
        expect(
          find.text('Fuel your boosters and protect your streak.'),
          findsOneWidget,
        );
      },
    );
  });

  group('Group 8: Responsive Viewports, Accessibility & Themes', () {
    testWidgets(
      'renders cleanly without RenderFlex overflow on compact mobile (320x568)',
      (tester) async {
        await pumpStreakScreen(
          tester,
          viewportSize: const Size(320, 568),
        );

        expect(find.text('DAILY STREAK'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders cleanly on large tablet viewport (800x1280)',
      (tester) async {
        await pumpStreakScreen(
          tester,
          viewportSize: const Size(800, 1280),
        );

        expect(find.text('DAILY STREAK'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders cleanly under 1.3x accessibility text scaling without overflow',
      (tester) async {
        await pumpStreakScreen(
          tester,
          textScaleFactor: 1.3,
        );

        expect(find.text('DAILY STREAK'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders cleanly in Dark Theme mode',
      (tester) async {
        final darkTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          fontFamily: 'Outfit',
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFF97316),
            surface: Color(0xFF1E293B),
            onSurface: Colors.white,
          ),
        );

        await pumpStreakScreen(
          tester,
          theme: darkTheme,
        );

        expect(find.text('DAILY STREAK'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders cleanly in Midnight Theme mode (black scaffold background)',
      (tester) async {
        final midnightTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          fontFamily: 'Outfit',
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFF97316),
            surface: Color(0xFF050505),
            onSurface: Colors.white,
          ),
        );

        await pumpStreakScreen(
          tester,
          theme: midnightTheme,
        );

        expect(find.text('DAILY STREAK'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
