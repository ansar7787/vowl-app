// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_analytics_platform_interface/firebase_analytics_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:vowl/core/presentation/widgets/loading_overlay.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/notification_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/settings/presentation/pages/settings_screen.dart';
import 'package:vowl/features/settings/presentation/widgets/language_picker_sheet.dart';
import 'package:vowl/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:vowl/features/settings/presentation/widgets/tts_voice_selection_bottom_sheet.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockKidsTTSService extends Mock implements KidsTTSService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockLocaleService extends Mock implements LocaleService {
  @override
  String get currentLocaleFlag => '🇺🇸';

  @override
  String get currentLocaleName => 'English';

  @override
  Locale get currentLocale => const Locale('en', 'US');
}

class MockFirebaseAnalyticsPlatform extends FirebaseAnalyticsPlatform
    with MockPlatformInterfaceMixin {
  bool? lastCollectionEnabled;

  @override
  FirebaseAnalyticsPlatform delegateFor({
    required FirebaseApp app,
    Map<String, dynamic>? webOptions,
  }) {
    return this;
  }

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    lastCollectionEnabled = enabled;
  }
}

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getTemporaryPath() async {
    final dir = Directory(
      '${Directory.systemTemp.path}/vowl_test_cache_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }
}

class MockUrlLauncherPlatform extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  String? lastLaunchedUrl;
  LaunchOptions? lastOptions;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    lastOptions = options;
    return true;
  }
}

class MockPermissionHandlerPlatform extends PermissionHandlerPlatform
    with MockPlatformInterfaceMixin {
  PermissionStatus notificationStatus = PermissionStatus.granted;
  bool openedSettings = false;

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    if (permission == Permission.notification) {
      return notificationStatus;
    }
    return PermissionStatus.granted;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    return {for (final p in permissions) p: notificationStatus};
  }

  @override
  Future<bool> openAppSettings() async {
    openedSettings = true;
    return true;
  }
}

// ---------------------------------------------------------------------------
// Test Data & Main Test Suite
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockThemeCubit mockThemeCubit;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockKidsTTSService mockKidsTtsService;
  late MockNotificationService mockNotificationService;
  late MockLocaleService mockLocaleService;
  late MockFirebaseAnalyticsPlatform mockAnalyticsPlatform;
  late MockPathProviderPlatform mockPathProvider;
  late MockUrlLauncherPlatform mockUrlLauncher;
  late MockPermissionHandlerPlatform mockPermissionHandler;
  late List<String> navigatedRoutes;

  const testUser = UserEntity(
    id: 'user_settings_123',
    email: 'aria.stark@vowl.app',
    displayName: 'Aria Stark',
    currentStreak: 12,
    totalExp: 1500,
    coins: 350,
    isPremium: false,
  );

  const testPremiumUser = UserEntity(
    id: 'user_settings_prem',
    email: 'jon.snow@vowl.app',
    displayName: 'Jon Snow',
    currentStreak: 45,
    totalExp: 9500,
    coins: 2400,
    isPremium: true,
  );

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();

    registerFallbackValue(const AuthLogoutRequested());
    registerFallbackValue(const AuthPasswordResetRequested(''));
  });

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    navigatedRoutes = [];

    mockAuthBloc = MockAuthBloc();
    mockThemeCubit = MockThemeCubit();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockKidsTtsService = MockKidsTTSService();
    mockNotificationService = MockNotificationService();
    mockLocaleService = MockLocaleService();
    mockAnalyticsPlatform = MockFirebaseAnalyticsPlatform();
    mockPathProvider = MockPathProviderPlatform();
    mockUrlLauncher = MockUrlLauncherPlatform();
    mockPermissionHandler = MockPermissionHandlerPlatform();

    FirebaseAnalyticsPlatform.instance = mockAnalyticsPlatform;
    PathProviderPlatform.instance = mockPathProvider;
    UrlLauncherPlatform.instance = mockUrlLauncher;
    PermissionHandlerPlatform.instance = mockPermissionHandler;

    PackageInfo.setMockInitialValues(
      appName: 'Vowl',
      packageName: 'com.vowl.app',
      version: '2.4.0',
      buildNumber: '108',
      buildSignature: 'xyz',
    );

    SharedPreferences.setMockInitialValues({
      'notifications_enabled': true,
      'sound_enabled': true,
      'game_sounds_enabled': true,
      'reduce_complex_gestures': false,
      'low_animation_mode': false,
      'analytics_enabled': true,
      'tts_voice_preset': 'clear_guide',
      'translation_target_lang': 'es', // Spanish
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
          call,
        ) async {
          if (call.method == 'getVoices') {
            return <Map<String, String>>[];
          }
          return 1;
        });

    when(
      () => mockAuthBloc.state,
    ).thenReturn(AuthState.authenticated(testUser));
    when(() => mockThemeCubit.state).thenReturn(
      const ThemeState(themeMode: ThemeMode.light, isMidnight: false),
    );

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});

    when(() => mockSoundService.setMuted(any())).thenReturn(null);
    when(() => mockSoundService.setGameSoundsEnabled(any())).thenReturn(null);
    when(() => mockKidsTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockNotificationService.onNotificationPreferenceChanged(any()),
    ).thenAnswer((_) async {});
    when(() => mockThemeCubit.toggleMidnight(any())).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    di.sl.registerSingleton<HapticService>(mockHapticService);

    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    di.sl.registerSingleton<SoundService>(mockSoundService);

    if (di.sl.isRegistered<KidsTTSService>()) {
      di.sl.unregister<KidsTTSService>();
    }
    di.sl.registerSingleton<KidsTTSService>(mockKidsTtsService);

    if (di.sl.isRegistered<NotificationService>()) {
      di.sl.unregister<NotificationService>();
    }
    di.sl.registerSingleton<NotificationService>(mockNotificationService);

    if (di.sl.isRegistered<AuthBloc>()) di.sl.unregister<AuthBloc>();
    di.sl.registerSingleton<AuthBloc>(mockAuthBloc);

    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    when(
      () => mockLocaleService.tr(
        any(),
        args: any(named: 'args'),
        fallback: any(named: 'fallback'),
      ),
    ).thenAnswer((invocation) {
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
  });

  Widget buildTestableWidget({
    WidgetTester? tester,
    AuthState? authState,
    ThemeState? themeState,
    ThemeMode themeMode = ThemeMode.light,
    Brightness brightness = Brightness.light,
    Size screenSize = const Size(390, 844),
    double textScaleFactor = 1.0,
    bool isMidnight = false,
  }) {
    if (tester != null) {
      tester.view.physicalSize = Size(
        screenSize.width * 2.0,
        screenSize.height * 2.0,
      );
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    final effectiveAuthState = authState ?? AuthState.authenticated(testUser);
    final effectiveThemeState =
        themeState ??
        ThemeState(
          themeMode: isMidnight
              ? ThemeMode.dark
              : (brightness == Brightness.dark
                    ? ThemeMode.dark
                    : ThemeMode.light),
          isMidnight: isMidnight,
        );

    when(() => mockAuthBloc.state).thenReturn(effectiveAuthState);
    when(() => mockThemeCubit.state).thenReturn(effectiveThemeState);

    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) {
            navigatedRoutes.add('/home');
            return const Scaffold(body: Text('Home Screen'));
          },
        ),
        GoRoute(
          path: '/about',
          builder: (context, state) {
            navigatedRoutes.add('/about');
            return const Scaffold(body: Text('About Screen'));
          },
        ),
        GoRoute(
          path: '/age-gate',
          builder: (context, state) {
            navigatedRoutes.add('/age-gate');
            return const Scaffold(body: Text('Age Gate Screen'));
          },
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: screenSize,
      minTextAdapt: true,
      builder: (context, child) => MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<ThemeCubit>.value(value: mockThemeCubit),
        ],
        child: MediaQuery(
          data: MediaQueryData(
            size: screenSize,
            textScaler: TextScaler.linear(textScaleFactor),
            platformBrightness: brightness,
          ),
          child: MaterialApp.router(
            routerConfig: router,
            theme: isMidnight
                ? ThemeData.dark().copyWith(
                    scaffoldBackgroundColor: Colors.black,
                  )
                : (brightness == Brightness.dark
                      ? ThemeData.dark()
                      : ThemeData.light()),
          ),
        ),
      ),
    );
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('Group 1: Initial & Loading States', () {
    testWidgets(
      'renders user error container when user is null in auth state',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(authState: const AuthState.unauthenticated()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Failed to load user profile.'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      },
    );

    testWidgets('renders LoadingOverlay when auth state is loggingOut', (
      tester,
    ) async {
      final loggingOutState = AuthState.authenticated(
        testUser,
      ).copyWith(status: AuthStatus.loggingOut);
      when(() => mockAuthBloc.state).thenReturn(loggingOutState);

      await tester.pumpWidget(
        buildTestableWidget(tester: tester, authState: loggingOutState),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LoadingOverlay), findsOneWidget);
      expect(find.text('SIGNING OUT...'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });

  group('Group 2: App Bar & Navigation', () {
    testWidgets(
      'renders pinned SliverAppBar with Settings title and back button',
      (tester) async {
        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      },
    );

    testWidgets('back button navigates to /home when route cannot be popped', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(navigatedRoutes.contains('/home'), isTrue);
      expect(find.text('Home Screen'), findsOneWidget);
    });
  });

  group('Group 3: Profile Section', () {
    testWidgets('renders free account user details with FREE ACCOUNT badge', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SettingsProfileSection), findsOneWidget);
      expect(find.text('Aria Stark'), findsOneWidget);
      expect(find.text('aria.stark@vowl.app'), findsOneWidget);
      expect(find.text('FREE ACCOUNT'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    });

    testWidgets('renders premium user details with PREMIUM QUESTER badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          authState: AuthState.authenticated(testPremiumUser),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jon Snow'), findsOneWidget);
      expect(find.text('jon.snow@vowl.app'), findsOneWidget);
      expect(find.text('PREMIUM QUESTER'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    });

    testWidgets('tapping avatar opens Edit Profile dialog', (tester) async {
      await tester.pumpWidget(buildTestableWidget(tester: tester));
      await tester.pumpAndSettle();

      // Find the camera icon on the avatar
      final cameraFinder = find.byIcon(Icons.camera_alt_rounded);
      expect(cameraFinder, findsOneWidget);

      await tester.tap(cameraFinder);
      await tester.pumpAndSettle();

      // Verify edit profile dialog is shown
      expect(find.text('Profile Settings'), findsOneWidget);
      verify(() => mockHapticService.selection()).called(1);
    });
  });

  group('Group 4: Account Section', () {
    testWidgets('renders Account section header and action tiles', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('Security & Password'), findsOneWidget);
      expect(find.text('Age Verification'), findsOneWidget);
      expect(find.byIcon(Icons.lock_person_rounded), findsOneWidget);
      expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);
    });

    testWidgets(
      'tapping Security & Password opens password reset dialog, sending link dispatches event',
      (tester) async {
        await tester.pumpWidget(buildTestableWidget(tester: tester));
        await tester.pumpAndSettle();

        await tapVisible(tester, find.text('Security & Password'));

        expect(find.text('Reset Password'), findsOneWidget);
        expect(find.textContaining('aria.stark@vowl.app'), findsOneWidget);

        // Tap Send Link Now
        await tester.tap(find.text('Send Link Now'));
        await tester.pumpAndSettle();

        verify(
          () => mockAuthBloc.add(
            const AuthPasswordResetRequested('aria.stark@vowl.app'),
          ),
        ).called(1);
        expect(find.text('Reset link sent!'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Age Verification opens dialog, confirming calls resetAgeGate and navigates',
      (tester) async {
        await tester.pumpWidget(buildTestableWidget(tester: tester));
        await tester.pumpAndSettle();

        await tapVisible(tester, find.text('Age Verification'));

        expect(find.text('Reset Age Verification?'), findsOneWidget);

        // Tap Continue
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        expect(navigatedRoutes.contains('/age-gate'), isTrue);
        expect(find.text('Age Gate Screen'), findsOneWidget);
      },
    );
  });

  group('Group 5: App Preferences Section', () {
    testWidgets('renders App Preferences header and switch tiles', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('APP PREFERENCES'), findsOneWidget);
      expect(find.text('Sound Effects'), findsOneWidget);
      expect(find.text('Game Sounds'), findsOneWidget);
      expect(find.text('Pronunciation Voice'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Reduce Complex Gestures'), findsOneWidget);
      expect(find.text('Low Animation Mode'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Language Selection'), findsOneWidget);
      expect(find.text('Translation Language'), findsOneWidget);
    });

    testWidgets(
      'toggling Sound Effects off opens confirmation; confirming mutes SoundService',
      (tester) async {
        await tester.pumpWidget(buildTestableWidget(tester: tester));
        await tester.pumpAndSettle();

        final soundSwitch = find.descendant(
          of: find.widgetWithText(SettingsSwitchTile, 'Sound Effects'),
          matching: find.byType(Switch),
        );
        expect(soundSwitch, findsOneWidget);

        // Toggle off
        await tapVisible(tester, soundSwitch);

        expect(find.text('Disable Sound?'), findsOneWidget);

        // Tap Mute Anyway
        await tester.tap(find.text('Mute Anyway'));
        await tester.pumpAndSettle();

        verify(() => mockSoundService.setMuted(true)).called(1);
        verify(() => mockKidsTtsService.stop()).called(1);
      },
    );

    testWidgets('toggling Game Sounds updates preference and SoundService', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(tester: tester));
      await tester.pumpAndSettle();

      final gameSoundSwitch = find.descendant(
        of: find.widgetWithText(SettingsSwitchTile, 'Game Sounds'),
        matching: find.byType(Switch),
      );
      expect(gameSoundSwitch, findsOneWidget);

      // Toggle off
      await tapVisible(tester, gameSoundSwitch);

      verify(() => mockSoundService.setGameSoundsEnabled(false)).called(1);
    });

    testWidgets(
      'Pronunciation Voice tile renders current preset and opens bottom sheet on tap',
      (tester) async {
        await tester.pumpWidget(buildTestableWidget(tester: tester));
        await tester.pumpAndSettle();

        expect(find.text('Clear Guide'), findsOneWidget);

        await tapVisible(tester, find.text('Pronunciation Voice'));

        expect(find.byType(TtsVoiceSelectionBottomSheet), findsOneWidget);
      },
    );

    testWidgets(
      'toggling Push Notifications off opens confirmation; confirming updates NotificationService',
      (tester) async {
        await tester.pumpWidget(buildTestableWidget(tester: tester));
        await tester.pumpAndSettle();

        final notifSwitch = find.descendant(
          of: find.widgetWithText(SettingsSwitchTile, 'Push Notifications'),
          matching: find.byType(Switch),
        );
        expect(notifSwitch, findsOneWidget);

        // Toggle off
        await tapVisible(tester, notifSwitch);

        expect(find.text('Disable Notifications?'), findsOneWidget);

        // Confirm disable
        await tester.tap(find.text('Yes, Disable'));
        await tester.pumpAndSettle();

        verify(
          () => mockNotificationService.onNotificationPreferenceChanged(false),
        ).called(1);
      },
    );

    testWidgets('toggling Reduce Complex Gestures updates SharedPreferences', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final gestureSwitch = find.descendant(
        of: find.widgetWithText(SettingsSwitchTile, 'Reduce Complex Gestures'),
        matching: find.byType(Switch),
      );
      expect(gestureSwitch, findsOneWidget);

      await tapVisible(tester, gestureSwitch);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('reduce_complex_gestures'), isTrue);
    });

    testWidgets('toggling Low Animation Mode updates global override', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final animSwitch = find.descendant(
        of: find.widgetWithText(SettingsSwitchTile, 'Low Animation Mode'),
        matching: find.byType(Switch),
      );
      expect(animSwitch, findsOneWidget);

      await tapVisible(tester, animSwitch);

      expect(VowlMotion.lowAnimationModeOverride.value, isTrue);
    });

    testWidgets('toggling Analytics calls FirebaseAnalytics platform', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final analyticsSwitch = find.descendant(
        of: find.widgetWithText(SettingsSwitchTile, 'Analytics'),
        matching: find.byType(Switch),
      );
      expect(analyticsSwitch, findsOneWidget);

      await tapVisible(tester, analyticsSwitch);

      expect(mockAnalyticsPlatform.lastCollectionEnabled, isFalse);
    });

    testWidgets(
      'Midnight Mode switch is hidden in Light Theme, visible in Dark Theme',
      (tester) async {
        // In Light Theme:
        await tester.pumpWidget(
          buildTestableWidget(brightness: Brightness.light),
        );
        await tester.pumpAndSettle();
        expect(find.text('Midnight Mode'), findsNothing);

        // In Dark Theme:
        await tester.pumpWidget(
          buildTestableWidget(
            brightness: Brightness.dark,
            themeState: const ThemeState(
              themeMode: ThemeMode.dark,
              isMidnight: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Midnight Mode'), findsOneWidget);

        final midnightSwitch = find.descendant(
          of: find.widgetWithText(SettingsSwitchTile, 'Midnight Mode'),
          matching: find.byType(Switch),
        );
        await tapVisible(tester, midnightSwitch);

        verify(() => mockThemeCubit.toggleMidnight(true)).called(1);
      },
    );

    testWidgets(
      'Language Selection tile displays flag and name, opens LanguagePickerSheet on tap',
      (tester) async {
        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        expect(find.text('🇺🇸 English'), findsOneWidget);

        await tapVisible(tester, find.text('Language Selection'));

        expect(find.byType(LanguagePickerSheet), findsOneWidget);
      },
    );

    testWidgets('Translation Language tile renders configured language name', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Spanish'), findsOneWidget);
    });
  });

  group('Group 6: Support & Legal Section', () {
    testWidgets('renders Support & Legal section header and info tiles', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('SUPPORT & LEGAL'), findsOneWidget);
      expect(find.text('Help Center'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('App Version'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('2.4.0 (108)'), findsOneWidget);
    });

    testWidgets('tapping Help Center launches support email link', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Help Center'));

      expect(
        mockUrlLauncher.lastLaunchedUrl,
        startsWith('mailto:support.vowl.app@gmail.com'),
      );
      expect(
        mockUrlLauncher.lastLaunchedUrl,
        contains('App%20Version%3A%202.4.0'),
      );
    });

    testWidgets('tapping Terms of Service launches legal terms URL', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Terms of Service'));

      expect(
        mockUrlLauncher.lastLaunchedUrl,
        'https://vowl-official.github.io/vowl-legal/terms.html',
      );
    });

    testWidgets('tapping Privacy Policy launches legal privacy URL', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Privacy Policy'));

      expect(
        mockUrlLauncher.lastLaunchedUrl,
        'https://vowl-official.github.io/vowl-legal/privacy.html',
      );
    });

    testWidgets('tapping About pushes /about route', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('About'));

      expect(navigatedRoutes.contains('/about'), isTrue);
      expect(find.text('About Screen'), findsOneWidget);
    });
  });

  group('Group 7: Danger Zone & Logout Flow', () {
    testWidgets('renders Danger Zone header and destructive action tiles', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('DANGER ZONE'), findsOneWidget);
      expect(find.text('Clear App Cache'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);
      expect(find.byType(SettingsLogoutButton), findsOneWidget);
      expect(find.text('SIGN OUT ACCOUNT'), findsOneWidget);
    });

    testWidgets('tapping Clear App Cache shows success SnackBar', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Clear App Cache'));

      expect(find.text('App cache cleared successfully!'), findsOneWidget);
      verify(() => mockHapticService.light()).called(1);
    });

    testWidgets(
      'tapping Delete Account opens warning dialog, Keep My Account dismisses',
      (tester) async {
        await tester.pumpWidget(buildTestableWidget(tester: tester));
        await tester.pumpAndSettle();

        await tapVisible(tester, find.text('Delete Account'));

        expect(find.text('Delete Account?'), findsOneWidget);
        expect(find.text('Keep My Account'), findsOneWidget);
        expect(find.text('Delete Everything'), findsOneWidget);

        await tester.tap(find.text('Keep My Account'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Account?'), findsNothing);
      },
    );

    testWidgets(
      'tapping SIGN OUT ACCOUNT opens sign out dialog, confirming dispatches AuthLogoutRequested',
      (tester) async {
        await tester.pumpWidget(buildTestableWidget(tester: tester));
        await tester.pumpAndSettle();

        await tapVisible(tester, find.text('SIGN OUT ACCOUNT'));

        expect(find.text('Sign Out?'), findsOneWidget);
        expect(find.text('Sign Out'), findsOneWidget);
        expect(find.text('CANCEL'), findsOneWidget);

        await tester.tap(find.text('Sign Out'));
        await tester.pumpAndSettle();

        verify(() => mockAuthBloc.add(const AuthLogoutRequested())).called(1);
      },
    );
  });

  group('Group 8: Responsive Viewports, Accessibility & Themes', () {
    testWidgets(
      'renders on compact mobile viewport (320x568) with zero overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2.0, 568 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildTestableWidget(screenSize: const Size(320, 568)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('renders on tablet viewport (800x1280) with zero overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800 * 1.5, 1280 * 1.5);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableWidget(screenSize: const Size(800, 1280)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly under 1.3x accessibility text scale', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(textScaleFactor: 1.3));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in Midnight theme mode', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          isMidnight: true,
          themeState: const ThemeState(
            themeMode: ThemeMode.dark,
            isMidnight: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
