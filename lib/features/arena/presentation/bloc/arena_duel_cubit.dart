import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/arena/data/utils/arena_ai_difficulty_engine.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';

class ArenaDuelCubit extends Cubit<ArenaDuelState> {
  final ArenaRepository _repository;
  final Random _rng;
  Timer? _questionTimer;
  Timer? _ghostTimer;
  Timer? _advanceTimer;
  Timer? _finishTimer;
  StreamSubscription<ArenaDuelSession>? _roomSub;
  int _questionStartTime = 0;
  int _ghostAnsweredQuestionIndex = -1;
  int _currentGhostDelayMs = 0;
  bool _isGhostAnswerPending = false;

  ArenaDuelCubit({required ArenaRepository repository, Random? random})
    : _repository = repository,
      _rng = random ?? Random(),
      super(const ArenaDuelState());

  @override
  Future<void> close() {
    _questionTimer?.cancel();
    _ghostTimer?.cancel();
    _advanceTimer?.cancel();
    _finishTimer?.cancel();
    _roomSub?.cancel();
    return super.close();
  }

  void startSession(ArenaDuelSession session, UserEntity currentUser) {
    _ghostAnsweredQuestionIndex = -1;
    _currentGhostDelayMs = 0;
    _isGhostAnswerPending = false;

    emit(
      state.copyWith(session: session, isWaitingForGuest: session.isWaiting),
    );

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
          final oppCorrect = isHost ? updated.guestCorrectCount : updated.hostCorrectCount;
          final oppTimeMs = isHost ? updated.guestTotalTimeMs : updated.hostTotalTimeMs;
          emit(state.copyWith(
            session: updated,
            rivalScore: oppScore,
            rivalCorrectCount: oppCorrect,
            rivalTotalTimeMs: oppTimeMs,
          ));

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
    _questionStartTime = DateTime.now().millisecondsSinceEpoch;

    final qIndex = state.currentQuestionIndex;

    // Safety check: if previous question ghost answer didn't resolve, resolve it now
    if (state.session?.isGhostRival == true &&
        qIndex > 0 &&
        _isGhostAnswerPending) {
      _resolveGhostAnswer(qIndex - 1);
    }

    emit(
      state.copyWith(
        timeRemaining: 15,
        isAnswered: false,
        selectedOption: null,
        isCorrect: null,
      ),
    );

    // Simulate ghost opponent answering this question
    if (state.session?.isGhostRival == true) {
      _scheduleGhostAnswer(qIndex);
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

  ArenaAiDifficultyTier _getAiTier() {
    final guestId = state.session?.guestId?.toLowerCase() ?? '';
    if (guestId.contains('hard')) {
      return ArenaAiDifficultyTier.hard;
    }
    if (guestId.contains('medium') || guestId.contains('med')) {
      return ArenaAiDifficultyTier.medium;
    }
    if (guestId.contains('easy')) {
      return ArenaAiDifficultyTier.easy;
    }

    final acc = state.session?.ghostAccuracy ?? 0.80;
    if (acc >= 0.86) {
      return ArenaAiDifficultyTier.hard;
    }
    if (acc >= 0.72) {
      return ArenaAiDifficultyTier.medium;
    }
    return ArenaAiDifficultyTier.easy;
  }

  void _scheduleGhostAnswer(int qIndex) {
    _ghostTimer?.cancel();
    _isGhostAnswerPending = true;

    final tier = _getAiTier();

    // Calibrate response speed based on AI tier (realistic millisecond pacing)
    final int delayMs;
    switch (tier) {
      case ArenaAiDifficultyTier.hard:
        // 1.8s to 3.2s
        delayMs = 1800 + _rng.nextInt(1400);
        break;
      case ArenaAiDifficultyTier.medium:
        // 2.8s to 4.4s
        delayMs = 2800 + _rng.nextInt(1600);
        break;
      case ArenaAiDifficultyTier.easy:
        // 4.2s to 6.4s
        delayMs = 4200 + _rng.nextInt(2200);
        break;
    }
    _currentGhostDelayMs = delayMs;

    _ghostTimer = Timer(Duration(milliseconds: delayMs), () {
      if (isClosed || state.isCompleted) return;
      _resolveGhostAnswer(qIndex);
    });
  }

  void _resolveGhostAnswer(int questionIndex) {
    if (_ghostAnsweredQuestionIndex >= questionIndex) {
      return; // Already resolved for this question
    }
    _ghostAnsweredQuestionIndex = questionIndex;
    _isGhostAnswerPending = false;
    _ghostTimer?.cancel();

    final accuracy = state.session?.ghostAccuracy ?? 0.80;
    final isRivalCorrect = _rng.nextDouble() <= accuracy;
    final delayMs = _currentGhostDelayMs > 0 ? _currentGhostDelayMs : 3200;
    final delaySeconds = delayMs / 1000.0;
    final speedBonus = isRivalCorrect
        ? max(20, ((15.0 - delaySeconds) * 100 / 15.0).round())
        : 0;

    final newRivalScore = state.rivalScore + speedBonus;
    final newRivalCorrect = isRivalCorrect
        ? state.rivalCorrectCount + 1
        : state.rivalCorrectCount;
    final newRivalTime = state.rivalTotalTimeMs + delayMs;

    emit(
      state.copyWith(
        rivalScore: newRivalScore,
        rivalCorrectCount: newRivalCorrect,
        rivalTotalTimeMs: newRivalTime,
      ),
    );
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
    final speedPoints = isCorrect
        ? max(20, (state.timeRemaining * 100 ~/ 15))
        : 0;
    final newMyScore = state.myScore + speedPoints;
    final newMyCorrect = isCorrect
        ? state.myCorrectCount + 1
        : state.myCorrectCount;
    final newMyTime = state.myTotalTimeMs + elapsedMs;
    final newCombo = isCorrect ? state.comboStreak + 1 : 0;

    final isFirstBlood =
        !state.hasFirstBlood &&
        state.currentQuestionIndex == 0 &&
        isCorrect &&
        state.rivalScore == 0;

    emit(
      state.copyWith(
        selectedOption: index,
        isAnswered: true,
        isCorrect: isCorrect,
        myScore: newMyScore,
        myCorrectCount: newMyCorrect,
        myTotalTimeMs: newMyTime,
        comboStreak: newCombo,
        hasFirstBlood: state.hasFirstBlood || isFirstBlood,
      ),
    );

    // Submit score to live room if live
    if (state.session != null && !state.session!.isGhostRival) {
      final isHost = currentUser.id == state.session!.hostId;
      _repository.submitScore(
        roomCode: state.session!.roomCode,
        userId: currentUser.id,
        score: newMyScore,
        correctCount: newMyCorrect,
        totalTimeMs: newMyTime,
        isHost: isHost,
      );
    }

    // Delay 1.5 seconds to show correct answer before advancing
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 1500), () {
      if (isClosed) return;
      _advanceToNextQuestion(currentUser);
    });
  }

  void _onTimeExpired(UserEntity currentUser) {
    final newMyTime = state.myTotalTimeMs + 15000;
    emit(
      state.copyWith(
        isAnswered: true,
        isCorrect: false,
        myTotalTimeMs: newMyTime,
        comboStreak: 0,
      ),
    );
    if (state.session != null && !state.session!.isGhostRival) {
      final isHost = currentUser.id == state.session!.hostId;
      _repository.submitScore(
        roomCode: state.session!.roomCode,
        userId: currentUser.id,
        score: state.myScore,
        correctCount: state.myCorrectCount,
        totalTimeMs: newMyTime,
        isHost: isHost,
      );
    }
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 1000), () {
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
        // Push final telemetry to room so opponent receives complete data
        final isHost = currentUser.id == state.session!.hostId;
        _repository.submitScore(
          roomCode: state.session!.roomCode,
          userId: currentUser.id,
          score: state.myScore,
          correctCount: state.myCorrectCount,
          totalTimeMs: state.myTotalTimeMs,
          isHost: isHost,
        );
        // Fallback auto-finalize after 12s if opponent lags
        _finishTimer?.cancel();
        _finishTimer = Timer(const Duration(seconds: 12), () {
          if (!isClosed && !state.isCompleted) {
            _finalizeMatch(currentUser);
          }
        });
      } else if (isGhost) {
        // Guarantee final question is resolved for the AI opponent
        if (_isGhostAnswerPending) {
          _resolveGhostAnswer(state.currentQuestionIndex);
        }

        // Natural 1.2s suspense pause before victory screen
        emit(state.copyWith(isWaitingForOpponentFinish: true));
        _finishTimer?.cancel();
        _finishTimer = Timer(const Duration(milliseconds: 1200), () {
          if (!isClosed && !state.isCompleted) {
            _finalizeMatch(currentUser);
          }
        });
      } else {
        _finalizeMatch(currentUser);
      }
    } else {
      // Transitioning to next question:
      // Guarantee ghost answered the question we are leaving behind
      if (state.session?.isGhostRival == true && _isGhostAnswerPending) {
        _resolveGhostAnswer(state.currentQuestionIndex);
      }

      emit(state.copyWith(currentQuestionIndex: nextIndex));
      _startQuestionTimer(currentUser);
    }
  }

  Future<void> _finalizeMatch(UserEntity currentUser) async {
    _questionTimer?.cancel();
    _ghostTimer?.cancel();
    _advanceTimer?.cancel();
    _finishTimer?.cancel();
    _roomSub?.cancel();

    // Final safety check: if ghost rival is still pending any question, resolve it
    if (state.session?.isGhostRival == true && _isGhostAnswerPending) {
      _resolveGhostAnswer(state.currentQuestionIndex);
    }

    // Final sync for live opponent stats: ensure we use the latest room data if opponent updated
    final int finalRivalScore;
    final int finalRivalCorrect;
    final int finalRivalTimeMs;

    if (state.session != null && !state.session!.isGhostRival) {
      final isHost = currentUser.id == state.session!.hostId;
      final sessionOppScore = isHost ? state.session!.guestScore : state.session!.hostScore;
      final sessionOppCorrect = isHost ? state.session!.guestCorrectCount : state.session!.hostCorrectCount;
      final sessionOppTime = isHost ? state.session!.guestTotalTimeMs : state.session!.hostTotalTimeMs;

      finalRivalScore = max(state.rivalScore, sessionOppScore);
      finalRivalCorrect = max(state.rivalCorrectCount, sessionOppCorrect);
      finalRivalTimeMs = max(state.rivalTotalTimeMs, sessionOppTime);
    } else {
      finalRivalScore = state.rivalScore;
      finalRivalCorrect = state.rivalCorrectCount;
      finalRivalTimeMs = state.rivalTotalTimeMs;
    }

    final bool isScoreTie = state.myScore == finalRivalScore;
    final bool isTimeTie = state.myTotalTimeMs == finalRivalTimeMs;
    final bool isDraw = isScoreTie && isTimeTie;
    final bool isWinner;
    final bool isSpeedTieBreak;
    final double speedDiff;

    if (isDraw) {
      isWinner = false;
      isSpeedTieBreak = false;
      speedDiff = 0.0;
    } else if (!isScoreTie) {
      isWinner = state.myScore > finalRivalScore;
      isSpeedTieBreak = false;
      speedDiff = 0.0;
    } else {
      // Millisecond speed tiebreaker
      isSpeedTieBreak = true;
      isWinner = state.myTotalTimeMs < finalRivalTimeMs;
      speedDiff =
          ((finalRivalTimeMs - state.myTotalTimeMs).abs()) / 1000.0;
    }

    final totalQ = state.session?.questions.length ?? 5;
    final isPerfect = isWinner && state.myCorrectCount >= totalQ;
    final payout = isDraw ? 30 : (isWinner ? (isPerfect ? 60 : 50) : 10);

    emit(
      state.copyWith(
        isCompleted: true,
        rivalScore: finalRivalScore,
        rivalCorrectCount: finalRivalCorrect,
        rivalTotalTimeMs: finalRivalTimeMs,
        isWinner: isWinner,
        isDraw: isDraw,
        isSpeedTieBreak: isSpeedTieBreak,
        speedDiffSeconds: speedDiff,
        payoutCoins: payout,
      ),
    );

    if (state.session != null) {
      await _repository.completeMatch(
        roomCode: state.session!.roomCode,
        currentUser: currentUser,
        isWinner: isWinner,
        isDraw: isDraw,
        isPerfect: isPerfect,
      );
    }
  }

  Future<void> _finalizeForfeitWin(UserEntity currentUser) async {
    _questionTimer?.cancel();
    _ghostTimer?.cancel();
    _advanceTimer?.cancel();
    _finishTimer?.cancel();
    _roomSub?.cancel();

    emit(
      state.copyWith(
        isCompleted: true,
        isWinner: true,
        isDraw: false,
        isSpeedTieBreak: false,
        speedDiffSeconds: 0.0,
        payoutCoins: 50,
        isWaitingForOpponentFinish: false,
      ),
    );

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
