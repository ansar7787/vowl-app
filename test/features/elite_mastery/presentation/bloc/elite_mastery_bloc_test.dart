import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/usecases/update_category_stats.dart';
import 'package:vowl/features/auth/domain/usecases/update_unlocked_level.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/features/elite_mastery/domain/entities/elite_mastery_quest.dart';
import 'package:vowl/features/elite_mastery/domain/usecases/get_elite_mastery_quests.dart';
import 'package:vowl/features/elite_mastery/presentation/bloc/elite_mastery_bloc.dart';

class MockGetEliteMasteryQuests extends Mock implements GetEliteMasteryQuests {}
class MockUpdateUserRewards extends Mock implements UpdateUserRewards {}
class MockUpdateCategoryStats extends Mock implements UpdateCategoryStats {}
class MockUpdateUnlockedLevel extends Mock implements UpdateUnlockedLevel {}
class MockUseHint extends Mock implements UseHint {}
class MockSoundService extends Mock implements SoundService {}
class MockHapticService extends Mock implements HapticService {}

class FakeGetEliteMasteryQuestParams extends Fake implements GetEliteMasteryQuestParams {}
class FakeUpdateUserRewardsParams extends Fake implements UpdateUserRewardsParams {}
class FakeUpdateCategoryStatsParams extends Fake implements UpdateCategoryStatsParams {}
class FakeUpdateUnlockedLevelParams extends Fake implements UpdateUnlockedLevelParams {}

void main() {
  late EliteMasteryBloc bloc;
  late MockGetEliteMasteryQuests mockGetQuests;
  late MockUpdateUserRewards mockUpdateUserRewards;
  late MockUpdateCategoryStats mockUpdateCategoryStats;
  late MockUpdateUnlockedLevel mockUpdateUnlockedLevel;
  late MockUseHint mockUseHint;
  late MockSoundService mockSoundService;
  late MockHapticService mockHapticService;

  setUpAll(() {
    registerFallbackValue(FakeGetEliteMasteryQuestParams());
    registerFallbackValue(FakeUpdateUserRewardsParams());
    registerFallbackValue(FakeUpdateCategoryStatsParams());
    registerFallbackValue(FakeUpdateUnlockedLevelParams());
    registerFallbackValue(GameSubtype.idiomMatch);
  });

  setUp(() {
    mockGetQuests = MockGetEliteMasteryQuests();
    mockUpdateUserRewards = MockUpdateUserRewards();
    mockUpdateCategoryStats = MockUpdateCategoryStats();
    mockUpdateUnlockedLevel = MockUpdateUnlockedLevel();
    mockUseHint = MockUseHint();
    mockSoundService = MockSoundService();
    mockHapticService = MockHapticService();

    bloc = EliteMasteryBloc(
      getQuests: mockGetQuests,
      updateUserRewards: mockUpdateUserRewards,
      updateCategoryStats: mockUpdateCategoryStats,
      updateUnlockedLevel: mockUpdateUnlockedLevel,
      useHint: mockUseHint,
      soundService: mockSoundService,
      hapticService: mockHapticService,
    );
  });

  tearDown(() {
    bloc.close();
  });

  const tGameType = GameSubtype.idiomMatch;
  const tLevel = 1;
  const tQuests = [
    EliteMasteryQuest(id: '1', instruction: 'i1', difficulty: 1),
    EliteMasteryQuest(id: '2', instruction: 'i2', difficulty: 1),
    EliteMasteryQuest(id: '3', instruction: 'i3', difficulty: 1),
  ];

  group('FetchEliteMasteryQuests', () {
    blocTest<EliteMasteryBloc, EliteMasteryState>(
      'should emit [Loading, Loaded] when data is fetched successfully',
      build: () {
        when(() => mockGetQuests(any())).thenAnswer((_) async => const Right(tQuests));
        return bloc;
      },
      act: (bloc) => bloc.add(FetchEliteMasteryQuests(gameType: tGameType, level: tLevel)),
      expect: () => [
        EliteMasteryLoading(),
        EliteMasteryLoaded(quests: tQuests, currentIndex: 0, livesRemaining: 3),
      ],
    );
  });

  group('SubmitEliteAnswer', () {
    final tLoadedState = EliteMasteryLoaded(
      quests: tQuests,
      currentIndex: 0,
      livesRemaining: 3,
    );

    blocTest<EliteMasteryBloc, EliteMasteryState>(
      'should emit state with lastAnswerCorrect: true when correct',
      build: () {
        when(() => mockSoundService.playCorrect()).thenAnswer((_) async => {});
        when(() => mockHapticService.success()).thenAnswer((_) async => {});
        return bloc;
      },
      seed: () => tLoadedState,
      act: (bloc) => bloc.add(SubmitEliteAnswer(true)),
      expect: () => [
        tLoadedState.copyWith(lastAnswerCorrect: true),
      ],
    );

    blocTest<EliteMasteryBloc, EliteMasteryState>(
      'should increment wrongCount when incorrect (first strike)',
      build: () {
        when(() => mockSoundService.playWrong()).thenAnswer((_) async => {});
        when(() => mockHapticService.error()).thenAnswer((_) async => {});
        return bloc;
      },
      seed: () => tLoadedState,
      act: (bloc) => bloc.add(SubmitEliteAnswer(false)),
      expect: () => [
        tLoadedState.copyWith(
          livesRemaining: 2,
          lastAnswerCorrect: false,
          wrongCount: 1,
          isFinalFailure: false,
        ),
      ],
    );

    blocTest<EliteMasteryBloc, EliteMasteryState>(
      'should re-queue quest and set isFinalFailure on second strike',
      build: () {
        when(() => mockSoundService.playWrong()).thenAnswer((_) async => {});
        when(() => mockHapticService.error()).thenAnswer((_) async => {});
        return bloc;
      },
      seed: () => tLoadedState.copyWith(wrongCount: 1, livesRemaining: 2),
      act: (bloc) => bloc.add(SubmitEliteAnswer(false)),
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
