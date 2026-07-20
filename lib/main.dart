import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/connectivity_wrapper.dart';
import 'package:vowl/core/presentation/widgets/global_audio_feedback_listener.dart';
import 'package:vowl/core/presentation/widgets/global_error_boundary.dart';
import 'package:vowl/core/presentation/widgets/insecure_device_screen.dart';
import 'package:vowl/core/presentation/widgets/loading_overlay.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/notification_service.dart';
import 'package:vowl/core/utils/remote_config_service.dart';
import 'package:vowl/core/utils/security_service.dart';
import 'package:vowl/core/utils/age_gate_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Edge-to-edge system UI with platform-appropriate brightness
  final brightness = PlatformDispatcher.instance.platformBrightness;
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // --- Parallelized safe initialization helpers ---

  Future<void> safeLoadDotEnv() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      if (kDebugMode) debugPrint('Warning: dotenv failed to load: $e');
    }
  }

  Future<bool> safeCheckSecurity() async {
    try {
      return await SecurityService.isDeviceSecure();
    } catch (e) {
      if (kDebugMode) debugPrint('Warning: security check failed: $e');
      // Default to secure to avoid locking out users on check failure.
      return true;
    }
  }

  Future<FirebaseApp?> safeInitializeFirebase() async {
    try {
      return await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Critical: Firebase failed to initialize: $e');
      return null;
    }
  }

  // 1. Parallelize non-dependent core initializations.
  // Kick them off together, then await individually so the results stay
  // strongly typed and reordering the calls can't silently break anything.
  final dotEnvFuture = safeLoadDotEnv();
  final firebaseFuture = safeInitializeFirebase();
  final securityFuture = safeCheckSecurity();
  final ageGateFuture = AgeGateService.loadCached();

  await dotEnvFuture;
  final FirebaseApp? firebaseApp = await firebaseFuture;
  final bool isSecure = await securityFuture;
  await ageGateFuture;

  if (firebaseApp != null) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 50 * 1024 * 1024, // 50 MB
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Warning: Firestore settings failed to apply: $e');
      }
    }
  }

  // 2. Dependency Injection (depends on Firebase)
  try {
    await di.init();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Critical: Dependency Injection failed: $e');
    }
  }

  if (!isSecure) {
    runApp(const InsecureDeviceScreen());
    return;
  }

  // 3. Crashlytics — must run after DI so Firestore is ready
  if (firebaseApp != null) {
    try {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Warning: Crashlytics initialization failed: $e');
      }
    }
  }

  // 4. LocaleService
  try {
    final localeService = di.sl<LocaleService>();
    initLocaleServiceReference(localeService);
    await localeService.init();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Warning: LocaleService initialization failed: $e');
    }
  }

  runApp(const MyApp());

  // Native splash will be removed dynamically in SplashPage once the image is decoded!

  // 5. Defer heavy SDKs until UI is stable
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 1500), () async {
      await _initDeferredServices(firebaseApp);
    });
  });
}

/// Initializes non-critical services after the first frame is stable.
/// Each service is wrapped individually so a single failure doesn't block others.
Future<void> _initDeferredServices(FirebaseApp? firebaseApp) async {
  Future<void> runSafe(String serviceName, Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e, stack) {
      if (kDebugMode) debugPrint('Error initializing $serviceName: $e');
      if (firebaseApp != null) {
        FirebaseCrashlytics.instance.recordError(
          e,
          stack,
          reason: '$serviceName initialization failed',
        );
      }
    }
  }

  await runSafe('AdService', () => di.sl<AdService>().init());
  await runSafe(
    'RemoteConfigService',
    () => di.sl<RemoteConfigService>().init(),
  );
  await runSafe(
    'FirebaseAppCheck',
    () => FirebaseAppCheck.instance.activate(
      // ignore: deprecated_member_use
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.deviceCheck,
      // ignore: deprecated_member_use
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
    ),
  );
  await runSafe('NotificationService', () async {
    await di.sl<NotificationService>().init();
    await di.sl<NotificationService>().scheduleWeeklyMotivation();
  });
}

// ============================================================================
// App widget
// ============================================================================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Pre-cache frequently shown mascot assets to avoid jank on first display.
      for (final path in const [
        'assets/images/mascot/voxbot_happy.webp',
        'assets/images/mascot/voxbot_neutral.webp',
        'assets/images/mascot/voxbot_thinking.webp',
        'assets/images/mascot/voxbot_worried.webp',
      ]) {
        precacheImage(AssetImage(path), context).catchError((_) {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(create: (_) => di.sl<AuthBloc>()),
          BlocProvider<EconomyBloc>(create: (_) => di.sl<EconomyBloc>()),
          BlocProvider<ProgressionBloc>(
            create: (_) => di.sl<ProgressionBloc>(),
          ),
          BlocProvider<ProfileBloc>(create: (_) => di.sl<ProfileBloc>()),
          BlocProvider<ThemeCubit>(create: (_) => di.sl<ThemeCubit>()),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            final bool isActuallyDark = themeState.themeMode == ThemeMode.system
                ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
                : themeState.isDark;

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isActuallyDark
                    ? Brightness.light
                    : Brightness.dark,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: isActuallyDark
                    ? Brightness.light
                    : Brightness.dark,
              ),
              child: ListenableBuilder(
                listenable: di.sl<LocaleService>(),
                builder: (context, _) {
                  final localeService = di.sl<LocaleService>();
                  return MaterialApp.router(
                    title: 'Vowl',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    darkTheme: themeState.isMidnight
                        ? AppTheme.midnightTheme
                        : AppTheme.darkTheme,
                    themeMode: themeState.themeMode,
                    locale: localeService.currentLocale,
                    supportedLocales: LocaleService.supportedLocales
                        .map((l) => l.locale)
                        .toList(),
                    localizationsDelegates: const [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    routerConfig: AppRouter.router,
                    builder: (context, child) => _AppShell(
                      isActuallyDark: isActuallyDark,
                      isMidnight: themeState.isMidnight,
                      child: child,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// App shell — wraps every route with the global error boundary, connectivity,
// audio feedback, auth listeners, and the logout loading overlay.
// Extracted from MyApp.build so the widget tree stays flat and testable.
// ============================================================================

class _AppShell extends StatelessWidget {
  const _AppShell({
    required this.isActuallyDark,
    required this.isMidnight,
    required this.child,
  });

  final bool isActuallyDark;
  final bool isMidnight;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return GlobalErrorBoundary(
      child: ConnectivityWrapper(
        child: GlobalAudioFeedbackListener(
          child: MultiBlocListener(
            listeners: [
              // Trigger daily streak check on sign-in
              BlocListener<AuthBloc, AuthState>(
                listenWhen: (prev, curr) =>
                    prev.status != AuthStatus.authenticated &&
                    curr.status == AuthStatus.authenticated,
                listener: (context, _) => context.read<ProgressionBloc>().add(
                  const ProgressionCheckDailyStreakRequested(),
                ),
              ),
              // Global auth message handler (snackbars)
              BlocListener<AuthBloc, AuthState>(
                listenWhen: (prev, curr) =>
                    prev.message != curr.message && curr.message != null,
                listener: (context, authState) {
                  final msg = authState.message!;
                  final isWarning =
                      msg.contains('security') || msg.contains('cancelled');
                  final isSuccessMsg =
                      msg == 'auth.email_verification_sent' ||
                      msg == 'settings_dialogs.account_deleted_success';
                  CustomSnackBar.show(
                    context: context,
                    // Localize the message key
                    message: context.tr(msg),
                    type: isSuccessMsg
                        ? CustomSnackBarType.success
                        : (authState.status == AuthStatus.unauthenticated &&
                              !isWarning)
                        ? CustomSnackBarType.error
                        : isWarning
                        ? CustomSnackBarType.warning
                        : CustomSnackBarType.info,
                  );
                },
              ),
            ],
            child: BlocBuilder<AuthBloc, AuthState>(
              buildWhen: (prev, curr) => prev.status != curr.status,
              builder: (context, authState) {
                return LoadingOverlay(
                  isLoading: authState.status == AuthStatus.loggingOut,
                  message: context.tr(
                    'loading_overlay.securing_data',
                    fallback: 'Securing Data...',
                  ),
                  child: Container(
                    color: isMidnight
                        ? Colors.black
                        : (isActuallyDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC)),
                    child: child!,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
