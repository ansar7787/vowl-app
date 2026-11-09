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
    int correctCount = 0,
    int totalTimeMs = 0,
  }) async {}

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
    lastIsDraw = isDraw;
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
      expect(
        cubit.state.payoutCoins,
        60,
      ); // 50 base win + 10 perfect bonus (1/1 correct)

      await cubit.close();
    });

    test(
      'resolves speed tiebreaker when points tie (Zero-Tie Guarantee)',
      () async {
        final repo = FakeArenaRepository();
        final cubit = ArenaDuelCubit(repository: repo);

        cubit.startSession(session, user);

        // Set rivalScore to match myScore, but myTotalTimeMs < rivalTotalTimeMs
        cubit.emit(
          cubit.state.copyWith(
            myScore: 400,
            rivalScore: 400,
            myTotalTimeMs: 4200,
            rivalTotalTimeMs: 5800,
            currentQuestionIndex: 0,
          ),
        );

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
      },
    );

    test(
      'awards immediate victory when opponent abandons match mid-game',
      () async {
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
      },
    );

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
        test(
          'AI opponent ($tier) reliably scores points and does not get 0 points when user plays quickly',
          () async {
            final repo = FakeArenaRepository();
            final cubit = ArenaDuelCubit(repository: repo);

            final ghostAccuracy = tier == 'hard'
                ? 0.90
                : (tier == 'medium' ? 0.78 : 0.65);
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
            expect(
              cubit.state.rivalScore,
              greaterThan(0),
              reason:
                  'AI ($tier) should have scored points across 5 questions instead of 0',
            );
            expect(
              cubit.state.rivalCorrectCount,
              greaterThan(0),
              reason:
                  'AI ($tier) with $ghostAccuracy accuracy should have correct answers',
            );
            expect(
              cubit.state.rivalTotalTimeMs,
              greaterThan(0),
              reason: 'AI ($tier) response time should be tracked',
            );

            await cubit.close();
          },
        );
      }
    });

    group('Host vs Guest Identity & Live Telemetry Tests', () {
      final session = ArenaDuelSession(
        roomCode: 'VOWL-LIVE-100',
        hostId: 'host_123',
        hostName: 'HostPlayer',
        hostPhotoUrl: 'https://vowl.app/host.jpg',
        guestId: 'guest_456',
        guestName: 'GuestPlayer',
        guestPhotoUrl: 'https://vowl.app/guest.jpg',
        stake: 30,
        pot: 60,
        status: 'in_progress',
        hostScore: 240,
        guestScore: 310,
        hostCorrectCount: 3,
        guestCorrectCount: 4,
        hostTotalTimeMs: 14200,
        guestTotalTimeMs: 11800,
        questions: questions,
        createdAt: DateTime.now(),
      );

      test('Correctly resolves Host perspective (User is Host)', () {
        expect(session.isHost('host_123'), true);
        expect(session.myName('host_123'), 'HostPlayer');
        expect(session.myPhotoUrl('host_123'), 'https://vowl.app/host.jpg');
        expect(session.opponentName('host_123'), 'GuestPlayer');
        expect(session.opponentPhotoUrl('host_123'), 'https://vowl.app/guest.jpg');
        expect(session.opponentScore('host_123'), 310);
        expect(session.opponentCorrectCount('host_123'), 4);
        expect(session.opponentTotalTimeMs('host_123'), 11800);
      });

      test('Correctly resolves Guest perspective (User is Guest - No Data Duplication)', () {
        expect(session.isHost('guest_456'), false);
        expect(session.myName('guest_456'), 'GuestPlayer');
        expect(session.myPhotoUrl('guest_456'), 'https://vowl.app/guest.jpg');
        expect(session.opponentName('guest_456'), 'HostPlayer');
        expect(session.opponentPhotoUrl('guest_456'), 'https://vowl.app/host.jpg');
        expect(session.opponentScore('guest_456'), 240);
        expect(session.opponentCorrectCount('guest_456'), 3);
        expect(session.opponentTotalTimeMs('guest_456'), 14200);

        // Crucial: Opponent photo must NOT be guest's photo
        expect(session.opponentPhotoUrl('guest_456'), isNot(equals(session.myPhotoUrl('guest_456'))));
        expect(session.opponentName('guest_456'), isNot(equals(session.myName('guest_456'))));
      });

      test('Live duel room stream synchronizes rival score, correct count, and response time', () async {
        final fakeRepo = FakeArenaRepository();
        final cubit = ArenaDuelCubit(repository: fakeRepo);
        final roomController = StreamController<ArenaDuelSession>.broadcast();
        fakeRepo.roomStreamController = roomController;

        const guestUser = UserEntity(
          id: 'guest_456',
          email: 'guest@vowl.app',
          displayName: 'GuestPlayer',
          photoUrl: 'https://vowl.app/guest.jpg',
        );

        final initialLiveSession = ArenaDuelSession(
          roomCode: 'VOWL-LIVE-100',
          hostId: 'host_123',
          hostName: 'HostPlayer',
          hostPhotoUrl: 'https://vowl.app/host.jpg',
          guestId: 'guest_456',
          guestName: 'GuestPlayer',
          guestPhotoUrl: 'https://vowl.app/guest.jpg',
          stake: 30,
          pot: 60,
          status: 'in_progress',
          hostScore: 0,
          guestScore: 0,
          hostCorrectCount: 0,
          guestCorrectCount: 0,
          hostTotalTimeMs: 0,
          guestTotalTimeMs: 0,
          questions: questions,
          createdAt: DateTime.now(),
        );

        cubit.startSession(initialLiveSession, guestUser);

        // Host submits progress: score 85, correct 1, time 2500ms
        final updatedFromHost = initialLiveSession.copyWith(
          hostScore: 85,
          hostCorrectCount: 1,
          hostTotalTimeMs: 2500,
        );
        roomController.add(updatedFromHost);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Guest's cubit must receive host's real telemetry
        expect(cubit.state.rivalScore, 85);
        expect(cubit.state.rivalCorrectCount, 1);
        expect(cubit.state.rivalTotalTimeMs, 2500);

        await cubit.close();
        await roomController.close();
      });
    });
  });
}
