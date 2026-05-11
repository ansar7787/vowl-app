import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/usecases/award_kids_sticker.dart';
import 'package:vowl/features/auth/domain/usecases/update_unlocked_level.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/domain/usecases/get_kids_quests.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';

class MockGetKidsQuests extends Mock implements GetKidsQuests {}
class MockUpdateUserRewards extends Mock implements UpdateUserRewards {}
class MockUpdateUnlockedLevel extends Mock implements UpdateUnlockedLevel {}
class MockAwardKidsSticker extends Mock implements AwardKidsSticker {}
class MockUseHint extends Mock implements UseHint {}
class MockSoundService extends Mock implements SoundService {}
class MockHapticService extends Mock implements HapticService {}

void main() {
  late KidsBloc bloc;
  late MockGetKidsQuests mockGetQuests;
  late MockUpdateUserRewards mockUpdateUserRewards;
  late MockUpdateUnlockedLevel mockUpdateUnlockedLevel;
  late MockAwardKidsSticker mockAwardKidsSticker;
  late MockUseHint mockUseHint;
  late MockSoundService mockSoundService;
  late MockHapticService mockHapticService;

  setUp(() {
    mockGetQuests = MockGetKidsQuests();
    mockUpdateUserRewards = MockUpdateUserRewards();
    mockUpdateUnlockedLevel = MockUpdateUnlockedLevel();
    mockAwardKidsSticker = MockAwardKidsSticker();
    mockUseHint = MockUseHint();
    mockSoundService = MockSoundService();
    mockHapticService = MockHapticService();

    bloc = KidsBloc(
      getKidsQuests: mockGetQuests,
      updateUserRewards: mockUpdateUserRewards,
      updateUnlockedLevel: mockUpdateUnlockedLevel,
      awardKidsSticker: mockAwardKidsSticker,
      useHint: mockUseHint,
      soundService: mockSoundService,
      hapticService: mockHapticService,
    );
  });

  tearDown(() {
    bloc.close();
  });

  final tQuests = [
    const KidsQuest(id: '1', instruction: 'i1', gameType: 'day_night', level: 1, correctAnswer: 'day', options: ['day', 'night']),
    const KidsQuest(id: '2', instruction: 'i2', gameType: 'day_night', level: 1, correctAnswer: 'night', options: ['day', 'night']),
  ];

  group('SubmitKidsAnswer', () {
    final tLoadedState = KidsLoaded(
      quests: tQuests,
      gameType: 'day_night',
      level: 1,
      currentIndex: 0,
      livesRemaining: 3,
    );

    blocTest<KidsBloc, KidsState>(
      'should increment attempts on first mistake (strike 1)',
      build: () {
        when(() => mockSoundService.playWrong()).thenAnswer((_) async => {});
        when(() => mockHapticService.error()).thenAnswer((_) async => {});
        return bloc;
      },
      seed: () => tLoadedState,
      act: (bloc) => bloc.add(const SubmitKidsAnswer(false)),
      expect: () => [
        tLoadedState.copyWith(
          livesRemaining: 2,
          lastAnswerCorrect: false,
          attempts: 1,
          isFinalFailure: false,
        ),
      ],
    );

    blocTest<KidsBloc, KidsState>(
      'should re-queue and set isFinalFailure on second mistake (strike 2)',
      build: () {
        when(() => mockSoundService.playWrong()).thenAnswer((_) async => {});
        when(() => mockHapticService.error()).thenAnswer((_) async => {});
        return bloc;
      },
      seed: () => tLoadedState.copyWith(attempts: 1, livesRemaining: 2),
      act: (bloc) => bloc.add(const SubmitKidsAnswer(false)),
      expect: () => [
        tLoadedState.copyWith(
          livesRemaining: 1,
          lastAnswerCorrect: false,
          attempts: 0, // Reset after re-queue
          isFinalFailure: true,
          quests: [...tQuests, tQuests[0]], // Re-queued
        ),
      ],
    );

    blocTest<KidsBloc, KidsState>(
      'should emit KidsGameOver when lives reach zero',
      build: () {
        when(() => mockSoundService.playWrong()).thenAnswer((_) async => {});
        when(() => mockHapticService.error()).thenAnswer((_) async => {});
        return bloc;
      },
      seed: () => tLoadedState.copyWith(livesRemaining: 1),
      act: (bloc) => bloc.add(const SubmitKidsAnswer(false)),
      expect: () => [
        isA<KidsGameOver>(),
      ],
    );
  });
}
