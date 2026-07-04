import 'package:get_it/get_it.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/local_smart_tutor.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/rewarded_ad_service.dart';
import 'package:vowl/core/utils/payment_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/data/services/asset_quest_service.dart';
import 'package:vowl/core/utils/story_service.dart';
import 'package:vowl/core/utils/praise_service.dart';
import 'package:vowl/core/utils/analytics_service.dart';
import 'package:vowl/core/utils/security_service.dart';
import 'package:vowl/core/utils/remote_config_service.dart';
import 'package:vowl/core/utils/notification_service.dart';
import 'package:vowl/core/utils/review_service.dart';
import 'package:vowl/core/utils/subscription_plans_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_audio_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/usecases/get_current_user.dart';
// FIX (HIGH-3): AppLogger imported so it can be registered in the DI graph.
import 'package:vowl/core/utils/app_logger.dart';

/// Initialises core systems, platform boundaries, and base infrastructure.
Future<void> initExternalAndCore(GetIt sl) async {
  // ============================================================
  // EXTERNAL PLATFORM BOUNDARIES
  // ============================================================
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  sl.registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  sl.registerLazySingleton<InternetConnection>(() => InternetConnection());
  sl.registerLazySingleton<FirebaseRemoteConfig>(
    () => FirebaseRemoteConfig.instance,
  );
  sl.registerLazySingleton<FirebaseFunctions>(() => FirebaseFunctions.instance);

  // ============================================================
  // LOGGING
  // FIX (HIGH-3): AppLogger was previously never registered, making the
  // abstraction unusable by any injected service. Now registered as a
  // lazy singleton so any service can declare `final AppLogger _log`
  // and receive the correct implementation at runtime.
  //
  // SWAP TO PRODUCTION: Replace DebugAppLogger with a Crashlytics-backed
  // implementation before shipping:
  //   sl.registerLazySingleton<AppLogger>(() => FirebaseAppLogger());
  // ============================================================
  sl.registerLazySingleton<AppLogger>(() => const DebugAppLogger());

  // ============================================================
  // CORE SYSTEMS & INFRASTRUCTURE
  // ============================================================
  sl.registerLazySingleton<SecurityService>(() => SecurityService());
  sl.registerLazySingleton<RemoteConfigService>(
    () => RemoteConfigService(sl<FirebaseRemoteConfig>()),
  );
  // FIX (HIGH — RESOURCE LEAK): NotificationService.dispose() already
  // existed (cancels 4 StreamSubscriptions: onMessage, onTokenRefresh,
  // onMessageOpenedApp, authStateChanges) but nothing in the DI graph ever
  // called it, so those subscriptions lived for the process lifetime even
  // across a `sl.reset()`. Wiring `dispose:` here closes that gap.
  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(),
    dispose: (service) => service.dispose(),
  );
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl<InternetConnection>()),
  );
  // NOTE: TtsService must be registered before SoundService since
  // SoundService depends on it. Both are lazy singletons so the order
  // here only matters for readability; the actual resolution is deferred.
  sl.registerLazySingleton<TtsService>(() => TtsService());
  sl.registerLazySingleton<SoundService>(() => SoundService(sl<TtsService>()));
  sl.registerLazySingleton<HapticService>(() => HapticService());
  sl.registerLazySingleton<SmartTutor>(() => const LocalSmartTutor());
  // FIX (CRITICAL — RESOURCE LEAK): AdService.dispose() already existed
  // (releases the platform InterstitialAd/RewardedAd objects — see its own
  // doc comment: "FIX (CRITICAL-4)") but, like NotificationService above,
  // was never actually invoked anywhere. A previous review pass added the
  // method but the DI wiring to call it was the other half of that fix and
  // was missing. Registering it here completes that fix.
  sl.registerLazySingleton<AdService>(
    () => AdService(),
    dispose: (service) => service.dispose(),
  );
  // FIX (CRITICAL — MISSING REGISTRATION): RewardedAdService had a DI-ready
  // factory constructor (`factory RewardedAdService() = ...`) but was never
  // actually registered anywhere in this DI graph - any `sl<RewardedAdService>()`
  // call would have thrown a "type not registered" error at runtime. Now
  // that its implementation is a real, working ad integration rather than
  // a stub (see rewarded_ad_service.dart's doc comment), it needs to
  // actually be reachable via DI to be usable.
  sl.registerLazySingleton<RewardedAdService>(
    () => RewardedAdService(),
    dispose: (service) => service.dispose(),
  );
  sl.registerLazySingleton<PaymentService>(
    () => PaymentService(
      getCurrentUser: sl<GetCurrentUser>(),
      firestore: sl<FirebaseFirestore>(),
      functions: sl<FirebaseFunctions>(),
    ),
    // FIX (HIGH — RESOURCE LEAK): PaymentService.dispose() clears the
    // Razorpay SDK instance and its event listeners; same gap, same fix.
    dispose: (service) => service.dispose(),
  );
  sl.registerLazySingleton<SubscriptionPlansService>(
    () => SubscriptionPlansService(firestore: sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<SpeechService>(() => SpeechService());
  sl.registerLazySingleton<KidsTTSService>(() => KidsTTSService());
  sl.registerLazySingleton<KidsAudioService>(() => KidsAudioService());
  sl.registerLazySingleton<AssetQuestService>(() => AssetQuestService());
  sl.registerLazySingleton<StoryService>(() => StoryService());
  sl.registerLazySingleton<PraiseService>(
    () => PraiseService(sl<TtsService>()),
  );
  sl.registerLazySingleton<AnalyticsService>(() => AnalyticsService());
  sl.registerLazySingleton<ReviewService>(() => ReviewService());
  sl.registerLazySingleton<LocaleService>(() => LocaleService());

  // ============================================================
  // NAVIGATION SCROLL CONTROLLERS
  //
  // Registered as lazy singletons so that tab screens can retrieve
  // the same controller across tab switches (enabling scroll-to-top
  // on tab re-tap without recreating the controller).
  //
  // LIFECYCLE NOTE: These controllers live for the duration of the
  // app session. If a screen that owns one is recreated (e.g., after
  // a memory trim), the controller retains its position. This is the
  // desired behaviour for tab-level persistence. Do NOT dispose these
  // controllers in individual screen State.dispose() calls.
  // ============================================================
  sl.registerLazySingleton<ScrollController>(
    () => ScrollController(),
    instanceName: 'home',
  );
  sl.registerLazySingleton<ScrollController>(
    () => ScrollController(),
    instanceName: 'games',
  );
}
