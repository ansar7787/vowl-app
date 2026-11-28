import 'package:flutter/foundation.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';

const Object _stateAbsent = _StateAbsent();

class _StateAbsent {
  const _StateAbsent();
}

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

  // === HYBRID PENTATHLON FIELDS ===
  /// Type Duel: live character count typed by rival (ghost AI or PvP).
  final int? rivalCharactersTyped;

  /// Rapid Fire Judge: active sub-item index (0–5).
  final int? rapidCurrentItemIndex;

  /// Rapid Fire Judge: user's judgments for the 6 sub-items (`[true, false, null, ...]`).
  final List<bool?>? rapidMyJudgments;

  /// Rapid Fire Judge: count of sub-items judged correctly so far.
  final int? rapidMyCorrectItems;

  /// Per-round outcome telemetry accumulated across the match (for result dialog & match history).
  final List<ArenaRoundResult> roundResults;

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
    this.rivalCharactersTyped,
    this.rapidCurrentItemIndex,
    this.rapidMyJudgments,
    this.rapidMyCorrectItems,
    this.roundResults = const [],
  });

  /// Returns the active [ArenaChallenge] for [currentQuestionIndex].
  ArenaChallenge? get currentChallenge {
    if (session == null || session!.challenges.isEmpty) return null;
    if (currentQuestionIndex < 0 ||
        currentQuestionIndex >= session!.challenges.length) {
      return null;
    }
    return session!.challenges[currentQuestionIndex];
  }

  /// Backward compat alias returning [ArenaQuestion] projection of [currentChallenge].
  @Deprecated('Use currentChallenge instead')
  ArenaQuestion? get currentQuestion => currentChallenge?.toLegacyQuestion();

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
    Object? selectedOption = _stateAbsent,
    bool? isAnswered,
    Object? isCorrect = _stateAbsent,
    int? timeRemaining,
    bool? isCompleted,
    bool? isWaitingForOpponentFinish,
    bool? isWinner,
    bool? isDraw,
    int? payoutCoins,
    bool? isWaitingForGuest,
    int? comboStreak,
    bool? hasFirstBlood,
    Object? errorMessage = _stateAbsent,
    Object? rivalCharactersTyped = _stateAbsent,
    Object? rapidCurrentItemIndex = _stateAbsent,
    Object? rapidMyJudgments = _stateAbsent,
    Object? rapidMyCorrectItems = _stateAbsent,
    List<ArenaRoundResult>? roundResults,
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
      selectedOption: identical(selectedOption, _stateAbsent)
          ? this.selectedOption
          : selectedOption as int?,
      isAnswered: isAnswered ?? this.isAnswered,
      isCorrect: identical(isCorrect, _stateAbsent)
          ? this.isCorrect
          : isCorrect as bool?,
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
      errorMessage: identical(errorMessage, _stateAbsent)
          ? this.errorMessage
          : errorMessage as String?,
      rivalCharactersTyped: identical(rivalCharactersTyped, _stateAbsent)
          ? this.rivalCharactersTyped
          : rivalCharactersTyped as int?,
      rapidCurrentItemIndex: identical(rapidCurrentItemIndex, _stateAbsent)
          ? this.rapidCurrentItemIndex
          : rapidCurrentItemIndex as int?,
      rapidMyJudgments: identical(rapidMyJudgments, _stateAbsent)
          ? this.rapidMyJudgments
          : rapidMyJudgments as List<bool?>?,
      rapidMyCorrectItems: identical(rapidMyCorrectItems, _stateAbsent)
          ? this.rapidMyCorrectItems
          : rapidMyCorrectItems as int?,
      roundResults: roundResults ?? this.roundResults,
    );
  }
}
