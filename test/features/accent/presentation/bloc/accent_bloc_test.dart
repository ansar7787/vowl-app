import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/domain/usecases/clear_accent_quest_cache.dart';
import 'package:vowl/features/accent/domain/usecases/get_accent_quest.dart';
import 'package:vowl/features/accent/domain/usecases/preload_accent_quest.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/auth/domain/usecases/award_badge.dart';
import 'package:vowl/features/auth/domain/usecases/update_category_stats.dart';
import 'package:vowl/features/auth/domain/usecases/update_unlocked_level.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';

class MockGetAccentQuest extends Mock implements GetAccentQuest {}
class MockPreloadAccentQuest extends Mock implements PreloadAccentQuest {}
class MockClearAccentQuestCache extends Mock implements ClearAccentQuestCache {}
class MockUpdateUserCoins extends Mock implements UpdateUserCoins {}
class MockUpdateUserRewards extends Mock implements UpdateUserRewards {}
class MockUpdateCategoryStats extends Mock implements UpdateCategoryStats {}
class MockUpdateUnlockedLevel extends Mock implements UpdateUnlockedLevel {}
class MockAwardBadge extends Mock implements AwardBadge {}
class MockSoundService extends Mock implements SoundService {}
class MockHapticService extends Mock implements HapticService {}
class MockUseHint extends Mock implements UseHint {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeGetAccentQuestParams extends Fake implements GetAccentQuestParams {}
class FakeUpdateUserRewardsParams extends Fake implements UpdateUserRewardsParams {}
class FakeUpdateCategoryStatsParams extends Fake implements UpdateCategoryStatsParams {}
class FakeUpdateUnlockedLevelParams extends Fake implements UpdateUnlockedLevelParams {}

void main() {
  late AccentBloc bloc;
  late MockGetAccentQuest mockGetQuest;
  late MockPreloadAccentQuest mockPreloadQuest;
  late MockClearAccentQuestCache mockClearCache;
  late MockUpdateUserCoins mockUpdateUserCoins;
  late MockUpdateUserRewards mockUpdateUserRewards;
  late MockUpdateCategoryStats mockUpdateCategoryStats;
  late MockUpdateUnlockedLevel mockUpdateUnlockedLevel;
  late MockAwardBadge mockAwardBadge;
  late MockSoundService mockSoundService;
  late MockHapticService mockHapticService;
  late MockUseHint mockUseHint;
  late MockNetworkInfo mockNetworkInfo;

  setUpAll(() {
    registerFallbackValue(FakeGetAccentQuestParams());
    registerFallbackValue(FakeUpdateUserRewardsParams());
    registerFallbackValue(FakeUpdateCategoryStatsParams());
    registerFallbackValue(FakeUpdateUnlockedLevelParams());
    registerFallbackValue(GameSubtype.accentShadowing);
  });

  setUp(() {
    mockGetQuest = MockGetAccentQuest();
    mockPreloadQuest = MockPreloadAccentQuest();
    mockClearCache = MockClearAccentQuestCache();
    mockUpdateUserCoins = MockUpdateUserCoins();
    mockUpdateUserRewards = MockUpdateUserRewards();
    mockUpdateCategoryStats = MockUpdateCategoryStats();
    mockUpdateUnlockedLevel = MockUpdateUnlockedLevel();
    mockAwardBadge = MockAwardBadge();
    mockSoundService = MockSoundService();
    mockHapticService = MockHapticService();
    mockUseHint = MockUseHint();
    mockNetworkInfo = MockNetworkInfo();

    bloc = AccentBloc(
      getQuest: mockGetQuest,
      preloadQuest: mockPreloadQuest,
      clearCache: mockClearCache,
      updateUserCoins: mockUpdateUserCoins,
      updateUserRewards: mockUpdateUserRewards,
      updateCategoryStats: mockUpdateCategoryStats,
      updateUnlockedLevel: mockUpdateUnlockedLevel,
      awardBadge: mockAwardBadge,
      soundService: mockSoundService,
      hapticService: mockHapticService,
      useHint: mockUseHint,
      networkInfo: mockNetworkInfo,
    );
  });

  tearDown(() {
    bloc.close();
  });

  const tGameType = GameSubtype.accentShadowing;
  const tLevel = 1;
  const tQuests = [
    AccentQuest(id: '1', instruction: 'i1', difficulty: 1),
    AccentQuest(id: '2', instruction: 'i2', difficulty: 1),
    AccentQuest(id: '3', instruction: 'i3', difficulty: 1),
  ];

  group('FetchAccentQuests', () {
    blocTest<AccentBloc, AccentState>(
      'should emit [Loading, Loaded] when data is fetched successfully',
      build: () {
        when(() => mockGetQuest(any())).thenAnswer((_) async => const Right(tQuests));
        return bloc;
      },
      act: (bloc) => bloc.add(FetchAccentQuests(gameType: tGameType, level: tLevel)),
      expect: () => [
        AccentLoading(),
        AccentLoaded(quests: tQuests, currentIndex: 0, livesRemaining: 3, gameType: tGameType, level: tLevel),
      ],
    );
  });

  group('SubmitAnswer', () {
    final tLoadedState = AccentLoaded(
      quests: tQuests,
      currentIndex: 0,
      livesRemaining: 3,
      gameType: tGameType,
      level: tLevel,
    );

    blocTest<AccentBloc, AccentState>(
      'should emit state with lastAnswerCorrect: true when correct',
      build: () {
        when(() => mockSoundService.playCorrect()).thenAnswer((_) async => {});
        when(() => mockHapticService.success()).thenAnswer((_) async => {});
        return bloc;
      },
      seed: () => tLoadedState,
      act: (bloc) => bloc.add(SubmitAnswer(true)),
      expect: () => [
        tLoadedState.copyWith(lastAnswerCorrect: true),
      ],
    );

    blocTest<AccentBloc, AccentState>(
      'should increment wrongCount when incorrect (first strike)',
      build: () {
        when(() => mockSoundService.playWrong()).thenAnswer((_) async => {});
        when(() => mockHapticService.error()).thenAnswer((_) async => {});
        return bloc;
      },
      seed: () => tLoadedState,
      act: (bloc) => bloc.add(SubmitAnswer(false)),
      expect: () => [
        tLoadedState.copyWith(
          livesRemaining: 2,
          lastAnswerCorrect: false,
          wrongCount: 1,
          isFinalFailure: false,
        ),
      ],
    );

    blocTest<AccentBloc, AccentState>(
      'should re-queue quest and set isFinalFailure on second strike',
      build: () {
        when(() => mockSoundService.playWrong()).thenAnswer((_) async => {});
        when(() => mockHapticService.error()).thenAnswer((_) async => {});
        return bloc;
      },
      seed: () => tLoadedState.copyWith(wrongCount: 1, livesRemaining: 2),
      act: (bloc) => bloc.add(SubmitAnswer(false)),
      expect: () => [
        tLoadedState.copyWith(
          livesRemaining: 1,
          lastAnswerCorrect: false,
          wrongCount: 0,
          isFinalFailure: true,
          quests: [...tQuests, tQuests[0]],
        ),
      ],
    );
  });
}
