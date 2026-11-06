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
  Timer? _ghostTimer;
  StreamSubscription<ArenaDuelSession>? _roomSub;
  int _questionStartTime = 0;

  ArenaDuelCubit({required ArenaRepository repository})
      : _repository = repository,
        super(const ArenaDuelState());

  @override
  Future<void> close() {
    _questionTimer?.cancel();
    _ghostTimer?.cancel();
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

          // If opponent forfeited / abandoned room mid-match, award immediate win
          if (updated.status == 'abandoned' && !state.isCompleted) {
            _finalizeForfeitWin(currentUser);
            return;
          }

          if (state.isWaitingForOpponentFinish && !state.isCompleted) {
            if (updated.isCompleted) {
              _finalizeMatch(currentUser);
            }
          }
        }
      });
    }
  }

  void _startQuestionTimer(UserEntity currentUser) {
    _questionTimer?.cancel();
    _ghostTimer?.cancel();
    _questionStartTime = DateTime.now().millisecondsSinceEpoch;

    emit(state.copyWith(
      timeRemaining: 15,
      isAnswered: false,
      selectedOption: null,
      isCorrect: null,
    ));

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
    _ghostTimer?.cancel();
    final targetQuestionIndex = state.currentQuestionIndex;
    final accuracy = state.session?.ghostAccuracy ?? 0.8;

    // Calibrate response speed based on AI tier
    final int delaySeconds;
    if (accuracy <= 0.68) {
      delaySeconds = Random().nextInt(3) + 4; // 4 to 6 seconds (Easy)
    } else if (accuracy <= 0.82) {
      delaySeconds = Random().nextInt(3) + 3; // 3 to 5 seconds (Medium)
    } else {
      delaySeconds = Random().nextInt(2) + 2; // 2 to 3 seconds (Hard)
    }
    final ghostElapsedMs = (delaySeconds * 1000) + Random().nextInt(500);

    _ghostTimer = Timer(Duration(seconds: delaySeconds), () {
      if (isClosed || state.isCompleted || state.currentQuestionIndex != targetQuestionIndex) return;
      final isRivalCorrect = Random().nextDouble() <= accuracy;
      final speedBonus = isRivalCorrect ? max(20, (15 - delaySeconds) * 100 ~/ 15) : 0;
      final newRivalScore = state.rivalScore + speedBonus;
      final newRivalCorrect = isRivalCorrect
          ? state.rivalCorrectCount + 1
          : state.rivalCorrectCount;
      final newRivalTime = state.rivalTotalTimeMs + ghostElapsedMs;

      emit(state.copyWith(
        rivalScore: newRivalScore,
        rivalCorrectCount: newRivalCorrect,
        rivalTotalTimeMs: newRivalTime,
      ));
    });
  }

  void selectOption(int index, UserEntity currentUser) {
    if (state.isAnswered || state.currentQuestion == null) return;
    _questionTimer?.cancel();

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedMs = _questionStartTime > 0
        ? (now - _questionStartTime).clamp(300, 15000)
        : (15 - state.timeRemaining) * 1000;

    final q = state.currentQuestion!;
    final isCorrect = index == q.correctIndex;
    final speedPoints = isCorrect ? max(20, (state.timeRemaining * 100 ~/ 15)) : 0;
    final newMyScore = state.myScore + speedPoints;
    final newMyCorrect = isCorrect ? state.myCorrectCount + 1 : state.myCorrectCount;
    final newMyTime = state.myTotalTimeMs + elapsedMs;

    emit(state.copyWith(
      selectedOption: index,
      isAnswered: true,
      isCorrect: isCorrect,
      myScore: newMyScore,
      myCorrectCount: newMyCorrect,
      myTotalTimeMs: newMyTime,
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
    final newMyTime = state.myTotalTimeMs + 15000;
    emit(state.copyWith(
      isAnswered: true,
      isCorrect: false,
      myTotalTimeMs: newMyTime,
    ));
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (isClosed) return;
      _advanceToNextQuestion(currentUser);
    });
  }

  void _advanceToNextQuestion(UserEntity currentUser) {
    final nextIndex = state.currentQuestionIndex + 1;
    final totalQuestions = state.session?.questions.length ?? 5;

    if (nextIndex >= totalQuestions) {
      final isGhost = state.session?.isGhostRival ?? false;
      final hasGuest = state.session?.guestId != null;

      if (!isGhost && hasGuest) {
        emit(state.copyWith(isWaitingForOpponentFinish: true));
        // Fallback auto-finalize after 12s if opponent lags
        Future.delayed(const Duration(seconds: 12), () {
          if (!isClosed && !state.isCompleted) {
            _finalizeMatch(currentUser);
          }
        });
      } else if (isGhost) {
        // Natural 1.2s suspense pause before victory screen
        emit(state.copyWith(isWaitingForOpponentFinish: true));
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!isClosed && !state.isCompleted) {
            _finalizeMatch(currentUser);
          }
        });
      } else {
        _finalizeMatch(currentUser);
      }
    } else {
      emit(state.copyWith(currentQuestionIndex: nextIndex));
      _startQuestionTimer(currentUser);
    }
  }

  Future<void> _finalizeMatch(UserEntity currentUser) async {
    _questionTimer?.cancel();
    _ghostTimer?.cancel();
    _roomSub?.cancel();

    final bool isScoreTie = state.myScore == state.rivalScore;
    final bool isWinner;
    final bool isSpeedTieBreak;
    final double speedDiff;

    if (!isScoreTie) {
      isWinner = state.myScore > state.rivalScore;
      isSpeedTieBreak = false;
      speedDiff = 0.0;
    } else {
      // ZERO-TIE RESOLUTION: Decisive millisecond tiebreaker
      isSpeedTieBreak = true;
      isWinner = state.myTotalTimeMs <= state.rivalTotalTimeMs;
      speedDiff = ((state.rivalTotalTimeMs - state.myTotalTimeMs).abs()) / 1000.0;
    }

    final payout = isWinner ? 50 : 10;

    emit(state.copyWith(
      isCompleted: true,
      isWinner: isWinner,
      isDraw: false,
      isSpeedTieBreak: isSpeedTieBreak,
      speedDiffSeconds: speedDiff,
      payoutCoins: payout,
    ));

    if (state.session != null) {
      await _repository.completeMatch(
        roomCode: state.session!.roomCode,
        currentUser: currentUser,
        isWinner: isWinner,
        isDraw: false,
      );
    }
  }

  Future<void> _finalizeForfeitWin(UserEntity currentUser) async {
    _questionTimer?.cancel();
    _ghostTimer?.cancel();
    _roomSub?.cancel();

    emit(state.copyWith(
      isCompleted: true,
      isWinner: true,
      isDraw: false,
      isSpeedTieBreak: false,
      speedDiffSeconds: 0.0,
      payoutCoins: 50,
      isWaitingForOpponentFinish: false,
    ));

    if (state.session != null) {
      await _repository.completeMatch(
        roomCode: state.session!.roomCode,
        currentUser: currentUser,
        isWinner: true,
        isDraw: false,
      );
    }
  }
}
