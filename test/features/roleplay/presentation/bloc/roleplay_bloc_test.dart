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
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/domain/usecases/get_roleplay_quest.dart';
import 'package:vowl/features/roleplay/domain/usecases/preload_roleplay_quests.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';

class MockGetRoleplayQuest extends Mock implements GetRoleplayQuest {}
class MockPreloadRoleplayQuests extends Mock implements PreloadRoleplayQuests {}
class MockUpdateUserRewards extends Mock implements UpdateUserRewards {}
class MockUpdateCategoryStats extends Mock implements UpdateCategoryStats {}
class MockUpdateUnlockedLevel extends Mock implements UpdateUnlockedLevel {}
class MockAwardBadge extends Mock implements AwardBadge {}
class MockSoundService extends Mock implements SoundService {}
class MockHapticService extends Mock implements HapticService {}
class MockUseHint extends Mock implements UseHint {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeUpdateUserRewardsParams extends Fake implements UpdateUserRewardsParams {}
class FakeUpdateCategoryStatsParams extends Fake implements UpdateCategoryStatsParams {}
class FakeUpdateUnlockedLevelParams extends Fake implements UpdateUnlockedLevelParams {}

void main() {
  late RoleplayBloc bloc;
  late MockGetRoleplayQuest mockGetQuest;
  late MockPreloadRoleplayQuests mockPreloadQuests;
  late MockUpdateUserRewards mockUpdateUserRewards;
  late MockUpdateCategoryStats mockUpdateCategoryStats;
  late MockUpdateUnlockedLevel mockUpdateUnlockedLevel;
  late MockAwardBadge mockAwardBadge;
  late MockSoundService mockSoundService;
  late MockHapticService mockHapticService;
  late MockUseHint mockUseHint;
  late MockNetworkInfo mockNetworkInfo;

  setUpAll(() {
    registerFallbackValue(FakeUpdateUserRewardsParams());
    registerFallbackValue(FakeUpdateCategoryStatsParams());
    registerFallbackValue(FakeUpdateUnlockedLevelParams());
    registerFallbackValue(GameSubtype.flashcards);
  });

  setUp(() {
    mockGetQuest = MockGetRoleplayQuest();
    mockPreloadQuests = MockPreloadRoleplayQuests();
    mockUpdateUserRewards = MockUpdateUserRewards();
    mockUpdateCategoryStats = MockUpdateCategoryStats();
    mockUpdateUnlockedLevel = MockUpdateUnlockedLevel();
    mockAwardBadge = MockAwardBadge();
    mockSoundService = MockSoundService();
    mockHapticService = MockHapticService();
    mockUseHint = MockUseHint();
    mockNetworkInfo = MockNetworkInfo();

    bloc = RoleplayBloc(
      getQuest: mockGetQuest,
      preloadQuests: mockPreloadQuests,
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

  const tGameType = GameSubtype.socialSpark;
  const tLevel = 1;
  final tQuests = [
    RoleplayQuest(id: '1', instruction: 'i1', difficulty: 1, livesAllowed: 3),
  ];

  group('FetchRoleplayQuests', () {
    blocTest<RoleplayBloc, RoleplayState>(
      'should emit [Loading, Loaded] when data is fetched successfully',
      build: () {
        when(() => mockGetQuest(gameType: any(named: 'gameType'), level: any(named: 'level')))
            .thenAnswer((_) async => Right(tQuests));
        return bloc;
      },
      act: (bloc) => bloc.add(FetchRoleplayQuests(gameType: tGameType, level: tLevel)),
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
      expect: () => [
        tLoadedState.copyWith(lastAnswerCorrect: true),
      ],
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
          lastAnswerCorrect: false,
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
          lastAnswerCorrect: false,
          wrongCount: 0,
          isFinalFailure: true,
          quests: [...tQuests, tQuests[0]],
        ),
      ],
    );
  });
}
