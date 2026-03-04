import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:voxai_quest/core/network/network_info.dart';
import 'package:voxai_quest/core/utils/seeding_service.dart';
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/local_smart_tutor.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/content_generation_service.dart';
import 'package:voxai_quest/core/utils/payment_service.dart';
import 'package:voxai_quest/core/utils/speech_service.dart';
import 'package:voxai_quest/core/utils/quest_upload_service.dart';
import 'package:voxai_quest/core/utils/tts_service.dart';
import 'package:voxai_quest/core/data/services/asset_quest_service.dart';
import 'package:voxai_quest/core/theme/theme_cubit.dart';
import 'package:voxai_quest/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:voxai_quest/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:voxai_quest/features/auth/domain/repositories/auth_repository.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voxai_quest/features/reading/domain/repositories/reading_repository.dart';
import 'package:voxai_quest/features/reading/data/repositories/reading_repository_impl.dart';
import 'package:voxai_quest/features/reading/data/datasources/reading_remote_data_source.dart';
import 'package:voxai_quest/features/reading/domain/usecases/get_reading_quest.dart';

import 'package:voxai_quest/features/writing/domain/repositories/writing_repository.dart';
import 'package:voxai_quest/features/writing/data/repositories/writing_repository_impl.dart';
import 'package:voxai_quest/features/writing/data/datasources/writing_remote_data_source.dart';
import 'package:voxai_quest/features/writing/domain/usecases/get_writing_quest.dart';
import 'package:voxai_quest/features/writing/domain/usecases/use_writing_hint.dart';

import 'package:voxai_quest/features/speaking/domain/repositories/speaking_repository.dart';
import 'package:voxai_quest/features/speaking/data/repositories/speaking_repository_impl.dart';
import 'package:voxai_quest/features/speaking/data/datasources/speaking_remote_data_source.dart';
import 'package:voxai_quest/features/speaking/domain/usecases/get_speaking_quest.dart';

import 'package:voxai_quest/features/roleplay/domain/repositories/roleplay_repository.dart';
import 'package:voxai_quest/features/roleplay/data/repositories/roleplay_repository_impl.dart';
import 'package:voxai_quest/features/roleplay/data/datasources/roleplay_remote_data_source.dart';
import 'package:voxai_quest/features/roleplay/domain/usecases/get_roleplay_quest.dart';

import 'package:voxai_quest/features/accent/domain/repositories/accent_repository.dart';
import 'package:voxai_quest/features/accent/data/repositories/accent_repository_impl.dart';
import 'package:voxai_quest/features/accent/data/datasources/accent_data_source.dart';
import 'package:voxai_quest/features/accent/domain/usecases/get_accent_quest.dart';
import 'package:voxai_quest/features/accent/domain/usecases/preload_accent_quest.dart';
import 'package:voxai_quest/features/accent/domain/usecases/clear_accent_quest_cache.dart';

import 'package:voxai_quest/features/listening/domain/repositories/listening_repository.dart';
import 'package:voxai_quest/features/listening/data/repositories/listening_repository_impl.dart';
import 'package:voxai_quest/features/listening/data/datasources/listening_remote_data_source.dart';
import 'package:voxai_quest/features/listening/domain/usecases/get_listening_quests.dart';

import 'package:voxai_quest/features/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:voxai_quest/features/vocabulary/data/repositories/vocabulary_repository_impl.dart';
import 'package:voxai_quest/features/vocabulary/data/datasources/vocabulary_remote_data_source.dart';
import 'package:voxai_quest/features/vocabulary/domain/usecases/get_vocabulary_quests.dart';

import 'package:voxai_quest/features/grammar/domain/repositories/grammar_repository.dart';

import 'package:voxai_quest/features/grammar/data/repositories/grammar_repository_impl.dart';
import 'package:voxai_quest/features/grammar/data/datasources/grammar_remote_data_source.dart';
import 'package:voxai_quest/features/grammar/domain/usecases/get_grammar_quest.dart';
import 'package:voxai_quest/features/grammar/domain/usecases/preload_grammar_quest.dart';

import 'package:voxai_quest/features/auth/domain/usecases/sign_up.dart';
import 'package:voxai_quest/features/auth/domain/usecases/log_in_with_email.dart';
import 'package:voxai_quest/features/auth/domain/usecases/log_in_with_google.dart';
import 'package:voxai_quest/features/auth/domain/usecases/log_out.dart';
import 'package:voxai_quest/features/auth/domain/usecases/get_user_stream.dart';
import 'package:voxai_quest/features/auth/domain/usecases/update_user_coins.dart';
import 'package:voxai_quest/features/auth/domain/usecases/update_category_stats.dart';
import 'package:voxai_quest/features/auth/domain/usecases/award_badge.dart'; // New
import 'package:voxai_quest/features/auth/domain/usecases/forgot_password.dart';
import 'package:voxai_quest/features/auth/domain/usecases/send_email_verification.dart';
import 'package:voxai_quest/features/auth/domain/usecases/reload_user.dart';
import 'package:voxai_quest/features/auth/domain/usecases/get_current_user.dart';
import 'package:voxai_quest/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:voxai_quest/features/auth/domain/usecases/update_user.dart'; // New
import 'package:voxai_quest/features/auth/domain/usecases/claim_vip_gift.dart';
import 'package:voxai_quest/features/auth/domain/usecases/purchase_hint.dart';
import 'package:voxai_quest/features/auth/domain/usecases/use_hint.dart';
import 'package:voxai_quest/features/auth/domain/usecases/update_profile_picture.dart';
import 'package:voxai_quest/features/auth/domain/usecases/update_display_name.dart';
import 'package:voxai_quest/features/auth/domain/usecases/repair_streak.dart';
import 'package:voxai_quest/features/auth/domain/usecases/purchase_streak_freeze.dart';
import 'package:voxai_quest/features/auth/domain/usecases/activate_double_xp.dart';

import 'package:voxai_quest/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:voxai_quest/features/leaderboard/data/repositories/leaderboard_repository_impl.dart';
// Feature Blocs
import 'package:voxai_quest/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:voxai_quest/features/kids_zone/presentation/utils/kids_audio_service.dart';
import 'package:voxai_quest/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:voxai_quest/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:voxai_quest/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:voxai_quest/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:voxai_quest/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:voxai_quest/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:voxai_quest/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:voxai_quest/features/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/login_cubit.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/signup_cubit.dart';
import 'package:voxai_quest/features/vocabulary/presentation/bloc/vocabulary_bloc.dart'
    as vocab;

import 'package:voxai_quest/features/auth/domain/usecases/update_unlocked_level.dart';
import 'package:voxai_quest/features/auth/domain/usecases/award_kids_sticker.dart';
import 'package:voxai_quest/features/auth/domain/usecases/update_kids_mascot.dart';
import 'package:voxai_quest/features/auth/domain/usecases/buy_kids_accessory.dart';
import 'package:voxai_quest/features/auth/domain/usecases/equip_kids_accessory.dart';
import 'package:voxai_quest/features/auth/domain/usecases/delete_account.dart';

import 'package:voxai_quest/features/kids_zone/domain/repositories/kids_repository.dart';
import 'package:voxai_quest/features/kids_zone/data/repositories/kids_repository_impl.dart';
import 'package:voxai_quest/features/kids_zone/data/datasources/kids_remote_data_source.dart';
import 'package:voxai_quest/features/kids_zone/domain/usecases/get_kids_quests.dart';
import 'package:voxai_quest/features/kids_zone/presentation/bloc/kids_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
  sl.registerLazySingleton(() => InternetConnection());

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<SeedingService>(() => SeedingService(sl()));
  sl.registerLazySingleton(() => SoundService());
  sl.registerLazySingleton(() => HapticService());
  sl.registerLazySingleton(() => LocalSmartTutor());
  sl.registerLazySingleton(() => AdService());
  sl.registerLazySingleton(
    () => PaymentService(authRepository: sl(), firestore: sl()),
  );
  sl.registerLazySingleton(() => SpeechService());
  sl.registerLazySingleton(() => ContentGenerationService());
  sl.registerLazySingleton(() => QuestUploadService());
  sl.registerLazySingleton(() => TtsService());
  sl.registerLazySingleton(() => KidsTTSService());
  sl.registerLazySingleton(() => KidsAudioService());
  sl.registerLazySingleton(() => AssetQuestService());

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      googleSignIn: sl<GoogleSignIn>(),
    ),
  );
  sl.registerLazySingleton<ReadingRemoteDataSource>(
    () => ReadingRemoteDataSourceImpl(sl<FirebaseFirestore>(), sl()),
  );
  sl.registerLazySingleton<WritingRemoteDataSource>(
    () => WritingRemoteDataSourceImpl(sl<FirebaseFirestore>(), sl()),
  );
  sl.registerLazySingleton<SpeakingRemoteDataSource>(
    () => SpeakingRemoteDataSourceImpl(sl<FirebaseFirestore>(), sl()),
  );
  sl.registerLazySingleton<GrammarRemoteDataSource>(
    () => GrammarRemoteDataSourceImpl(sl<FirebaseFirestore>(), sl()),
  );
  sl.registerLazySingleton<RoleplayRemoteDataSource>(
    () => RoleplayRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      assetQuestService: sl(),
    ),
  );
  sl.registerLazySingleton<AccentDataSource>(
    () => AccentDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      assetQuestService: sl(),
    ),
  );
  sl.registerLazySingleton<ListeningRemoteDataSource>(
    () => ListeningRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      assetQuestService: sl(),
    ),
  );
  sl.registerLazySingleton<VocabularyRemoteDataSource>(
    () => VocabularyRemoteDataSourceImpl(sl<FirebaseFirestore>(), sl()),
  );
  sl.registerLazySingleton<KidsRemoteDataSource>(
    () => KidsRemoteDataSourceImpl(firestore: sl()),
  );

  // Use Cases
  sl.registerLazySingleton<GetReadingQuest>(
    () => GetReadingQuest(sl<ReadingRepository>()),
  );
  sl.registerLazySingleton<GetWritingQuest>(
    () => GetWritingQuest(sl<WritingRepository>()),
  );
  sl.registerLazySingleton<GetSpeakingQuest>(
    () => GetSpeakingQuest(sl<SpeakingRepository>()),
  );
  sl.registerLazySingleton<GetGrammarQuest>(
    () => GetGrammarQuest(sl<GrammarRepository>()),
  );
  sl.registerLazySingleton<PreloadGrammarQuest>(
    () => PreloadGrammarQuest(sl<GrammarRepository>()),
  );
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
    () => UpdateUserCoins(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<UpdateCategoryStats>(
    () => UpdateCategoryStats(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<AwardBadge>(() => AwardBadge(sl<AuthRepository>()));
  sl.registerLazySingleton<AwardKidsSticker>(
    () => AwardKidsSticker(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<UpdateKidsMascot>(
    () => UpdateKidsMascot(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<BuyKidsAccessory>(
    () => BuyKidsAccessory(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<EquipKidsAccessory>(
    () => EquipKidsAccessory(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<UpdateUnlockedLevel>(
    () => UpdateUnlockedLevel(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<SendEmailVerification>(
    () => SendEmailVerification(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ReloadUser>(() => ReloadUser(sl<AuthRepository>()));
  sl.registerLazySingleton<GetCurrentUser>(
    () => GetCurrentUser(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<UpdateUser>(() => UpdateUser(sl<AuthRepository>()));
  sl.registerLazySingleton<ClaimVipGift>(
    () => ClaimVipGift(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<PurchaseHint>(
    () => PurchaseHint(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<UseHint>(() => UseHint(sl<AuthRepository>()));
  sl.registerLazySingleton<UseWritingHint>(
    () => UseWritingHint(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<UpdateUserRewards>(
    () => UpdateUserRewards(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetRoleplayQuest>(
    () => GetRoleplayQuest(sl<RoleplayRepository>()),
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
  sl.registerLazySingleton<GetListeningQuests>(
    () => GetListeningQuests(sl<ListeningRepository>()),
  );
  sl.registerLazySingleton<GetVocabularyQuests>(
    () => GetVocabularyQuests(sl<VocabularyRepository>()),
  );
  sl.registerLazySingleton<UpdateProfilePicture>(
    () => UpdateProfilePicture(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<UpdateDisplayName>(
    () => UpdateDisplayName(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<RepairStreak>(
    () => RepairStreak(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<PurchaseStreakFreeze>(
    () => PurchaseStreakFreeze(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ActivateDoubleXP>(
    () => ActivateDoubleXP(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<DeleteAccount>(
    () => DeleteAccount(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetKidsQuests>(() => GetKidsQuests(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      firebaseAuth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
      storage: sl<FirebaseStorage>(),
    ),
  );
  sl.registerLazySingleton<ReadingRepository>(
    () =>
        ReadingRepositoryImpl(remoteDataSource: sl<ReadingRemoteDataSource>()),
  );
  sl.registerLazySingleton<WritingRepository>(
    () =>
        WritingRepositoryImpl(remoteDataSource: sl<WritingRemoteDataSource>()),
  );
  sl.registerLazySingleton<SpeakingRepository>(
    () => SpeakingRepositoryImpl(
      remoteDataSource: sl<SpeakingRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<GrammarRepository>(
    () =>
        GrammarRepositoryImpl(remoteDataSource: sl<GrammarRemoteDataSource>()),
  );
  sl.registerLazySingleton<LeaderboardRepository>(
    () => LeaderboardRepositoryImpl(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<RoleplayRepository>(
    () => RoleplayRepositoryImpl(
      remoteDataSource: sl<RoleplayRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerLazySingleton<AccentRepository>(
    () => AccentRepositoryImpl(
      remoteDataSource: sl<AccentDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerLazySingleton<ListeningRepository>(
    () => ListeningRepositoryImpl(
      remoteDataSource: sl<ListeningRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerLazySingleton<VocabularyRepository>(
    () => VocabularyRepositoryImpl(
      remoteDataSource: sl<VocabularyRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<KidsRepository>(
    () => KidsRepositoryImpl(remoteDataSource: sl()),
  );

  // --- Blocs ---
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      getUserStream: sl<GetUserStream>(),
      logOut: sl<LogOut>(),
      reloadUser: sl<ReloadUser>(),
      getCurrentUser: sl<GetCurrentUser>(),
      updateUser: sl<UpdateUser>(),
      claimVipGift: sl<ClaimVipGift>(),
      purchaseHint: sl<PurchaseHint>(),
      updateUserCoins: sl<UpdateUserCoins>(),
      updateProfilePicture: sl<UpdateProfilePicture>(),
      updateDisplayName: sl<UpdateDisplayName>(),
      updateKidsMascot: sl<UpdateKidsMascot>(),
      buyKidsAccessory: sl<BuyKidsAccessory>(),
      equipKidsAccessory: sl<EquipKidsAccessory>(),
      repairStreak: sl<RepairStreak>(),
      purchaseStreakFreeze: sl<PurchaseStreakFreeze>(),
      activateDoubleXP: sl<ActivateDoubleXP>(),
      deleteAccount: sl<DeleteAccount>(),
      forgotPassword: sl<ForgotPassword>(),
      networkInfo: sl<NetworkInfo>(),
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
  sl.registerFactory<WritingBloc>(
    () => WritingBloc(
      getQuest: sl<GetWritingQuest>(),
      updateUserCoins: sl<UpdateUserCoins>(),
      updateUserRewards: sl<UpdateUserRewards>(),
      updateCategoryStats: sl<UpdateCategoryStats>(),
      updateUnlockedLevel: sl<UpdateUnlockedLevel>(),
      awardBadge: sl<AwardBadge>(),
      soundService: sl<SoundService>(),
      hapticService: sl(),
      useHint: sl<UseWritingHint>(),
    ),
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
  sl.registerFactory<RoleplayBloc>(
    () => RoleplayBloc(
      getQuest: sl<GetRoleplayQuest>(),
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
  sl.registerFactory<KidsBloc>(
    () => KidsBloc(
      getKidsQuests: sl(),
      updateUserRewards: sl(),
      updateUnlockedLevel: sl(),
      awardKidsSticker: sl(),
      soundService: sl(),
      hapticService: sl(),
    ),
  );
}
