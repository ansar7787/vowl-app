import 'package:flutter/foundation.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_state.dart';

@immutable
class ArenaDuelState {
  final ArenaDuelSession? session;
  final int currentQuestionIndex;
  final int myScore;
  final int rivalScore;
  final int? selectedOption;
  final bool isAnswered;
  final bool? isCorrect;
  final int timeRemaining;
  final bool isCompleted;
  final bool isWinner;
  final bool isDraw;
  final int payoutCoins;
  final bool isWaitingForGuest;
  final String? errorMessage;

  const ArenaDuelState({
    this.session,
    this.currentQuestionIndex = 0,
    this.myScore = 0,
    this.rivalScore = 0,
    this.selectedOption,
    this.isAnswered = false,
    this.isCorrect,
    this.timeRemaining = 10,
    this.isCompleted = false,
    this.isWinner = false,
    this.isDraw = false,
    this.payoutCoins = 0,
    this.isWaitingForGuest = false,
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
    int? selectedOption,
    bool? isAnswered,
    bool? isCorrect,
    int? timeRemaining,
    bool? isCompleted,
    bool? isWinner,
    bool? isDraw,
    int? payoutCoins,
    bool? isWaitingForGuest,
    String? errorMessage,
  }) {
    return ArenaDuelState(
      session: session ?? this.session,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      myScore: myScore ?? this.myScore,
      rivalScore: rivalScore ?? this.rivalScore,
      selectedOption: selectedOption,
      isAnswered: isAnswered ?? this.isAnswered,
      isCorrect: isCorrect,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isCompleted: isCompleted ?? this.isCompleted,
      isWinner: isWinner ?? this.isWinner,
      isDraw: isDraw ?? this.isDraw,
      payoutCoins: payoutCoins ?? this.payoutCoins,
      isWaitingForGuest: isWaitingForGuest ?? this.isWaitingForGuest,
      errorMessage: errorMessage,
    );
  }
}
