import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';

class ArenaDuelCubit extends Cubit<ArenaDuelState> {
  final ArenaRepository _repository;
  Timer? _questionTimer;
  StreamSubscription<ArenaDuelSession>? _roomSub;

  ArenaDuelCubit({required ArenaRepository repository})
      : _repository = repository,
        super(const ArenaDuelState());

  @override
  Future<void> close() {
    _questionTimer?.cancel();
    _roomSub?.cancel();
    return super.close();
  }

  void startSession(ArenaDuelSession session, UserEntity currentUser) {
    emit(state.copyWith(
      session: session,
      isWaitingForGuest: session.isWaiting,
    ));

    if (!session.isWaiting) {
      _startQuestionTimer(currentUser);
    }

    if (!session.isGhostRival) {
      _roomSub = _repository.listenToRoom(session.roomCode).listen((updated) {
        if (state.isWaitingForGuest && !updated.isWaiting) {
          emit(state.copyWith(session: updated, isWaitingForGuest: false));
          _startQuestionTimer(currentUser);
        } else {
          final isHost = currentUser.id == updated.hostId;
          final oppScore = isHost ? updated.guestScore : updated.hostScore;
          emit(state.copyWith(session: updated, rivalScore: oppScore));
        }
      });
    }
  }

  void _startQuestionTimer(UserEntity currentUser) {
    _questionTimer?.cancel();
    emit(state.copyWith(timeRemaining: 10, isAnswered: false, selectedOption: null, isCorrect: null));

    // Simulate ghost opponent answering
    if (state.session?.isGhostRival == true) {
      _simulateGhostAnswer();
    }

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeRemaining <= 1) {
        timer.cancel();
        _onTimeExpired(currentUser);
      } else {
        emit(state.copyWith(timeRemaining: state.timeRemaining - 1));
      }
    });
  }

  void _simulateGhostAnswer() {
    final accuracy = state.session?.ghostAccuracy ?? 0.8;
    final delaySeconds = Random().nextInt(3) + 2; // Answers in 2-4 seconds

    Future.delayed(Duration(seconds: delaySeconds), () {
      if (isClosed || state.isCompleted) return;
      final isRivalCorrect = Random().nextDouble() <= accuracy;
      if (isRivalCorrect) {
        final speedBonus = max(10, 100 - (delaySeconds * 10));
        emit(state.copyWith(rivalScore: state.rivalScore + speedBonus));
      }
    });
  }

  void selectOption(int index, UserEntity currentUser) {
    if (state.isAnswered || state.currentQuestion == null) return;
    _questionTimer?.cancel();

    final q = state.currentQuestion!;
    final isCorrect = index == q.correctIndex;
    final speedPoints = isCorrect ? max(20, state.timeRemaining * 10) : 0;
    final newMyScore = state.myScore + speedPoints;

    emit(state.copyWith(
      selectedOption: index,
      isAnswered: true,
      isCorrect: isCorrect,
      myScore: newMyScore,
    ));

    // Submit score to live room if live
    if (state.session != null && !state.session!.isGhostRival) {
      final isHost = currentUser.id == state.session!.hostId;
      _repository.submitScore(
        roomCode: state.session!.roomCode,
        userId: currentUser.id,
        score: newMyScore,
        isHost: isHost,
      );
    }

    // Delay 1.5 seconds to show correct answer before advancing
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (isClosed) return;
      _advanceToNextQuestion(currentUser);
    });
  }

  void _onTimeExpired(UserEntity currentUser) {
    emit(state.copyWith(isAnswered: true, isCorrect: false));
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (isClosed) return;
      _advanceToNextQuestion(currentUser);
    });
  }

  void _advanceToNextQuestion(UserEntity currentUser) {
    final nextIndex = state.currentQuestionIndex + 1;
    final totalQuestions = state.session?.questions.length ?? 5;

    if (nextIndex >= totalQuestions) {
      _finalizeMatch(currentUser);
    } else {
      emit(state.copyWith(currentQuestionIndex: nextIndex));
      _startQuestionTimer(currentUser);
    }
  }

  Future<void> _finalizeMatch(UserEntity currentUser) async {
    _questionTimer?.cancel();

    final isWinner = state.myScore > state.rivalScore;
    final isDraw = state.myScore == state.rivalScore;
    final payout = isDraw ? 30 : (isWinner ? 50 : 10);

    emit(state.copyWith(
      isCompleted: true,
      isWinner: isWinner,
      isDraw: isDraw,
      payoutCoins: payout,
    ));

    if (state.session != null) {
      await _repository.completeMatch(
        roomCode: state.session!.roomCode,
        currentUser: currentUser,
        isWinner: isWinner,
        isDraw: isDraw,
      );
    }
  }
}

