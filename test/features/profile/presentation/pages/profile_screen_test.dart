import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/loading_overlay.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/reward_limit_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/usecases/add_golden_key.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_golden_key.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/features/home/presentation/widgets/vowl_mascot_card.dart';
import 'package:vowl/features/profile/presentation/pages/profile_screen.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_badges_list.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_bento_stats.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_header.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_stickers_progress.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockAdService extends Mock implements AdService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockPurchaseGoldenKey extends Mock implements PurchaseGoldenKey {}

class MockAddGoldenKey extends Mock implements AddGoldenKey {}

class MockRewardLimitService extends Mock implements RewardLimitService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockProfileBloc mockProfileBloc;
  late MockHapticService mockHapticService;
  late MockAdService mockAdService;
  late MockAppLogger mockLogger;
  late MockPurchaseGoldenKey mockPurchaseGoldenKey;
  late MockAddGoldenKey mockAddGoldenKey;
  late MockRewardLimitService mockRewardLimitService;
  late List<String> navigatedRoutes;
  final mockLocaleService = MockLocaleService();

  const testUser = UserEntity(
    id: 'user_profile_123',
    email: 'aria.stark@vowl.app',
    displayName: 'Aria Stark',
    currentStreak: 15,
    totalExp: 2600, // Level 26 -> Scholar
    coins: 520,
    keys: 4,
    claimedLevelMilestones: [5, 10, 25],
    isPremium: false,
    vowlMascot: 'nova',
    vowlEquippedAccessory: 'cyber_wings',
    kidsStickers: ['sticker_star', 'sticker_bear'],
    completedLevels: {'kids_alphabet': [1, 2, 3]},
  );

  setUpAll(() {
    registerFallbackValue(const AuthReloadUser());
    registerFallbackValue(const ProfileUpdateDisplayNameRequested(''));
  });

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({
      'has_seen_vowl_welcome_showcase': true,
      'notifications_enabled': false,
    });
    navigatedRoutes = [];

    mockAuthBloc = MockAuthBloc();
    mockProfileBloc = MockProfileBloc();
    mockHapticService = MockHapticService();
    mockAdService = MockAdService();
    mockLogger = MockAppLogger();
    mockPurchaseGoldenKey = MockPurchaseGoldenKey();
    mockAddGoldenKey = MockAddGoldenKey();
    mockRewardLimitService = MockRewardLimitService();

    when(() => mockAuthBloc.state)
        .thenReturn(AuthState.authenticated(testUser));
    when(() => mockProfileBloc.state).thenReturn(const ProfileState());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);

    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    when(() => mockLocaleService.tr(
          any(),
          args: any(named: 'args'),
          fallback: any(named: 'fallback'),
        )).thenAnswer((invocation) {
      final key = invocation.positionalArguments[0] as String;
      final args = (invocation.namedArguments[#args] as List<String>?) ?? [];
      final fallback = invocation.namedArguments[#fallback] as String?;
      String text = fallback ?? key;
      for (int i = 0; i < args.length; i++) {
        text = text.replaceAll('{$i}', args[i]);
      }
      return text;
    });
    initLocaleServiceReference(mockLocaleService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);

    if (di.sl.isRegistered<AdService>()) {
      di.sl.unregister<AdService>();
    }
    di.sl.registerSingleton<AdService>(mockAdService);

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
    di.sl.registerSingleton<AppLogger>(mockLogger);

    if (di.sl.isRegistered<PurchaseGoldenKey>()) {
      di.sl.unregister<PurchaseGoldenKey>();
    }
    di.sl.registerSingleton<PurchaseGoldenKey>(mockPurchaseGoldenKey);

    if (di.sl.isRegistered<AddGoldenKey>()) {
      di.sl.unregister<AddGoldenKey>();
    }
    di.sl.registerSingleton<AddGoldenKey>(mockAddGoldenKey);

    if (di.sl.isRegistered<RewardLimitService>()) {
      di.sl.unregister<RewardLimitService>();
    }
    di.sl.registerSingleton<RewardLimitService>(mockRewardLimitService);
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    if (di.sl.isRegistered<AdService>()) {
      di.sl.unregister<AdService>();
    }
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
    if (di.sl.isRegistered<PurchaseGoldenKey>()) {
      di.sl.unregister<PurchaseGoldenKey>();
    }
    if (di.sl.isRegistered<AddGoldenKey>()) {
      di.sl.unregister<AddGoldenKey>();
    }
    if (di.sl.isRegistered<RewardLimitService>()) {
      di.sl.unregister<RewardLimitService>();
    }
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Widget createWidgetUnderTest({
    ThemeMode themeMode = ThemeMode.light,
    GoRouter? customRouter,
    ThemeData? customDarkTheme,
  }) {
    final router = customRouter ??
        GoRouter(
          initialLocation: '/profile',
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: AppRouter.progressDashboardRoute,
              builder: (context, state) {
                navigatedRoutes.add(AppRouter.progressDashboardRoute);
                return const Scaffold(body: Text('Progress Dashboard Page'));
              },
            ),
            GoRoute(
              path: AppRouter.reviewMistakesRoute,
              builder: (context, state) {
                navigatedRoutes.add(AppRouter.reviewMistakesRoute);
                return const Scaffold(body: Text('Review Mistakes Page'));
              },
            ),
            GoRoute(
              path: AppRouter.levelRoute,
              builder: (context, state) {
                navigatedRoutes.add(AppRouter.levelRoute);
                return const Scaffold(body: Text('Level Details Page'));
              },
            ),
            GoRoute(
              path: AppRouter.questCoinsRoute,
              builder: (context, state) {
                navigatedRoutes.add(AppRouter.questCoinsRoute);
                return const Scaffold(body: Text('Coins Details Page'));
              },
            ),
            GoRoute(
              path: AppRouter.adventureXPRoute,
              builder: (context, state) {
                navigatedRoutes.add(AppRouter.adventureXPRoute);
                return const Scaffold(body: Text('XP Details Page'));
              },
            ),
            GoRoute(
              path: AppRouter.trophyRoomRoute,
              builder: (context, state) {
                navigatedRoutes.add(AppRouter.trophyRoomRoute);
                return const Scaffold(body: Text('Trophy Room Page'));
              },
            ),
            GoRoute(
              path: '/kids-room',
              builder: (context, state) {
                navigatedRoutes.add('/kids-room');
                return const Scaffold(body: Text('Kids Room Page'));
              },
            ),
            GoRoute(
              path: AppRouter.premiumRoute,
              builder: (context, state) {
                navigatedRoutes.add(AppRouter.premiumRoute);
                return const Scaffold(body: Text('Premium Store Page'));
              },
            ),
            GoRoute(
              path: AppRouter.settingsRoute,
              builder: (context, state) {
                navigatedRoutes.add(AppRouter.settingsRoute);
                return const Scaffold(body: Text('Settings Page'));
              },
            ),
            GoRoute(
              path: AppRouter.streakRoute,
              builder: (context, state) {
                navigatedRoutes.add(AppRouter.streakRoute);
                return const Scaffold(body: Text('Streak Page'));
              },
            ),
            GoRoute(
              path: AppRouter.vowlMascotRoute,
              builder: (context, state) {
                navigatedRoutes.add(AppRouter.vowlMascotRoute);
                return const Scaffold(body: Text('Mascot Nest Page'));
              },
            ),
          ],
        );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MaterialApp.router(
          theme: AppTheme.lightTheme,
          darkTheme: customDarkTheme ?? AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
        ),
      ),
    );
  }

  Future<void> pumpProfileScreen(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
    GoRouter? customRouter,
    ThemeData? customDarkTheme,
  }) async {
    await tester.pumpWidget(createWidgetUnderTest(
      themeMode: themeMode,
      customRouter: customRouter,
      customDarkTheme: customDarkTheme,
    ));
    await tester.pumpAndSettle();
  }

  Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('Group 1: Authentication & Loading States', () {
    testWidgets('renders ProfileShimmerLoading when user is null',
        (tester) async {
      when(() => mockAuthBloc.state)
          .thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(ProfileShimmerLoading), findsOneWidget);
      expect(find.byType(LoadingOverlay), findsOneWidget);
      expect(find.byType(CustomScrollView), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders active LoadingOverlay when auth status is loggingOut',
        (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(testUser).copyWith(status: AuthStatus.loggingOut),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(LoadingOverlay), findsOneWidget);
      final overlay = tester.widget<LoadingOverlay>(find.byType(LoadingOverlay));
      expect(overlay.isLoading, isTrue);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders CustomScrollView and ProfileHeader when authenticated',
        (tester) async {
      await pumpProfileScreen(tester);

      expect(find.byType(ProfileShimmerLoading), findsNothing);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(ProfileHeader), findsOneWidget);
    });
  });

  group('Group 2: SliverAppBar & Hero Header', () {
    testWidgets('renders ProfileHeader with display name, email, and rank title',
        (tester) async {
      await pumpProfileScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('Aria Stark'), findsWidgets);
      expect(find.text('aria.stark@vowl.app'), findsOneWidget);
      // Level 26 -> SCHOLAR
      expect(find.text('SCHOLAR'), findsOneWidget);
    });

    testWidgets('displays immediate photo from ProfileState when present for matching user',
        (tester) async {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          photoUrl: 'https://example.com/fresh_avatar.jpg',
          photoUserId: 'user_profile_123',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 700));

      final header = tester.widget<ProfileHeader>(find.byType(ProfileHeader));
      expect(header.immediatePhotoUrl, 'https://example.com/fresh_avatar.jpg');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('does NOT display immediate photo if photo belongs to another user account',
        (tester) async {
      when(() => mockProfileBloc.state).thenReturn(
        const ProfileState(
          photoUrl: 'https://example.com/other_user_avatar.jpg',
          photoUserId: 'other_user_999',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 700));

      final header = tester.widget<ProfileHeader>(find.byType(ProfileHeader));
      expect(header.immediatePhotoUrl, isNull);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('scrolls down and displays collapsed mini-avatar and title',
        (tester) async {
      await pumpProfileScreen(tester);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
      await tester.pumpAndSettle();

      // In collapsed state, mini title text 'Aria Stark' appears in FlexibleSpaceBar title
      expect(find.text('Aria Stark'), findsWidgets);
    });
  });

  group('Group 3: Edit Name & Photo Bottom Sheets', () {
    testWidgets('tapping edit name opens sheet and submits new display name',
        (tester) async {
      await pumpProfileScreen(tester);

      // Find the name pill button in ProfileHeader
      final nameFinder = find.text('Aria Stark');
      expect(nameFinder, findsWidgets);

      await tester.tap(nameFinder.first);
      await tester.pumpAndSettle();

      expect(find.text('Update Identity'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      await tester.enterText(textFieldFinder, 'Queen Aria');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      verify(() => mockProfileBloc.add(
            const ProfileUpdateDisplayNameRequested('Queen Aria'),
          )).called(1);
    });

    testWidgets('tapping edit photo opens image source bottom sheet',
        (tester) async {
      await pumpProfileScreen(tester);

      final cameraIconFinder = find.byIcon(Icons.camera_alt_rounded);
      expect(cameraIconFinder, findsOneWidget);

      await tester.tap(cameraIconFinder);
      await tester.pumpAndSettle();

      expect(find.text('Avatar Projection'), findsOneWidget);
      expect(find.text('Reality'), findsOneWidget);
      expect(find.text('Memory'), findsOneWidget);
      expect(find.byIcon(Icons.camera_rounded), findsOneWidget);
      expect(find.byIcon(Icons.image_search_rounded), findsOneWidget);
    });
  });

  group('Group 4: Companion / Vowl Mascot Card', () {
    testWidgets('renders VowlMascotCard in profile scroll view',
        (tester) async {
      await pumpProfileScreen(tester);

      expect(find.byType(VowlMascotCard), findsOneWidget);
    });
  });

  group('Group 5: Adventure Stats & Bento Grid', () {
    testWidgets('renders Adventure Stats header and ProfileBentoStats',
        (tester) async {
      await pumpProfileScreen(tester);

      expect(find.text('Adventure Stats'), findsOneWidget);
      expect(find.byType(ProfileBentoStats), findsOneWidget);
      expect(find.text('CURRENT LEVEL'), findsOneWidget);
      expect(find.text('Lvl 27'), findsOneWidget);
      expect(find.text('Vowl Treasury'), findsOneWidget);
      expect(find.text('Daily Streak'), findsOneWidget);
      expect(find.text('ADVENTURE XP'), findsOneWidget);
    });

    testWidgets('tapping current level bento card pushes levelRoute',
        (tester) async {
      await pumpProfileScreen(tester);

      await tester.tap(find.text('CURRENT LEVEL'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains(AppRouter.levelRoute));
      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('tapping treasury bento card pushes coinsRoute',
        (tester) async {
      await pumpProfileScreen(tester);

      await scrollToAndTap(tester, find.text('Vowl Treasury'));

      expect(navigatedRoutes, contains(AppRouter.questCoinsRoute));
      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('tapping daily streak bento card pushes streakRoute',
        (tester) async {
      await pumpProfileScreen(tester);

      await scrollToAndTap(tester, find.text('Daily Streak'));

      expect(navigatedRoutes, contains(AppRouter.streakRoute));
    });

    testWidgets('tapping XP boosted bento card pushes xpRoute',
        (tester) async {
      await pumpProfileScreen(tester);

      await scrollToAndTap(tester, find.text('ADVENTURE XP'));

      expect(navigatedRoutes, contains(AppRouter.adventureXPRoute));
      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
    });
  });

  group('Group 6: Learning Report & Review Mistakes Feature Cards', () {
    testWidgets('renders Learning Report and tapping pushes progressDashboardRoute',
        (tester) async {
      await pumpProfileScreen(tester);

      final reportFinder = find.text('Learning Report');
      expect(reportFinder, findsOneWidget);

      await scrollToAndTap(tester, reportFinder);

      expect(navigatedRoutes, contains(AppRouter.progressDashboardRoute));
      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('renders Review & Master when isKidsModeOnly is false',
        (tester) async {
      await pumpProfileScreen(tester);

      final reviewFinder = find.text('Review & Master');
      expect(reviewFinder, findsOneWidget);

      await scrollToAndTap(tester, reviewFinder);

      expect(navigatedRoutes, contains(AppRouter.reviewMistakesRoute));
      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('omits Review & Master when isKidsModeOnly is true',
        (tester) async {
      final kidsUser = testUser.copyWith(
        totalExp: 0,
        completedLevels: {'kids_alphabet': [1, 2]},
      );
      when(() => mockAuthBloc.state)
          .thenReturn(AuthState.authenticated(kidsUser));

      await pumpProfileScreen(tester);

      expect(find.text('Review & Master'), findsNothing);
    });
  });

  group('Group 7: Golden Keys Shop Banner', () {
    testWidgets('renders Golden Keys banner and user key count',
        (tester) async {
      await pumpProfileScreen(tester);

      expect(find.text('Golden Keys'), findsOneWidget);
      expect(find.text('4'), findsWidgets);
    });

    testWidgets('tapping Golden Keys banner opens KeyShopBottomSheet',
        (tester) async {
      await pumpProfileScreen(tester);

      await scrollToAndTap(tester, find.text('Golden Keys'));

      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
    });
  });

  group('Group 8: Hall of Fame (ProfileBadgesList)', () {
    testWidgets('renders ProfileBadgesList and earned badges',
        (tester) async {
      await pumpProfileScreen(tester);

      expect(find.byType(ProfileBadgesList), findsOneWidget);
    });

    testWidgets('renders empty state message when no badges earned',
        (tester) async {
      final noBadgesUser = testUser.copyWith(claimedLevelMilestones: []);
      when(() => mockAuthBloc.state)
          .thenReturn(AuthState.authenticated(noBadgesUser));

      await pumpProfileScreen(tester);

      expect(find.text('HALL OF FAME VACANT'), findsOneWidget);
      expect(
        find.text('Embark on adventures to unlock legendary badges.'),
        findsOneWidget,
      );
    });
  });

  group('Group 9: Kids Zone (Conditional Rendering)', () {
    testWidgets('renders Kids Zone section when stickers exist',
        (tester) async {
      await pumpProfileScreen(tester);

      expect(find.text('Kids Zone'), findsOneWidget);
      expect(find.text('Kids Room'), findsOneWidget);
      expect(find.byType(ProfileStickersProgress), findsOneWidget);

      await scrollToAndTap(tester, find.text('Kids Room'));

      expect(navigatedRoutes, contains('/kids-room'));
      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('omits Kids Zone section when stickers empty and levels zero',
        (tester) async {
      final adultUser = testUser.copyWith(
        kidsStickers: [],
        completedLevels: {'grammar': [1]},
      );
      when(() => mockAuthBloc.state)
          .thenReturn(AuthState.authenticated(adultUser));

      await pumpProfileScreen(tester);

      expect(find.text('Kids Zone'), findsNothing);
      expect(find.text('Kids Room'), findsNothing);
      expect(find.byType(ProfileStickersProgress), findsNothing);
    });
  });

  group('Group 10: Premium CTA Banner', () {
    testWidgets('renders UPGRADE TO PREMIUM when user is not premium',
        (tester) async {
      final freeUser = testUser.copyWith(isPremium: false);
      when(() => mockAuthBloc.state)
          .thenReturn(AuthState.authenticated(freeUser));

      await pumpProfileScreen(tester);

      final upgradeFinder = find.text('UPGRADE TO PREMIUM');
      expect(upgradeFinder, findsOneWidget);

      await scrollToAndTap(tester, upgradeFinder);

      expect(navigatedRoutes, contains(AppRouter.premiumRoute));
      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('renders Premium Active when user is premium',
        (tester) async {
      final premUser = testUser.copyWith(isPremium: true);
      when(() => mockAuthBloc.state)
          .thenReturn(AuthState.authenticated(premUser));

      await pumpProfileScreen(tester);

      final activeFinder = find.text('Premium Active');
      expect(activeFinder, findsOneWidget);

      await scrollToAndTap(tester, activeFinder);

      expect(navigatedRoutes, contains(AppRouter.premiumRoute));
      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
    });
  });

  group('Group 11: Preferences & Sign Out', () {
    testWidgets('renders Settings tile in preferences and tapping routes to settings',
        (tester) async {
      await pumpProfileScreen(tester);

      final settingsTile = find.text('Settings');
      expect(settingsTile, findsOneWidget);

      await scrollToAndTap(tester, settingsTile);

      expect(navigatedRoutes, contains(AppRouter.settingsRoute));
      verify(() => mockHapticService.light()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('tapping SIGN OUT ACCOUNT displays confirmation dialog',
        (tester) async {
      await pumpProfileScreen(tester);

      final signOutBtn = find.text('SIGN OUT ACCOUNT');
      expect(signOutBtn, findsOneWidget);

      await scrollToAndTap(tester, signOutBtn);

      expect(find.text('Sign Out?'), findsOneWidget);
      verify(() => mockHapticService.warning()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('confirming sign out dialog dispatches AuthLogoutRequested',
        (tester) async {
      await pumpProfileScreen(tester);

      final signOutBtn = find.text('SIGN OUT ACCOUNT');
      await scrollToAndTap(tester, signOutBtn);

      expect(find.text('Sign Out?'), findsOneWidget);

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      verify(() => mockAuthBloc.add(const AuthLogoutRequested())).called(1);
    });
  });

  group('Group 12: Pull-to-Refresh', () {
    testWidgets('pull-to-refresh dispatches AuthReloadUser', (tester) async {
      await pumpProfileScreen(tester);

      tester
          .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
          .show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      verify(() => mockAuthBloc.add(const AuthReloadUser())).called(1);
    });
  });

  group('Group 13: Responsive Viewports, Accessibility & Themes', () {
    testWidgets('renders cleanly on compact mobile (320x568) without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 568 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ProfileScreen), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('renders cleanly on tablet viewport (800x1280) without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(800 * 1.5, 1280 * 1.5);
      tester.view.devicePixelRatio = 1.5;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ProfileScreen), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('renders cleanly with 1.3x accessibility text scale',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ProfileScreen), findsOneWidget);

      addTearDown(() {
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('renders cleanly in Midnight theme mode (black scaffold background)',
        (tester) async {
      final midnightTheme = AppTheme.darkTheme.copyWith(
        scaffoldBackgroundColor: Colors.black,
      );

      await tester.pumpWidget(createWidgetUnderTest(
        themeMode: ThemeMode.dark,
        customDarkTheme: midnightTheme,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });
}

