import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_cubit.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class FakeArenaRepository implements ArenaRepository {
  bool completeMatchCalled = false;
  bool lastIsWinner = false;
  bool lastIsDraw = false;
  StreamController<ArenaDuelSession>? roomStreamController;

  @override
  Future<ArenaDuelSession> quickMatch({
    required UserEntity currentUser,
  }) async => throw UnimplementedError();

  @override
  Future<ArenaDuelSession> challengeRivalDirectly({
    required UserEntity currentUser,
    required UserEntity rival,
    required int rivalRank,
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
      roomStreamController?.stream ?? const Stream.empty();

  @override
  Future<void> submitScore({
    required String roomCode,
    required String userId,
    required int score,
    required bool isHost,
  }) async {}

  @override
  Future<void> completeMatch({
    required String roomCode,
    required UserEntity currentUser,
    required bool isWinner,
    required bool isDraw,
  }) async {
    completeMatchCalled = true;
    lastIsWinner = isWinner;
    lastIsDraw = isDraw;
  }

  @override
  Future<void> forfeitMatch({
    required String roomCode,
    required String userId,
  }) async {}

  @override
  Future<void> refundStake({
    required String userId,
  }) async {}

  @override
  Future<void> cancelMatchmaking({
    required String userId,
  }) async {}
}

void main() {
  group('ArenaDuelCubit Zero-Tie Resolution', () {
    const user = UserEntity(
      id: 'test_user_1',
      email: 'test@vowl.app',
      displayName: 'Lexicon Master',
      coins: 100,
    );

    final questions = [
      const ArenaQuestion(
        question: 'Synonym for Concise?',
        options: ['Verbose', 'Succinct', 'Vague', 'Dull'],
        correctIndex: 1,
        explanation: 'Succinct means concise.',
      ),
    ];

    final session = ArenaDuelSession(
      roomCode: 'VOWL-TEST-100',
      hostId: 'test_user_1',
      hostName: 'Lexicon Master',
      stake: 30,
      pot: 60,
      status: 'in_progress',
      isGhostRival: false,
      questions: questions,
      createdAt: DateTime.now(),
    );

    test('resolves decisive winner when scores are different', () async {
      final repo = FakeArenaRepository();
      final cubit = ArenaDuelCubit(repository: repo);

      cubit.startSession(session, user);
      // Select correct answer
      cubit.selectOption(1, user);

      // Advance question / finalize match (only 1 question)
      await Future<void>.delayed(const Duration(milliseconds: 1600));

      expect(cubit.state.isCompleted, true);
      expect(cubit.state.isWinner, true);
      expect(cubit.state.isDraw, false);
      expect(cubit.state.isSpeedTieBreak, false);
      expect(cubit.state.payoutCoins, 50);

      await cubit.close();
    });

    test('resolves speed tiebreaker when points tie (Zero-Tie Guarantee)', () async {
      final repo = FakeArenaRepository();
      final cubit = ArenaDuelCubit(repository: repo);

      cubit.startSession(session, user);

      // Set rivalScore to match myScore, but myTotalTimeMs < rivalTotalTimeMs
      cubit.emit(cubit.state.copyWith(
        myScore: 400,
        rivalScore: 400,
        myTotalTimeMs: 4200,
        rivalTotalTimeMs: 5800,
        currentQuestionIndex: 0,
      ));

      // Answer option to complete 1-question duel
      cubit.selectOption(0, user); // wrong option, scores remain tied
      await Future<void>.delayed(const Duration(milliseconds: 1600));

      expect(cubit.state.isCompleted, true);
      expect(cubit.state.isSpeedTieBreak, true);
      expect(cubit.state.isWinner, true); // Faster player won!
      expect(cubit.state.isDraw, false); // No draws!
      expect(cubit.state.payoutCoins, 50);
      expect(cubit.state.speedDiffSeconds, greaterThan(0.0));
      expect(cubit.state.speedDiffSeconds, lessThanOrEqualTo(1.6));

      await cubit.close();
    });

    test('awards immediate victory when opponent abandons match mid-game', () async {
      final repo = FakeArenaRepository();
      final controller = StreamController<ArenaDuelSession>.broadcast();
      repo.roomStreamController = controller;

      final cubit = ArenaDuelCubit(repository: repo);
      cubit.startSession(session, user);

      // Opponent forfeits/abandons the room
      final abandonedSession = session.copyWith(status: 'abandoned');
      controller.add(abandonedSession);

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(cubit.state.isCompleted, true);
      expect(cubit.state.isWinner, true);
      expect(cubit.state.payoutCoins, 50);
      expect(repo.completeMatchCalled, true);
      expect(repo.lastIsWinner, true);

      await controller.close();
      await cubit.close();
    });

    group('Ghost AI Opponent Tier Tests (Easy, Medium, Hard)', () {
      final duelQuestions = List.generate(
        5,
        (i) => ArenaQuestion(
          question: 'Question $i',
          options: const ['A', 'B', 'C', 'D'],
          correctIndex: 0,
          explanation: 'Explanation $i',
        ),
      );

      for (final tier in ['easy', 'medium', 'hard']) {
        test('AI opponent ($tier) reliably scores points and does not get 0 points when user plays quickly', () async {
          final repo = FakeArenaRepository();
          final cubit = ArenaDuelCubit(repository: repo);

          final ghostAccuracy = tier == 'hard' ? 0.90 : (tier == 'medium' ? 0.78 : 0.65);
          final ghostSession = ArenaDuelSession(
            roomCode: 'VOWL-AI-TEST-$tier',
            hostId: user.id,
            hostName: user.displayName ?? 'Lexicon Master',
            guestId: 'computer_$tier',
            guestName: 'Computer',
            stake: 30,
            pot: 60,
            status: 'in_progress',
            isGhostRival: true,
            ghostAccuracy: ghostAccuracy,
            questions: duelQuestions,
            createdAt: DateTime.now(),
          );

          cubit.startSession(ghostSession, user);

          // Fast user answers each question after only 50ms
          for (int q = 0; q < 5; q++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            cubit.selectOption(0, user); // User selects correct option
            // Advance delay in cubit is 1500ms
            await Future<void>.delayed(const Duration(milliseconds: 1600));
          }

          // Suspense pause before match finalization
          await Future<void>.delayed(const Duration(milliseconds: 1400));

          expect(cubit.state.isCompleted, true);
          // Crucial check: AI must NOT have 0 points or 0ms!
          expect(cubit.state.rivalScore, greaterThan(0),
              reason: 'AI ($tier) should have scored points across 5 questions instead of 0');
          expect(cubit.state.rivalCorrectCount, greaterThan(0),
              reason: 'AI ($tier) with $ghostAccuracy accuracy should have correct answers');
          expect(cubit.state.rivalTotalTimeMs, greaterThan(0),
              reason: 'AI ($tier) response time should be tracked');

          await cubit.close();
        });
      }
    });
  });
}

