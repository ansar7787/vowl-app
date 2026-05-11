import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/usecases/award_badge.dart';
import 'package:vowl/features/auth/domain/usecases/update_category_stats.dart';
import 'package:vowl/features/auth/domain/usecases/update_unlocked_level.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/speaking/domain/usecases/get_speaking_quest.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/domain/usecases/get_writing_quest.dart';
import 'package:vowl/features/writing/domain/usecases/use_writing_hint.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';

class MockGetWritingQuest extends Mock implements GetWritingQuest {}
class MockUpdateUserCoins extends Mock implements UpdateUserCoins {}
class MockUpdateUserRewards extends Mock implements UpdateUserRewards {}
class MockUpdateCategoryStats extends Mock implements UpdateCategoryStats {}
class MockUpdateUnlockedLevel extends Mock implements UpdateUnlockedLevel {}
class MockAwardBadge extends Mock implements AwardBadge {}
class MockSoundService extends Mock implements SoundService {}
class MockHapticService extends Mock implements HapticService {}
class MockUseWritingHint extends Mock implements UseWritingHint {}

class FakeQuestParams extends Fake implements QuestParams {}
class FakeUpdateUserRewardsParams extends Fake implements UpdateUserRewardsParams {}
class FakeUpdateCategoryStatsParams extends Fake implements UpdateCategoryStatsParams {}
class FakeUpdateUnlockedLevelParams extends Fake implements UpdateUnlockedLevelParams {}

void main() {
  late WritingBloc bloc;
  late MockGetWritingQuest mockGetQuest;
  late MockUpdateUserCoins mockUpdateUserCoins;
  late MockUpdateUserRewards mockUpdateUserRewards;
  late MockUpdateCategoryStats mockUpdateCategoryStats;
  late MockUpdateUnlockedLevel mockUpdateUnlockedLevel;
  late MockAwardBadge mockAwardBadge;
  late MockSoundService mockSoundService;
  late MockHapticService mockHapticService;
  late MockUseWritingHint mockUseHint;

  setUpAll(() {
    registerFallbackValue(FakeQuestParams());
    registerFallbackValue(FakeUpdateUserRewardsParams());
    registerFallbackValue(FakeUpdateCategoryStatsParams());
    registerFallbackValue(FakeUpdateUnlockedLevelParams());
    registerFallbackValue(GameSubtype.sentenceBuilder);
  });

  setUp(() {
    mockGetQuest = MockGetWritingQuest();
    mockUpdateUserCoins = MockUpdateUserCoins();
    mockUpdateUserRewards = MockUpdateUserRewards();
    mockUpdateCategoryStats = MockUpdateCategoryStats();
    mockUpdateUnlockedLevel = MockUpdateUnlockedLevel();
    mockAwardBadge = MockAwardBadge();
    mockSoundService = MockSoundService();
    mockHapticService = MockHapticService();
    mockUseHint = MockUseWritingHint();

    bloc = WritingBloc(
      getQuest: mockGetQuest,
      updateUserCoins: mockUpdateUserCoins,
      updateUserRewards: mockUpdateUserRewards,
      updateCategoryStats: mockUpdateCategoryStats,
      updateUnlockedLevel: mockUpdateUnlockedLevel,
      awardBadge: mockAwardBadge,
      soundService: mockSoundService,
      hapticService: mockHapticService,
      useHint: mockUseHint,
    );
  });

  tearDown(() {
    bloc.close();
  });

  const tGameType = GameSubtype.sentenceBuilder;
  const tLevel = 1;
  const tQuests = [
    WritingQuest(id: '1', instruction: 'i1', difficulty: 1),
    WritingQuest(id: '2', instruction: 'i2', difficulty: 1),
    WritingQuest(id: '3', instruction: 'i3', difficulty: 1),
  ];

  group('FetchWritingQuests', () {
    blocTest<WritingBloc, WritingState>(
      'should emit [Loading, Loaded] when data is fetched successfully',
      build: () {
        when(() => mockGetQuest(any())).thenAnswer((_) async => const Right(tQuests));
        return bloc;
      },
      act: (bloc) => bloc.add(FetchWritingQuests(gameType: tGameType, level: tLevel)),
      expect: () => [
        WritingLoading(),
        WritingLoaded(quests: tQuests, currentIndex: 0, livesRemaining: 3),
      ],
    );
  });

  group('SubmitAnswer', () {
    final tLoadedState = WritingLoaded(
      quests: tQuests,
      currentIndex: 0,
      livesRemaining: 3,
    );

    blocTest<WritingBloc, WritingState>(
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

    blocTest<WritingBloc, WritingState>(
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

    blocTest<WritingBloc, WritingState>(
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
