import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/profile/presentation/pages/trophy_room_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockLocaleService mockLocaleService;
  late List<String> navigatedRoutes;

  const testUser = UserEntity(
    id: 'test_trophy_user',
    email: 'trophy@vowl.app',
    displayName: 'Sir Arthur',
    isPremium: true,
    badges: [
      'novice_speaking',
      'streak_7',
      'master_speaking', // Legendary badge
    ],
  );

  setUpAll(() {
    registerFallbackValue(const AuthReloadUser());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('haptic_feedback'),
      (call) async => null,
    );
  });

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    navigatedRoutes = [];

    mockAuthBloc = MockAuthBloc();
    mockLocaleService = MockLocaleService();

    when(() => mockAuthBloc.state)
        .thenReturn(AuthState.authenticated(testUser));

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
      initialLocation: '/trophies',
      routes: [
        GoRoute(
          path: '/trophies',
          builder: (context, state) => const TrophyRoomScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) {
            navigatedRoutes.add('/home');
            return const Scaffold(body: Text('Home Screen Placeholder'));
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

  group('Group 1: Trophy Summary & Header', () {
    testWidgets('renders Trophy Room title and summary counter with 3 earned badges', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('MY TROPHY ROOM'), findsOneWidget);
      expect(find.text('Total Earned'), findsOneWidget);
      // User has 3 badges total (2 standard + 1 legendary)
      expect(find.textContaining('3 / 50', findRichText: true), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    });

    testWidgets('tapping back button navigates out or to /home', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();
    });
  });

  group('Group 2: Filter Tabs (Standard vs Legendary)', () {
    testWidgets('switches between Standard and Legendary filter views', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Legendary'), findsOneWidget);

      // In Standard mode, standard earned badges (novice_speaking, streak_7) are visible
      expect(find.text('NOVICE'), findsWidgets);
      expect(find.text('SPEAKING'), findsWidgets);

      // Tap Legendary tab
      await tester.tap(find.text('Legendary'));
      await tester.pumpAndSettle();

      // In Legendary mode, master_speaking is visible with crown emoji
      expect(find.text('MASTER'), findsWidgets);
      expect(find.text('SPEAKING'), findsWidgets);
      expect(find.text('👑'), findsWidgets);

      // Tap Standard tab to switch back
      await tester.tap(find.text('Standard'));
      await tester.pumpAndSettle();

      expect(find.text('NOVICE'), findsWidgets);
    });
  });

  group('Group 3: Empty State / Status Message', () {
    testWidgets('renders empty status message when user has zero badges', (tester) async {
      final userZero = testUser.copyWith(badges: []);
      when(() => mockAuthBloc.state)
          .thenReturn(AuthState.authenticated(userZero));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('0 / 50', findRichText: true), findsOneWidget);
      expect(
        find.text('No trophies yet. Keep completing lessons and challenges to earn your first shiny badge!'),
        findsOneWidget,
      );

      // Switch to Legendary
      await tester.tap(find.text('Legendary'));
      await tester.pumpAndSettle();

      expect(find.text('No legendary trophies unlocked yet.'), findsOneWidget);
    });
  });

  group('Group 4: Badge Interaction & Locked Slots', () {
    testWidgets('renders earned badge cards and locked slots with lock icons', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Locked slots have lock icons
      expect(find.byIcon(Icons.lock_rounded), findsWidgets);

      // Tapping an unlocked badge card triggers scale tap
      final earnedBadge = find.widgetWithText(ScaleButton, 'NOVICE');
      expect(earnedBadge, findsOneWidget);

      await tester.tap(earnedBadge);
      await tester.pumpAndSettle();
    });
  });

  group('Group 5: Responsiveness & Themes', () {
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
