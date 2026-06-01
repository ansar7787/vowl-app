import 'package:vowl/core/utils/sound_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
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
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:vowl/features/kids_zone/data/datasources/kids_local_data_source.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:vowl/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';
import 'package:vowl/features/auth/domain/repositories/user_repository.dart';
import 'package:vowl/features/auth/data/repositories/user_repository_impl.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';
import 'package:vowl/features/auth/data/repositories/gamification_repository_impl.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';
import 'package:vowl/features/auth/data/repositories/shop_repository_impl.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/reading/domain/repositories/reading_repository.dart';
import 'package:vowl/features/reading/data/repositories/reading_repository_impl.dart';
import 'package:vowl/features/reading/data/datasources/reading_remote_data_source.dart';
import 'package:vowl/features/reading/domain/usecases/get_reading_quest.dart';
import 'package:vowl/features/elite_mastery/data/datasources/elite_mastery_data_source.dart';
import 'package:vowl/features/elite_mastery/domain/repositories/elite_mastery_repository.dart';
import 'package:vowl/features/elite_mastery/data/repositories/elite_mastery_repository_impl.dart';
import 'package:vowl/features/elite_mastery/domain/usecases/get_elite_mastery_quests.dart';
import 'package:vowl/features/elite_mastery/presentation/bloc/elite_mastery_bloc.dart';

import 'package:vowl/features/writing/domain/repositories/writing_repository.dart';
import 'package:vowl/features/writing/data/repositories/writing_repository_impl.dart';
import 'package:vowl/features/writing/data/datasources/writing_remote_data_source.dart';
import 'package:vowl/features/writing/domain/usecases/get_writing_quest.dart';
import 'package:vowl/features/writing/domain/usecases/use_writing_hint.dart';

import 'package:vowl/features/speaking/domain/repositories/speaking_repository.dart';
import 'package:vowl/features/speaking/data/repositories/speaking_repository_impl.dart';
import 'package:vowl/features/speaking/data/datasources/speaking_remote_data_source.dart';
import 'package:vowl/features/speaking/domain/usecases/get_speaking_quest.dart';

import 'package:vowl/features/roleplay/domain/repositories/roleplay_repository.dart';
import 'package:vowl/features/roleplay/data/repositories/roleplay_repository_impl.dart';
import 'package:vowl/features/roleplay/data/datasources/roleplay_remote_data_source.dart';
import 'package:vowl/features/roleplay/domain/usecases/get_roleplay_quest.dart';
import 'package:vowl/features/roleplay/domain/usecases/preload_roleplay_quests.dart';

import 'package:vowl/features/accent/domain/repositories/accent_repository.dart';
import 'package:vowl/features/accent/data/repositories/accent_repository_impl.dart';
import 'package:vowl/features/accent/data/datasources/accent_data_source.dart';
import 'package:vowl/features/accent/domain/usecases/get_accent_quest.dart';
import 'package:vowl/features/accent/domain/usecases/preload_accent_quest.dart';
import 'package:vowl/features/accent/domain/usecases/clear_accent_quest_cache.dart';

import 'package:vowl/features/listening/domain/repositories/listening_repository.dart';
import 'package:vowl/features/listening/data/repositories/listening_repository_impl.dart';
import 'package:vowl/features/listening/data/datasources/listening_remote_data_source.dart';
import 'package:vowl/features/listening/domain/usecases/get_listening_quests.dart';

import 'package:vowl/features/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:vowl/features/vocabulary/data/repositories/vocabulary_repository_impl.dart';
import 'package:vowl/features/vocabulary/data/datasources/vocabulary_remote_data_source.dart';
import 'package:vowl/features/vocabulary/domain/usecases/get_vocabulary_quests.dart';

import 'package:vowl/features/grammar/domain/repositories/grammar_repository.dart';

import 'package:vowl/features/grammar/data/repositories/grammar_repository_impl.dart';
import 'package:vowl/features/grammar/data/datasources/grammar_remote_data_source.dart';
import 'package:vowl/features/grammar/domain/usecases/get_grammar_quest.dart';
import 'package:vowl/features/grammar/domain/usecases/preload_grammar_quest.dart';

import 'package:vowl/features/auth/domain/usecases/sign_up.dart';
import 'package:vowl/features/auth/domain/usecases/log_in_with_email.dart';
import 'package:vowl/features/auth/domain/usecases/log_in_with_google.dart';
import 'package:vowl/features/auth/domain/usecases/log_out.dart';
import 'package:vowl/features/auth/domain/usecases/get_user_stream.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/domain/usecases/update_category_stats.dart';
import 'package:vowl/features/auth/domain/usecases/award_badge.dart'; // New
import 'package:vowl/features/auth/domain/usecases/forgot_password.dart';
import 'package:vowl/features/auth/domain/usecases/send_email_verification.dart';
import 'package:vowl/features/auth/domain/usecases/reload_user.dart';
import 'package:vowl/features/auth/domain/usecases/get_current_user.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/domain/usecases/update_user.dart'; // New
import 'package:vowl/features/auth/domain/usecases/claim_vip_gift.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_hint.dart';
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/features/auth/domain/usecases/update_profile_picture.dart';
import 'package:vowl/features/auth/domain/usecases/update_display_name.dart';
import 'package:vowl/features/auth/domain/usecases/repair_streak.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_streak_freeze.dart';
import 'package:vowl/features/auth/domain/usecases/activate_double_xp.dart';

import 'package:vowl/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:vowl/features/leaderboard/data/repositories/leaderboard_repository_impl.dart';
// Feature Blocs
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_audio_service.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/login_cubit.dart';
import 'package:vowl/features/auth/presentation/bloc/signup_cubit.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart'
    as vocab;
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';

import 'package:vowl/features/auth/domain/usecases/update_unlocked_level.dart';
import 'package:vowl/features/auth/domain/usecases/award_kids_sticker.dart';
import 'package:vowl/features/auth/domain/usecases/update_kids_mascot.dart';
import 'package:vowl/features/auth/domain/usecases/buy_kids_accessory.dart';
import 'package:vowl/features/auth/domain/usecases/equip_kids_accessory.dart';
import 'package:vowl/features/auth/domain/usecases/delete_account.dart';
import 'package:vowl/features/auth/domain/usecases/claim_daily_gift.dart';
import 'package:vowl/features/auth/domain/usecases/claim_daily_chest.dart';
import 'package:vowl/features/auth/domain/usecases/claim_kids_daily_reward.dart';
import 'package:vowl/features/auth/domain/usecases/award_kids_coins.dart';

import 'package:vowl/features/kids_zone/domain/repositories/kids_repository.dart';
import 'package:vowl/features/kids_zone/data/repositories/kids_repository_impl.dart';
import 'package:vowl/features/kids_zone/data/datasources/kids_remote_data_source.dart';
import 'package:vowl/features/kids_zone/domain/usecases/get_kids_quests.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';

final sl = GetIt.instance;

/// Central Dependency Injection container coordinator.
/// Modularly decomposed to maintain SRP and prevent giant merge conflicts.
Future<void> init() async {
  await _initExternalAndCore();
  _initAuthFeature();
  _initReadingFeature();
  _initWritingFeature();
  _initSpeakingFeature();
  _initGrammarFeature();
  _initRoleplayFeature();
  _initAccentFeature();
  _initListeningFeature();
  _initVocabularyFeature();
  _initKidsZoneFeature();
  _initEliteMasteryFeature();
}

// ==========================================
// 1. EXTERNAL & CORE INFRASTRUCTURE SERVICES
// ==========================================
Future<void> _initExternalAndCore() async {
  // External Platform Boundaries
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  sl.registerLazySingleton<InternetConnection>(() => InternetConnection());
  sl.registerLazySingleton<FirebaseRemoteConfig>(() => FirebaseRemoteConfig.instance);

  // Core Systems
  sl.registerLazySingleton<SecurityService>(() => SecurityService());
  sl.registerLazySingleton<RemoteConfigService>(() => RemoteConfigService(sl<FirebaseRemoteConfig>()));
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl<InternetConnection>()));
  sl.registerLazySingleton<SeedingService>(() => SeedingService(sl<FirebaseFirestore>()));
  sl.registerLazySingleton<SoundService>(() => SoundService());
  sl.registerLazySingleton<HapticService>(() => HapticService());
  sl.registerLazySingleton<LocalSmartTutor>(() => LocalSmartTutor());
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
  sl.registerLazySingleton<PraiseService>(() => PraiseService());
  sl.registerLazySingleton<AnalyticsService>(() => AnalyticsService());
  sl.registerLazySingleton<ReviewService>(() => ReviewService());
}

// ==========================================
// 2. AUTHENTICATION & ECONOMY FEATURE MODULE
// ==========================================
void _initAuthFeature() {
  // Data Source
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      googleSignIn: sl<GoogleSignIn>(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      firebaseAuth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
      storage: sl<FirebaseStorage>(),
    ),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
      storage: sl<FirebaseStorage>(),
    ),
  );
  sl.registerLazySingleton<GamificationRepository>(
    () => GamificationRepositoryImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );
  sl.registerLazySingleton<ShopRepository>(
    () => ShopRepositoryImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );
  sl.registerLazySingleton<LeaderboardRepository>(
    () => LeaderboardRepositoryImpl(sl<FirebaseFirestore>()),
  );

  // Use Cases
  sl.registerLazySingleton<SignUp>(() => SignUp(sl<AuthRepository>()));
  sl.registerLazySingleton<LogInWithEmail>(
    () => LogInWithEmail(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogInWithGoogle>(
    () => LogInWithGoogle(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ForgotPassword>(
    () => ForgotPassword(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogOut>(() => LogOut(sl<AuthRepository>()));
  sl.registerLazySingleton<GetUserStream>(
    () => GetUserStream(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<UpdateUserCoins>(
    () => UpdateUserCoins(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<UpdateCategoryStats>(
    () => UpdateCategoryStats(sl<GamificationRepository>()),
  );
  sl.registerLazySingleton<AwardBadge>(() => AwardBadge(sl<GamificationRepository>()));
  sl.registerLazySingleton<AwardKidsSticker>(
    () => AwardKidsSticker(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<UpdateKidsMascot>(
    () => UpdateKidsMascot(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<BuyKidsAccessory>(
    () => BuyKidsAccessory(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<EquipKidsAccessory>(
    () => EquipKidsAccessory(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<UpdateUnlockedLevel>(
    () => UpdateUnlockedLevel(sl<GamificationRepository>()),
  );
  sl.registerLazySingleton<SendEmailVerification>(
    () => SendEmailVerification(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ReloadUser>(() => ReloadUser(sl<AuthRepository>()));
  sl.registerLazySingleton<GetCurrentUser>(
    () => GetCurrentUser(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<UpdateUser>(() => UpdateUser(sl<UserRepository>()));
  sl.registerLazySingleton<ClaimVipGift>(
    () => ClaimVipGift(sl<UserRepository>()),
  );
  sl.registerLazySingleton<PurchaseHint>(
    () => PurchaseHint(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<UseHint>(() => UseHint(sl<ShopRepository>()));
  sl.registerLazySingleton<UseWritingHint>(
    () => UseWritingHint(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<UpdateUserRewards>(
    () => UpdateUserRewards(sl<GamificationRepository>()),
  );
  sl.registerLazySingleton<UpdateProfilePicture>(
    () => UpdateProfilePicture(sl<UserRepository>()),
  );
  sl.registerLazySingleton<UpdateDisplayName>(
    () => UpdateDisplayName(sl<UserRepository>()),
  );
  sl.registerLazySingleton<RepairStreak>(
    () => RepairStreak(sl<GamificationRepository>()),
  );
  sl.registerLazySingleton<PurchaseStreakFreeze>(
    () => PurchaseStreakFreeze(sl<GamificationRepository>()),
  );
  sl.registerLazySingleton<ActivateDoubleXP>(
    () => ActivateDoubleXP(sl<GamificationRepository>()),
  );
  sl.registerLazySingleton<DeleteAccount>(
    () => DeleteAccount(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ClaimDailyGift>(
    () => ClaimDailyGift(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<ClaimDailyChest>(
    () => ClaimDailyChest(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<ClaimKidsDailyReward>(
    () => ClaimKidsDailyReward(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<AwardKidsCoins>(
    () => AwardKidsCoins(sl<ShopRepository>()),
  );

  // Presentation BLoCs
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      getUserStream: sl<GetUserStream>(),
      logOut: sl<LogOut>(),
      reloadUser: sl<ReloadUser>(),
      deleteAccount: sl<DeleteAccount>(),
      forgotPassword: sl<ForgotPassword>(),
      getCurrentUser: sl<GetCurrentUser>(),
    ),
  );
  sl.registerLazySingleton<EconomyBloc>(
    () => EconomyBloc(
      updateUserCoins: sl<UpdateUserCoins>(),
      purchaseHint: sl<PurchaseHint>(),
      claimVipGift: sl<ClaimVipGift>(),
      claimDailyGift: sl<ClaimDailyGift>(),
      updateUser: sl<UpdateUser>(),
      claimDailyChest: sl<ClaimDailyChest>(),
      claimKidsDailyReward: sl<ClaimKidsDailyReward>(),
      awardKidsCoins: sl<AwardKidsCoins>(),
      useHint: sl<UseHint>(),
      authBloc: sl<AuthBloc>(),
    ),
  );
  sl.registerLazySingleton<ProgressionBloc>(
    () => ProgressionBloc(
      repairStreak: sl<RepairStreak>(),
      purchaseStreakFreeze: sl<PurchaseStreakFreeze>(),
      activateDoubleXP: sl<ActivateDoubleXP>(),
      updateUser: sl<UpdateUser>(),
      authBloc: sl<AuthBloc>(),
      notificationService: sl<NotificationService>(),
    ),
  );
  sl.registerLazySingleton<ProfileBloc>(
    () => ProfileBloc(
      updateDisplayName: sl<UpdateDisplayName>(),
      updateProfilePicture: sl<UpdateProfilePicture>(),
      updateKidsMascot: sl<UpdateKidsMascot>(),
      buyKidsAccessory: sl<BuyKidsAccessory>(),
      equipKidsAccessory: sl<EquipKidsAccessory>(),
      updateUser: sl<UpdateUser>(),
      authBloc: sl<AuthBloc>(),
    ),
  );

  sl.registerFactory<LoginCubit>(
    () => LoginCubit(
      logInWithEmail: sl<LogInWithEmail>(),
      logInWithGoogle: sl<LogInWithGoogle>(),
      forgotPassword: sl<ForgotPassword>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerFactory<SignUpCubit>(
    () => SignUpCubit(
      signUp: sl<SignUp>(),
      sendEmailVerification: sl<SendEmailVerification>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerFactory<ThemeCubit>(() => ThemeCubit());
  sl.registerFactory<LeaderboardBloc>(
    () => LeaderboardBloc(repository: sl<LeaderboardRepository>()),
  );
}

// ==========================================
// 3. READING QUEST MODULE
// ==========================================
void _initReadingFeature() {
  sl.registerLazySingleton<ReadingRemoteDataSource>(
    () => ReadingRemoteDataSourceImpl(sl<FirebaseFirestore>(), sl<AssetQuestService>()),
  );
  sl.registerLazySingleton<ReadingRepository>(
    () => ReadingRepositoryImpl(remoteDataSource: sl<ReadingRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetReadingQuest>(
    () => GetReadingQuest(sl<ReadingRepository>()),
  );
  sl.registerFactory<ReadingBloc>(
    () => ReadingBloc(
      getQuest: sl<GetReadingQuest>(),
      updateUserCoins: sl<UpdateUserCoins>(),
      updateUserRewards: sl<UpdateUserRewards>(),
      updateCategoryStats: sl<UpdateCategoryStats>(),
      updateUnlockedLevel: sl<UpdateUnlockedLevel>(),
      awardBadge: sl<AwardBadge>(),
      soundService: sl<SoundService>(),
      hapticService: sl<HapticService>(),
      useHint: sl<UseHint>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
}

// ==========================================
// 4. WRITING QUEST MODULE
// ==========================================
void _initWritingFeature() {
  sl.registerLazySingleton<WritingRemoteDataSource>(
    () => WritingRemoteDataSourceImpl(sl<FirebaseFirestore>(), sl<AssetQuestService>()),
  );
  sl.registerLazySingleton<WritingRepository>(
    () => WritingRepositoryImpl(remoteDataSource: sl<WritingRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetWritingQuest>(
    () => GetWritingQuest(sl<WritingRepository>()),
  );
  sl.registerFactory<WritingBloc>(
    () => WritingBloc(
      getQuest: sl<GetWritingQuest>(),
      updateUserCoins: sl<UpdateUserCoins>(),
      updateUserRewards: sl<UpdateUserRewards>(),
      updateCategoryStats: sl<UpdateCategoryStats>(),
      updateUnlockedLevel: sl<UpdateUnlockedLevel>(),
      awardBadge: sl<AwardBadge>(),
      soundService: sl<SoundService>(),
      hapticService: sl<HapticService>(),
      useHint: sl<UseHint>(),
    ),
  );
}

// ==========================================
// 5. SPEAKING QUEST MODULE
// ==========================================
void _initSpeakingFeature() {
  sl.registerLazySingleton<SpeakingRemoteDataSource>(
    () => SpeakingRemoteDataSourceImpl(sl<FirebaseFirestore>(), sl<AssetQuestService>()),
  );
  sl.registerLazySingleton<SpeakingRepository>(
    () => SpeakingRepositoryImpl(
      remoteDataSource: sl<SpeakingRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<GetSpeakingQuest>(
    () => GetSpeakingQuest(sl<SpeakingRepository>()),
  );
  sl.registerFactory<SpeakingBloc>(
    () => SpeakingBloc(
      getQuest: sl<GetSpeakingQuest>(),
      updateUserCoins: sl<UpdateUserCoins>(),
      updateUserRewards: sl<UpdateUserRewards>(),
      updateCategoryStats: sl<UpdateCategoryStats>(),
      updateUnlockedLevel: sl<UpdateUnlockedLevel>(),
      awardBadge: sl<AwardBadge>(),
      soundService: sl<SoundService>(),
      hapticService: sl<HapticService>(),
      useHint: sl<UseHint>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
}

// ==========================================
// 6. GRAMMAR QUEST MODULE
// ==========================================
void _initGrammarFeature() {
  sl.registerLazySingleton<GrammarRemoteDataSource>(
    () => GrammarRemoteDataSourceImpl(sl<FirebaseFirestore>(), sl<AssetQuestService>()),
  );
  sl.registerLazySingleton<GrammarRepository>(
    () => GrammarRepositoryImpl(remoteDataSource: sl<GrammarRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetGrammarQuest>(
    () => GetGrammarQuest(sl<GrammarRepository>()),
  );
  sl.registerLazySingleton<PreloadGrammarQuest>(
    () => PreloadGrammarQuest(sl<GrammarRepository>()),
  );
  sl.registerFactory<GrammarBloc>(
    () => GrammarBloc(
      getQuest: sl<GetGrammarQuest>(),
      preloadQuest: sl<PreloadGrammarQuest>(),
      updateUserCoins: sl<UpdateUserCoins>(),
      updateUserRewards: sl<UpdateUserRewards>(),
      updateCategoryStats: sl<UpdateCategoryStats>(),
      updateUnlockedLevel: sl<UpdateUnlockedLevel>(),
      awardBadge: sl<AwardBadge>(),
      soundService: sl<SoundService>(),
      hapticService: sl<HapticService>(),
      useHint: sl<UseHint>(),
    ),
  );
}

// ==========================================
// 7. ROLEPLAY QUEST MODULE
// ==========================================
void _initRoleplayFeature() {
  sl.registerLazySingleton<RoleplayRemoteDataSource>(
    () => RoleplayRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      assetQuestService: sl<AssetQuestService>(),
    ),
  );
  sl.registerLazySingleton<RoleplayRepository>(
    () => RoleplayRepositoryImpl(
      remoteDataSource: sl<RoleplayRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerLazySingleton<GetRoleplayQuest>(
    () => GetRoleplayQuest(sl<RoleplayRepository>()),
  );
  sl.registerLazySingleton<PreloadRoleplayQuests>(
    () => PreloadRoleplayQuests(sl<RoleplayRepository>()),
  );
  sl.registerFactory<RoleplayBloc>(
    () => RoleplayBloc(
      getQuest: sl<GetRoleplayQuest>(),
      preloadQuests: sl<PreloadRoleplayQuests>(),
      updateUserRewards: sl<UpdateUserRewards>(),
      updateCategoryStats: sl<UpdateCategoryStats>(),
      updateUnlockedLevel: sl<UpdateUnlockedLevel>(),
      awardBadge: sl<AwardBadge>(),
      soundService: sl<SoundService>(),
      hapticService: sl<HapticService>(),
      useHint: sl<UseHint>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
}

// ==========================================
// 8. ACCENT QUEST MODULE
// ==========================================
void _initAccentFeature() {
  sl.registerLazySingleton<AccentDataSource>(
    () => AccentDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      assetQuestService: sl<AssetQuestService>(),
    ),
  );
  sl.registerLazySingleton<AccentRepository>(
    () => AccentRepositoryImpl(
      remoteDataSource: sl<AccentDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerLazySingleton<GetAccentQuest>(
    () => GetAccentQuest(sl<AccentRepository>()),
  );
  sl.registerLazySingleton<PreloadAccentQuest>(
    () => PreloadAccentQuest(sl<AccentRepository>()),
  );
  sl.registerLazySingleton<ClearAccentQuestCache>(
    () => ClearAccentQuestCache(sl<AccentRepository>()),
  );
  sl.registerFactory<AccentBloc>(
    () => AccentBloc(
      getQuest: sl<GetAccentQuest>(),
      preloadQuest: sl<PreloadAccentQuest>(),
      clearCache: sl<ClearAccentQuestCache>(),
      updateUserCoins: sl<UpdateUserCoins>(),
      updateUserRewards: sl<UpdateUserRewards>(),
      updateCategoryStats: sl<UpdateCategoryStats>(),
      updateUnlockedLevel: sl<UpdateUnlockedLevel>(),
      awardBadge: sl<AwardBadge>(),
      soundService: sl<SoundService>(),
      hapticService: sl<HapticService>(),
      useHint: sl<UseHint>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
}

// ==========================================
// 9. LISTENING QUEST MODULE
// ==========================================
void _initListeningFeature() {
  sl.registerLazySingleton<ListeningRemoteDataSource>(
    () => ListeningRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      assetQuestService: sl<AssetQuestService>(),
    ),
  );
  sl.registerLazySingleton<ListeningRepository>(
    () => ListeningRepositoryImpl(
      remoteDataSource: sl<ListeningRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerLazySingleton<GetListeningQuests>(
    () => GetListeningQuests(sl<ListeningRepository>()),
  );
  sl.registerFactory<ListeningBloc>(
    () => ListeningBloc(
      getQuest: sl<GetListeningQuests>(),
      updateUserCoins: sl<UpdateUserCoins>(),
      updateUserRewards: sl<UpdateUserRewards>(),
      updateCategoryStats: sl<UpdateCategoryStats>(),
      updateUnlockedLevel: sl<UpdateUnlockedLevel>(),
      awardBadge: sl<AwardBadge>(),
      soundService: sl<SoundService>(),
      hapticService: sl<HapticService>(),
      useHint: sl<UseHint>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
}

// ==========================================
// 10. VOCABULARY QUEST MODULE
// ==========================================
void _initVocabularyFeature() {
  sl.registerLazySingleton<VocabularyRemoteDataSource>(
    () => VocabularyRemoteDataSourceImpl(sl<FirebaseFirestore>(), sl<AssetQuestService>()),
  );
  sl.registerLazySingleton<VocabularyRepository>(
    () => VocabularyRepositoryImpl(
      remoteDataSource: sl<VocabularyRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<GetVocabularyQuests>(
    () => GetVocabularyQuests(sl<VocabularyRepository>()),
  );
  sl.registerFactory<vocab.VocabularyBloc>(
    () => vocab.VocabularyBloc(
      getQuests: sl<GetVocabularyQuests>(),
      updateUserCoins: sl<UpdateUserCoins>(),
      updateUserRewards: sl<UpdateUserRewards>(),
      updateCategoryStats: sl<UpdateCategoryStats>(),
      updateUnlockedLevel: sl<UpdateUnlockedLevel>(),
      awardBadge: sl<AwardBadge>(),
      soundService: sl<SoundService>(),
      hapticService: sl<HapticService>(),
      useHint: sl<UseHint>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
}

// ==========================================
// 11. KIDS ZONE FEATURE MODULE
// ==========================================
void _initKidsZoneFeature() {
  sl.registerLazySingleton<KidsRemoteDataSource>(
    () => KidsRemoteDataSourceImpl(firestore: sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<KidsLocalDataSource>(
    () => KidsLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<KidsRepository>(
    () => KidsRepositoryImpl(
      remoteDataSource: sl<KidsRemoteDataSource>(),
      localDataSource: sl<KidsLocalDataSource>(),
    ),
  );
  sl.registerLazySingleton<GetKidsQuests>(() => GetKidsQuests(sl<KidsRepository>()));
  sl.registerFactory<KidsBloc>(
    () => KidsBloc(
      getKidsQuests: sl<GetKidsQuests>(),
      updateUserRewards: sl<UpdateUserRewards>(),
      updateUnlockedLevel: sl<UpdateUnlockedLevel>(),
      awardKidsSticker: sl<AwardKidsSticker>(),
      useHint: sl<UseHint>(),
      soundService: sl<SoundService>(),
      hapticService: sl<HapticService>(),
    ),
  );
}

// ==========================================
// 12. ELITE MASTERY FEATURE MODULE
// ==========================================
void _initEliteMasteryFeature() {
  sl.registerLazySingleton<EliteMasteryDataSource>(
    () => EliteMasteryDataSourceImpl(assetQuestService: sl<AssetQuestService>()),
  );
  sl.registerLazySingleton<EliteMasteryRepository>(
    () => EliteMasteryRepositoryImpl(dataSource: sl<EliteMasteryDataSource>()),
  );
  sl.registerLazySingleton<GetEliteMasteryQuests>(
    () => GetEliteMasteryQuests(sl<EliteMasteryRepository>()),
  );
  sl.registerFactory<EliteMasteryBloc>(
    () => EliteMasteryBloc(
      getQuests: sl<GetEliteMasteryQuests>(),
      updateUserRewards: sl<UpdateUserRewards>(),
      updateCategoryStats: sl<UpdateCategoryStats>(),
      updateUnlockedLevel: sl<UpdateUnlockedLevel>(),
      useHint: sl<UseHint>(),
      soundService: sl<SoundService>(),
      hapticService: sl<HapticService>(),
    ),
  );
}
