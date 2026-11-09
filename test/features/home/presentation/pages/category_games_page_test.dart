import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/home/presentation/pages/category_games_page.dart';
import 'package:vowl/features/home/presentation/widgets/category_overworld/category_overworld_map.dart';
import 'package:vowl/features/home/presentation/widgets/category_overworld/category_realm_island.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockLocaleService mockLocaleService;
  late List<String> navigatedRoutes;

  const testUser = UserEntity(
    id: 'user_123',
    email: 'learner@vowl.app',
    displayName: 'Aria Stark',
    currentStreak: 12,
    totalExp: 1400,
    completedLevels: {
      'partsOfSpeech': [1, 2, 3],
      'grammarQuest': [1, 2],
      'synonymAntonym': [1],
    },
  );

  setUpAll(() {
    mockLocaleService = MockLocaleService();
    try {
      initLocaleServiceReference(mockLocaleService);
    } catch (_) {}
  });

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    navigatedRoutes = [];
    reset(mockLocaleService);

    mockAuthBloc = MockAuthBloc();

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
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Widget createWidgetUnderTest({
    String categoryId = 'grammar',
    ThemeData? theme,
    List<RouteBase>? extraRoutes,
    String initialLocation = '/category-games',
    GoRouter? routerConfig,
  }) {
    final router =
        routerConfig ??
        GoRouter(
          initialLocation: initialLocation,
          routes: [
            GoRoute(
              path: '/category-games',
              builder: (context, state) => BlocProvider<AuthBloc>.value(
                value: mockAuthBloc,
                child: CategoryGamesPage(categoryId: categoryId),
              ),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) {
                navigatedRoutes.add('/home');
                return const Scaffold(body: Text('Home Screen'));
              },
            ),
            GoRoute(
              path: '/levels',
              builder: (context, state) {
                final cat = state.uri.queryParameters['category'] ?? '';
                final game = state.uri.queryParameters['gameType'] ?? '';
                navigatedRoutes.add('/levels?category=$cat&gameType=$game');
                return Scaffold(body: Text('Levels: $cat - $game'));
              },
            ),
            ...?extraRoutes,
          ],
        );

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          routerConfig: router,
          theme: theme ?? ThemeData.light(),
        );
      },
    );
  }

  Future<void> pumpCategoryGamesPage(
    WidgetTester tester, {
    String categoryId = 'grammar',
    ThemeData? theme,
    List<RouteBase>? extraRoutes,
    String initialLocation = '/category-games',
    GoRouter? routerConfig,
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(
      createWidgetUnderTest(
        categoryId: categoryId,
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
    testWidgets('renders GameShimmerLoading placeholder when user is null', (
      tester,
    ) async {
      when(
        () => mockAuthBloc.state,
      ).thenReturn(const AuthState.unauthenticated());

      await pumpCategoryGamesPage(tester, settle: false);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(CustomScrollView), findsNothing);
    });

    testWidgets(
      'renders full category feed with CustomScrollView when user is authenticated',
      (tester) async {
        await pumpCategoryGamesPage(tester);

        expect(find.byType(CategoryGamesPage), findsOneWidget);
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.byType(CategoryOverworldMap), findsOneWidget);
        expect(find.byType(GameShimmerLoading), findsNothing);
      },
    );
  });

  group('Group 2: Floating Glass Island AppBar', () {
    testWidgets(
      'renders category title in uppercase and back button in app bar',
      (tester) async {
        await pumpCategoryGamesPage(tester, categoryId: 'grammar');

        expect(find.text('GRAMMAR'), findsOneWidget);

        final backButton = find.bySemanticsLabel('Back');
        expect(backButton, findsOneWidget);
      },
    );

    testWidgets('tapping back button when canPop is false navigates to /home', (
      tester,
    ) async {
      await pumpCategoryGamesPage(tester, categoryId: 'grammar');

      final backButton = find.bySemanticsLabel('Back');
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains('/home'));
    });

    testWidgets('tapping back button when canPop is true pops route', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.push('/category-games'),
                  child: const Text('Go To Games'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/category-games',
            builder: (context, state) => BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: const CategoryGamesPage(categoryId: 'grammar'),
            ),
          ),
        ],
      );

      await pumpCategoryGamesPage(tester, routerConfig: router);

      // Push category games page from home
      await tester.tap(find.text('Go To Games'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryGamesPage), findsOneWidget);

      // Tap back button
      final backButton = find.bySemanticsLabel('Back');
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Should have popped back to home
      expect(find.text('Go To Games'), findsOneWidget);
      expect(find.byType(CategoryGamesPage), findsNothing);
    });
  });

  group('Group 3: Mastery Dashboard', () {
    testWidgets('renders OVERALL MASTERY label and level stats in dashboard', (
      tester,
    ) async {
      await pumpCategoryGamesPage(tester, categoryId: 'grammar');

      expect(find.text('OVERALL MASTERY'), findsOneWidget);
      expect(find.text('POWER'), findsOneWidget);
      expect(find.text('GAMES'), findsOneWidget);
      expect(find.text('RANK'), findsOneWidget);

      // Stat icons
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.sports_esports_rounded), findsOneWidget);
      expect(find.byIcon(Icons.stars_rounded), findsOneWidget);
    });
  });

  group('Group 4: Category Overworld Map & Direct Routing', () {
    testWidgets(
      'renders floating realm islands and navigates directly to levels on tap',
      (tester) async {
        await pumpCategoryGamesPage(tester, categoryId: 'grammar');

        // Scroll slightly to comfortably center the first realm island
        final scrollable = find.byType(CustomScrollView);
        await tester.drag(scrollable, const Offset(0, -80));
        await tester.pumpAndSettle();

        // Parts of Speech is in grammar
        final partsOfSpeechCard = find.text('PARTS OF SPEECH');
        expect(partsOfSpeechCard, findsOneWidget);

        // Find the tap target for the card
        final cardTapTarget = find
            .ancestor(of: partsOfSpeechCard, matching: find.byType(ScaleButton))
            .first;

        await tester.tap(cardTapTarget, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(navigatedRoutes.length, 1);
        expect(
          navigatedRoutes.first,
          startsWith('/levels?category=grammar&gameType=partsOfSpeech'),
        );
      },
    );
  });

  group('Group 5: Responsive Viewports & Themes', () {
    testWidgets(
      'renders cleanly without RenderFlex overflow on compact mobile (320x568)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(createWidgetUnderTest(categoryId: 'grammar'));
        await tester.pumpAndSettle();

        expect(find.byType(CategoryGamesPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('renders cleanly on large tablet viewport (800x1280)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(createWidgetUnderTest(categoryId: 'grammar'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryGamesPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'renders cleanly under 1.3x accessibility text scaling without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(1.3),
            ),
            child: createWidgetUnderTest(categoryId: 'grammar'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CategoryGamesPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('renders cleanly in Dark Theme mode', (tester) async {
      await pumpCategoryGamesPage(
        tester,
        categoryId: 'grammar',
        theme: ThemeData.dark(),
      );

      expect(find.byType(CategoryGamesPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'renders cleanly in Midnight Theme mode (black scaffold background)',
      (tester) async {
        await pumpCategoryGamesPage(
          tester,
          categoryId: 'grammar',
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
          ),
        );

        expect(find.byType(CategoryGamesPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Group 6: Realm Island Badges & State Symmetry', () {
    testWidgets(
      'displays trophy crest badge and pure gameplay stars when 200 levels completed',
      (tester) async {
        final completed200User = testUser.copyWith(
          completedLevels: {'partsOfSpeech': List.generate(200, (i) => i + 1)},
          starRatings: {
            'partsOfSpeech': {
              '1': 3,
              '2': 3,
              'magic_stars': 500, // Ad stars from vault must be excluded
              'claimed_chests': 2,
            },
          },
        );

        when(
          () => mockAuthBloc.state,
        ).thenReturn(AuthState.authenticated(completed200User));

        await pumpCategoryGamesPage(tester, categoryId: 'grammar');

        final scrollable = find.byType(CustomScrollView);
        await tester.drag(scrollable, const Offset(0, -80));
        await tester.pumpAndSettle();

        // Must NOT show 201 anywhere
        expect(find.text('201'), findsNothing);
        expect(find.text('Lv.201'), findsNothing);

        // Trophy crown badge is present
        expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);

        // Must display pure gameplay stars (6/600), NOT including magic_stars
        expect(find.text('★ 6 / 600'), findsOneWidget);
      },
    );

    testWidgets(
      'displays 100% PERFECT badge when all 200 levels have 3 stars (600 stars)',
      (tester) async {
        final perfectUser = testUser.copyWith(
          completedLevels: {'partsOfSpeech': List.generate(200, (i) => i + 1)},
          starRatings: {
            'partsOfSpeech': {
              for (var i = 1; i <= 200; i++) '$i': 3,
              'magic_stars': 200,
            },
          },
        );

        when(
          () => mockAuthBloc.state,
        ).thenReturn(AuthState.authenticated(perfectUser));

        await pumpCategoryGamesPage(tester, categoryId: 'grammar');

        final scrollable = find.byType(CustomScrollView);
        await tester.drag(scrollable, const Offset(0, -80));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.stars_rounded), findsWidgets);
        expect(find.text('★ 600 / 600'), findsOneWidget);
        expect(find.text('100% PERFECT'), findsOneWidget);
      },
    );

    testWidgets(
      'displays NEW badge on unplayed games and Lv.X pill on in-progress games',
      (tester) async {
        // partsOfSpeech has 3 completed levels (in progress), other games are unplayed
        await pumpCategoryGamesPage(tester, categoryId: 'grammar');

        final scrollable = find.byType(CustomScrollView);
        await tester.drag(scrollable, const Offset(0, -80));
        await tester.pumpAndSettle();

        // In-progress game shows Lv.4
        expect(find.text('Lv.4'), findsOneWidget);

        // Fresh games show NEW
        expect(find.text('NEW'), findsWidgets);

        // Realm islands are rendered
        expect(find.byType(CategoryRealmIsland), findsWidgets);
      },
    );
  });
}
