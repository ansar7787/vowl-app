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
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/domain/usecases/get_roleplay_quest.dart';
import 'package:vowl/features/roleplay/domain/usecases/preload_roleplay_quests.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/constants/roleplay_constants.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';

class MockGetRoleplayQuest extends Mock implements GetRoleplayQuest {}

class MockPreloadRoleplayQuests extends Mock implements PreloadRoleplayQuests {}

class MockUpdateUserRewards extends Mock implements UpdateUserRewards {}

class MockUpdateUserCoins extends Mock implements UpdateUserCoins {}

class MockUpdateCategoryStats extends Mock implements UpdateCategoryStats {}

class MockUpdateUnlockedLevel extends Mock implements UpdateUnlockedLevel {}

class MockAwardBadge extends Mock implements AwardBadge {}

class MockSoundService extends Mock implements SoundService {}

class MockHapticService extends Mock implements HapticService {}

class MockUseHint extends Mock implements UseHint {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeUpdateUserRewardsParams extends Fake
    implements UpdateUserRewardsParams {}

class FakeGetRoleplayQuestParams extends Fake
    implements GetRoleplayQuestParams {}

class FakeUpdateUserCoinsParams extends Fake implements UpdateUserCoinsParams {}

class FakeUpdateCategoryStatsParams extends Fake
    implements UpdateCategoryStatsParams {}

class FakeUpdateUnlockedLevelParams extends Fake
    implements UpdateUnlockedLevelParams {}

void main() {
  late RoleplayBloc bloc;
  late MockGetRoleplayQuest mockGetQuest;
  late MockPreloadRoleplayQuests mockPreloadQuests;
  late MockUpdateUserRewards mockUpdateUserRewards;
  late MockUpdateUserCoins mockUpdateUserCoins;
  late MockUpdateCategoryStats mockUpdateCategoryStats;
  late MockUpdateUnlockedLevel mockUpdateUnlockedLevel;
  late MockAwardBadge mockAwardBadge;
  late MockSoundService mockSoundService;
  late MockHapticService mockHapticService;
  late MockUseHint mockUseHint;
  late MockNetworkInfo mockNetworkInfo;

  setUpAll(() {
    registerFallbackValue(FakeUpdateUserRewardsParams());
    registerFallbackValue(FakeUpdateUserCoinsParams());
    registerFallbackValue(FakeUpdateCategoryStatsParams());
    registerFallbackValue(FakeUpdateUnlockedLevelParams());
    registerFallbackValue(FakeGetRoleplayQuestParams());
    registerFallbackValue(GameSubtype.flashcards);
  });

  setUp(() {
    mockNetworkInfo = MockNetworkInfo();
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    mockGetQuest = MockGetRoleplayQuest();
    mockPreloadQuests = MockPreloadRoleplayQuests();
    mockUpdateUserRewards = MockUpdateUserRewards();
    mockUpdateUserCoins = MockUpdateUserCoins();
    mockUpdateCategoryStats = MockUpdateCategoryStats();
    mockUpdateUnlockedLevel = MockUpdateUnlockedLevel();
    mockAwardBadge = MockAwardBadge();
    mockSoundService = MockSoundService();
    mockHapticService = MockHapticService();
    mockUseHint = MockUseHint();

    bloc = RoleplayBloc(
      getQuest: mockGetQuest,
      preloadQuests: mockPreloadQuests,
      updateUserRewards: mockUpdateUserRewards,
      updateUserCoins: mockUpdateUserCoins,
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

  const tGameType = GameSubtype.socialSpark;
  const tLevel = 1;
  final tQuests = [
    RoleplayQuest(id: '1', instruction: 'i1', difficulty: 1, livesAllowed: 3),
    RoleplayQuest(id: '2', instruction: 'i2', difficulty: 1, livesAllowed: 3),
  ];

  group('FetchRoleplayQuests', () {
    blocTest<RoleplayBloc, RoleplayState>(
      'should emit [Loading, Loaded] when data is fetched successfully',
      build: () {
        when(() => mockGetQuest(any())).thenAnswer((_) async => Right(tQuests));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(FetchRoleplayQuests(gameType: tGameType, level: tLevel)),
      expect: () => [
        RoleplayLoading(),
        RoleplayLoaded(
          quests: tQuests,
          currentIndex: 0,
          livesRemaining: 3,
          gameType: tGameType,
          level: tLevel,
          currentNodeId: 'start',
        ),
      ],
    );
  });

  group('SubmitAnswer', () {
    final tLoadedState = RoleplayLoaded(
      quests: tQuests,
      currentIndex: 0,
      livesRemaining: 3,
      gameType: tGameType,
      level: tLevel,
    );

    blocTest<RoleplayBloc, RoleplayState>(
      'should emit state with lastAnswerCorrect: true when answer is correct',
      build: () {
        when(() => mockSoundService.playCorrect()).thenAnswer((_) async => {});
        when(() => mockHapticService.success()).thenAnswer((_) async => {});
        return bloc;
      },
      seed: () => tLoadedState,
      act: (bloc) => bloc.add(SubmitAnswer(true)),
      expect: () => [tLoadedState.copyWith(answerStatus: AnswerStatus.correct)],
    );

    blocTest<RoleplayBloc, RoleplayState>(
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
          answerStatus: AnswerStatus.incorrect,
          wrongCount: 1,
          isFinalFailure: false,
        ),
      ],
    );

    blocTest<RoleplayBloc, RoleplayState>(
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
          answerStatus: AnswerStatus.incorrect,
          wrongCount: 0,
          isFinalFailure: true,
          quests: [...tQuests, tQuests[0]],
        ),
      ],
    );

    blocTest<RoleplayBloc, RoleplayState>(
      'should not award mid-game coins when RoleplaySpeakConfirmed is received',
      build: () => bloc,
      seed: () => tLoadedState,
      act: (bloc) => bloc.add(const RoleplaySpeakConfirmed(5)),
      expect: () => [],
    );

    blocTest<RoleplayBloc, RoleplayState>(
      'should award strictly 5 XP + 10 Coins on level complete',
      build: () {
        when(() => mockUpdateUserRewards(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockUpdateCategoryStats(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockAwardBadge(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => tLoadedState.copyWith(
        currentIndex: 1,
        answerStatus: AnswerStatus.correct,
      ),
      act: (bloc) => bloc.add(const NextQuestion()),
      expect: () => [
        isA<RoleplayGameComplete>()
            .having((s) => s.xpEarned, 'xpEarned', kRoleplayLevelCompleteXp)
            .having((s) => s.coinsEarned, 'coinsEarned', kRoleplayLevelCompleteCoins),
      ],
      verify: (_) {
        verify(
          () => mockUpdateUserRewards(
            const UpdateUserRewardsParams(
              gameType: 'socialSpark',
              level: tLevel,
              xpIncrease: kRoleplayLevelCompleteXp,
              coinIncrease: kRoleplayLevelCompleteCoins,
              starsEarned: 3,
            ),
          ),
        ).called(1);
      },
    );

    blocTest<RoleplayBloc, RoleplayState>(
      'should NOT re-queue quest on final question even on second strike',
      build: () {
        when(() => mockSoundService.playWrong()).thenAnswer((_) async => {});
        when(() => mockHapticService.error()).thenAnswer((_) async => {});
        return bloc;
      },
      seed: () => tLoadedState.copyWith(
        currentIndex: 1, // Final quest of 2
        wrongCount: 1,
        livesRemaining: 2,
      ),
      act: (bloc) => bloc.add(const SubmitAnswer(false)),
      expect: () => [
        tLoadedState.copyWith(
          currentIndex: 1,
          livesRemaining: 1,
          answerStatus: AnswerStatus.incorrect,
          wrongCount: 0,
          isFinalFailure: true,
          quests: tQuests, // Untouched!
        ),
      ],
    );
  });

  group('RestoreLife and Level Completion Flow', () {
    final tLoadedState = RoleplayLoaded(
      quests: tQuests,
      currentIndex: 1,
      livesRemaining: 1,
      gameType: tGameType,
      level: tLevel,
    );

    blocTest<RoleplayBloc, RoleplayState>(
      'should prune duplicate copies on RestoreLife and complete level when final question is answered correctly',
      build: () {
        when(() => mockSoundService.playCorrect()).thenAnswer((_) async => {});
        when(() => mockHapticService.success()).thenAnswer((_) async => {});
        when(() => mockUpdateUserRewards(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockUpdateCategoryStats(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockAwardBadge(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => RoleplayGameOver(
        quests: [...tQuests, tQuests[1]], // Duplicate of final quest
        currentIndex: 1,
        gameType: tGameType,
        level: tLevel,
      ),
      act: (bloc) {
        bloc.add(const RestoreLife());
        bloc.add(const SubmitAnswer(true));
        bloc.add(const NextQuestion());
      },
      expect: () => [
        // 1. Restored: duplicate pruned
        RoleplayLoaded(
          quests: tQuests,
          currentIndex: 1,
          livesRemaining: 1,
          gameType: tGameType,
          level: tLevel,
          currentNodeId: 'start',
        ),
        // 2. Answered correctly
        tLoadedState.copyWith(
          currentNodeId: 'start',
          answerStatus: AnswerStatus.correct,
        ),
        // 3. Level complete immediately!
        isA<RoleplayGameComplete>()
            .having((s) => s.xpEarned, 'xpEarned', kRoleplayLevelCompleteXp)
            .having((s) => s.coinsEarned, 'coinsEarned', kRoleplayLevelCompleteCoins),
      ],
    );
  });
}
