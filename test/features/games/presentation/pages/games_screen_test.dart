import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/feature_catalog/beginner_discovery_card.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/games/presentation/pages/games_screen.dart';
import 'package:vowl/features/games/presentation/widgets/kids_category_shelf.dart';
import 'package:vowl/features/home/presentation/widgets/category_shelf.dart';

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
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(testUser),
    );
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
  });

  tearDown(() {
    gamesScrollController.dispose();
    if (di.sl.isRegistered<ScrollController>(instanceName: 'games')) {
      di.sl.unregister<ScrollController>(instanceName: 'games');
    }
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
  });

  Widget createWidgetUnderTest({
    ThemeMode themeMode = ThemeMode.light,
    GoRouter? customRouter,
  }) {
    final router =
        customRouter ??
        GoRouter(
          initialLocation: '/games',
          routes: [
            GoRoute(
              path: '/games',
              builder: (context, state) => const GamesScreen(),
            ),
            GoRoute(
              path: '/kids-zone',
              builder: (context, state) {
                navigatedRoutes.add('/kids-zone');
                return const Scaffold(body: Text('Kids Zone Destination'));
              },
            ),
            GoRoute(
              path: '/category-games',
              builder: (context, state) {
                final category = state.uri.queryParameters['category'] ?? '';
                navigatedRoutes.add('/category-games?category=$category');
                return Scaffold(body: Text('Category Games: $category'));
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
      when(() => mockAuthBloc.state).thenReturn(
        const AuthState.unauthenticated(),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Shimmer loading should render when user is null
      expect(find.byType(CustomScrollView), findsNothing);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('GamesScreen - Authenticated Header & Hero Dashboard Tests', () {
    testWidgets('renders Quest Hub App Bar and Hero Mastery Dashboard cleanly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // App bar elements
      expect(find.text('Quest Hub'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_mosaic_rounded), findsOneWidget);

      // Scroll down so Hero Mastery Dashboard is visible
      gamesScrollController.jumpTo(400);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Hero Dashboard elements
      expect(find.text('CORE MASTERY'), findsOneWidget);
      expect(find.textContaining('Levels Cleared'), findsOneWidget);
      expect(find.text('STREAK'), findsOneWidget);
      expect(find.text('XP'), findsOneWidget);
      expect(find.text('CORE GAMES'), findsOneWidget);
      expect(find.text('12'), findsOneWidget); // currentStreak
      expect(find.text('4.5K'), findsOneWidget); // 4500 XP formatted
    });

    testWidgets('displays BeginnerDiscoveryCard for standard adult learners', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(BeginnerDiscoveryCard), findsOneWidget);
    });

    testWidgets('hides BeginnerDiscoveryCard when user is in kidsModeOnly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const kidsUser = UserEntity(
        id: 'kids_1',
        email: 'kid@vowl.app',
        totalExp: 0,
        completedLevels: {
          'handwriting': [1],
        },
      );
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(kidsUser),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(BeginnerDiscoveryCard), findsNothing);
    });
  });

  group('GamesScreen - Kids Zone Section & Navigation', () {
    testWidgets('renders Kids Zone shelf and balloon badge', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      gamesScrollController.jumpTo(600);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('KIDS ZONE'), findsOneWidget);
      expect(find.text('Play & Learn'), findsOneWidget);
      expect(find.text('🎈'), findsOneWidget);
      expect(find.byType(KidsCategoryShelf), findsOneWidget);
    });

    testWidgets('navigates to /kids-zone on tapping See All in Kids Zone header', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      gamesScrollController.jumpTo(600);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final seeAllButtons = find.text('SEE ALL');
      expect(seeAllButtons, findsWidgets);

      // Tap the first 'SEE ALL' button which belongs to Kids Zone
      await tester.tap(seeAllButtons.first);
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains('/kids-zone'));
      expect(find.text('Kids Zone Destination'), findsOneWidget);
    });
  });

  group('GamesScreen - Adult Category Sections & Shelves', () {
    testWidgets('renders category shelves for core curriculum games', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll to adult category sections
      gamesScrollController.jumpTo(2200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('SPEAKING'), findsWidgets);
      expect(find.byType(CategoryShelf), findsWidgets);

      // Scroll to the bottom of the curriculum to verify Elite Mastery
      gamesScrollController.jumpTo(
        gamesScrollController.position.maxScrollExtent,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('ELITE MASTERY'), findsWidgets);
      expect(find.text('👑'), findsOneWidget);
    });

    testWidgets('navigates to category games page on tapping category See all', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll so Speaking category is well in view
      gamesScrollController.jumpTo(500);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final seeAllButtons = find.text('SEE ALL');
      expect(seeAllButtons, findsWidgets);

      // Tap the second 'SEE ALL' button which belongs to Speaking (first is Kids Zone)
      await tester.tap(seeAllButtons.at(1));
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains('/category-games?category=speaking'));
      expect(find.text('Category Games: speaking'), findsOneWidget);
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

