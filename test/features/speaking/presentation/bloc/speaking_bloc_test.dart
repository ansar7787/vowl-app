import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/usecases/award_badge.dart';
import 'package:vowl/features/auth/domain/usecases/update_category_stats.dart';
import 'package:vowl/features/auth/domain/usecases/update_unlocked_level.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/domain/usecases/get_speaking_quest.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';

class MockGetSpeakingQuest extends Mock implements GetSpeakingQuest {}
class MockUpdateUserCoins extends Mock implements UpdateUserCoins {}
class MockUpdateUserRewards extends Mock implements UpdateUserRewards {}
class MockUpdateCategoryStats extends Mock implements UpdateCategoryStats {}
class MockUpdateUnlockedLevel extends Mock implements UpdateUnlockedLevel {}
class MockAwardBadge extends Mock implements AwardBadge {}
class MockSoundService extends Mock implements SoundService {}
class MockHapticService extends Mock implements HapticService {}
class MockUseHint extends Mock implements UseHint {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeQuestParams extends Fake implements QuestParams {}
class FakeUpdateUserRewardsParams extends Fake implements UpdateUserRewardsParams {}
class FakeUpdateCategoryStatsParams extends Fake implements UpdateCategoryStatsParams {}
class FakeUpdateUnlockedLevelParams extends Fake implements UpdateUnlockedLevelParams {}

void main() {
  late SpeakingBloc bloc;
  late MockGetSpeakingQuest mockGetQuest;
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
    registerFallbackValue(FakeQuestParams());
    registerFallbackValue(FakeUpdateUserRewardsParams());
    registerFallbackValue(FakeUpdateCategoryStatsParams());
    registerFallbackValue(FakeUpdateUnlockedLevelParams());
    registerFallbackValue(GameSubtype.repeatSentence);
  });

  setUp(() {
    mockGetQuest = MockGetSpeakingQuest();
    mockUpdateUserCoins = MockUpdateUserCoins();
    mockUpdateUserRewards = MockUpdateUserRewards();
    mockUpdateCategoryStats = MockUpdateCategoryStats();
    mockUpdateUnlockedLevel = MockUpdateUnlockedLevel();
    mockAwardBadge = MockAwardBadge();
    mockSoundService = MockSoundService();
    mockHapticService = MockHapticService();
    mockUseHint = MockUseHint();
    mockNetworkInfo = MockNetworkInfo();

    bloc = SpeakingBloc(
      getQuest: mockGetQuest,
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

  const tGameType = GameSubtype.repeatSentence;
  const tLevel = 1;
  const tQuests = [
    SpeakingQuest(id: '1', instruction: 'i1', difficulty: 1),
    SpeakingQuest(id: '2', instruction: 'i2', difficulty: 1),
    SpeakingQuest(id: '3', instruction: 'i3', difficulty: 1),
  ];

  group('FetchSpeakingQuests', () {
    blocTest<SpeakingBloc, SpeakingState>(
      'should emit [Loading, Loaded] when data is fetched successfully',
      build: () {
        when(() => mockGetQuest(any())).thenAnswer((_) async => const Right(tQuests));
        return bloc;
      },
      act: (bloc) => bloc.add(FetchSpeakingQuests(gameType: tGameType, level: tLevel)),
      expect: () => [
        SpeakingLoading(),
        SpeakingLoaded(quests: tQuests, currentIndex: 0, livesRemaining: 3),
      ],
    );
  });

  group('SubmitAnswer', () {
    final tLoadedState = SpeakingLoaded(
      quests: tQuests,
      currentIndex: 0,
      livesRemaining: 3,
    );

    blocTest<SpeakingBloc, SpeakingState>(
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

    blocTest<SpeakingBloc, SpeakingState>(
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

    blocTest<SpeakingBloc, SpeakingState>(
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
