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
import 'package:vowl/core/utils/payment_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';
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
import 'package:vowl/core/utils/coin_packs_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/translation_service.dart';
import 'package:vowl/core/utils/ml_services/language_id_service.dart';
import 'package:vowl/core/utils/ml_services/smart_reply_service.dart';
import 'package:vowl/core/utils/ml_services/text_recognition_service.dart';
import 'package:vowl/core/utils/ml_services/digital_ink_service.dart';
import 'package:vowl/core/utils/ml_services/entity_extraction_service.dart';
import 'package:vowl/core/utils/ml_services/image_labeling_service.dart';
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
  sl.registerLazySingleton<InternetConnection>(
    () => InternetConnection.createInstance(
      checkInterval: const Duration(seconds: 5),
      customCheckOptions: [
        InternetCheckOption(
          uri: Uri.parse('https://one.one.one.one'),
          timeout: const Duration(seconds: 10),
        ),
        InternetCheckOption(
          uri: Uri.parse('https://jsonplaceholder.typicode.com/todos/1'),
          timeout: const Duration(seconds: 10),
        ),
      ],
    ),
  );
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
  // REMOVED: RewardedAdService registration — the duplicate rewarded-ad
  // subsystem has been consolidated into AdService (see ad_service.dart).
  // The sole call site (profile/rewarded_ad_card.dart) now uses AdService
  // directly, eliminating competing loads against the same ad unit ID.
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
  sl.registerLazySingleton<CoinPacksService>(
    () => CoinPacksService(firestore: sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<SpeechService>(() => SpeechService());
  sl.registerLazySingleton<AudioRecordingService>(
    () => AudioRecordingService(),
    dispose: (service) => service.dispose(),
  );
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
  sl.registerLazySingleton<LanguageIdService>(
    () => LanguageIdService(),
    dispose: (service) => service.dispose(),
  );
  sl.registerLazySingleton<SmartReplyService>(
    () => SmartReplyService(),
    dispose: (service) => service.dispose(),
  );
  sl.registerLazySingleton<TextRecognitionService>(
    () => TextRecognitionService(),
    dispose: (service) => service.dispose(),
  );
  sl.registerLazySingleton<DigitalInkService>(
    () => DigitalInkService(),
    dispose: (service) => service.dispose(),
  );
  sl.registerLazySingleton<EntityExtractionService>(
    () => EntityExtractionService(),
    dispose: (service) => service.dispose(),
  );
  sl.registerLazySingleton<ImageLabelingService>(
    () => ImageLabelingService(),
    dispose: (service) => service.dispose(),
  );
  sl.registerLazySingleton<TranslationService>(
    () => TranslationService(),
    dispose: (service) => service.dispose(),
  );

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
