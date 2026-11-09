import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/home/presentation/widgets/continue_learning_card.dart';

class MockHapticService extends Mock implements HapticService {}

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;
  late MockLocaleService mockLocaleService;
  late List<String> navigatedRoutes;

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    mockHapticService = MockHapticService();
    mockLocaleService = MockLocaleService();
    navigatedRoutes = [];

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));
    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer((inv) {
      final fallback = inv.namedArguments[#fallback] as String?;
      final args = inv.namedArguments[#args] as List<String>?;
      if (fallback != null && args != null && args.isNotEmpty) {
        var res = fallback;
        for (final arg in args) {
          res = res.replaceFirst('{}', arg);
        }
        return res;
      }
      return fallback ?? (inv.positionalArguments.first as String);
    });

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);

    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    initLocaleServiceReference(mockLocaleService);
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
  });

  Widget createSubject({
    UserEntity? user,
    bool isShimmer = false,
    ThemeMode themeMode = ThemeMode.dark,
    double width = 393,
    double height = 852,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: isShimmer || user == null
                ? const ContinueLearningCard.shimmer()
                : ContinueLearningCard(user: user),
          ),
        ),
        GoRoute(
          path: AppRouter.categoryGamesRoute,
          builder: (context, state) {
            final cat = state.uri.queryParameters['category'] ?? '';
            navigatedRoutes.add(
              '${AppRouter.categoryGamesRoute}?category=$cat',
            );
            return Scaffold(body: Text('Category: $cat'));
          },
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: Size(width, height),
      builder: (context, _) => MaterialApp.router(
        routerConfig: router,
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      ),
    );
  }

  UserEntity buildUser({
    Map<String, List<int>> completedLevels = const {
      'flashcards': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
    },
    List<Map<String, dynamic>> recentActivities = const [
      {'type': 'quest', 'gameType': 'flashcards'},
    ],
  }) {
    return UserEntity(
      id: 'user_123',
      email: 'test@vowl.app',
      displayName: 'Muhammed Ansar',
      completedLevels: completedLevels,
      recentActivities: recentActivities,
    );
  }

  testWidgets(
    'renders ContinueLearningCard with active user showing resolved category, levels tag, and resume CTA',
    (tester) async {
      final user = buildUser();
      await tester.pumpWidget(createSubject(user: user));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(ContinueLearningCard), findsOneWidget);
      expect(find.text('VOCABULARY'), findsOneWidget);
      expect(find.text('Continue Learning'), findsOneWidget);
      expect(find.text('14 / 20'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    },
  );

  testWidgets('renders new learner state when totalLevelsCompleted is 0', (
    tester,
  ) async {
    final newUser = buildUser(completedLevels: {}, recentActivities: []);

    await tester.pumpWidget(createSubject(user: newUser));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Start Your Journey'), findsOneWidget);
    expect(find.text('DAY 1 JOURNEY'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.textContaining('First step in'), findsOneWidget);
  });

  testWidgets(
    'tapping card triggers selection haptics and navigates to category games route',
    (tester) async {
      final user = buildUser();
      await tester.pumpWidget(createSubject(user: user));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byType(ContinueLearningCard));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);
      expect(navigatedRoutes.length, 1);
      expect(
        navigatedRoutes.first,
        '${AppRouter.categoryGamesRoute}?category=vocabulary',
      );
    },
  );

  testWidgets(
    'renders shimmer skeleton without errors when isShimmer is true',
    (tester) async {
      await tester.pumpWidget(createSubject(isShimmer: true));
      await tester.pump();

      expect(find.byType(ContinueLearningCard), findsOneWidget);
      expect(find.text('Continue Learning'), findsNothing);
    },
  );

  testWidgets(
    'renders cleanly on small screen 320dp without RenderFlex overflow',
    (tester) async {
      final user = buildUser();
      await tester.pumpWidget(
        createSubject(user: user, width: 320, height: 568),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
      expect(find.byType(ContinueLearningCard), findsOneWidget);
    },
  );

  testWidgets('renders cleanly in Light theme mode', (tester) async {
    final user = buildUser();
    await tester.pumpWidget(
      createSubject(user: user, themeMode: ThemeMode.light),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.byType(ContinueLearningCard), findsOneWidget);
  });

  testWidgets('displays urgent habit spotlight when streak is pending today', (
    tester,
  ) async {
    final now = DateTime.now();
    final yesterdayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${(now.day - 1).toString().padLeft(2, '0')}';
    final user = UserEntity(
      id: 'user_streak',
      email: 'streak@vowl.app',
      currentStreak: 5,
      dailyXpHistory: {yesterdayKey: 50},
      completedLevels: const {
        'flashcards': [1, 2, 3],
      },
    );

    await tester.pumpWidget(createSubject(user: user));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('DAILY GOAL'), findsOneWidget);
    expect(find.text('Secure'), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.textContaining('protect your 5d streak'), findsOneWidget);
  });

  testWidgets('displays secured habit badge when streak is completed today', (
    tester,
  ) async {
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final user = UserEntity(
      id: 'user_secured',
      email: 'secured@vowl.app',
      currentStreak: 6,
      dailyXpHistory: {todayKey: 100},
      completedLevels: const {
        'flashcards': [1, 2, 3, 4],
      },
    );

    await tester.pumpWidget(createSubject(user: user));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('STREAK ACTIVE'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });
}
