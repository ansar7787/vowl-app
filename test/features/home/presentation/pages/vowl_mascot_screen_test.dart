import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/features/home/presentation/pages/vowl_mascot_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class MockLocaleService extends Mock implements LocaleService {}

class MockHapticService extends Mock implements HapticService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockProfileBloc mockProfileBloc;
  late MockLocaleService mockLocaleService;
  late MockHapticService mockHapticService;
  late List<String> navigatedRoutes;

  final testUser = UserEntity(
    id: 'user_vowl_mascot_test',
    email: 'phoenix@vowl.app',
    displayName: 'Phoenix Learner',
    coins: 15000,
    vowlMascot: 'vowl_prime',
    vowlOwnedMascots: const [
      'vowl_prime',
      'silver_wing',
      'crystal_swan',
      'neon_parrot',
    ],
    vowlEquippedAccessory: null,
    vowlOwnedAccessories: const ['scholar_cap'],
  );

  final testUserWithAccessory = testUser.copyWith(
    vowlEquippedAccessory: 'scholar_cap',
  );

  setUpAll(() {
    registerFallbackValue(const ProfileClearPurchaseFeedback());
    registerFallbackValue(
      const ProfileUpdateVowlMascotRequested('vowl_prime'),
    );
    registerFallbackValue(
      const ProfileBuyVowlMascotRequested('night_bat', 5000),
    );
    registerFallbackValue(
      const ProfileEquipVowlAccessoryRequested(null),
    );
    registerFallbackValue(
      const ProfileBuyVowlAccessoryRequested('scholar_cap', 1500),
    );

    mockLocaleService = MockLocaleService();
    try {
      initLocaleServiceReference(mockLocaleService);
    } catch (_) {}
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    VowlMotion.lowAnimationModeOverride.value = true;
    navigatedRoutes = [];
    reset(mockLocaleService);

    mockAuthBloc = MockAuthBloc();
    mockProfileBloc = MockProfileBloc();
    mockHapticService = MockHapticService();

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);

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
    when(() => mockProfileBloc.state).thenReturn(
      const ProfileState(),
    );
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
  });

  Widget createWidgetUnderTest({
    ThemeData? theme,
    List<RouteBase>? extraRoutes,
    String initialLocation = '/mascot',
    GoRouter? routerConfig,
    double textScaleFactor = 1.0,
  }) {
    final router = routerConfig ??
        GoRouter(
          initialLocation: initialLocation,
          routes: [
            GoRoute(
              path: '/mascot',
              builder: (context, state) => MultiBlocProvider(
                providers: [
                  BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                  BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
                ],
                child: const VowlMascotScreen(),
              ),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) {
                navigatedRoutes.add('/home');
                return const Scaffold(body: Text('Home Screen'));
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
          builder: (context, routerChild) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScaleFactor),
              ),
              child: routerChild!,
            );
          },
          theme: theme ??
              ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                fontFamily: 'Outfit',
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFFF97316),
                  surface: Colors.white,
                ),
              ),
        );
      },
    );
  }

  Future<void> pumpMascotScreen(
    WidgetTester tester, {
    ThemeData? theme,
    Size physicalSize = const Size(600, 1600),
    double textScaleFactor = 1.0,
    GoRouter? routerConfig,
  }) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createWidgetUnderTest(
        theme: theme,
        textScaleFactor: textScaleFactor,
        routerConfig: routerConfig,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  // ===========================================================================
  // GROUP 1: AUTHENTICATION & LOADING STATES
  // ===========================================================================
  group('Group 1: Authentication & Loading States', () {
    testWidgets('renders HomeShimmerLoading when user is unauthenticated (null)', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(
        const AuthState.unauthenticated(),
      );

      await pumpMascotScreen(tester);

      expect(find.byType(HomeShimmerLoading), findsOneWidget);
      expect(find.byType(CustomScrollView), findsNothing);
    });

    testWidgets('renders CustomScrollView and full screen when authenticated', (
      tester,
    ) async {
      await pumpMascotScreen(tester);

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(HomeShimmerLoading), findsNothing);
      expect(find.text('VOWL NEST'), findsOneWidget);
    });
  });

  // ===========================================================================
  // GROUP 2: FLOATING SLIVER APPBAR, TITLE & COINS DISPLAY
  // ===========================================================================
  group('Group 2: Floating Sliver AppBar, Title & Coins Display', () {
    testWidgets('renders VOWL NEST title, subtitle, back button, and coins', (
      tester,
    ) async {
      await pumpMascotScreen(tester);

      expect(find.text('VOWL NEST'), findsOneWidget);
      expect(find.text('Manage your companion'), findsOneWidget);
      expect(find.text('15,000'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('tapping back button navigates to /home when canPop is false', (
      tester,
    ) async {
      await pumpMascotScreen(tester);

      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(navigatedRoutes, contains(AppRouter.homeRoute));
    });

    testWidgets('tapping back button pops router when canPop is true', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/initial',
        routes: [
          GoRoute(
            path: '/initial',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => context.push('/mascot'),
                child: const Text('Go to Mascot'),
              ),
            ),
          ),
          GoRoute(
            path: '/mascot',
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
              ],
              child: const VowlMascotScreen(),
            ),
          ),
        ],
      );

      await pumpMascotScreen(tester, routerConfig: router);

      expect(find.text('Go to Mascot'), findsOneWidget);
      await tester.tap(find.text('Go to Mascot'));
      await tester.pumpAndSettle();

      expect(find.text('VOWL NEST'), findsOneWidget);

      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Go to Mascot'), findsOneWidget);
      expect(find.text('VOWL NEST'), findsNothing);
    });

    testWidgets('formats coin balance with decimal thousand separators', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(testUser.copyWith(coins: 1234567)),
      );

      await pumpMascotScreen(tester);

      expect(find.text('1,234,567'), findsOneWidget);
    });
  });

  // ===========================================================================
  // GROUP 3: TAB SWITCHER (COMPANION VS BOUTIQUE)
  // ===========================================================================
  group('Group 3: Tab Switcher (COMPANION vs BOUTIQUE)', () {
    testWidgets('renders COMPANION and BOUTIQUE tabs with COMPANION active by default', (
      tester,
    ) async {
      await pumpMascotScreen(tester);

      expect(find.text('COMPANION'), findsOneWidget);
      expect(find.text('BOUTIQUE'), findsOneWidget);
      expect(find.text('SYNCHRONIZED ELITES'), findsOneWidget);
      expect(find.text('CYBERNETIC AUGMENTS'), findsNothing);
    });

    testWidgets('tapping BOUTIQUE switches view and plays selection haptic', (
      tester,
    ) async {
      await pumpMascotScreen(tester);

      await tester.tap(find.text('BOUTIQUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.selection()).called(1);
      expect(find.text('CYBERNETIC AUGMENTS'), findsOneWidget);
      expect(find.text('SYNCHRONIZED ELITES'), findsNothing);
    });

    testWidgets('tapping COMPANION switches view back to companion grid', (
      tester,
    ) async {
      await pumpMascotScreen(tester);

      await tester.tap(find.text('BOUTIQUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CYBERNETIC AUGMENTS'), findsOneWidget);

      await tester.tap(find.text('COMPANION'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.selection()).called(2);
      expect(find.text('SYNCHRONIZED ELITES'), findsOneWidget);
      expect(find.text('CYBERNETIC AUGMENTS'), findsNothing);
    });
  });

  // ===========================================================================
  // GROUP 4: COMPANION TAB — MASCOT SELECTION & EQUIPPING
  // ===========================================================================
  group('Group 4: Companion Tab — Mascot Selection & Equipping', () {
    testWidgets('renders mascots with names, emojis, and equipped indicator', (
      tester,
    ) async {
      await pumpMascotScreen(tester);

      expect(find.text('VOWL PRIME'), findsWidgets);
      expect(find.text('SILVER WING'), findsOneWidget);
      expect(find.text('CRYSTAL SWAN'), findsOneWidget);
      expect(find.text('NEON PARROT'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('tapping owned unequipped mascot dispatches ProfileUpdateVowlMascotRequested', (
      tester,
    ) async {
      await pumpMascotScreen(tester);

      await tester.tap(find.text('SILVER WING'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      verify(() => mockHapticService.light()).called(1);
      verify(
        () => mockProfileBloc.add(
          const ProfileUpdateVowlMascotRequested('silver_wing'),
        ),
      ).called(1);
    });

    testWidgets('tapping affordable unowned mascot dispatches ProfileBuyVowlMascotRequested', (
      tester,
    ) async {
      await pumpMascotScreen(tester);

      await tester.ensureVisible(find.text('NIGHT ORACLE BAT'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('NIGHT ORACLE BAT'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      verify(() => mockHapticService.light()).called(1);
      verify(
        () => mockProfileBloc.add(
          const ProfileBuyVowlMascotRequested('night_bat', 5000),
        ),
      ).called(1);
    });

    testWidgets('tapping unaffordable unowned mascot triggers error haptic and snackbar', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(testUser.copyWith(coins: 0)),
      );

      await pumpMascotScreen(tester);

      await tester.ensureVisible(find.text('NIGHT ORACLE BAT'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('NIGHT ORACLE BAT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.error()).called(1);
      verifyNever(
        () => mockProfileBloc.add(
          any(that: isA<ProfileBuyVowlMascotRequested>()),
        ),
      );
      expect(
        find.text('Insufficient Elite credits for this augment'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('renders Elite Neural Link section with equipped mascot details', (
      tester,
    ) async {
      await pumpMascotScreen(tester);

      await tester.scrollUntilVisible(
        find.text('ELITE NEURAL LINK'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('ELITE NEURAL LINK'), findsOneWidget);
      expect(find.text('ELITE INTERFACE:'), findsOneWidget);
      expect(find.text('NO AUGMENTATIONS'), findsOneWidget);
    });

    testWidgets('renders equipped accessory in Elite Neural Link when present', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(testUserWithAccessory),
      );

      await pumpMascotScreen(tester);

      await tester.scrollUntilVisible(
        find.text('ELITE NEURAL LINK'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('ELITE NEURAL LINK'), findsOneWidget);
      expect(find.text("Scholar's Cap"), findsOneWidget);
    });
  });

  // ===========================================================================
  // GROUP 5: BOUTIQUE TAB — CYBERNETIC AUGMENTS & ACCESSORY EQUIPPING
  // ===========================================================================
  group('Group 5: Boutique Tab — Cybernetic Augments & Accessory Equipping', () {
    testWidgets('displays cybernetic augments in boutique tab', (
      tester,
    ) async {
      await pumpMascotScreen(tester);

      await tester.tap(find.text('BOUTIQUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("SCHOLAR'S CAP"), findsOneWidget);
      expect(find.text('CRIMSON SCARF'), findsOneWidget);
      expect(find.text('CYBER VISOR'), findsOneWidget);
    });

    testWidgets('owned unequipped accessory displays LINK and dispatches ProfileEquipVowlAccessoryRequested', (
      tester,
    ) async {
      await pumpMascotScreen(tester);

      await tester.tap(find.text('BOUTIQUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final linkButton = find.text('LINK');
      expect(linkButton, findsOneWidget);

      await tester.tap(linkButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
      verify(
        () => mockProfileBloc.add(
          const ProfileEquipVowlAccessoryRequested('scholar_cap'),
        ),
      ).called(1);
    });

    testWidgets('equipped accessory displays DISCONNECT and dispatches null equip', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(testUserWithAccessory),
      );

      await pumpMascotScreen(tester);

      await tester.tap(find.text('BOUTIQUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final disconnectButton = find.text('DISCONNECT');
      expect(disconnectButton, findsOneWidget);

      await tester.tap(disconnectButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
      verify(
        () => mockProfileBloc.add(
          const ProfileEquipVowlAccessoryRequested(null),
        ),
      ).called(1);
    });

    testWidgets('affordable unowned accessory displays price and dispatches buy event', (
      tester,
    ) async {
      await pumpMascotScreen(tester);

      await tester.tap(find.text('BOUTIQUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final priceButton = find.text('2,500');
      expect(priceButton, findsOneWidget);

      await tester.tap(priceButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
      verify(
        () => mockProfileBloc.add(
          const ProfileBuyVowlAccessoryRequested('red_scarf', 2500),
        ),
      ).called(1);
    });

    testWidgets('unaffordable unowned accessory displays error snackbar when tapped', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(testUser.copyWith(coins: 0)),
      );

      await pumpMascotScreen(tester);

      await tester.tap(find.text('BOUTIQUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final unaffordableButton = find.text('2,500');
      expect(unaffordableButton, findsOneWidget);

      await tester.tap(unaffordableButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.error()).called(1);
      verifyNever(
        () => mockProfileBloc.add(
          any(that: isA<ProfileBuyVowlAccessoryRequested>()),
        ),
      );
      expect(
        find.text('Insufficient Elite credits for this augment'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 4));
    });
  });

  // ===========================================================================
  // GROUP 6: PURCHASE FEEDBACK & MULTIBLOCLISTENER NOTIFICATIONS
  // ===========================================================================
  group('Group 6: Purchase Feedback & MultiBlocListener State Notifications', () {
    testWidgets('displays success SnackBar when mascot purchase succeeds', (
      tester,
    ) async {
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([
          const ProfileState(
            lastPurchaseType: 'vowl_mascot',
            lastPurchaseSuccess: true,
          ),
        ]),
        initialState: const ProfileState(),
      );

      await pumpMascotScreen(tester);

      expect(find.text('Mascot Linked!'), findsOneWidget);
      verify(() => mockHapticService.success()).called(1);
      verify(
        () => mockProfileBloc.add(const ProfileClearPurchaseFeedback()),
      ).called(1);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('displays success SnackBar when accessory augment succeeds', (
      tester,
    ) async {
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([
          const ProfileState(
            lastPurchaseType: 'vowl_accessory',
            lastPurchaseSuccess: true,
          ),
        ]),
        initialState: const ProfileState(),
      );

      await pumpMascotScreen(tester);

      expect(find.text('Augment Integrated!'), findsOneWidget);
      verify(() => mockHapticService.success()).called(1);
      verify(
        () => mockProfileBloc.add(const ProfileClearPurchaseFeedback()),
      ).called(1);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('displays error SnackBar when mascot sync fails', (
      tester,
    ) async {
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([
          const ProfileState(
            lastPurchaseType: 'vowl_mascot',
            lastPurchaseSuccess: false,
            message: 'Sync Failed',
          ),
        ]),
        initialState: const ProfileState(),
      );

      await pumpMascotScreen(tester);

      expect(find.text('Sync Failed'), findsOneWidget);
      verify(() => mockHapticService.error()).called(1);
      verify(
        () => mockProfileBloc.add(const ProfileClearPurchaseFeedback()),
      ).called(1);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('safety timeout clears processing spinner after 3 seconds', (
      tester,
    ) async {
      await pumpMascotScreen(tester);

      await tester.tap(find.text('SILVER WING'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  // ===========================================================================
  // GROUP 7: STATUS OVERLAY & ACCESSIBILITY SEMANTICS
  // ===========================================================================
  group('Group 7: Status Overlay & Accessibility Semantics', () {
    testWidgets('renders elite status bar overlay with Status OK and security icon', (
      tester,
    ) async {
      await pumpMascotScreen(tester);

      expect(find.byIcon(Icons.security_rounded), findsOneWidget);
      expect(find.text('Status OK'), findsOneWidget);
    });

    testWidgets('provides accessible semantics for back button, tabs, and headers', (
      tester,
    ) async {
      await pumpMascotScreen(tester);

      final backSemantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Back',
      );
      expect(backSemantics, findsOneWidget);

      final companionSemantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'COMPANION',
      );
      expect(companionSemantics, findsOneWidget);

      final boutiqueSemantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'BOUTIQUE',
      );
      expect(boutiqueSemantics, findsOneWidget);

      final headerFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.header == true,
      );
      expect(headerFinder, findsWidgets);
    });
  });

  // ===========================================================================
  // GROUP 8: RESPONSIVE VIEWPORTS & THEMES
  // ===========================================================================
  group('Group 8: Responsive Viewports & Themes', () {
    testWidgets('renders cleanly on compact mobile screen (320x568)', (
      tester,
    ) async {
      await pumpMascotScreen(tester, physicalSize: const Size(320, 568));

      expect(find.text('VOWL NEST'), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('uses 3 columns in grid on tablet screen (>600 width)', (
      tester,
    ) async {
      await pumpMascotScreen(tester, physicalSize: const Size(800, 1280));

      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      final gridView = tester.widget<GridView>(gridFinder);
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
    });

    testWidgets('renders correctly under Midnight theme (black background)', (
      tester,
    ) async {
      final midnightTheme = ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Outfit',
      );

      await pumpMascotScreen(tester, theme: midnightTheme);

      expect(find.text('VOWL NEST'), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF020617));
    });

    testWidgets('handles 1.3x text scaling without layout errors', (
      tester,
    ) async {
      await pumpMascotScreen(tester, textScaleFactor: 1.3);

      expect(find.text('VOWL NEST'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

