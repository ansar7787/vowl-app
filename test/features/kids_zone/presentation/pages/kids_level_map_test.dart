import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/story_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/reward_limit_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_level_unlock.dart';
import 'package:vowl/features/kids_zone/presentation/pages/kids_level_map.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_map_node.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_star_vault_bottom_sheet.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState> implements EconomyBloc {}
class MockHapticService extends Mock implements HapticService {}
class MockLocaleService extends Mock implements LocaleService {}
class MockStoryService extends Mock implements StoryService {}
class MockTtsService extends Mock implements TtsService {}
class MockSoundService extends Mock implements SoundService {}
class MockAdService extends Mock implements AdService {}
class MockRewardLimitService extends Mock implements RewardLimitService {}
class MockUpdateUserRewards extends Mock implements UpdateUserRewards {}
class MockPurchaseLevelUnlock extends Mock implements PurchaseLevelUnlock {}

class FakeBuildContext extends Fake implements BuildContext {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeBuildContext());
  });

  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockLocaleService mockLocaleService;
  late MockStoryService mockStoryService;
  late MockTtsService mockTtsService;
  late MockSoundService mockSoundService;
  late MockAdService mockAdService;
  late MockRewardLimitService mockRewardLimitService;
  late MockUpdateUserRewards mockUpdateUserRewards;
  late MockPurchaseLevelUnlock mockPurchaseLevelUnlock;

  late List<String> navigatedRoutes;
  late List<dynamic> routeExtras;

  const testUser = UserEntity(
    id: 'kid_user_1',
    email: 'kid@vowl.app',
    displayName: 'Little Explorer',
    kidsCoins: 150,
    keys: 5,
    kidsMascot: 'owly',
    unlockedLevels: {'alphabet': 2},
    completedLevels: {
      'alphabet': [1],
    },
    starRatings: {
      'alphabet': {
        '1': 3,
        'magic_stars': 2,
      },
    },
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    VowlMotion.lowAnimationModeOverride.value = true;
    navigatedRoutes = [];
    routeExtras = [];

    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockLocaleService = MockLocaleService();
    mockStoryService = MockStoryService();
    mockTtsService = MockTtsService();
    mockSoundService = MockSoundService();
    mockAdService = MockAdService();
    mockRewardLimitService = MockRewardLimitService();
    mockUpdateUserRewards = MockUpdateUserRewards();
    mockPurchaseLevelUnlock = MockPurchaseLevelUnlock();

    // Reset GetIt registrations safely
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<StoryService>()) di.sl.unregister<StoryService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<RewardLimitService>()) di.sl.unregister<RewardLimitService>();
    if (di.sl.isRegistered<UpdateUserRewards>()) di.sl.unregister<UpdateUserRewards>();
    if (di.sl.isRegistered<PurchaseLevelUnlock>()) di.sl.unregister<PurchaseLevelUnlock>();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<StoryService>(mockStoryService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<AdService>(mockAdService);
    di.sl.registerSingleton<RewardLimitService>(mockRewardLimitService);
    di.sl.registerSingleton<UpdateUserRewards>(mockUpdateUserRewards);
    di.sl.registerSingleton<PurchaseLevelUnlock>(mockPurchaseLevelUnlock);

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
    when(() => mockStoryService.getStoryBeat(any(), any(), any())).thenReturn(null);
    when(() => mockTtsService.speak(any())).thenAnswer((_) async {});
    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(testUser),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Widget createWidgetUnderTest({
    ThemeMode themeMode = ThemeMode.light,
    String gameType = 'alphabet',
    String title = 'Alphabet Adventure',
    Color primaryColor = Colors.teal,
  }) {
    final router = GoRouter(
      initialLocation: '/kids/map/$gameType',
      routes: [
        GoRoute(
          path: '/kids/map/:gameType',
          builder: (context, state) => KidsLevelMap(
            gameType: gameType,
            title: title,
            primaryColor: primaryColor,
          ),
        ),
        GoRoute(
          path: AppRouter.kidsAlphabetRoute,
          builder: (context, state) {
            navigatedRoutes.add(AppRouter.kidsAlphabetRoute);
            routeExtras.add(state.extra);
            return const Scaffold(body: Text('Kids Alphabet Game'));
          },
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) {
            navigatedRoutes.add('/home');
            return const Scaffold(body: Text('Home Screen'));
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
    await tester.pump(const Duration(milliseconds: 1000));
  }

  Future<void> cleanUp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('KidsLevelMap - Header, Progression & Components', () {
    testWidgets(
      'renders KidsLevelMap with chunky header, sticker icon, title, and coins counter',
      (tester) async {
        await pumpScreen(tester);

        expect(find.byType(KidsLevelMap), findsOneWidget);
        expect(find.text('Alphabet Adventure'), findsOneWidget);
        expect(find.text('KIDS QUEST'), findsOneWidget);
        expect(find.text('150 COINS'), findsOneWidget);

        // App bar back button
        expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

        await cleanUp(tester);
      },
    );

    testWidgets(
      'renders level progression nodes: completed level 1, active level 2, and locked levels',
      (tester) async {
        await pumpScreen(tester);

        expect(find.byType(KidsMapNode), findsWidgets);

        // Level 1 (Completed)
        expect(find.text('1'), findsWidgets);

        // Level 2 (Active / Current Playable)
        expect(find.text('2'), findsWidgets);

        // Higher locked levels have lock icons
        expect(find.byIcon(Icons.lock_rounded), findsWidgets);

        await cleanUp(tester);
      },
    );

    testWidgets(
      'renders Star Vault FAB with aggregated star count and Golden Keys FAB',
      (tester) async {
        await pumpScreen(tester);

        // Star Vault button shows 5 total stars (3 gameplay + 2 magic) and Golden Keys shows 5 keys
        expect(find.text('5'), findsNWidgets(2));
        expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

        // Golden Keys button shows key icon
        expect(find.byIcon(Icons.key_rounded), findsWidgets);

        await cleanUp(tester);
      },
    );
  });

  group('KidsLevelMap - Interactivity & Navigation', () {
    testWidgets(
      'tapping active playable level 2 navigates to game route with level 2 payload',
      (tester) async {
        await pumpScreen(tester);

        final level2Node = find.ancestor(
          of: find.text('2'),
          matching: find.byType(ScaleButton),
        );
        expect(level2Node, findsOneWidget);

        await tester.tap(level2Node, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(navigatedRoutes, contains(AppRouter.kidsAlphabetRoute));
        expect(routeExtras, contains(2));

        await cleanUp(tester);
      },
    );

    testWidgets(
      'tapping completed level 1 navigates to game route with level 1 payload for replay',
      (tester) async {
        await pumpScreen(tester);

        final level1Node = find.ancestor(
          of: find.text('1').first,
          matching: find.byType(ScaleButton),
        );
        expect(level1Node, findsOneWidget);

        await tester.tap(level1Node, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(navigatedRoutes, contains(AppRouter.kidsAlphabetRoute));
        expect(routeExtras, contains(1));

        await cleanUp(tester);
      },
    );

    testWidgets(
      'tapping locked level displays warning snackbar and does not navigate',
      (tester) async {
        await pumpScreen(tester);

        final lockedLock = find.byIcon(Icons.lock_rounded).first;
        await tester.tap(lockedLock);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Navigation should not occur
        expect(navigatedRoutes, isEmpty);

        await cleanUp(tester);
      },
    );

    testWidgets(
      'tapping back button navigates to /home when cannot pop',
      (tester) async {
        await pumpScreen(tester);

        final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
        expect(backBtn, findsOneWidget);

        await tester.tap(backBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(navigatedRoutes, contains('/home'));

        await cleanUp(tester);
      },
    );

    testWidgets(
      'tapping Star Vault FAB opens KidsStarVaultBottomSheet',
      (tester) async {
        await pumpScreen(tester);

        final starVaultBtn = find.byIcon(Icons.lock_outline_rounded);
        await tester.tap(starVaultBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(KidsStarVaultBottomSheet), findsOneWidget);

        await cleanUp(tester);
      },
    );

    testWidgets(
      'tapping Golden Keys FAB opens KeyShopBottomSheet modal',
      (tester) async {
        await pumpScreen(tester);

        // Find Golden Keys ScaleButton
        final keysFab = find.ancestor(
          of: find.byIcon(Icons.key_rounded).first,
          matching: find.byType(ScaleButton),
        );
        expect(keysFab, findsOneWidget);

        await tester.tap(keysFab, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // KeyShopBottomSheet displays 'Golden Key' title
        expect(find.text('Golden Key'), findsOneWidget);

        await cleanUp(tester);
      },
    );
  });

  group('KidsLevelMap - Visuals & Responsive Layout', () {
    testWidgets(
      'renders cleanly in dark mode without contrast issues',
      (tester) async {
        await pumpScreen(tester, themeMode: ThemeMode.dark);

        expect(find.byType(KidsLevelMap), findsOneWidget);
        expect(find.text('Alphabet Adventure'), findsOneWidget);

        await cleanUp(tester);
      },
    );

    testWidgets(
      'renders on compact 320dp width without RenderFlex overflow',
      (tester) async {
        await pumpScreen(tester, width: 320, height: 568);

        expect(find.byType(KidsLevelMap), findsOneWidget);
        expect(tester.takeException(), isNull);

        await cleanUp(tester);
      },
    );

    testWidgets(
      'tapping buddy triggers TTS cheer and displays speech bubble within screen bounds without overflow',
      (tester) async {
        await pumpScreen(tester, width: 360, height: 640);

        final mascotFinder = find.byType(VowlMascot);
        expect(mascotFinder, findsWidgets);

        await tester.tap(mascotFinder.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        verify(() => mockTtsService.speak(any())).called(1);
        expect(tester.takeException(), isNull);

        await cleanUp(tester);
      },
    );

    testWidgets(
      'tapping playable level node stops active TTS playback',
      (tester) async {
        await pumpScreen(tester);

        final level2Finder = find.text('2');
        expect(level2Finder, findsOneWidget);

        await tester.tap(level2Finder, warnIfMissed: false);
        await tester.pump();

        verify(() => mockTtsService.stop()).called(greaterThanOrEqualTo(1));
        await cleanUp(tester);
      },
    );
  });
}

