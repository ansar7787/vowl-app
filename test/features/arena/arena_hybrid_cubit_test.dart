import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/arena/data/services/arena_curriculum_engine.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/entities/arena_match_record.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_cubit.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class _TestArenaRepo implements ArenaRepository {
  bool completeMatchCalled = false;
  bool lastIsWinner = false;
  bool lastIsPerfect = false;
  int typingSyncCalls = 0;
  final List<ArenaMatchRecord> historyRecords = [];
  StreamController<ArenaDuelSession>? roomController;
  StreamController<int>? typingController;

  @override
  Future<ArenaDuelSession> quickMatch({required UserEntity currentUser}) async =>
      throw UnimplementedError();

  @override
  Future<ArenaDuelSession> challengeRivalDirectly({
    required UserEntity currentUser,
    required UserEntity rival,
    required int rivalRank,
  }) async => throw UnimplementedError();

  @override
  Future<ArenaDuelSession> rematchGhostAi({
    required UserEntity currentUser,
    required String previousGuestId,
    required String previousGuestName,
    String? previousGuestPhotoUrl,
    required double previousAccuracy,
    int previousOpponentDuelWins = 0,
  }) async => throw UnimplementedError();

  @override
  Future<ArenaDuelSession> createRoomCode({
    required UserEntity currentUser,
  }) async => throw UnimplementedError();

  @override
  Future<ArenaDuelSession> joinRoom({
    required String roomCode,
    required UserEntity currentUser,
  }) async => throw UnimplementedError();

  @override
  Stream<ArenaDuelSession> listenToRoom(String roomCode) =>
      roomController?.stream ?? const Stream.empty();

  @override
  Future<void> submitScore({
    required String roomCode,
    required String userId,
    required int score,
    required bool isHost,
    int correctCount = 0,
    int totalTimeMs = 0,
    bool finished = false,
  }) async {}

  @override
  Future<void> updateTypingProgress({
    required String roomCode,
    required String userId,
    required int charactersTyped,
    int roundIndex = 0,
  }) async {
    typingSyncCalls++;
  }

  @override
  Stream<int> listenToRivalTypingProgress({
    required String roomCode,
    required String rivalId,
    int? roundIndex,
  }) => typingController?.stream ?? const Stream.empty();

  @override
  Future<void> sendRematchRequest({
    required String roomCode,
    required String requesterId,
    required String requesterName,
  }) async {}

  @override
  Stream<Map<String, dynamic>> listenToRematchRequest({
    required String roomCode,
  }) => const Stream.empty();

  @override
  Future<ArenaDuelSession> acceptRematch({
    required String originalRoomCode,
    required UserEntity currentUser,
  }) async => throw UnimplementedError();

  @override
  Future<ArenaDuelSession> enterAcceptedRematch({
    required String newRoomCode,
    required UserEntity currentUser,
  }) async => throw UnimplementedError();

  @override
  Future<void> declineRematch({required String roomCode}) async {}

  @override
  Future<void> writeMatchHistory({
    required String userId,
    required ArenaMatchRecord record,
  }) async {
    historyRecords.add(record);
  }

  @override
  Future<List<ArenaMatchRecord>> getMatchHistory({
    required String userId,
    int limit = 50,
  }) async => historyRecords;

  @override
  Future<void> completeMatch({
    required String roomCode,
    required UserEntity currentUser,
    required bool isWinner,
    required bool isDraw,
    bool isPerfect = false,
  }) async {
    completeMatchCalled = true;
    lastIsWinner = isWinner;
    lastIsPerfect = isPerfect;
  }

  @override
  Future<void> forfeitMatch({
    required String roomCode,
    required String userId,
  }) async {}

  @override
  Future<void> refundStake({required String userId}) async {}

  @override
  Future<void> cancelMatchmaking({required String userId}) async {}
}

void main() {
  const user = UserEntity(
    id: 'user_1',
    email: 'test@vowl.app',
    displayName: 'Test Challenger',
    coins: 200,
    duelWins: 18,
  );

  List<ArenaChallenge> buildSamplePentathlon() {
    return const [
      ArenaChallenge(
        mechanic: ArenaMechanicType.wordSnap,
        id: 'WS_1',
        prompt: 'Very large',
        correctAnswer: 'enormous',
        scrambledLetters: 'ONURMOSE',
        explanation: 'Enormous means very large.',
      ),
      ArenaChallenge(
        mechanic: ArenaMechanicType.typeDuel,
        id: 'TD_1',
        prompt: 'Designs buildings',
        correctAnswer: 'architect',
        acceptedSpellings: ['architect', 'builder'],
        letterCount: 9,
        explanation: 'Architect designs buildings.',
      ),
      ArenaChallenge(
        mechanic: ArenaMechanicType.rapidJudge,
        id: 'RJ_1',
        prompt: 'Judge grammar',
        correctAnswer: '',
        explanation: 'Grammar checks.',
        rapidItems: [
          RapidJudgeItem(sentence: 'S1', isCorrect: false, rule: 'R1'),
          RapidJudgeItem(sentence: 'S2', isCorrect: true, rule: 'R2'),
          RapidJudgeItem(sentence: 'S3', isCorrect: false, rule: 'R3'),
          RapidJudgeItem(sentence: 'S4', isCorrect: true, rule: 'R4'),
          RapidJudgeItem(sentence: 'S5', isCorrect: false, rule: 'R5'),
          RapidJudgeItem(sentence: 'S6', isCorrect: true, rule: 'R6'),
        ],
      ),
      ArenaChallenge(
        mechanic: ArenaMechanicType.sentenceBuild,
        id: 'SB_1',
        prompt: 'Arrange',
        correctAnswer: 'She reads books daily',
        shuffledWords: ['daily', 'She', 'books', 'reads'],
        wordCount: 4,
        explanation: 'SVO order.',
      ),
      ArenaChallenge(
        mechanic: ArenaMechanicType.spotError,
        id: 'SE_1',
        prompt: 'Tap wrong word',
        correctAnswer: "they're",
        sentenceTokens: ['Read', "they're", 'book'],
        errorTokenIndex: 1,
        errorToken: "they're",
        correctedToken: 'their',
        explanation: 'Their = possessive.',
      ),
      ArenaChallenge(
        mechanic: ArenaMechanicType.mcq,
        id: 'MCQ_1',
        prompt: 'Opposite of ancient?',
        correctAnswer: 'Modern',
        options: ['Old', 'Modern', 'Weak', 'Slow'],
        correctIndex: 1,
        discipline: 'word_clash',
        explanation: 'Modern is opposite of ancient.',
      ),
      ArenaChallenge(
        mechanic: ArenaMechanicType.speedSpell,
        id: 'SP_1',
        prompt: 'Fill blanks',
        correctAnswer: 'enormous',
        displayMask: 'e_o_m_us',
        missingLetters: ['n', 'r', 'o'],
        missingPositions: [1, 3, 5],
        explanation: 'e-n-o-r-m-o-u-s',
      ),
    ];
  }

  ArenaDuelSession singleRoundSession(
    ArenaChallenge challenge, {
    bool isGhost = false,
    String? guestId,
    double ghostAcc = 0.85,
  }) {
    return ArenaDuelSession(
      roomCode: isGhost ? 'VOWL-AI-123456' : 'VOWL-DUEL-123456',
      hostId: user.id,
      hostName: user.safeDisplayName,
      guestId: guestId ?? (isGhost ? 'computer_medium' : 'user_2'),
      guestName: isGhost ? 'Computer' : 'Rival',
      status: 'in_progress',
      isGhostRival: isGhost,
      ghostAccuracy: ghostAcc,
      challenges: [challenge],
      createdAt: DateTime.now(),
    );
  }

  group('ArenaDuelCubit Individual Mechanic Scoring', () {
    test('Word Snap scores correct and wrong submissions', () async {
      final repo = _TestArenaRepo();
      final cubit = ArenaDuelCubit(repository: repo);
      cubit.startSession(singleRoundSession(buildSamplePentathlon()[0]), user);

      cubit.submitWordSnap('ENORMOUS', user);
      expect(cubit.state.isAnswered, isTrue);
      expect(cubit.state.isCorrect, isTrue);
      expect(cubit.state.myScore, greaterThanOrEqualTo(20));
      expect(cubit.state.roundResults.length, 1);
      expect(cubit.state.roundResults.first.mechanic, ArenaMechanicType.wordSnap);

      await cubit.close();
    });

    test('Type Duel handles case-insensitivity and acceptedSpellings', () async {
      final repo = _TestArenaRepo();
      final cubit = ArenaDuelCubit(repository: repo);
      cubit.startSession(singleRoundSession(buildSamplePentathlon()[1]), user);

      expect(cubit.state.timeRemaining, 20);
      cubit.submitTypeDuel('  Builder  ', user);
      expect(cubit.state.isCorrect, isTrue);
      expect(cubit.state.myScore, greaterThanOrEqualTo(20));

      await cubit.close();
    });

    test('Rapid Fire Judge applies partial credit formula across 6 items', () async {
      final repo = _TestArenaRepo();
      final cubit = ArenaDuelCubit(repository: repo);
      cubit.startSession(singleRoundSession(buildSamplePentathlon()[2]), user);

      expect(cubit.state.timeRemaining, 30);
      // Answer 5 out of 6 correctly (item 0 wrong, items 1..5 right)
      cubit.submitRapidJudgment(0, true, user); // wrong (item is false)
      cubit.submitRapidJudgment(1, true, user);
      cubit.submitRapidJudgment(2, false, user);
      cubit.submitRapidJudgment(3, true, user);
      cubit.submitRapidJudgment(4, false, user);
      cubit.submitRapidJudgment(5, true, user);

      expect(cubit.state.isAnswered, isTrue);
      expect(cubit.state.rapidMyCorrectItems, 5);
      expect(cubit.state.isCorrect, isTrue);
      expect(cubit.state.myScore, greaterThan(0));
      expect(cubit.state.roundResults.first.rapidCorrectItems, 5);
      expect(cubit.state.roundResults.first.rapidTotalItems, 6);

      await cubit.close();
    });

    test('Sentence Build validates exact ordered word list', () async {
      final repo = _TestArenaRepo();
      final cubit = ArenaDuelCubit(repository: repo);
      cubit.startSession(singleRoundSession(buildSamplePentathlon()[3]), user);

      expect(cubit.state.timeRemaining, 20);
      cubit.submitSentenceBuild(['She', 'reads', 'books', 'daily'], user);
      expect(cubit.state.isCorrect, isTrue);
      expect(cubit.state.myScore, greaterThanOrEqualTo(20));

      await cubit.close();
    });

    test('Spot the Error validates tapped token index', () async {
      final repo = _TestArenaRepo();
      final cubit = ArenaDuelCubit(repository: repo);
      cubit.startSession(singleRoundSession(buildSamplePentathlon()[4]), user);

      cubit.submitSpotError(1, user);
      expect(cubit.state.isCorrect, isTrue);
      expect(cubit.state.myScore, greaterThanOrEqualTo(20));

      await cubit.close();
    });

    test('Speed Spell validates filled missing letters case-insensitively', () async {
      final repo = _TestArenaRepo();
      final cubit = ArenaDuelCubit(repository: repo);
      cubit.startSession(singleRoundSession(buildSamplePentathlon()[6]), user);

      cubit.submitSpeedSpell('NrO', user);
      expect(cubit.state.isCorrect, isTrue);
      expect(cubit.state.myScore, greaterThanOrEqualTo(20));

      await cubit.close();
    });
  });

  group('Full 7-Round Hybrid Pentathlon E2E Flow with Ghost AI', () {
    test('plays all 7 unique mechanics start-to-completion and saves match history', () async {
      final repo = _TestArenaRepo();
      final cubit = ArenaDuelCubit(repository: repo, random: Random(7));
      final pentathlon = await ArenaCurriculumEngine.generateHybridPentathlon(
        seed: 7,
      );
      expect(pentathlon.length, 7);

      final session = ArenaDuelSession(
        roomCode: 'VOWL-AI-777777',
        hostId: user.id,
        hostName: user.safeDisplayName,
        guestId: 'computer_hard',
        guestName: 'Computer',
        hostDuelWins: user.duelWins,
        guestDuelWins: 20,
        status: 'in_progress',
        isGhostRival: true,
        ghostAccuracy: 0.90,
        challenges: pentathlon,
        createdAt: DateTime.now(),
      );

      cubit.startSession(session, user);

      for (var r = 0; r < 7; r++) {
        final challenge = cubit.state.currentChallenge!;
        switch (challenge.mechanic) {
          case ArenaMechanicType.wordSnap:
            cubit.submitWordSnap(challenge.correctAnswer, user);
            break;
          case ArenaMechanicType.typeDuel:
            cubit.submitTypeDuel(challenge.correctAnswer, user);
            break;
          case ArenaMechanicType.rapidJudge:
            final items = challenge.rapidItems!;
            for (var i = 0; i < items.length; i++) {
              cubit.submitRapidJudgment(i, items[i].isCorrect, user);
            }
            break;
          case ArenaMechanicType.sentenceBuild:
            cubit.submitSentenceBuild(challenge.correctAnswer.split(' '), user);
            break;
          case ArenaMechanicType.spotError:
            cubit.submitSpotError(challenge.errorTokenIndex!, user);
            break;
          case ArenaMechanicType.mcq:
            cubit.selectOption(challenge.correctIndex!, user);
            break;
          case ArenaMechanicType.speedSpell:
            cubit.submitSpeedSpell(challenge.missingLetters!.join(''), user);
            break;
          case ArenaMechanicType.voiceDuel:
            break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 1600));
      }

      // Suspense pause after 7th round
      await Future<void>.delayed(const Duration(milliseconds: 1400));

      expect(cubit.state.isCompleted, isTrue);
      expect(cubit.state.myCorrectCount, 7);
      expect(cubit.state.roundResults.length, 7);
      expect(cubit.state.rivalScore, greaterThan(0));
      expect(cubit.state.rivalTotalTimeMs, greaterThan(0));
      expect(repo.completeMatchCalled, isTrue);
      expect(repo.historyRecords.length, 1);
      expect(repo.historyRecords.first.rounds.length, 7);
      expect(repo.historyRecords.first.rounds.first.correctAnswer, isNotEmpty);

      await cubit.close();
    });

    test('live PvP finalizes immediately when bothPlayersFinished is true', () async {
      final repo = _TestArenaRepo();
      final controller = StreamController<ArenaDuelSession>.broadcast();
      repo.roomController = controller;

      final liveSession = ArenaDuelSession(
        roomCode: 'VOWL-DUEL-SYNC1',
        hostId: user.id,
        hostName: user.safeDisplayName,
        guestId: 'rival_1',
        guestName: 'Rival',
        status: 'in_progress',
        isGhostRival: false,
        challenges: [buildSamplePentathlon()[0]],
        createdAt: DateTime.now(),
      );

      final cubit = ArenaDuelCubit(repository: repo);
      cubit.startSession(liveSession, user);

      cubit.submitWordSnap('ENORMOUS', user);
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      expect(cubit.state.isWaitingForOpponentFinish, isTrue);
      expect(cubit.state.isCompleted, isFalse);

      // Rival completes too -> emits bothPlayersFinished without waiting 45s
      controller.add(
        liveSession.copyWith(
          hostFinished: true,
          guestFinished: true,
          guestScore: 40,
          guestCorrectCount: 1,
          guestTotalTimeMs: 9000,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(cubit.state.isCompleted, isTrue);
      expect(cubit.state.isWinner, isTrue);
      expect(repo.completeMatchCalled, isTrue);

      await controller.close();
      await cubit.close();
    });
  });
}
