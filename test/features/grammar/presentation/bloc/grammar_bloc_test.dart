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
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/domain/usecases/get_grammar_quest.dart';
import 'package:vowl/features/grammar/domain/usecases/preload_grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/speaking/domain/usecases/get_speaking_quest.dart';

class MockGetGrammarQuest extends Mock implements GetGrammarQuest {}
class MockPreloadGrammarQuest extends Mock implements PreloadGrammarQuest {}
class MockUpdateUserCoins extends Mock implements UpdateUserCoins {}
class MockUpdateUserRewards extends Mock implements UpdateUserRewards {}
class MockUpdateCategoryStats extends Mock implements UpdateCategoryStats {}
class MockUpdateUnlockedLevel extends Mock implements UpdateUnlockedLevel {}
class MockAwardBadge extends Mock implements AwardBadge {}
class MockSoundService extends Mock implements SoundService {}
class MockHapticService extends Mock implements HapticService {}
class MockUseHint extends Mock implements UseHint {}

class FakeQuestParams extends Fake implements QuestParams {}
class FakeUpdateUserRewardsParams extends Fake implements UpdateUserRewardsParams {}
class FakeUpdateCategoryStatsParams extends Fake implements UpdateCategoryStatsParams {}
class FakeUpdateUnlockedLevelParams extends Fake implements UpdateUnlockedLevelParams {}

void main() {
  late GrammarBloc bloc;
  late MockGetGrammarQuest mockGetQuest;
  late MockPreloadGrammarQuest mockPreloadQuest;
  late MockUpdateUserCoins mockUpdateUserCoins;
  late MockUpdateUserRewards mockUpdateUserRewards;
  late MockUpdateCategoryStats mockUpdateCategoryStats;
  late MockUpdateUnlockedLevel mockUpdateUnlockedLevel;
  late MockAwardBadge mockAwardBadge;
  late MockSoundService mockSoundService;
  late MockHapticService mockHapticService;
  late MockUseHint mockUseHint;

  setUpAll(() {
    registerFallbackValue(FakeQuestParams());
    registerFallbackValue(FakeUpdateUserRewardsParams());
    registerFallbackValue(FakeUpdateCategoryStatsParams());
    registerFallbackValue(FakeUpdateUnlockedLevelParams());
  });

  setUp(() {
    mockGetQuest = MockGetGrammarQuest();
    mockPreloadQuest = MockPreloadGrammarQuest();
    mockUpdateUserCoins = MockUpdateUserCoins();
    mockUpdateUserRewards = MockUpdateUserRewards();
    mockUpdateCategoryStats = MockUpdateCategoryStats();
    mockUpdateUnlockedLevel = MockUpdateUnlockedLevel();
    mockAwardBadge = MockAwardBadge();
    mockSoundService = MockSoundService();
    mockHapticService = MockHapticService();
    mockUseHint = MockUseHint();

    bloc = GrammarBloc(
      getQuest: mockGetQuest,
      preloadQuest: mockPreloadQuest,
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

  const tGameType = GameSubtype.sentenceCorrection;
  const tLevel = 1;
  const tQuests = [
    GrammarQuest(id: '1', instruction: 'i1', difficulty: 1),
    GrammarQuest(id: '2', instruction: 'i2', difficulty: 1),
    GrammarQuest(id: '3', instruction: 'i3', difficulty: 1),
  ];

  group('FetchGrammarQuests', () {
    blocTest<GrammarBloc, GrammarState>(
      'should emit [Loading, Loaded] when data is fetched successfully',
      build: () {
        when(() => mockGetQuest(any())).thenAnswer((_) async => const Right(tQuests));
        return bloc;
      },
      act: (bloc) => bloc.add(FetchGrammarQuests(gameType: tGameType, level: tLevel)),
      expect: () => [
        GrammarLoading(),
        GrammarLoaded(quests: tQuests, currentIndex: 0, livesRemaining: 3),
      ],
    );
  });

  group('SubmitAnswer', () {
    final tLoadedState = GrammarLoaded(
      quests: tQuests,
      currentIndex: 0,
      livesRemaining: 3,
    );

    blocTest<GrammarBloc, GrammarState>(
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

    blocTest<GrammarBloc, GrammarState>(
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

    blocTest<GrammarBloc, GrammarState>(
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
