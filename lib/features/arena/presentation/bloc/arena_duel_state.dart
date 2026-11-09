import 'package:flutter/foundation.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';

@immutable
class ArenaDuelState {
  final ArenaDuelSession? session;
  final int currentQuestionIndex;
  final int myScore;
  final int rivalScore;
  final int myCorrectCount;
  final int rivalCorrectCount;
  final int myTotalTimeMs;
  final int rivalTotalTimeMs;
  final bool isSpeedTieBreak;
  final double speedDiffSeconds;
  final int? selectedOption;
  final bool isAnswered;
  final bool? isCorrect;
  final int timeRemaining;
  final bool isCompleted;
  final bool isWaitingForOpponentFinish;
  final bool isWinner;
  final bool isDraw;
  final int payoutCoins;
  final bool isWaitingForGuest;
  final int comboStreak;
  final bool hasFirstBlood;
  final String? errorMessage;

  const ArenaDuelState({
    this.session,
    this.currentQuestionIndex = 0,
    this.myScore = 0,
    this.rivalScore = 0,
    this.myCorrectCount = 0,
    this.rivalCorrectCount = 0,
    this.myTotalTimeMs = 0,
    this.rivalTotalTimeMs = 0,
    this.isSpeedTieBreak = false,
    this.speedDiffSeconds = 0.0,
    this.selectedOption,
    this.isAnswered = false,
    this.isCorrect,
    this.timeRemaining = 15,
    this.isCompleted = false,
    this.isWaitingForOpponentFinish = false,
    this.isWinner = false,
    this.isDraw = false,
    this.payoutCoins = 0,
    this.isWaitingForGuest = false,
    this.comboStreak = 0,
    this.hasFirstBlood = false,
    this.errorMessage,
  });

  ArenaQuestion? get currentQuestion {
    if (session == null || session!.questions.isEmpty) return null;
    if (currentQuestionIndex >= session!.questions.length) return null;
    return session!.questions[currentQuestionIndex];
  }

  ArenaDuelState copyWith({
    ArenaDuelSession? session,
    int? currentQuestionIndex,
    int? myScore,
    int? rivalScore,
    int? myCorrectCount,
    int? rivalCorrectCount,
    int? myTotalTimeMs,
    int? rivalTotalTimeMs,
    bool? isSpeedTieBreak,
    double? speedDiffSeconds,
    int? selectedOption,
    bool? isAnswered,
    bool? isCorrect,
    int? timeRemaining,
    bool? isCompleted,
    bool? isWaitingForOpponentFinish,
    bool? isWinner,
    bool? isDraw,
    int? payoutCoins,
    bool? isWaitingForGuest,
    int? comboStreak,
    bool? hasFirstBlood,
    String? errorMessage,
  }) {
    return ArenaDuelState(
      session: session ?? this.session,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      myScore: myScore ?? this.myScore,
      rivalScore: rivalScore ?? this.rivalScore,
      myCorrectCount: myCorrectCount ?? this.myCorrectCount,
      rivalCorrectCount: rivalCorrectCount ?? this.rivalCorrectCount,
      myTotalTimeMs: myTotalTimeMs ?? this.myTotalTimeMs,
      rivalTotalTimeMs: rivalTotalTimeMs ?? this.rivalTotalTimeMs,
      isSpeedTieBreak: isSpeedTieBreak ?? this.isSpeedTieBreak,
      speedDiffSeconds: speedDiffSeconds ?? this.speedDiffSeconds,
      selectedOption: selectedOption,
      isAnswered: isAnswered ?? this.isAnswered,
      isCorrect: isCorrect,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isCompleted: isCompleted ?? this.isCompleted,
      isWaitingForOpponentFinish:
          isWaitingForOpponentFinish ?? this.isWaitingForOpponentFinish,
      isWinner: isWinner ?? this.isWinner,
      isDraw: isDraw ?? this.isDraw,
      payoutCoins: payoutCoins ?? this.payoutCoins,
      isWaitingForGuest: isWaitingForGuest ?? this.isWaitingForGuest,
      comboStreak: comboStreak ?? this.comboStreak,
      hasFirstBlood: hasFirstBlood ?? this.hasFirstBlood,
      errorMessage: errorMessage,
    );
  }
}
