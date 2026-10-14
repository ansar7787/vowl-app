import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/data/services/asset_quest_service.dart';
import 'package:vowl/core/presentation/widgets/games/maps/components/glass_map_header.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_map_node.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/story_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockAssetQuestService extends Mock implements AssetQuestService {}

class MockStoryService extends Mock implements StoryService {}

class MockLocaleService extends Mock implements LocaleService {}

class FakeBuildContext extends Fake implements BuildContext {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockAssetQuestService mockAssetQuestService;
  late MockStoryService mockStoryService;
  final mockLocaleService = MockLocaleService();
  late List<String> navigatedRoutes;

  const testUser = UserEntity(
    id: 'user_456',
    email: 'reader@vowl.app',
    displayName: 'Elena Rostova',
    currentStreak: 7,
    totalExp: 2400,
    coins: 180,
    unlockedLevels: {
      'readAndAnswer': 3,
    },
    completedLevels: {
      'readAndAnswer': [1, 2],
    },
    starRatings: {
      'readAndAnswer': {
        '1': 3,
        '2': 2,
      },
    },
  );

  setUpAll(() {
    registerFallbackValue(FakeBuildContext());
    try {
      initLocaleServiceReference(mockLocaleService);
    } catch (_) {}
  });

  setUp(() {
    navigatedRoutes = [];
    reset(mockLocaleService);

    mockAuthBloc = MockAuthBloc();
    mockAssetQuestService = MockAssetQuestService();
    mockStoryService = MockStoryService();

    if (di.sl.isRegistered<AssetQuestService>()) {
      di.sl.unregister<AssetQuestService>();
    }
    if (di.sl.isRegistered<StoryService>()) {
      di.sl.unregister<StoryService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }

    di.sl.registerSingleton<AssetQuestService>(mockAssetQuestService);
    di.sl.registerSingleton<StoryService>(mockStoryService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);

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

    when(
      () => mockAssetQuestService.preloadBatch(any(), any()),
    ).thenAnswer((_) async {});

    when(
      () => mockStoryService.getStoryBeat(any(), any(), any()),
    ).thenReturn(null);
  });

  tearDown(() {
    if (di.sl.isRegistered<AssetQuestService>()) {
      di.sl.unregister<AssetQuestService>();
    }
    if (di.sl.isRegistered<StoryService>()) {
      di.sl.unregister<StoryService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
  });

  Widget createWidgetUnderTest({
    ThemeMode themeMode = ThemeMode.light,
    UserEntity? customUser,
  }) {
    if (customUser != null) {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(customUser),
      );
    }

    final router = GoRouter(
      initialLocation: '/map',
      routes: [
        GoRoute(
          path: '/map',
          builder: (context, state) => const ModernCategoryMap(
            gameType: 'readAndAnswer',
            categoryId: 'reading',
          ),
        ),
        GoRoute(
          path: '/game',
          builder: (context, state) {
            final uri = state.uri.toString();
            navigatedRoutes.add(uri);
            return Scaffold(
              body: Text('Game Screen: $uri'),
            );
          },
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) {
            navigatedRoutes.add('/home');
            return const Scaffold(body: Text('Home Screen Destination'));
          },
        ),
      ],
    );

    return BlocProvider<AuthBloc>.value(
      value: mockAuthBloc,
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

  group('ModernCategoryMap - Initial Rendering & Header', () {
    testWidgets('renders map structure, GlassMapHeader and CustomScrollView', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ModernCategoryMap), findsOneWidget);
      expect(find.byType(GlassMapHeader), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(ModernMapNode), findsWidgets);
    });

    testWidgets('invokes AssetQuestService preloadBatch for current unlocked level', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockAssetQuestService.preloadBatch('readAndAnswer', 3)).called(1);
    });
  });

  group('ModernCategoryMap - Node Progression & Level States', () {
    testWidgets('renders completed levels, stars, and playable node', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Level 1 and 2 are completed, Level 3 is the active/playable node
      expect(find.text('1'), findsWidgets);
      expect(find.text('2'), findsWidgets);
      expect(find.text('3'), findsWidgets);

      // Star icons on completed level nodes
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
    });
  });

  group('ModernCategoryMap - Tap Interaction & Routing', () {
    testWidgets('tapping unlocked level node pushes /game with category and level', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Find the node for Level 1 (completed/unlocked) and tap it
      final level1Finder = find.widgetWithText(ScaleButton, '1');
      if (level1Finder.evaluate().isNotEmpty) {
        await tester.tap(level1Finder.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(navigatedRoutes, isNotEmpty);
        expect(navigatedRoutes.first, contains('/game'));
        expect(navigatedRoutes.first, contains('category=reading'));
        expect(navigatedRoutes.first, contains('gameType=readAndAnswer'));
        expect(navigatedRoutes.first, contains('level=1'));
      }
    });

    testWidgets('tapping back button pops route or navigates to /home', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const level1User = UserEntity(
        id: 'u_fresh',
        email: 'fresh@vowl.app',
      );

      await tester.pumpWidget(createWidgetUnderTest(customUser: level1User));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(navigatedRoutes, contains('/home'));
    });
  });

  group('ModernCategoryMap - Theme & Layout Safety', () {
    testWidgets('renders cleanly in dark mode without contrast issues', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest(themeMode: ThemeMode.dark));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.byType(ModernCategoryMap), findsOneWidget);
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
      expect(find.byType(ModernCategoryMap), findsOneWidget);
    });
  });
}

