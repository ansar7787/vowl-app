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
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/domain/usecases/get_vocabulary_quests.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';

class MockGetVocabularyQuests extends Mock implements GetVocabularyQuests {}
class MockUpdateUserCoins extends Mock implements UpdateUserCoins {}
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
  late VocabularyBloc bloc;
  late MockGetVocabularyQuests mockGetQuests;
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
    registerFallbackValue(FakeUpdateUserRewardsParams());
    registerFallbackValue(FakeUpdateCategoryStatsParams());
    registerFallbackValue(FakeUpdateUnlockedLevelParams());
  });

  setUp(() {
    mockGetQuests = MockGetVocabularyQuests();
    mockUpdateUserCoins = MockUpdateUserCoins();
    mockUpdateUserRewards = MockUpdateUserRewards();
    mockUpdateCategoryStats = MockUpdateCategoryStats();
    mockUpdateUnlockedLevel = MockUpdateUnlockedLevel();
    mockAwardBadge = MockAwardBadge();
    mockSoundService = MockSoundService();
    mockHapticService = MockHapticService();
    mockUseHint = MockUseHint();
    mockNetworkInfo = MockNetworkInfo();

    bloc = VocabularyBloc(
      getQuests: mockGetQuests,
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

  const tGameType = GameSubtype.flashcards;
  const tLevel = 1;
  const tQuests = [
    VocabularyQuest(id: '1', instruction: 'i1', difficulty: 1),
    VocabularyQuest(id: '2', instruction: 'i2', difficulty: 1),
    VocabularyQuest(id: '3', instruction: 'i3', difficulty: 1),
  ];

  group('FetchVocabularyQuests', () {
    blocTest<VocabularyBloc, VocabularyState>(
      'should emit [Loading, Loaded] when data is fetched successfully',
      build: () {
        when(() => mockGetQuests(any(), any())).thenAnswer((_) async => tQuests);
        return bloc;
      },
      act: (bloc) => bloc.add(FetchVocabularyQuests(gameType: tGameType, level: tLevel)),
      expect: () => [
        VocabularyLoading(),
        VocabularyLoaded(quests: tQuests, currentIndex: 0, livesRemaining: 3),
      ],
      verify: (_) {
        verify(() => mockGetQuests(tGameType.name, tLevel));
      },
    );

    blocTest<VocabularyBloc, VocabularyState>(
      'should emit [Loading, Error] when data fetch fails',
      build: () {
        when(() => mockGetQuests(any(), any())).thenThrow(Exception('failed'));
        return bloc;
      },
      act: (bloc) => bloc.add(FetchVocabularyQuests(gameType: tGameType, level: tLevel)),
      expect: () => [
        VocabularyLoading(),
        isA<VocabularyError>(),
      ],
    );
  });

  group('SubmitAnswer', () {
    final tLoadedState = VocabularyLoaded(
      quests: tQuests,
      currentIndex: 0,
      livesRemaining: 3,
    );

    blocTest<VocabularyBloc, VocabularyState>(
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
      verify: (_) {
        verify(() => mockSoundService.playCorrect()).called(1);
        verify(() => mockHapticService.success()).called(1);
      },
    );

    blocTest<VocabularyBloc, VocabularyState>(
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

    blocTest<VocabularyBloc, VocabularyState>(
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

    blocTest<VocabularyBloc, VocabularyState>(
      'should emit VocabularyLoaded with 0 lives when lives reach 0 (mistake 1)',
      build: () {
        when(() => mockSoundService.playWrong()).thenAnswer((_) async => {});
        when(() => mockHapticService.error()).thenAnswer((_) async => {});
        return bloc;
      },
      seed: () => tLoadedState.copyWith(livesRemaining: 1),
      act: (bloc) => bloc.add(SubmitAnswer(false)),
      expect: () => [
        tLoadedState.copyWith(
          livesRemaining: 0,
          lastAnswerCorrect: false,
          wrongCount: 1,
          isFinalFailure: true,
        ),
      ],
    );
  });

  group('NextQuestion', () {
    final tLoadedState = VocabularyLoaded(
      quests: tQuests,
      currentIndex: 0,
      livesRemaining: 3,
      lastAnswerCorrect: true,
    );

    blocTest<VocabularyBloc, VocabularyState>(
      'should emit state with currentIndex: 1 when NextQuestion is added',
      build: () => bloc,
      seed: () => tLoadedState,
      act: (bloc) => bloc.add(NextQuestion()),
      expect: () => [
        tLoadedState.copyWith(currentIndex: 1, lastAnswerCorrect: null, hintUsed: false),
      ],
    );

    blocTest<VocabularyBloc, VocabularyState>(
      'should emit VocabularyGameComplete when completing the last question',
      build: () {
        when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async => {});
        when(() => mockUpdateUserRewards(any())).thenAnswer((_) async => const Right(null));
        when(() => mockUpdateCategoryStats(any())).thenAnswer((_) async => const Right(null));
        when(() => mockUpdateUnlockedLevel(any())).thenAnswer((_) async => const Right(null));
        when(() => mockAwardBadge(any())).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => tLoadedState.copyWith(
        currentIndex: tQuests.length - 1,
        lastAnswerCorrect: true,
      ),
      act: (bloc) => bloc.add(NextQuestion()),
      expect: () => [
        isA<VocabularyGameComplete>(),
      ],
    );
  });
}
