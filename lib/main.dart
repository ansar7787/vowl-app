import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'package:vowl/core/utils/security_service.dart';
import 'package:vowl/core/utils/remote_config_service.dart';
import 'package:vowl/core/utils/notification_service.dart';
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
      statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    ),
  );
  
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 1. Sequential Initialization of core services (order matters: Firebase before DI)
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  await di.init();
  final isSecure = await SecurityService.isDeviceSecure();

  // 2. Configure Firestore Persistence (Non-blocking)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 50 * 1024 * 1024, // 50MB - prevents storage exhaustion on low-end devices
  );

  if (!isSecure) {
    runApp(const InsecureDeviceScreen());
    return;
  }

  // Initialize Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const MyApp());

  // Delay splash removal slightly to ensure first frame is stable and theme is loaded
  // We remove it after a short delay to ensure Flutter has painted the first frame
  Future.delayed(const Duration(milliseconds: 200), () {
    FlutterNativeSplash.remove();
  });

  // Defer heavy/non-critical services to ensure buttery smooth splash-to-home transition
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 1500), () async {
      // Initialize heavy SDKs only once the UI is stable
      di.sl<AdService>().init();
      di.sl<RemoteConfigService>().init();
      
      // Initialize App Check and Notifications
      FirebaseAppCheck.instance.activate(
        providerAndroid: AndroidPlayIntegrityProvider(),
        providerApple: AppleDeviceCheckProvider(),
      );
      
      di.sl<NotificationService>().init().then((_) {
        di.sl<NotificationService>().requestPermissions();
        di.sl<NotificationService>().scheduleWeeklyMotivation();
      });
    });
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Global Asset Pre-caching for "Elite Performance"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pre-load mascot WEBP assets into RAM early
      precacheImage(const AssetImage('assets/images/mascot/voxbot_happy.webp'), context);
      precacheImage(const AssetImage('assets/images/mascot/voxbot_neutral.webp'), context);
      precacheImage(const AssetImage('assets/images/mascot/voxbot_thinking.webp'), context);
      precacheImage(const AssetImage('assets/images/mascot/voxbot_worried.webp'), context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
            BlocProvider<EconomyBloc>(create: (context) => di.sl<EconomyBloc>()),
            BlocProvider<ProgressionBloc>(create: (context) => di.sl<ProgressionBloc>()),
            BlocProvider<ProfileBloc>(create: (context) => di.sl<ProfileBloc>()),
            BlocProvider<ThemeCubit>(create: (context) => di.sl<ThemeCubit>()),
          ],
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              final bool isActuallyDark = state.themeMode == ThemeMode.system
                  ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
                  : state.isDark;

              SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness:
                      isActuallyDark ? Brightness.light : Brightness.dark,
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarIconBrightness:
                      isActuallyDark ? Brightness.light : Brightness.dark,
                ),
              );

              return MaterialApp.router(
                title: 'Vowl',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: state.isMidnight ? AppTheme.midnightTheme : AppTheme.darkTheme,
                themeMode: state.themeMode,
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
                          ],
                          child: BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, authState) {
                              final isLoggingOut =
                                  authState.status == AuthStatus.loggingOut;
        
                              return LoadingOverlay(
                                isLoading: isLoggingOut,
                                message: 'Securing your quest data',
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
    );
  }
}
