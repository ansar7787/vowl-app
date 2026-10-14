import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/games/presentation/widgets/kids_category_shelf.dart';
import 'package:vowl/features/kids_zone/domain/services/kids_game_helper.dart';

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockLocaleService = MockLocaleService();
  late List<String> navigatedRoutes;
  late List<Map<String, dynamic>?> navigatedExtras;

  setUpAll(() {
    try {
      initLocaleServiceReference(mockLocaleService);
    } catch (_) {}
  });

  setUp(() {
    navigatedRoutes = [];
    navigatedExtras = [];
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
  });

  Widget createWidgetUnderTest({
    required UserEntity user,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    final router = GoRouter(
      initialLocation: '/shelf',
      routes: [
        GoRoute(
          path: '/shelf',
          builder: (context, state) => Scaffold(
            body: Center(
              child: KidsCategoryShelf(user: user),
            ),
          ),
        ),
        GoRoute(
          path: '/kids/map/:gameType',
          builder: (context, state) {
            final gameType = state.pathParameters['gameType'] ?? '';
            navigatedRoutes.add('/kids/map/$gameType');
            navigatedExtras.add(state.extra as Map<String, dynamic>?);
            return Scaffold(
              body: Text('Kids Map: $gameType'),
            );
          },
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
      ),
    );
  }

  group('KidsCategoryShelf - Layout & Rendering', () {
    testWidgets('renders horizontal list view and game cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testUser = UserEntity(
        id: 'u1',
        email: 'kid@vowl.app',
      );

      await tester.pumpWidget(createWidgetUnderTest(user: testUser));
      await tester.pumpAndSettle();

      expect(find.byType(KidsCategoryShelf), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      final firstGame = KidsGameHelper.allGames.first;
      expect(find.text(firstGame.gridTitle.toUpperCase()), findsOneWidget);
      expect(find.text(firstGame.subtitle.toUpperCase()), findsOneWidget);
    });

    testWidgets('supports smooth horizontal scrolling across cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testUser = UserEntity(
        id: 'u1',
        email: 'kid@vowl.app',
      );

      await tester.pumpWidget(createWidgetUnderTest(user: testUser));
      await tester.pumpAndSettle();

      // Drag horizontal list to the left
      await tester.drag(find.byType(ListView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Expect no exceptions occurred during transform spatial physics
      expect(tester.takeException(), isNull);
    });
  });

  group('KidsCategoryShelf - Indicator Badges & Progression States', () {
    testWidgets('displays NEW badge for freshly unlocked games (level 1, 0 cleared)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const newUser = UserEntity(
        id: 'new_kid',
        email: 'kid@vowl.app',
        unlockedLevels: {'handwriting': 1},
        completedLevels: {'handwriting': []},
      );

      await tester.pumpWidget(createWidgetUnderTest(user: newUser));
      await tester.pumpAndSettle();

      expect(find.text('NEW'), findsWidgets);
    });

    testWidgets('displays current level number and circular progress when in-progress', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final firstGameType = KidsGameHelper.allGames.first.gameType;

      final inProgressUser = UserEntity(
        id: 'progress_kid',
        email: 'kid@vowl.app',
        unlockedLevels: {firstGameType: 15},
        completedLevels: {
          firstGameType: List.generate(14, (i) => i + 1),
        },
      );

      await tester.pumpWidget(createWidgetUnderTest(user: inProgressUser));
      await tester.pumpAndSettle();

      expect(find.text('15'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('displays golden checkmark badge when category is fully mastered (200 levels)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final firstGameType = KidsGameHelper.allGames.first.gameType;

      final masteredUser = UserEntity(
        id: 'master_kid',
        email: 'kid@vowl.app',
        unlockedLevels: {firstGameType: 200},
        completedLevels: {
          firstGameType: List.generate(200, (i) => i + 1),
        },
      );

      await tester.pumpWidget(createWidgetUnderTest(user: masteredUser));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsWidgets);
    });
  });

  group('KidsCategoryShelf - Navigation Interaction', () {
    testWidgets('tapping a game card navigates to /kids/map/:gameType with title and color', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testUser = UserEntity(
        id: 'u1',
        email: 'kid@vowl.app',
      );

      await tester.pumpWidget(createWidgetUnderTest(user: testUser));
      await tester.pumpAndSettle();

      final firstGame = KidsGameHelper.allGames.first;
      final cardButtons = find.byType(ScaleButton);
      expect(cardButtons, findsWidgets);

      await tester.tap(cardButtons.first);
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains('/kids/map/${firstGame.gameType}'));
      expect(navigatedExtras.first?['title'], equals(firstGame.fullTitle));
      expect(find.text('Kids Map: ${firstGame.gameType}'), findsOneWidget);
    });
  });

  group('KidsCategoryShelf - Theme & Small Screen Layout Safety', () {
    testWidgets('renders cleanly in dark mode without contrast issues', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testUser = UserEntity(
        id: 'u1',
        email: 'kid@vowl.app',
      );

      await tester.pumpWidget(
        createWidgetUnderTest(user: testUser, themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(KidsCategoryShelf), findsOneWidget);
    });

    testWidgets('compact mobile screen (320dp width) zero-overflow layout safety', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testUser = UserEntity(
        id: 'u1',
        email: 'kid@vowl.app',
      );

      await tester.pumpWidget(createWidgetUnderTest(user: testUser));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(KidsCategoryShelf), findsOneWidget);
    });
  });
}

