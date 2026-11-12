import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/games/presentation/pages/games_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockAppLogger mockLogger;
  late ScrollController gamesScrollController;
  late List<String> navigatedRoutes;
  final mockLocaleService = MockLocaleService();

  const testUser = UserEntity(
    id: 'user_123',
    email: 'learner@vowl.app',
    displayName: 'Aria Stark',
    currentStreak: 12,
    totalExp: 4500,
    coins: 350,
    completedLevels: {
      'readAndAnswer': [1, 2, 3],
      'repeatSentence': [1, 2],
      'grammarQuest': [1, 2, 3, 4],
    },
    unlockedLevels: {
      'grammarQuest': 5,
    },
  );

  setUpAll(() {
    try {
      initLocaleServiceReference(mockLocaleService);
    } catch (_) {}
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    navigatedRoutes = [];
    reset(mockLocaleService);

    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockLogger = MockAppLogger();
    gamesScrollController = ScrollController();

    if (di.sl.isRegistered<ScrollController>(instanceName: 'games')) {
      di.sl.unregister<ScrollController>(instanceName: 'games');
    }
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();

    di.sl.registerSingleton<ScrollController>(
      gamesScrollController,
      instanceName: 'games',
    );
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockLogger);

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

    when(
      () => mockAuthBloc.state,
    ).thenReturn(AuthState.authenticated(testUser));
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() {
    gamesScrollController.dispose();
  });

  Widget createWidgetUnderTest({ThemeMode themeMode = ThemeMode.light}) {
    final router = GoRouter(
      initialLocation: '/games',
      routes: [
        GoRoute(
          path: '/games',
          builder: (context, state) => const GamesScreen(),
        ),
        GoRoute(
          path: '/game',
          builder: (context, state) {
            navigatedRoutes.add(state.uri.toString());
            return Scaffold(
              body: Center(
                child: Text(
                  'Game Screen: ${state.uri.queryParameters['gameType']}',
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: '/levels',
          builder: (context, state) {
            navigatedRoutes.add(state.uri.toString());
            return Scaffold(
              body: Center(
                child: Text(
                  'Level Map: ${state.uri.queryParameters['gameType']}',
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: '/category-games',
          builder: (context, state) {
            navigatedRoutes.add(state.uri.toString());
            return Scaffold(
              body: Center(
                child: Text(
                  'Category Games: ${state.uri.queryParameters['category']}',
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: '/word-snap',
          builder: (context, state) {
            navigatedRoutes.add(state.uri.toString());
            return const Scaffold(body: Center(child: Text('Word Snap')));
          },
        ),
        GoRoute(
          path: '/word-mixer',
          builder: (context, state) {
            navigatedRoutes.add(state.uri.toString());
            return const Scaffold(body: Center(child: Text('Word Mixer')));
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
        builder: (context, child) => MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
        ),
      ),
    );
  }

  group('GamesScreen - Loading / Shimmer State Tests', () {
    testWidgets('renders shimmer placeholder when auth state user is null', (
      tester,
    ) async {
      when(
        () => mockAuthBloc.state,
      ).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(CustomScrollView), findsNothing);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('GamesScreen - Authenticated Header & 10/10 Components', () {
    testWidgets('renders Quest Hub App Bar with user coins and streak stats', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Quest Hub'), findsOneWidget);
      expect(find.text('350'), findsOneWidget); // User coins
      expect(find.text('12'), findsOneWidget); // User streak
    });

    testWidgets(
      'renders Quick Resume Hero Card with active game and PLAY button',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('QUICK RESUME'), findsOneWidget);
        expect(find.text('PLAY'), findsWidgets);
        // Ensure no raw translation placeholder "{}" is rendered
        expect(find.textContaining('{}'), findsNothing);
        // Verify progress level text under progress bar
        expect(find.textContaining(' / 20'), findsOneWidget);
        // Verify linear progress indicator is rendered
        expect(find.byType(LinearProgressIndicator), findsWidgets);
      },
    );

    testWidgets(
      'renders Quick Resume Hero Card with UNLOCK button and key icon, intercepting with TollGateBottomSheet when at toll gate',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const tollGateUser = UserEntity(
          id: 'user_toll',
          email: 'toll@vowl.app',
          displayName: 'Alex Learner',
          coins: 100,
          currentStreak: 5,
          isPremium: false,
          completedLevels: {
            'sentenceBuilder': [1, 2, 3],
          },
          unlockedLevels: {
            'sentenceBuilder': 3,
          },
          categoryStats: {
            'writing': 65,
          },
        );

        when(() => mockAuthBloc.state)
            .thenReturn(AuthState.authenticated(tollGateUser));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('QUICK RESUME'), findsOneWidget);
        expect(find.text('UNLOCK'), findsWidgets);
        expect(find.byIcon(Icons.lock_rounded), findsWidgets);
        expect(find.byIcon(Icons.vpn_key_rounded), findsWidgets);

        // Tapping the unlock button opens TollGateBottomSheet instead of pushing /game
        await tester.tap(find.text('UNLOCK').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(BottomSheet), findsOneWidget);
        expect(navigatedRoutes.any((r) => r.contains('/game')), isFalse);
      },
    );

    testWidgets(
      'renders 1v1 PvP Duel flagship card with exact production rewards',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('1v1 Duel'), findsOneWidget);
        // Exact production rewards verified from repository implementations
        expect(
          find.textContaining('WIN 50'),
          findsOneWidget,
        ); // 1v1 duel winner
        expect(find.textContaining('+5 XP'), findsOneWidget);
        expect(find.textContaining('30🪙 entry'), findsOneWidget);
        expect(
          find.text('+50 XP'),
          findsNothing,
        ); // 50 XP economy inflation bug fixed
        expect(
          find.text('+40 XP'),
          findsNothing,
        ); // Erroneous placeholder absent
      },
    );

    testWidgets('renders Curriculum Mastery Card with achievable tier', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Beginner Tier'), findsOneWidget);
    });

    testWidgets('renders Category Filter Dock and search field', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('QUEST ARCHIVE'), findsOneWidget);
      expect(find.text('100+ Games'), findsOneWidget);
      expect(find.text('All (100)'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('GamesScreen - Overworld Realms & Serpentine Map Integration', () {
    testWidgets('renders Overworld Realm Cards in default view', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('SPEAKING REALM'), findsOneWidget);
      expect(find.text('EXPLORE'), findsWidgets);
    });

    testWidgets('tapping a category filter pill renders in-place CategoryOverworldMap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Speaking filter pill (visible in the initial dock scroll position)
      await tester.tap(find.text('Speaking'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifies active realm header banner with "All Realms" button
      expect(find.text('All Realms'), findsOneWidget);
      expect(find.textContaining('Serpentine Path'), findsOneWidget);

      // Tapping "All Realms" restores the Overworld Realms Sliver
      await tester.tap(find.text('All Realms'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('SPEAKING REALM'), findsOneWidget);
    });
  });

  group('GamesScreen - Theme & Small Screen Layout Safety', () {
    testWidgets('renders cleanly in dark mode without visual glitches', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest(themeMode: ThemeMode.dark));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GamesScreen), findsOneWidget);
      expect(find.text('Quest Hub'), findsOneWidget);
    });

    testWidgets('small screen (320dp width) zero-overflow layout safety', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.byType(GamesScreen), findsOneWidget);
    });
  });
}
