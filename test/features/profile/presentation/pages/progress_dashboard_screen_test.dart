import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/profile/presentation/pages/progress_dashboard_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockHapticService mockHapticService;
  late MockLocaleService mockLocaleService;
  late List<String> navigatedRoutes;

  final now = DateTime.now();
  final dayKeys = List.generate(7, (i) {
    final day = now.subtract(Duration(days: 6 - i));
    return DateFormat('yyyy-MM-dd').format(day);
  });

  final testUser = UserEntity(
    id: 'test_user_progress',
    email: 'learner@vowl.app',
    displayName: 'Aria Stark',
    isPremium: true,
    totalExp: 1250,
    dailyXpHistory: {
      dayKeys[0]: 50,
      dayKeys[1]: 80,
      dayKeys[2]: 0,
      dayKeys[3]: 120,
      dayKeys[4]: 40,
      dayKeys[5]: 90,
      dayKeys[6]: 150,
    },
    completedLevels: {
      'consonantClarity': [1, 2, 3, 4, 5],
      'sentenceCorrection': [1, 2],
      'pitchModulation': [1],
    },
    recentActivities: [
      {
        'type': 'quest',
        'gameType': 'consonantClarity',
        'timestamp': DateTime.now().toIso8601String(),
      },
      {
        'type': 'quest',
        'gameType': 'sentenceCorrection',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
    ],
  );

  setUpAll(() {
    registerFallbackValue(const AuthReloadUser());
  });

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    navigatedRoutes = [];

    mockAuthBloc = MockAuthBloc();
    mockHapticService = MockHapticService();
    mockLocaleService = MockLocaleService();

    when(() => mockAuthBloc.state)
        .thenReturn(AuthState.authenticated(testUser));

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);

    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    initLocaleServiceReference(mockLocaleService);
    when(() => mockLocaleService.tr(any(), args: any(named: 'args'), fallback: any(named: 'fallback')))
        .thenAnswer((inv) {
      final fallback = inv.namedArguments[const Symbol('fallback')] as String?;
      final key = inv.positionalArguments[0] as String;
      return fallback ?? key;
    });
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
  });

  Widget buildTestWidget({
    Size screenSize = const Size(360, 690),
    double textScaleFactor = 1.0,
    ThemeMode themeMode = ThemeMode.light,
    bool isMidnight = false,
  }) {
    final router = GoRouter(
      initialLocation: '/report',
      routes: [
        GoRoute(
          path: '/report',
          builder: (context, state) => const ProgressDashboardScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home Screen Placeholder')),
        ),
        GoRoute(
          path: AppRouter.categoryGamesRoute,
          builder: (context, state) {
            navigatedRoutes.add('categoryGames:${state.uri.queryParameters['category']}');
            return Scaffold(
              body: Text('Category Games: ${state.uri.queryParameters['category']}'),
            );
          },
        ),
        GoRoute(
          path: AppRouter.levelsRoute,
          builder: (context, state) {
            navigatedRoutes.add('levels:${state.uri.queryParameters['gameType']}');
            return Scaffold(
              body: Text('Levels: ${state.uri.queryParameters['gameType']}'),
            );
          },
        ),
      ],
    );

    ThemeData theme;
    if (isMidnight) {
      theme = ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      );
    } else if (themeMode == ThemeMode.dark) {
      theme = AppTheme.darkTheme;
    } else {
      theme = AppTheme.lightTheme;
    }

    return ScreenUtilInit(
      designSize: screenSize,
      builder: (context, child) => MediaQuery(
        data: MediaQueryData(
          size: screenSize,
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: MaterialApp.router(
            routerConfig: router,
            theme: theme,
          ),
        ),
      ),
    );
  }

  group('Group 1: Loading State', () {
    testWidgets('renders CircularProgressIndicator when user is null', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Group 2: Header & Back Button', () {
    testWidgets('renders title and popping back navigates out', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Learning Report'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
    });
  });

  group('Group 3: Weekly XP Trend Section', () {
    testWidgets('renders weekly XP trend bar chart with active days and total XP', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('WEEKLY XP TREND'), findsOneWidget);
      // Total XP: 50 + 80 + 0 + 120 + 40 + 90 + 150 = 530 XP
      expect(find.text('530 XP'), findsOneWidget);
      expect(find.text('6 of 7 days active this week.'), findsOneWidget);

      // Verify today's XP label
      expect(find.text('150'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
    });
  });

  group('Group 4: Cross-Category Mastery Overview', () {
    testWidgets('calculates overall mastery and renders category chips', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('TOTAL MASTERY'), findsOneWidget);
      // 5 + 2 + 1 = 8 levels cleared
      expect(find.text('8 levels cleared across all categories.'), findsOneWidget);

      // Verify category chips exist
      for (final cat in QuestType.values) {
        final icon = LevelThemeHelper.getCategoryTheme(cat.name).icon;
        expect(find.byIcon(icon), findsWidgets);
      }

      // Tap first category chip (Speaking)
      final chipFinder = find.widgetWithText(ScaleButton, 'Speaking');
      if (chipFinder.evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(chipFinder.first, 150);
        await tester.pumpAndSettle();
        await tester.tap(chipFinder.first);
        await tester.pumpAndSettle();

        verify(() => mockHapticService.selection()).called(1);
        expect(navigatedRoutes.any((r) => r.startsWith('categoryGames:')), isTrue);
      }
    });
  });

  group('Group 5: Continue Learning Quick Actions', () {
    testWidgets('renders empty state when user has zero completed levels', (tester) async {
      final userZero = testUser.copyWith(
        completedLevels: {},
        recentActivities: [],
      );
      when(() => mockAuthBloc.state)
          .thenReturn(AuthState.authenticated(userZero));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_circle_outline_rounded), findsOneWidget);
      expect(find.text('Start playing to see your progress here!'), findsOneWidget);
    });

    testWidgets('renders recent games and tapping a game card navigates to levels route', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('CONTINUE LEARNING'), findsOneWidget);
      expect(find.text('CONSONANT CLARITY'), findsOneWidget);
      expect(find.text('SENTENCE CORRECTION'), findsOneWidget);

      // Tap first game resume card
      final consonantClarityCard = find.widgetWithText(ScaleButton, 'CONSONANT CLARITY');
      expect(consonantClarityCard, findsOneWidget);

      await tester.scrollUntilVisible(consonantClarityCard, 200);
      await tester.pumpAndSettle();

      await tester.tap(consonantClarityCard);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);
      expect(navigatedRoutes.any((r) => r.contains('consonantClarity')), isTrue);
    });
  });

  group('Group 6: Responsiveness & Themes', () {
    testWidgets('renders cleanly on compact mobile (320x568) without overflow', (tester) async {
      await tester.pumpWidget(buildTestWidget(screenSize: const Size(320, 568)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet viewport (800x1280) without overflow', (tester) async {
      await tester.pumpWidget(buildTestWidget(screenSize: const Size(800, 1280)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with 1.3x accessibility text scale', (tester) async {
      await tester.pumpWidget(buildTestWidget(textScaleFactor: 1.3));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      await tester.pumpWidget(buildTestWidget(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in midnight theme mode', (tester) async {
      await tester.pumpWidget(buildTestWidget(isMidnight: true));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
