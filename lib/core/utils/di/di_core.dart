import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/seeding_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/local_smart_tutor.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/payment_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/quest_upload_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/data/services/asset_quest_service.dart';
import 'package:vowl/core/utils/story_service.dart';
import 'package:vowl/core/utils/praise_service.dart';
import 'package:vowl/core/utils/analytics_service.dart';
import 'package:vowl/core/utils/security_service.dart';
import 'package:vowl/core/utils/remote_config_service.dart';
import 'package:vowl/core/utils/notification_service.dart';
import 'package:vowl/core/utils/review_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_audio_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/usecases/get_current_user.dart';

/// Initializes core systems, platform boundaries, and base infrastructure.
Future<void> initExternalAndCore(GetIt sl) async {
  // ==========================================
  // EXTERNAL PLATFORM BOUNDARIES
  // ==========================================
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  sl.registerLazySingleton<InternetConnection>(() => InternetConnection());
  sl.registerLazySingleton<FirebaseRemoteConfig>(() => FirebaseRemoteConfig.instance);

  // ==========================================
  // CORE SYSTEMS & INFRASTRUCTURE
  // ==========================================
  sl.registerLazySingleton<SecurityService>(() => SecurityService());
  sl.registerLazySingleton<RemoteConfigService>(() => RemoteConfigService(sl<FirebaseRemoteConfig>()));
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl<InternetConnection>()));
  sl.registerLazySingleton<SeedingService>(() => SeedingService(sl<FirebaseFirestore>()));
  sl.registerLazySingleton<SoundService>(() => SoundService());
  sl.registerLazySingleton<HapticService>(() => HapticService());
  sl.registerLazySingleton<SmartTutor>(() => const LocalSmartTutor());
  sl.registerLazySingleton<AdService>(() => AdService());
  sl.registerLazySingleton<PaymentService>(() => PaymentService(
        getCurrentUser: sl<GetCurrentUser>(),
        firestore: sl<FirebaseFirestore>(),
      ));
  sl.registerLazySingleton<SpeechService>(() => SpeechService());
  sl.registerLazySingleton<QuestUploadService>(() => QuestUploadService());
  sl.registerLazySingleton<TtsService>(() => TtsService());
  sl.registerLazySingleton<KidsTTSService>(() => KidsTTSService());
  sl.registerLazySingleton<KidsAudioService>(() => KidsAudioService());
  sl.registerLazySingleton<AssetQuestService>(() => AssetQuestService());
  sl.registerLazySingleton<StoryService>(() => StoryService());
  sl.registerLazySingleton<PraiseService>(() => PraiseService(sl<TtsService>()));
  sl.registerLazySingleton<AnalyticsService>(() => AnalyticsService());
  sl.registerLazySingleton<ReviewService>(() => ReviewService());
}
