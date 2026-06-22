import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/connectivity_wrapper.dart';
import 'package:vowl/core/presentation/widgets/global_error_boundary.dart';
import 'package:vowl/core/presentation/widgets/global_audio_feedback_listener.dart';
import 'package:vowl/core/presentation/widgets/insecure_device_screen.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/security_service.dart';
import 'package:vowl/core/utils/remote_config_service.dart';
import 'package:vowl/core/utils/notification_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/core/presentation/widgets/loading_overlay.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Set system UI to transparent for edge-to-edge look
  // Initial style should be neutral or respect platform brightness to avoid white flicker
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

  // Safe helper to load environment variables without crashing startup
  Future<void> safeLoadDotEnv() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Warning: Dotenv failed to load: $e");
    }
  }

  // Safe helper for device security check
  Future<bool> safeCheckSecurity() async {
    try {
      return await SecurityService.isDeviceSecure();
    } catch (e) {
      debugPrint("Warning: Security check failed: $e");
      return true; // Default to secure in case of exception to avoid locking out users
    }
  }

  // Safe helper for Firebase initialization
  Future<FirebaseApp?> safeInitializeFirebase() async {
    try {
      return await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint("Critical: Firebase failed to initialize: $e");
      return null;
    }
  }

  // 1. Parallelize non-dependent core initializations safely to prevent main thread blocking/jank
  final initResults = await Future.wait([
    safeLoadDotEnv(),
    safeInitializeFirebase(),
    safeCheckSecurity(),
  ]);

  final firebaseApp = initResults[1] as FirebaseApp?;
  final bool isSecure = initResults[2] as bool? ?? true;

  if (firebaseApp != null) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Configure Firestore Persistence (Non-blocking) safely
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes:
            50 *
            1024 *
            1024, // 50MB - prevents storage exhaustion on low-end devices
      );
    } catch (e) {
      debugPrint("Warning: Firestore settings failed to apply: $e");
    }
  }

  // 2. Initialize Dependency Injection (depends on Firebase initialization)
  try {
    await di.init();
  } catch (e) {
    debugPrint("Critical: Dependency Injection initialization failed: $e");
  }

  if (!isSecure) {
    runApp(const InsecureDeviceScreen());
    return;
  }

  // Initialize Crashlytics
  if (firebaseApp != null) {
    try {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
      debugPrint("Warning: Crashlytics initialization failed: $e");
    }
  }
  
  // Initialize LocaleService
  try {
    final localeService = di.sl<LocaleService>();
    initLocaleServiceReference(localeService);
    await localeService.init();
  } catch (e) {
    debugPrint("Warning: LocaleService initialization failed: $e");
  }

  runApp(const MyApp());

  // Delay splash removal slightly to ensure first frame is stable and theme is loaded
  Future.delayed(const Duration(milliseconds: 200), () {
    FlutterNativeSplash.remove();
  });

  // Defer heavy/non-critical services to ensure buttery smooth splash-to-home transition
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 1500), () async {
      // Initialize heavy SDKs only once the UI is stable, wrapping each in a try-catch
      try {
        await di.sl<AdService>().init();
      } catch (e, stack) {
        debugPrint("Error initializing AdService: $e");
        if (firebaseApp != null) {
          FirebaseCrashlytics.instance.recordError(
            e,
            stack,
            reason: 'AdService initialization failed',
          );
        }
      }

      try {
        await di.sl<RemoteConfigService>().init();
      } catch (e, stack) {
        debugPrint("Error initializing RemoteConfigService: $e");
        if (firebaseApp != null) {
          FirebaseCrashlytics.instance.recordError(
            e,
            stack,
            reason: 'RemoteConfigService initialization failed',
          );
        }
      }

      try {
        // ignore: deprecated_member_use
        await FirebaseAppCheck.instance.activate(
          // ignore: deprecated_member_use
          appleProvider: kDebugMode
              ? AppleProvider.debug
              : AppleProvider.deviceCheck,
          // ignore: deprecated_member_use
          androidProvider: kDebugMode
              ? AndroidProvider.debug
              : AndroidProvider.playIntegrity,
        );
      } catch (e, stack) {
        debugPrint("Error activating Firebase App Check: $e");
        if (firebaseApp != null) {
          FirebaseCrashlytics.instance.recordError(
            e,
            stack,
            reason: 'FirebaseAppCheck activation failed',
          );
        }
      }

      try {
        await di.sl<NotificationService>().init();
        await di.sl<NotificationService>().scheduleWeeklyMotivation();
      } catch (e, stack) {
        debugPrint("Error initializing NotificationService: $e");
        if (firebaseApp != null) {
          FirebaseCrashlytics.instance.recordError(
            e,
            stack,
            reason: 'NotificationService initialization failed',
          );
        }
      }
    });
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Global Asset Pre-caching for "Elite Performance"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Pre-load mascot WEBP assets into RAM early
      precacheImage(
        const AssetImage('assets/images/mascot/voxbot_happy.webp'),
        context,
      );
      precacheImage(
        const AssetImage('assets/images/mascot/voxbot_neutral.webp'),
        context,
      );
      precacheImage(
        const AssetImage('assets/images/mascot/voxbot_thinking.webp'),
        context,
      );
      precacheImage(
        const AssetImage('assets/images/mascot/voxbot_worried.webp'),
        context,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(create: (context) => di.sl<AuthBloc>()),
            BlocProvider<EconomyBloc>(
              create: (context) => di.sl<EconomyBloc>(),
            ),
            BlocProvider<ProgressionBloc>(
              create: (context) => di.sl<ProgressionBloc>(),
            ),
            BlocProvider<ProfileBloc>(
              create: (context) => di.sl<ProfileBloc>(),
            ),
            BlocProvider<ThemeCubit>(create: (context) => di.sl<ThemeCubit>()),
          ],
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              final bool isActuallyDark = state.themeMode == ThemeMode.system
                  ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
                  : state.isDark;

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
                      darkTheme: state.isMidnight
                          ? AppTheme.midnightTheme
                          : AppTheme.darkTheme,
                      themeMode: state.themeMode,
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
                      builder: (context, child) {
                    return GlobalErrorBoundary(
                      child: ConnectivityWrapper(
                        child: GlobalAudioFeedbackListener(
                          child: MultiBlocListener(
                            listeners: [
                              BlocListener<AuthBloc, AuthState>(
                                listenWhen: (prev, curr) =>
                                    prev.status != AuthStatus.authenticated &&
                                    curr.status == AuthStatus.authenticated,
                                listener: (context, authState) {
                                  context.read<ProgressionBloc>().add(
                                    const ProgressionCheckDailyStreakRequested(),
                                  );
                                },
                              ),
                              BlocListener<AuthBloc, AuthState>(
                                listenWhen: (prev, curr) => prev.message != curr.message && curr.message != null,
                                listener: (context, authState) {
                                  final isWarning = authState.message!.contains('security') || authState.message!.contains('cancelled');
                                  CustomSnackBar.show(
                                    context: context,
                                    message: context.tr(authState.message!),
                                    type: authState.status == AuthStatus.unauthenticated && !isWarning
                                        ? CustomSnackBarType.error
                                        : isWarning
                                            ? CustomSnackBarType.warning
                                            : CustomSnackBarType.info,
                                  );
                                },
                              ),
                            ],
                            child: BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, authState) {
                                final isLoggingOut =
                                    authState.status == AuthStatus.loggingOut;

                                return LoadingOverlay(
                                  isLoading: isLoggingOut,
                                  message: context.tr('loading_overlay.securing_data'),
                                  child: Container(
                                    color: state.isMidnight
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
                  },
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
