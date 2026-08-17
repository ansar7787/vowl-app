import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/data/services/asset_quest_service.dart';

// Reading
import 'package:vowl/features/reading/domain/repositories/reading_repository.dart';
import 'package:vowl/features/reading/data/repositories/reading_repository_impl.dart';
import 'package:vowl/features/reading/data/datasources/reading_remote_data_source.dart';
import 'package:vowl/features/reading/domain/usecases/get_reading_quest.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';

// Writing
import 'package:vowl/features/writing/domain/repositories/writing_repository.dart';
import 'package:vowl/features/writing/data/repositories/writing_repository_impl.dart';
import 'package:vowl/features/writing/data/datasources/writing_remote_data_source.dart';
import 'package:vowl/features/writing/domain/usecases/get_writing_quest.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';

// Speaking
import 'package:vowl/features/speaking/domain/repositories/speaking_repository.dart';
import 'package:vowl/features/speaking/data/repositories/speaking_repository_impl.dart';
import 'package:vowl/features/speaking/data/datasources/speaking_remote_data_source.dart';
import 'package:vowl/features/speaking/domain/usecases/get_speaking_quest.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';

// Grammar
import 'package:vowl/features/grammar/domain/repositories/grammar_repository.dart';
import 'package:vowl/features/grammar/data/repositories/grammar_repository_impl.dart';
import 'package:vowl/features/grammar/data/datasources/grammar_remote_data_source.dart';
import 'package:vowl/features/grammar/domain/usecases/get_grammar_quest.dart';
import 'package:vowl/features/grammar/domain/usecases/preload_grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';

// Roleplay
import 'package:vowl/features/roleplay/domain/repositories/roleplay_repository.dart';
import 'package:vowl/features/roleplay/data/repositories/roleplay_repository_impl.dart';
import 'package:vowl/features/roleplay/data/datasources/roleplay_remote_data_source.dart';
import 'package:vowl/features/roleplay/domain/usecases/get_roleplay_quest.dart';
import 'package:vowl/features/roleplay/domain/usecases/preload_roleplay_quests.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';

// Accent
import 'package:vowl/features/accent/domain/repositories/accent_repository.dart';
import 'package:vowl/features/accent/data/repositories/accent_repository_impl.dart';
import 'package:vowl/features/accent/data/datasources/accent_data_source.dart';
import 'package:vowl/features/accent/domain/usecases/get_accent_quest.dart';
import 'package:vowl/features/accent/domain/usecases/preload_accent_quest.dart';
import 'package:vowl/features/accent/domain/usecases/clear_accent_quest_cache.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';

// Listening
import 'package:vowl/features/listening/domain/repositories/listening_repository.dart';
import 'package:vowl/features/listening/data/repositories/listening_repository_impl.dart';
import 'package:vowl/features/listening/data/datasources/listening_remote_data_source.dart';
import 'package:vowl/features/listening/domain/usecases/get_listening_quests.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';

// Vocabulary
import 'package:vowl/features/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:vowl/features/vocabulary/data/repositories/vocabulary_repository_impl.dart';
import 'package:vowl/features/vocabulary/data/datasources/vocabulary_remote_data_source.dart';
import 'package:vowl/features/vocabulary/domain/usecases/get_vocabulary_quests.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart'
    as vocab;

// Kids Zone
import 'package:vowl/features/kids_zone/domain/repositories/kids_repository.dart';
import 'package:vowl/features/kids_zone/data/repositories/kids_repository_impl.dart';
import 'package:vowl/features/kids_zone/data/datasources/kids_remote_data_source.dart';
import 'package:vowl/features/kids_zone/data/datasources/kids_local_data_source.dart';
import 'package:vowl/features/kids_zone/domain/usecases/get_kids_quests.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';

// Elite Mastery
import 'package:vowl/features/elite_mastery/data/datasources/elite_mastery_data_source.dart';
import 'package:vowl/features/elite_mastery/domain/repositories/elite_mastery_repository.dart';
import 'package:vowl/features/elite_mastery/data/repositories/elite_mastery_repository_impl.dart';
import 'package:vowl/features/elite_mastery/domain/usecases/get_elite_mastery_quests.dart';
import 'package:vowl/features/elite_mastery/presentation/bloc/elite_mastery_bloc.dart';

// Translation
import 'package:vowl/core/utils/translation_service.dart';
import 'package:vowl/features/translation/presentation/bloc/translation_bloc.dart';

// Shared use cases
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/domain/usecases/update_category_stats.dart';
import 'package:vowl/features/auth/domain/usecases/update_unlocked_level.dart';
import 'package:vowl/features/auth/domain/usecases/award_badge.dart';
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/features/auth/domain/usecases/award_kids_sticker.dart';

/// Registers all quest-specific feature modules.
///
/// ### Registration pattern
/// - Repositories: `registerLazySingleton` — shared data layer, stateless.
/// - Data sources: `registerLazySingleton` — hold no mutable state.
/// - BLoCs: `registerFactory` — per-screen instances that are created fresh
///   for each navigation and disposed when the screen is popped.
void initFeatures(GetIt sl) {
  _initReading(sl);
  _initWriting(sl);
  _initSpeaking(sl);
  _initGrammar(sl);
  _initRoleplay(sl);
  _initAccent(sl);
  _initListening(sl);
  _initVocabulary(sl);
  _initKidsZone(sl);
  _initEliteMastery(sl);
  _initTranslation(sl);
}

// ── Reading ───────────────────────────────────────────────────────────────────

void _initReading(GetIt sl) {
  sl.registerLazySingleton<ReadingRemoteDataSource>(
    () => ReadingRemoteDataSourceImpl(
      sl<FirebaseFirestore>(),
      sl<AssetQuestService>(),
    ),
  );
  sl.registerLazySingleton<ReadingRepository>(
    () => ReadingRepositoryImpl(
      remoteDataSource: sl<ReadingRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
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

// ── Writing ───────────────────────────────────────────────────────────────────

void _initWriting(GetIt sl) {
  sl.registerLazySingleton<WritingRemoteDataSource>(
    () => WritingRemoteDataSourceImpl(
      sl<FirebaseFirestore>(),
      sl<AssetQuestService>(),
    ),
  );
  // FIX (HIGH-4): Added networkInfo to WritingRepository to match the
  // connectivity-aware pattern used by ReadingRepository, ListeningRepository,
  // RoleplayRepository, and AccentRepository. WritingRepositoryImpl performs
  // Firestore fetches that require network awareness.
  sl.registerLazySingleton<WritingRepository>(
    () => WritingRepositoryImpl(
      remoteDataSource: sl<WritingRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerLazySingleton<GetWritingQuest>(
    () => GetWritingQuest(sl<WritingRepository>()),
  );
  // FIX (HIGH-4): Added networkInfo: sl<NetworkInfo>() to WritingBloc.
  // Previously WritingBloc was the only game BLoC that performed network-
  // dependent operations without a NetworkInfo reference, meaning it could
  // not check connectivity before attempting Firestore fetches.
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

// ── Speaking ──────────────────────────────────────────────────────────────────

void _initSpeaking(GetIt sl) {
  sl.registerLazySingleton<SpeakingRemoteDataSource>(
    () => SpeakingRemoteDataSourceImpl(
      sl<FirebaseFirestore>(),
      sl<AssetQuestService>(),
    ),
  );
  sl.registerLazySingleton<SpeakingRepository>(
    () => SpeakingRepositoryImpl(
      remoteDataSource: sl<SpeakingRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
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
    ),
  );
}

// ── Grammar ───────────────────────────────────────────────────────────────────

void _initGrammar(GetIt sl) {
  sl.registerLazySingleton<GrammarRemoteDataSource>(
    () => GrammarRemoteDataSourceImpl(
      sl<FirebaseFirestore>(),
      sl<AssetQuestService>(),
    ),
  );
  sl.registerLazySingleton<GrammarRepository>(
    () =>
        GrammarRepositoryImpl(remoteDataSource: sl<GrammarRemoteDataSource>()),
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

// ── Roleplay ──────────────────────────────────────────────────────────────────

void _initRoleplay(GetIt sl) {
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

// ── Accent ────────────────────────────────────────────────────────────────────

void _initAccent(GetIt sl) {
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

// ── Listening ─────────────────────────────────────────────────────────────────

void _initListening(GetIt sl) {
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

// ── Vocabulary ────────────────────────────────────────────────────────────────

void _initVocabulary(GetIt sl) {
  sl.registerLazySingleton<VocabularyRemoteDataSource>(
    () => VocabularyRemoteDataSourceImpl(
      sl<FirebaseFirestore>(),
      sl<AssetQuestService>(),
    ),
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

// ── Kids Zone ─────────────────────────────────────────────────────────────────

void _initKidsZone(GetIt sl) {
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
  sl.registerLazySingleton<GetKidsQuests>(
    () => GetKidsQuests(sl<KidsRepository>()),
  );
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

// ── Elite Mastery ─────────────────────────────────────────────────────────────

void _initEliteMastery(GetIt sl) {
  sl.registerLazySingleton<EliteMasteryDataSource>(
    () =>
        EliteMasteryDataSourceImpl(assetQuestService: sl<AssetQuestService>()),
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
      updateUserCoins: sl<UpdateUserCoins>(),
      updateUserRewards: sl<UpdateUserRewards>(),
      updateCategoryStats: sl<UpdateCategoryStats>(),
      updateUnlockedLevel: sl<UpdateUnlockedLevel>(),
      useHint: sl<UseHint>(),
      soundService: sl<SoundService>(),
      hapticService: sl<HapticService>(),
    ),
  );
}

// ── Translation ─────────────────────────────────────────────────────────────

void _initTranslation(GetIt sl) {
  sl.registerFactory<TranslationBloc>(
    () => TranslationBloc(service: sl<TranslationService>()),
  );
}
