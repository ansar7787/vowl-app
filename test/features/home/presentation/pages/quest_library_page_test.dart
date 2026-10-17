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
import 'package:vowl/features/home/presentation/pages/quest_library_page.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockLocaleService mockLocaleService;
  late List<String> navigatedRoutes;

  const testUser = UserEntity(
    id: 'user_quest_123',
    email: 'adventurer@vowl.app',
    displayName: 'Elena Fisher',
    currentStreak: 15,
    totalExp: 2800,
    completedLevels: {
      'partsOfSpeech': [1, 2, 3, 4, 5],
      'grammarQuest': [1, 2],
      'synonymAntonym': [1, 2, 3],
      'wordRoots': [1],
    },
    categoryStats: {
      'partsOfSpeech': 5,
      'grammarQuest': 2,
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
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Widget createWidgetUnderTest({
    ThemeData? theme,
    List<RouteBase>? extraRoutes,
    String initialLocation = '/quest-library',
    GoRouter? routerConfig,
  }) {
    final router = routerConfig ??
        GoRouter(
          initialLocation: initialLocation,
          routes: [
            GoRoute(
              path: '/quest-library',
              builder: (context, state) => BlocProvider<AuthBloc>.value(
                value: mockAuthBloc,
                child: const QuestLibraryPage(),
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
                final category = state.uri.queryParameters['category'] ?? '';
                final gameType = state.uri.queryParameters['gameType'] ?? '';
                navigatedRoutes.add('/levels?category=$category&gameType=$gameType');
                return Scaffold(
                  body: Text('Levels Screen: category=$category, gameType=$gameType'),
                );
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
                  primary: Color(0xFF3B82F6),
                  surface: Colors.white,
                  onSurface: Color(0xFF0F172A),
                ),
              ),
        );
      },
    );
  }

  Future<void> pumpQuestLibraryPage(
    WidgetTester tester, {
    ThemeData? theme,
    List<RouteBase>? extraRoutes,
    String initialLocation = '/quest-library',
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

        await pumpQuestLibraryPage(tester, settle: false);

        expect(find.byType(HomeShimmerLoading), findsOneWidget);
        expect(find.byType(CustomScrollView), findsNothing);
      },
    );

    testWidgets(
      'renders full quest library with CustomScrollView when user is authenticated',
      (tester) async {
        await pumpQuestLibraryPage(tester);

        expect(find.byType(QuestLibraryPage), findsOneWidget);
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.byType(HomeShimmerLoading), findsNothing);
      },
    );
  });

  group('Group 2: Floating Glass Island AppBar', () {
    testWidgets(
      'renders QUEST ARCHIVE title pill and back button in app bar',
      (tester) async {
        await pumpQuestLibraryPage(tester);

        expect(find.text('QUEST ARCHIVE'), findsOneWidget);
        expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'tapping back button when canPop is false navigates to /home',
      (tester) async {
        await pumpQuestLibraryPage(tester);

        final backBtnFinder = find.byWidgetPredicate(
          (w) =>
              w is ScaleButton &&
              w.child is Container &&
              find.descendant(of: find.byWidget(w), matching: find.byIcon(Icons.arrow_back_ios_new_rounded)).evaluate().isNotEmpty,
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
                    onPressed: () => context.push('/quest-library'),
                    child: const Text('Open Library'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/quest-library',
              builder: (context, state) => BlocProvider<AuthBloc>.value(
                value: mockAuthBloc,
                child: const QuestLibraryPage(),
              ),
            ),
          ],
        );

        await pumpQuestLibraryPage(tester, routerConfig: router, initialLocation: '/initial');

        await tester.tap(find.text('Open Library'));
        await tester.pumpAndSettle();
        expect(find.text('QUEST ARCHIVE'), findsOneWidget);

        final backBtnFinder = find.byWidgetPredicate(
          (w) =>
              w is ScaleButton &&
              w.child is Container &&
              find.descendant(of: find.byWidget(w), matching: find.byIcon(Icons.arrow_back_ios_new_rounded)).evaluate().isNotEmpty,
        );

        await tester.tap(backBtnFinder);
        await tester.pumpAndSettle();

        expect(find.text('Open Library'), findsOneWidget);
        expect(find.text('QUEST ARCHIVE'), findsNothing);
      },
    );
  });

  group('Group 3: Stats Dashboard Panel', () {
    testWidgets(
      'renders GLOBAL ARCHIVE PROGRESS, Mastery, levels cleared, and mini stats',
      (tester) async {
        await pumpQuestLibraryPage(tester);

        expect(find.text('GLOBAL ARCHIVE PROGRESS'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
        expect(find.byIcon(Icons.stars_rounded), findsOneWidget);
        expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
        expect(find.text('STATUS'), findsOneWidget);
        expect(find.text('NEXT RANK'), findsOneWidget);
      },
    );
  });

  group('Group 4: Search & Category Filtering', () {
    testWidgets(
      'renders search field and all category chips in horizontal track',
      (tester) async {
        await pumpQuestLibraryPage(tester);

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Search quests...'), findsOneWidget);

        expect(find.text('ALL'), findsOneWidget);
        expect(find.text('VOCABULARY'), findsOneWidget);
        expect(find.text('GRAMMAR'), findsOneWidget);
        expect(find.text('SPEAKING'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping category chip switches to vertical card list mode',
      (tester) async {
        await pumpQuestLibraryPage(tester);

        // Tap GRAMMAR chip
        await tester.tap(find.text('GRAMMAR'));
        await tester.pumpAndSettle();

        // In vertical card list mode, cards render category tags
        expect(find.text('grammar'), findsWidgets);
      },
    );

    testWidgets(
      'entering search query filters list and displays matching quest cards',
      (tester) async {
        await pumpQuestLibraryPage(tester);

        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'parts of speech');
        await tester.pumpAndSettle();

        expect(find.text('PARTS OF SPEECH'), findsOneWidget);
      },
    );

    testWidgets(
      'entering non-matching search query displays empty state',
      (tester) async {
        await pumpQuestLibraryPage(tester);

        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'non_existent_quest_xyz_999');
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
        expect(find.text('No matching quests found'), findsOneWidget);
        expect(find.text('Try a different search or category'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping clear icon button clears search input and restores content',
      (tester) async {
        await pumpQuestLibraryPage(tester);

        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'test');
        await tester.pumpAndSettle();

        final clearBtn = find.byIcon(Icons.close_rounded);
        expect(clearBtn, findsOneWidget);

        await tester.tap(clearBtn);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.close_rounded), findsNothing);
        expect(find.text('ALL'), findsOneWidget);
      },
    );
  });

  group('Group 5: Grouped Sections & Routing', () {
    testWidgets(
      'tapping VIEW ALL button in a category section selects that category',
      (tester) async {
        await pumpQuestLibraryPage(tester);

        // Find the first VIEW ALL button
        final viewAllButton = find.text('VIEW ALL').first;
        await tester.tap(viewAllButton);
        await tester.pumpAndSettle();

        // Now in filtered vertical mode
        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets(
      'tapping compact quest card in horizontal list navigates to /levels with query parameters',
      (tester) async {
        await pumpQuestLibraryPage(tester);

        // The first compact card in the first section
        final cardFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              (w.properties.label?.contains('Level') ?? false),
        ).first;

        expect(cardFinder, findsOneWidget);
        await tester.tap(cardFinder);
        await tester.pumpAndSettle();

        expect(navigatedRoutes.any((r) => r.startsWith('/levels?category=')), isTrue);
        expect(find.textContaining('Levels Screen:'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping vertical quest card in filtered mode navigates to /levels',
      (tester) async {
        await pumpQuestLibraryPage(tester);

        // Switch to grammar
        await tester.tap(find.text('GRAMMAR'));
        await tester.pumpAndSettle();

        // Find a card in vertical list
        final cardFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              (w.properties.label?.contains('Completed') ?? false),
        ).first;

        expect(cardFinder, findsOneWidget);
        await tester.tap(cardFinder);
        await tester.pumpAndSettle();

        expect(navigatedRoutes.any((r) => r.startsWith('/levels?category=')), isTrue);
        expect(find.textContaining('Levels Screen:'), findsOneWidget);
      },
    );
  });

  group('Group 6: Responsive Viewports, Accessibility & Themes', () {
    testWidgets(
      'renders cleanly without RenderFlex overflow on compact mobile (320x568)',
      (tester) async {
        await pumpQuestLibraryPage(
          tester,
          viewportSize: const Size(320, 568),
        );

        expect(find.text('QUEST ARCHIVE'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders cleanly on large tablet viewport (800x1280)',
      (tester) async {
        await pumpQuestLibraryPage(
          tester,
          viewportSize: const Size(800, 1280),
        );

        expect(find.text('QUEST ARCHIVE'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders cleanly under 1.3x accessibility text scaling without overflow',
      (tester) async {
        await pumpQuestLibraryPage(
          tester,
          textScaleFactor: 1.3,
        );

        expect(find.text('QUEST ARCHIVE'), findsOneWidget);
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
            primary: Color(0xFF3B82F6),
            surface: Color(0xFF1E293B),
            onSurface: Colors.white,
          ),
        );

        await pumpQuestLibraryPage(
          tester,
          theme: darkTheme,
        );

        expect(find.text('QUEST ARCHIVE'), findsOneWidget);
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
            primary: Color(0xFF3B82F6),
            surface: Color(0xFF050505),
            onSurface: Colors.white,
          ),
        );

        await pumpQuestLibraryPage(
          tester,
          theme: midnightTheme,
        );

        expect(find.text('QUEST ARCHIVE'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
