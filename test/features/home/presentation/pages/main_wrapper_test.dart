import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/home/presentation/pages/main_wrapper.dart';

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocaleService mockLocaleService;
  late ScrollController homeScrollController;
  late ScrollController gamesScrollController;

  setUpAll(() {
    mockLocaleService = MockLocaleService();
    try {
      initLocaleServiceReference(mockLocaleService);
    } catch (_) {}
  });

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    reset(mockLocaleService);

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

    homeScrollController = ScrollController();
    gamesScrollController = ScrollController();

    if (di.sl.isRegistered<ScrollController>(instanceName: 'home')) {
      di.sl.unregister<ScrollController>(instanceName: 'home');
    }
    if (di.sl.isRegistered<ScrollController>(instanceName: 'games')) {
      di.sl.unregister<ScrollController>(instanceName: 'games');
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }

    di.sl.registerSingleton<ScrollController>(
      homeScrollController,
      instanceName: 'home',
    );
    di.sl.registerSingleton<ScrollController>(
      gamesScrollController,
      instanceName: 'games',
    );
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
  });

  tearDown(() {
    if (di.sl.isRegistered<ScrollController>(instanceName: 'home')) {
      di.sl.unregister<ScrollController>(instanceName: 'home');
    }
    if (di.sl.isRegistered<ScrollController>(instanceName: 'games')) {
      di.sl.unregister<ScrollController>(instanceName: 'games');
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    homeScrollController.dispose();
    gamesScrollController.dispose();
  });

  GoRouter createTestRouter({String initialLocation = '/home'}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainWrapper(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => ListView(
                    controller: di.sl<ScrollController>(instanceName: 'home'),
                    children: List.generate(
                      40,
                      (i) => SizedBox(
                        height: 60,
                        child: Text('Home Item $i'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/games',
                  builder: (context, state) => ListView(
                    controller: di.sl<ScrollController>(instanceName: 'games'),
                    children: List.generate(
                      40,
                      (i) => SizedBox(
                        height: 60,
                        child: Text('Games Item $i'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/ranks',
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('Ranks Screen Content')),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('Profile Screen Content')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget createWidgetUnderTest({
    GoRouter? router,
    ThemeData? theme,
  }) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          routerConfig: router ?? createTestRouter(),
          theme: theme ?? ThemeData.light(),
        );
      },
    );
  }

  Future<void> pumpMainWrapper(
    WidgetTester tester, {
    GoRouter? router,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(
      createWidgetUnderTest(
        router: router,
        theme: theme,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Group 1: Initial Shell Rendering & Active Indicator', () {
    testWidgets(
      'renders MainWrapper with 4 navigation items and Home tab active initially',
      (tester) async {
        await pumpMainWrapper(tester);

        expect(find.byType(MainWrapper), findsOneWidget);
        expect(find.text('Home Item 0'), findsOneWidget);

        // Home tab is active: has active icon and 'Home' label
        expect(find.byIcon(Icons.home_rounded), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);

        // Inactive tabs show outline icons and do NOT show label texts
        expect(find.byIcon(Icons.sports_esports_outlined), findsOneWidget);
        expect(find.byIcon(Icons.leaderboard_outlined), findsOneWidget);
        expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

        expect(find.text('Games'), findsNothing);
        expect(find.text('Ranks'), findsNothing);
        expect(find.text('Profile'), findsNothing);
      },
    );

    testWidgets(
      'renders glass container and background blur decoration in bottomNavigationBar',
      (tester) async {
        await pumpMainWrapper(tester);

        expect(find.byType(BackdropFilter), findsOneWidget);
        expect(find.byType(ClipRRect), findsWidgets);
      },
    );
  });

  group('Group 2: Tab Switching & Branch Navigation', () {
    testWidgets(
      'tapping Games tab switches branch to /games and updates active pill',
      (tester) async {
        await pumpMainWrapper(tester);

        final gamesTab = find.bySemanticsLabel('Games');
        expect(gamesTab, findsOneWidget);

        await tester.tap(gamesTab);
        await tester.pumpAndSettle();

        expect(find.text('Games Item 0'), findsOneWidget);
        expect(find.byIcon(Icons.sports_esports_rounded), findsOneWidget);
        expect(find.text('Games'), findsOneWidget);

        // Home should now be inactive
        expect(find.byIcon(Icons.home_outlined), findsOneWidget);
        expect(find.text('Home'), findsNothing);
      },
    );

    testWidgets(
      'tapping Ranks tab switches branch to /ranks and updates active pill',
      (tester) async {
        await pumpMainWrapper(tester);

        final ranksTab = find.bySemanticsLabel('Ranks');
        expect(ranksTab, findsOneWidget);

        await tester.tap(ranksTab);
        await tester.pumpAndSettle();

        expect(find.text('Ranks Screen Content'), findsOneWidget);
        expect(find.byIcon(Icons.leaderboard_rounded), findsOneWidget);
        expect(find.text('Ranks'), findsOneWidget);

        // Games and Home are inactive
        expect(find.byIcon(Icons.home_outlined), findsOneWidget);
        expect(find.byIcon(Icons.sports_esports_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Profile tab switches branch to /profile and updates active pill',
      (tester) async {
        await pumpMainWrapper(tester);

        final profileTab = find.bySemanticsLabel('Profile');
        expect(profileTab, findsOneWidget);

        await tester.tap(profileTab);
        await tester.pumpAndSettle();

        expect(find.text('Profile Screen Content'), findsOneWidget);
        expect(find.byIcon(Icons.person_rounded), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      },
    );

    testWidgets(
      'navigating across tabs in sequence maintains shell state cleanly',
      (tester) async {
        await pumpMainWrapper(tester);

        // Tap Games
        await tester.tap(find.bySemanticsLabel('Games'));
        await tester.pumpAndSettle();
        expect(find.text('Games Item 0'), findsOneWidget);

        // Tap Ranks
        await tester.tap(find.bySemanticsLabel('Ranks'));
        await tester.pumpAndSettle();
        expect(find.text('Ranks Screen Content'), findsOneWidget);

        // Tap Profile
        await tester.tap(find.bySemanticsLabel('Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Profile Screen Content'), findsOneWidget);

        // Tap Home
        await tester.tap(find.bySemanticsLabel('Home'));
        await tester.pumpAndSettle();
        expect(find.text('Home Item 0'), findsOneWidget);
        expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      },
    );
  });

  group('Group 3: Scroll-to-Top on Active Tab Re-Tap', () {
    testWidgets(
      're-tapping active Home tab animates homeScrollController to 0.0',
      (tester) async {
        await pumpMainWrapper(tester);

        // Scroll down Home list
        homeScrollController.jumpTo(300);
        await tester.pumpAndSettle();
        expect(homeScrollController.offset, 300);

        // Re-tap active Home tab
        final homeTab = find.bySemanticsLabel('Home');
        await tester.tap(homeTab);
        await tester.pumpAndSettle();

        // Should have animated to top 0.0
        expect(homeScrollController.offset, 0.0);
      },
    );

    testWidgets(
      're-tapping active Games tab animates gamesScrollController to 0.0',
      (tester) async {
        await pumpMainWrapper(tester);

        // Switch to Games tab
        await tester.tap(find.bySemanticsLabel('Games'));
        await tester.pumpAndSettle();

        // Scroll down Games list
        gamesScrollController.jumpTo(250);
        await tester.pumpAndSettle();
        expect(gamesScrollController.offset, 250);

        // Re-tap active Games tab
        final gamesTab = find.bySemanticsLabel('Games');
        await tester.tap(gamesTab);
        await tester.pumpAndSettle();

        // Should have animated to top 0.0
        expect(gamesScrollController.offset, 0.0);
      },
    );

    testWidgets(
      're-tapping tab when scroll controller is unregistered does not throw exception',
      (tester) async {
        await pumpMainWrapper(tester);

        // Unregister home scroll controller
        di.sl.unregister<ScrollController>(instanceName: 'home');

        final homeTab = find.bySemanticsLabel('Home');
        await tester.tap(homeTab);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Group 4: Accessibility & Semantics', () {
    testWidgets(
      'nav items expose proper Semantics button and selected state',
      (tester) async {
        await pumpMainWrapper(tester);

        final homeFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.selected == true &&
              w.properties.label == 'Home',
        );
        expect(homeFinder, findsOneWidget);

        final gamesFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.selected == false &&
              w.properties.label == 'Games',
        );
        expect(gamesFinder, findsOneWidget);

        final ranksFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.selected == false &&
              w.properties.label == 'Ranks',
        );
        expect(ranksFinder, findsOneWidget);

        final profileFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.selected == false &&
              w.properties.label == 'Profile',
        );
        expect(profileFinder, findsOneWidget);
      },
    );

    testWidgets(
      'maintains 48dp minimum touch target floor on all items',
      (tester) async {
        await pumpMainWrapper(tester);

        final constrainedContainers = find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints?.minWidth != null &&
              w.constraints!.minWidth >= 48.0 &&
              w.constraints?.minHeight != null &&
              w.constraints!.minHeight >= 48.0,
        );

        // At least 4 nav item tap targets meeting the 48dp floor
        expect(constrainedContainers, findsAtLeastNWidgets(4));
      },
    );
  });

  group('Group 5: Responsive Layouts & Themes', () {
    testWidgets(
      'renders without RenderFlex overflow on small mobile viewport (320x568)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(MainWrapper), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders cleanly on large tablet viewport (800x1280)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1280);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(MainWrapper), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders cleanly under 1.3x accessibility text scaling without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
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

        expect(find.byType(MainWrapper), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders cleanly in Dark Theme mode',
      (tester) async {
        await pumpMainWrapper(
          tester,
          theme: ThemeData.dark(),
        );

        expect(find.byType(MainWrapper), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders cleanly in Midnight Theme mode (black scaffold background)',
      (tester) async {
        await pumpMainWrapper(
          tester,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
          ),
        );

        expect(find.byType(MainWrapper), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

