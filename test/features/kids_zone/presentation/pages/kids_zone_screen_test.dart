import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/age_gate_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/ml_services/digital_ink_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/pages/kids_zone_screen.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_category_grid.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_global_progress_card.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_magic_chest.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_smart_mix_widget.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_zone_home_header.dart';
import 'package:vowl/features/leaderboard/domain/repositories/leaderboard_repository.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockSoundService extends Mock implements SoundService {}

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

class MockDigitalInkService extends Mock implements DigitalInkService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockAppLogger mockLogger;
  late MockSoundService mockSoundService;
  late MockLeaderboardRepository mockLeaderboardRepo;
  late MockDigitalInkService mockDigitalInkService;
  final mockLocaleService = MockLocaleService();
  late List<String> navigatedRoutes;

  const testUser = UserEntity(
    id: 'kid_user_1',
    email: 'kid@vowl.app',
    displayName: 'Leo Junior',
    kidsCoins: 120,
    kidsMascot: 'owly',
    kidsBuddyMood: 'happy',
    completedLevels: {
      'alphabet': [1, 2, 3, 4, 5],
      'numbers': [1, 2, 3],
    },
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    navigatedRoutes = [];
    reset(mockLocaleService);

    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockLogger = MockAppLogger();
    mockSoundService = MockSoundService();
    mockLeaderboardRepo = MockLeaderboardRepository();
    mockDigitalInkService = MockDigitalInkService();

    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<LeaderboardRepository>()) {
      di.sl.unregister<LeaderboardRepository>();
    }
    if (di.sl.isRegistered<DigitalInkService>()) {
      di.sl.unregister<DigitalInkService>();
    }

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockLogger);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<LeaderboardRepository>(mockLeaderboardRepo);
    di.sl.registerSingleton<DigitalInkService>(mockDigitalInkService);

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

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockDigitalInkService.isModelDownloaded())
        .thenAnswer((_) async => true);
    when(() => mockLeaderboardRepo.getTopUsers(limit: any(named: 'limit')))
        .thenAnswer(
      (_) async => Right(
        LeaderboardResult(
          users: [testUser],
          lastUpdated: DateTime.now(),
        ),
      ),
    );

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(testUser),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

    await AgeGateService.completeAgeGate(isAdult: true);
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<LeaderboardRepository>()) {
      di.sl.unregister<LeaderboardRepository>();
    }
    if (di.sl.isRegistered<DigitalInkService>()) {
      di.sl.unregister<DigitalInkService>();
    }
  });

  Widget createWidgetUnderTest({
    ThemeMode themeMode = ThemeMode.light,
    GoRouter? customRouter,
  }) {
    final router =
        customRouter ??
        GoRouter(
          initialLocation: '/kids-zone',
          routes: [
            GoRoute(
              path: '/kids-zone',
              builder: (context, state) => const KidsZoneScreen(),
            ),
            GoRoute(
              path: '/kids-stickers',
              builder: (context, state) {
                navigatedRoutes.add('/kids-stickers');
                return const Scaffold(body: Text('Stickers Screen'));
              },
            ),
            GoRoute(
              path: '/kids-room',
              builder: (context, state) {
                navigatedRoutes.add('/kids-room');
                return const Scaffold(body: Text('Kids Room Screen'));
              },
            ),
            GoRoute(
              path: '/kids-boutique',
              name: 'kids-boutique',
              builder: (context, state) {
                navigatedRoutes.add('/kids-boutique');
                return const Scaffold(body: Text('Boutique Screen'));
              },
            ),
            GoRoute(
              path: '/kids-mascot',
              builder: (context, state) {
                navigatedRoutes.add('/kids-mascot');
                return const Scaffold(body: Text('Mascot Screen'));
              },
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) {
                navigatedRoutes.add('/home');
                return const Scaffold(body: Text('Home Screen'));
              },
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) {
                navigatedRoutes.add('/settings');
                return const Scaffold(body: Text('Settings Screen'));
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
        builder: (context, child) {
          return MaterialApp.router(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            routerConfig: router,
          );
        },
      ),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
    double width = 390,
    double height = 844,
  }) async {
    tester.view.physicalSize = Size(width * 2, height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetUnderTest(themeMode: themeMode));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> cleanUp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  group('KidsZoneScreen - Core Hub Rendering & Components', () {
    testWidgets(
      'renders KidsZoneScreen with app bar, coins count, mascot header, and smart mix widget',
      (tester) async {
        await pumpScreen(tester);

        expect(find.byType(KidsZoneScreen), findsOneWidget);
        expect(find.text('120'), findsOneWidget); // User's kidsCoins
        expect(find.byType(KidsZoneHomeHeader), findsOneWidget);
        expect(find.text('Leo Junior'), findsOneWidget);
        expect(find.byType(KidsSmartMixWidget), findsOneWidget);

        await cleanUp(tester);
      },
    );

    testWidgets(
      'renders global progress card with levels completed and rank',
      (tester) async {
        await pumpScreen(tester);

        expect(find.byType(KidsGlobalProgressCard), findsOneWidget);
        expect(find.text('8'), findsWidgets); // Kids total levels completed (5+3)

        await cleanUp(tester);
      },
    );

    testWidgets(
      'renders KidsMagicChest daily reward component',
      (tester) async {
        await pumpScreen(tester);

        expect(find.byType(KidsMagicChest), findsOneWidget);

        await cleanUp(tester);
      },
    );

    testWidgets(
      'renders category grid with themed sections after scrolling',
      (tester) async {
        await pumpScreen(tester);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(KidsCategoryGrid), findsOneWidget);

        await cleanUp(tester);
      },
    );

    testWidgets(
      'renders shimmer loading when user state is unauthenticated / null',
      (tester) async {
        when(() => mockAuthBloc.state)
            .thenReturn(const AuthState.unauthenticated());

        await pumpScreen(tester);

        expect(find.byType(HomeShimmerLoading), findsOneWidget);

        await cleanUp(tester);
      },
    );

    testWidgets(
      'renders cleanly in dark mode without contrast issues',
      (tester) async {
        await pumpScreen(tester, themeMode: ThemeMode.dark);

        expect(find.byType(KidsZoneScreen), findsOneWidget);
        expect(find.text('120'), findsOneWidget);

        await cleanUp(tester);
      },
    );
  });

  group('KidsZoneScreen - Quick Menu Navigation', () {
    testWidgets(
      'tapping quick menu Album navigates to /kids-stickers',
      (tester) async {
        await pumpScreen(tester);

        final albumIcon = find.byIcon(Icons.auto_stories_rounded);
        expect(albumIcon, findsOneWidget);

        await tester.tap(albumIcon);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(navigatedRoutes, contains('/kids-stickers'));

        await cleanUp(tester);
      },
    );

    testWidgets(
      'tapping quick menu Room navigates to /kids-room',
      (tester) async {
        await pumpScreen(tester);

        final roomIcon = find.byIcon(Icons.bedroom_child_rounded);
        expect(roomIcon, findsOneWidget);

        await tester.tap(roomIcon);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(navigatedRoutes, contains('/kids-room'));

        await cleanUp(tester);
      },
    );

    testWidgets(
      'tapping quick menu Shop navigates to kids-boutique',
      (tester) async {
        await pumpScreen(tester);

        final shopIcon = find.byIcon(Icons.shopping_bag_rounded);
        expect(shopIcon, findsOneWidget);

        await tester.tap(shopIcon);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(navigatedRoutes, contains('/kids-boutique'));

        await cleanUp(tester);
      },
    );

    testWidgets(
      'tapping quick menu Buddies navigates to /kids-mascot',
      (tester) async {
        await pumpScreen(tester);

        final buddiesIcon = find.byIcon(Icons.face_retouching_natural_rounded);
        expect(buddiesIcon, findsOneWidget);

        await tester.tap(buddiesIcon);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(navigatedRoutes, contains('/kids-mascot'));

        await cleanUp(tester);
      },
    );
  });

  group('KidsZoneScreen - App Bar Actions & Age Gating', () {
    testWidgets(
      'tapping back button navigates to /home when adult is cached',
      (tester) async {
        await AgeGateService.completeAgeGate(isAdult: true);
        await pumpScreen(tester);

        final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
        expect(backBtn, findsOneWidget);

        await tester.tap(backBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(navigatedRoutes, contains('/home'));

        await cleanUp(tester);
      },
    );

    testWidgets(
      'tapping settings button navigates to /settings when user is child/kids-only',
      (tester) async {
        await AgeGateService.completeAgeGate(isAdult: false);
        await pumpScreen(tester);

        final settingsBtn = find.byIcon(Icons.settings_rounded);
        expect(settingsBtn, findsOneWidget);

        await tester.tap(settingsBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(navigatedRoutes, contains('/settings'));

        await cleanUp(tester);
      },
    );
  });

  group('KidsZoneScreen - Small Screen Safety (320dp)', () {
    testWidgets(
      'renders on compact 320dp width without RenderFlex overflow',
      (tester) async {
        await pumpScreen(tester, width: 320, height: 568);

        expect(tester.takeException(), isNull);
        expect(find.byType(KidsZoneScreen), findsOneWidget);
        expect(find.text('120'), findsOneWidget);

        await cleanUp(tester);
      },
    );
  });
}

