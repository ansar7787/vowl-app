import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/arena/data/utils/arena_ai_difficulty_engine.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/entities/arena_match_record.dart';
import 'package:vowl/features/arena/domain/entities/arena_rank.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';

class ArenaDuelCubit extends Cubit<ArenaDuelState> {
  final ArenaRepository _repository;
  final Random _rng;
  Timer? _questionTimer;
  Timer? _ghostTimer;
  Timer? _ghostTypingTimer;
  Timer? _advanceTimer;
  Timer? _finishTimer;
  StreamSubscription<ArenaDuelSession>? _roomSub;
  StreamSubscription<int>? _typingSub;

  int _questionStartTime = 0;
  int _ghostAnsweredQuestionIndex = -1;
  int _currentGhostDelayMs = 0;
  bool _isGhostAnswerPending = false;

  // Draft tracking for timeout evaluation & live PvP typing throttle
  String _currentTypeDuelDraft = '';
  String _currentSpeedSpellDraft = '';
  int _lastTypingSyncMs = 0;
  int _lastSyncedChars = -1;

  ArenaDuelCubit({required ArenaRepository repository, Random? random})
    : _repository = repository,
      _rng = random ?? Random(),
      super(const ArenaDuelState());

  @override
  Future<void> close() {
    _cancelAllTimersAndSubs();
    return super.close();
  }

  void _cancelAllTimersAndSubs() {
    _questionTimer?.cancel();
    _ghostTimer?.cancel();
    _ghostTypingTimer?.cancel();
    _advanceTimer?.cancel();
    _finishTimer?.cancel();
    _roomSub?.cancel();
    _typingSub?.cancel();
  }

  void startSession(ArenaDuelSession session, UserEntity currentUser) {
    _ghostAnsweredQuestionIndex = -1;
    _currentGhostDelayMs = 0;
    _isGhostAnswerPending = false;
    _currentTypeDuelDraft = '';
    _currentSpeedSpellDraft = '';

    emit(
      state.copyWith(
        session: session,
        isWaitingForGuest: session.isWaiting,
        roundResults: const [],
      ),
    );

    if (!session.isWaiting) {
      _startQuestionTimer(currentUser);
    }

    if (!session.isGhostRival) {
      _roomSub = _repository.listenToRoom(session.roomCode).listen((updated) {
        if (state.isWaitingForGuest && !updated.isWaiting) {
          emit(state.copyWith(session: updated, isWaitingForGuest: false));
          _startQuestionTimer(currentUser);
          _attachLiveTypingListener(updated, currentUser);
        } else {
          final isHost = currentUser.id == updated.hostId;
          final oppScore = isHost ? updated.guestScore : updated.hostScore;
          final oppCorrect = isHost
              ? updated.guestCorrectCount
              : updated.hostCorrectCount;
          final oppTimeMs = isHost
              ? updated.guestTotalTimeMs
              : updated.hostTotalTimeMs;
          emit(
            state.copyWith(
              session: updated,
              rivalScore: oppScore,
              rivalCorrectCount: oppCorrect,
              rivalTotalTimeMs: oppTimeMs,
            ),
          );

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

      if (!session.isWaiting) {
        _attachLiveTypingListener(session, currentUser);
      }
    }
  }

  void _attachLiveTypingListener(
    ArenaDuelSession session,
    UserEntity currentUser,
  ) {
    final isHost = currentUser.id == session.hostId;
    final rivalId = isHost ? session.guestId : session.hostId;
    if (rivalId == null || rivalId.isEmpty) return;

    _typingSub?.cancel();
    _typingSub = _repository
        .listenToRivalTypingProgress(
          roomCode: session.roomCode,
          rivalId: rivalId,
        )
        .listen((chars) {
          if (isClosed || state.isCompleted) return;
          if (state.currentChallenge?.mechanic == ArenaMechanicType.typeDuel) {
            emit(state.copyWith(rivalCharactersTyped: chars));
          }
        });
  }

  /// Timer duration in seconds for a specific mechanic type.
  int timerForMechanic(ArenaMechanicType mechanic) => mechanic.timerSeconds;

  void _startQuestionTimer(UserEntity currentUser) {
    _questionTimer?.cancel();
    _ghostTimer?.cancel();
    _ghostTypingTimer?.cancel();
    _questionStartTime = DateTime.now().millisecondsSinceEpoch;
    _currentTypeDuelDraft = '';
    _currentSpeedSpellDraft = '';
    _lastSyncedChars = -1;

    final qIndex = state.currentQuestionIndex;

    // Safety check: if previous round ghost answer didn't resolve, resolve it now
    if (state.session?.isGhostRival == true &&
        qIndex > 0 &&
        _isGhostAnswerPending) {
      _resolveGhostAnswer(qIndex - 1);
    }

    final activeChallenge = state.currentChallenge;
    final mechanic = activeChallenge?.mechanic ?? ArenaMechanicType.mcq;
    final maxSeconds = timerForMechanic(mechanic);
    final isRapid = mechanic == ArenaMechanicType.rapidJudge;
    final rapidCount = isRapid ? (activeChallenge?.rapidItems?.length ?? 6) : 0;

    emit(
      state.copyWith(
        timeRemaining: maxSeconds,
        isAnswered: false,
        selectedOption: null,
        isCorrect: null,
        rivalCharactersTyped: null,
        rapidCurrentItemIndex: isRapid ? 0 : null,
        rapidMyJudgments: isRapid ? List<bool?>.filled(rapidCount, null) : null,
        rapidMyCorrectItems: isRapid ? 0 : null,
      ),
    );

    // Simulate ghost opponent answering this round
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

  int _singleAnswerDelay(ArenaAiDifficultyTier tier) {
    switch (tier) {
      case ArenaAiDifficultyTier.hard:
        return 1800 + _rng.nextInt(1400);
      case ArenaAiDifficultyTier.medium:
        return 2800 + _rng.nextInt(1600);
      case ArenaAiDifficultyTier.easy:
        return 4200 + _rng.nextInt(2200);
    }
  }

  int _baseDelay(ArenaAiDifficultyTier tier) {
    switch (tier) {
      case ArenaAiDifficultyTier.easy:
        return 2800 + _rng.nextInt(1400);
      case ArenaAiDifficultyTier.medium:
        return 1800 + _rng.nextInt(1000);
      case ArenaAiDifficultyTier.hard:
        return 1000 + _rng.nextInt(800);
    }
  }

  int _perLetterMs(ArenaAiDifficultyTier tier) {
    switch (tier) {
      case ArenaAiDifficultyTier.easy:
        return 700 + _rng.nextInt(300);
      case ArenaAiDifficultyTier.medium:
        return 400 + _rng.nextInt(200);
      case ArenaAiDifficultyTier.hard:
        return 200 + _rng.nextInt(150);
    }
  }

  int _perCharMs(ArenaAiDifficultyTier tier) {
    switch (tier) {
      case ArenaAiDifficultyTier.easy:
        return 600 + _rng.nextInt(300);
      case ArenaAiDifficultyTier.medium:
        return 350 + _rng.nextInt(200);
      case ArenaAiDifficultyTier.hard:
        return 200 + _rng.nextInt(150);
    }
  }

  int _perItemMs(ArenaAiDifficultyTier tier) {
    switch (tier) {
      case ArenaAiDifficultyTier.easy:
        return 3500 + _rng.nextInt(1500);
      case ArenaAiDifficultyTier.medium:
        return 2500 + _rng.nextInt(1000);
      case ArenaAiDifficultyTier.hard:
        return 1500 + _rng.nextInt(1000);
    }
  }

  int _perTileMs(ArenaAiDifficultyTier tier) {
    switch (tier) {
      case ArenaAiDifficultyTier.easy:
        return 1200 + _rng.nextInt(600);
      case ArenaAiDifficultyTier.medium:
        return 800 + _rng.nextInt(400);
      case ArenaAiDifficultyTier.hard:
        return 400 + _rng.nextInt(400);
    }
  }

  void _streamGhostTypingProgress(int wordLength, int totalDelayMs) {
    _ghostTypingTimer?.cancel();
    if (wordLength <= 0) return;

    final perCharDelay = max(120, totalDelayMs ~/ wordLength);
    var charsTyped = 0;

    _ghostTypingTimer = Timer.periodic(Duration(milliseconds: perCharDelay), (
      timer,
    ) {
      if (isClosed || state.isCompleted) {
        timer.cancel();
        return;
      }
      charsTyped++;
      emit(state.copyWith(rivalCharactersTyped: charsTyped));
      if (charsTyped >= wordLength) {
        timer.cancel();
      }
    });
  }

  void _scheduleGhostAnswer(int qIndex) {
    _ghostTimer?.cancel();
    _ghostTypingTimer?.cancel();
    _isGhostAnswerPending = true;

    final tier = _getAiTier();
    final challenge = state.currentChallenge;
    final mechanic = challenge?.mechanic ?? ArenaMechanicType.mcq;
    final maxMs = timerForMechanic(mechanic) * 1000;

    final int rawDelayMs;
    switch (mechanic) {
      case ArenaMechanicType.mcq:
      case ArenaMechanicType.spotError:
        rawDelayMs = _singleAnswerDelay(tier);
        break;
      case ArenaMechanicType.wordSnap:
        final letters =
            challenge?.scrambledLetters?.length ??
            challenge?.correctAnswer.length ??
            7;
        rawDelayMs = _baseDelay(tier) + (letters * _perLetterMs(tier));
        break;
      case ArenaMechanicType.speedSpell:
        final missing = challenge?.missingPositions?.length ?? 3;
        rawDelayMs = _baseDelay(tier) + (missing * _perLetterMs(tier));
        break;
      case ArenaMechanicType.typeDuel:
        final wordLen = max(4, challenge?.correctAnswer.length ?? 7);
        rawDelayMs = _baseDelay(tier) + (wordLen * _perCharMs(tier));
        final clampedDelay = rawDelayMs.clamp(800, maxMs - 500);
        _streamGhostTypingProgress(wordLen, clampedDelay);
        break;
      case ArenaMechanicType.rapidJudge:
        final itemCount = challenge?.rapidItems?.length ?? 6;
        rawDelayMs = itemCount * _perItemMs(tier);
        break;
      case ArenaMechanicType.sentenceBuild:
        final tileCount = challenge?.shuffledWords?.length ?? 6;
        rawDelayMs = _baseDelay(tier) + (tileCount * _perTileMs(tier));
        break;
      case ArenaMechanicType.voiceDuel:
        rawDelayMs = _singleAnswerDelay(tier);
        break;
    }

    final delayMs = rawDelayMs.clamp(800, maxMs - 500);
    _currentGhostDelayMs = delayMs;

    _ghostTimer = Timer(Duration(milliseconds: delayMs), () {
      if (isClosed || state.isCompleted) return;
      _resolveGhostAnswer(qIndex);
    });
  }

  void _resolveGhostAnswer(int roundIndex) {
    if (_ghostAnsweredQuestionIndex >= roundIndex) {
      return; // Already resolved for this round
    }
    _ghostAnsweredQuestionIndex = roundIndex;
    _isGhostAnswerPending = false;
    _ghostTimer?.cancel();
    _ghostTypingTimer?.cancel();

    final challenges = state.session?.challenges ?? const [];
    final challenge = (roundIndex >= 0 && roundIndex < challenges.length)
        ? challenges[roundIndex]
        : null;
    final mechanic = challenge?.mechanic ?? ArenaMechanicType.mcq;
    final maxSec = timerForMechanic(mechanic).toDouble();

    final accuracy = state.session?.ghostAccuracy ?? 0.80;
    final delayMs = _currentGhostDelayMs > 0 ? _currentGhostDelayMs : 3200;
    final delaySeconds = delayMs / 1000.0;

    final bool isRivalCorrect;
    final int speedBonus;

    if (mechanic == ArenaMechanicType.rapidJudge) {
      final totalItems = challenge?.rapidItems?.length ?? 6;
      var ghostCorrectItems = 0;
      for (var i = 0; i < totalItems; i++) {
        if (_rng.nextDouble() <= accuracy) {
          ghostCorrectItems++;
        }
      }
      final accRatio = totalItems > 0 ? ghostCorrectItems / totalItems : 0.0;
      final speedFactor = max(0.2, (maxSec - delaySeconds) / maxSec);
      speedBonus = (accRatio * speedFactor * 100).round();
      isRivalCorrect = ghostCorrectItems >= (totalItems / 2).ceil();
    } else {
      isRivalCorrect = _rng.nextDouble() <= accuracy;
      speedBonus = isRivalCorrect
          ? max(20, ((maxSec - delaySeconds) * 100 / maxSec).round())
          : 0;
    }

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

  // =========================================================================
  // DRAFT INPUT TRACKERS (Type Duel live sync & timeout evaluation)
  // =========================================================================

  /// Called when Type Duel text changes so timeouts evaluate typed drafts and
  /// live PvP rivals see character count progress (throttled every 500ms).
  void onTypeDuelTextChanged(String text, UserEntity currentUser) {
    if (state.isAnswered) return;
    _currentTypeDuelDraft = text;

    final session = state.session;
    if (session != null && !session.isGhostRival) {
      final len = text.length;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (len != _lastSyncedChars && nowMs - _lastTypingSyncMs >= 500) {
        _lastSyncedChars = len;
        _lastTypingSyncMs = nowMs;
        unawaited(
          _repository.updateTypingProgress(
            roomCode: session.roomCode,
            userId: currentUser.id,
            charactersTyped: len,
          ),
        );
      }
    }
  }

  /// Called as Speed Spell letter boxes change so timeouts can check completeness.
  void onSpeedSpellDraftChanged(String filledLetters) {
    if (state.isAnswered) return;
    _currentSpeedSpellDraft = filledLetters;
  }

  // =========================================================================
  // MECHANIC SUBMIT METHODS (1..7)
  // =========================================================================

  /// Mechanic 6: MCQ Classic — player tapped an option tile.
  void selectOption(int index, UserEntity currentUser) {
    final challenge = state.currentChallenge;
    if (state.isAnswered || challenge == null) return;
    final isCorrect = index == (challenge.correctIndex ?? -1);
    _scoreRound(
      isCorrect: isCorrect,
      currentUser: currentUser,
      selectedOption: index,
    );
  }

  /// Mechanic 1: Word Snap — player tapped all scrambled letters to spell the word.
  void submitWordSnap(String spelledWord, UserEntity currentUser) {
    final challenge = state.currentChallenge;
    if (state.isAnswered || challenge == null) return;
    final normalized = spelledWord.trim().toLowerCase();
    final target = challenge.correctAnswer.trim().toLowerCase();
    final isCorrect = normalized.isNotEmpty && normalized == target;
    _scoreRound(isCorrect: isCorrect, currentUser: currentUser);
  }

  /// Mechanic 2: Type Duel — player submitted typed word from definition.
  void submitTypeDuel(String typedWord, UserEntity currentUser) {
    final challenge = state.currentChallenge;
    if (state.isAnswered || challenge == null) return;
    final isCorrect = _evaluateTypeDuelAnswer(typedWord, challenge);
    _scoreRound(isCorrect: isCorrect, currentUser: currentUser);
  }

  bool _evaluateTypeDuelAnswer(String typedWord, ArenaChallenge challenge) {
    final normalized = typedWord.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    if (normalized == challenge.correctAnswer.trim().toLowerCase()) {
      return true;
    }
    final spellings = challenge.acceptedSpellings;
    if (spellings != null) {
      for (final alt in spellings) {
        if (normalized == alt.trim().toLowerCase()) {
          return true;
        }
      }
    }
    return false;
  }

  /// Mechanic 3: Rapid Fire Judge — player judged one sub-item (0–5).
  void submitRapidJudgment(
    int itemIndex,
    bool judgedCorrect,
    UserEntity currentUser,
  ) {
    final challenge = state.currentChallenge;
    if (state.isAnswered || challenge == null) return;
    final items = challenge.rapidItems;
    if (items == null || itemIndex < 0 || itemIndex >= items.length) return;

    final currentJudgments = List<bool?>.from(
      state.rapidMyJudgments ?? List<bool?>.filled(items.length, null),
    );
    if (currentJudgments[itemIndex] != null) return; // Already judged

    currentJudgments[itemIndex] = judgedCorrect;
    final itemWasCorrect = judgedCorrect == items[itemIndex].isCorrect;
    final updatedCorrectItems =
        (state.rapidMyCorrectItems ?? 0) + (itemWasCorrect ? 1 : 0);

    final nextItemIndex = itemIndex + 1;
    emit(
      state.copyWith(
        rapidMyJudgments: currentJudgments,
        rapidMyCorrectItems: updatedCorrectItems,
        rapidCurrentItemIndex: min(nextItemIndex, items.length - 1),
      ),
    );

    if (nextItemIndex >= items.length) {
      finalizeRapidRound(currentUser);
    }
  }

  /// Mechanic 3: Finalizes Rapid Fire Judge round using partial-credit formula:
  /// `accuracyRatio * speedFactor * 100`.
  void finalizeRapidRound(UserEntity currentUser, {bool isTimeout = false}) {
    final challenge = state.currentChallenge;
    if (state.isAnswered || challenge == null) return;
    _questionTimer?.cancel();

    final maxSec = timerForMechanic(ArenaMechanicType.rapidJudge);
    final maxMs = maxSec * 1000;
    final totalItems = challenge.rapidItems?.length ?? 6;
    final correctItems = state.rapidMyCorrectItems ?? 0;

    final int elapsedMs;
    if (isTimeout) {
      elapsedMs = maxMs;
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      elapsedMs = _questionStartTime > 0
          ? (now - _questionStartTime).clamp(300, maxMs)
          : ((maxSec - state.timeRemaining) * 1000).clamp(300, maxMs);
    }

    final accuracyRatio = totalItems > 0 ? (correctItems / totalItems) : 0.0;
    final timeRemainingMs = max(0, maxMs - elapsedMs);
    final speedFactor = max(0.2, timeRemainingMs / maxMs);
    final speedPoints = correctItems > 0
        ? (accuracyRatio * speedFactor * 100).round()
        : 0;
    final isCorrect = correctItems >= (totalItems / 2).ceil();

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

    final roundResult = ArenaRoundResult(
      mechanic: ArenaMechanicType.rapidJudge,
      isCorrect: isCorrect,
      myTimeMs: elapsedMs,
      myPoints: speedPoints,
      rapidCorrectItems: correctItems,
      rapidTotalItems: totalItems,
    );

    emit(
      state.copyWith(
        isAnswered: true,
        isCorrect: isCorrect,
        myScore: newMyScore,
        myCorrectCount: newMyCorrect,
        myTotalTimeMs: newMyTime,
        comboStreak: newCombo,
        hasFirstBlood: state.hasFirstBlood || isFirstBlood,
        roundResults: [...state.roundResults, roundResult],
      ),
    );

    _submitScoreIfLive(currentUser, newMyScore, newMyCorrect, newMyTime);
    _scheduleAdvance(currentUser, delayMs: isTimeout ? 1000 : 1500);
  }

  /// Mechanic 4: Sentence Build — player arranged all word tiles.
  void submitSentenceBuild(
    List<String> orderedWords,
    UserEntity currentUser,
  ) {
    final challenge = state.currentChallenge;
    if (state.isAnswered || challenge == null) return;
    final built = orderedWords.join(' ').trim().toLowerCase();
    final target = challenge.correctAnswer.trim().toLowerCase();
    final isCorrect = built.isNotEmpty && built == target;
    _scoreRound(isCorrect: isCorrect, currentUser: currentUser);
  }

  /// Mechanic 5: Spot the Error — player tapped a word token index.
  void submitSpotError(int tappedTokenIndex, UserEntity currentUser) {
    final challenge = state.currentChallenge;
    if (state.isAnswered || challenge == null) return;
    final isCorrect = tappedTokenIndex == (challenge.errorTokenIndex ?? -1);
    _scoreRound(
      isCorrect: isCorrect,
      currentUser: currentUser,
      selectedOption: tappedTokenIndex,
    );
  }

  /// Mechanic 7: Speed Spell — player filled all missing letters.
  void submitSpeedSpell(String filledLetters, UserEntity currentUser) {
    final challenge = state.currentChallenge;
    if (state.isAnswered || challenge == null) return;
    final isCorrect = _evaluateSpeedSpellAnswer(filledLetters, challenge);
    _scoreRound(isCorrect: isCorrect, currentUser: currentUser);
  }

  bool _evaluateSpeedSpellAnswer(
    String filledLetters,
    ArenaChallenge challenge,
  ) {
    final missing = challenge.missingLetters;
    if (missing == null || missing.isEmpty) return false;
    final normalized = filledLetters.trim().toLowerCase();
    final expected = missing.join('').toLowerCase();
    return normalized.length == expected.length && normalized == expected;
  }

  // =========================================================================
  // UNIVERSAL SCORING & TIMEOUT
  // =========================================================================

  void _scoreRound({
    required bool isCorrect,
    required UserEntity currentUser,
    int? selectedOption,
    int? overridePoints,
    int? overrideElapsedMs,
    int advanceDelayMs = 1500,
  }) {
    final challenge = state.currentChallenge;
    if (challenge == null) return;
    _questionTimer?.cancel();

    final maxSec = timerForMechanic(challenge.mechanic);
    final maxMs = maxSec * 1000;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedMs =
        overrideElapsedMs ??
        (_questionStartTime > 0
            ? (now - _questionStartTime).clamp(300, maxMs)
            : ((maxSec - state.timeRemaining) * 1000).clamp(300, maxMs));

    final speedPoints =
        overridePoints ??
        (isCorrect ? max(20, (state.timeRemaining * 100 ~/ maxSec)) : 0);

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

    final roundResult = ArenaRoundResult(
      mechanic: challenge.mechanic,
      isCorrect: isCorrect,
      myTimeMs: elapsedMs,
      myPoints: speedPoints,
    );

    emit(
      state.copyWith(
        selectedOption: selectedOption,
        isAnswered: true,
        isCorrect: isCorrect,
        myScore: newMyScore,
        myCorrectCount: newMyCorrect,
        myTotalTimeMs: newMyTime,
        comboStreak: newCombo,
        hasFirstBlood: state.hasFirstBlood || isFirstBlood,
        roundResults: [...state.roundResults, roundResult],
      ),
    );

    _submitScoreIfLive(currentUser, newMyScore, newMyCorrect, newMyTime);
    _scheduleAdvance(currentUser, delayMs: advanceDelayMs);
  }

  void _onTimeExpired(UserEntity currentUser) {
    final challenge = state.currentChallenge;
    if (challenge == null || state.isAnswered) return;

    final maxMs = timerForMechanic(challenge.mechanic) * 1000;

    switch (challenge.mechanic) {
      case ArenaMechanicType.rapidJudge:
        // Unanswered sub-items count as wrong; score whatever was judged.
        finalizeRapidRound(currentUser, isTimeout: true);
        return;

      case ArenaMechanicType.typeDuel:
        // Evaluate whatever is typed: late-but-correct earns minimum 20 pts.
        final isCorrect = _evaluateTypeDuelAnswer(
          _currentTypeDuelDraft,
          challenge,
        );
        _scoreRound(
          isCorrect: isCorrect,
          currentUser: currentUser,
          overridePoints: isCorrect ? 20 : 0,
          overrideElapsedMs: maxMs,
          advanceDelayMs: 1000,
        );
        return;

      case ArenaMechanicType.speedSpell:
        // Partial fills = 0; all blanks filled correctly = minimum 20 pts.
        final isCorrect = _evaluateSpeedSpellAnswer(
          _currentSpeedSpellDraft,
          challenge,
        );
        _scoreRound(
          isCorrect: isCorrect,
          currentUser: currentUser,
          overridePoints: isCorrect ? 20 : 0,
          overrideElapsedMs: maxMs,
          advanceDelayMs: 1000,
        );
        return;

      case ArenaMechanicType.mcq:
      case ArenaMechanicType.wordSnap:
      case ArenaMechanicType.sentenceBuild:
      case ArenaMechanicType.spotError:
      case ArenaMechanicType.voiceDuel:
        _scoreRound(
          isCorrect: false,
          currentUser: currentUser,
          overridePoints: 0,
          overrideElapsedMs: maxMs,
          advanceDelayMs: 1000,
        );
        return;
    }
  }

  void _submitScoreIfLive(
    UserEntity currentUser,
    int score,
    int correctCount,
    int totalTimeMs,
  ) {
    if (state.session != null && !state.session!.isGhostRival) {
      final isHost = currentUser.id == state.session!.hostId;
      _repository.submitScore(
        roomCode: state.session!.roomCode,
        userId: currentUser.id,
        score: score,
        correctCount: correctCount,
        totalTimeMs: totalTimeMs,
        isHost: isHost,
      );
    }
  }

  void _scheduleAdvance(UserEntity currentUser, {int delayMs = 1500}) {
    _advanceTimer?.cancel();
    _advanceTimer = Timer(Duration(milliseconds: delayMs), () {
      if (isClosed) return;
      _advanceToNextQuestion(currentUser);
    });
  }

  void _advanceToNextQuestion(UserEntity currentUser) {
    final nextIndex = state.currentQuestionIndex + 1;
    final totalRounds = state.session?.challenges.length ?? 7;

    if (nextIndex >= totalRounds) {
      final isGhost = state.session?.isGhostRival ?? false;
      final hasGuest = state.session?.guestId != null;

      if (!isGhost && hasGuest) {
        emit(state.copyWith(isWaitingForOpponentFinish: true));
        _submitScoreIfLive(
          currentUser,
          state.myScore,
          state.myCorrectCount,
          state.myTotalTimeMs,
        );
        // Fallback auto-finalize after 12s if opponent lags
        _finishTimer?.cancel();
        _finishTimer = Timer(const Duration(seconds: 12), () {
          if (!isClosed && !state.isCompleted) {
            _finalizeMatch(currentUser);
          }
        });
      } else if (isGhost) {
        // Guarantee final round is resolved for AI opponent
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
      // Transitioning to next round: guarantee ghost answered previous round
      if (state.session?.isGhostRival == true && _isGhostAnswerPending) {
        _resolveGhostAnswer(state.currentQuestionIndex);
      }

      emit(state.copyWith(currentQuestionIndex: nextIndex));
      _startQuestionTimer(currentUser);
    }
  }

  Future<void> _finalizeMatch(UserEntity currentUser) async {
    _cancelAllTimersAndSubs();

    // Final safety check: resolve any pending ghost answer
    if (state.session?.isGhostRival == true && _isGhostAnswerPending) {
      _resolveGhostAnswer(state.currentQuestionIndex);
    }

    final int finalRivalScore;
    final int finalRivalCorrect;
    final int finalRivalTimeMs;

    if (state.session != null && !state.session!.isGhostRival) {
      final isHost = currentUser.id == state.session!.hostId;
      final sessionOppScore = isHost
          ? state.session!.guestScore
          : state.session!.hostScore;
      final sessionOppCorrect = isHost
          ? state.session!.guestCorrectCount
          : state.session!.hostCorrectCount;
      final sessionOppTime = isHost
          ? state.session!.guestTotalTimeMs
          : state.session!.hostTotalTimeMs;

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
      speedDiff = ((finalRivalTimeMs - state.myTotalTimeMs).abs()) / 1000.0;
    }

    final totalRounds = state.session?.challenges.length ?? 7;
    final isPerfect = isWinner && state.myCorrectCount >= totalRounds;
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
      final session = state.session!;
      await _repository.completeMatch(
        roomCode: session.roomCode,
        currentUser: currentUser,
        isWinner: isWinner,
        isDraw: isDraw,
        isPerfect: isPerfect,
      );

      final oppWins = session.opponentDuelWins(currentUser.id);
      final matchRecord = ArenaMatchRecord(
        id: '${session.roomCode}_${DateTime.now().millisecondsSinceEpoch}',
        roomCode: session.roomCode,
        opponentName: session.opponentName(currentUser.id),
        opponentPhotoUrl: session.opponentPhotoUrl(currentUser.id),
        opponentRank: oppWins.arenaRank,
        isGhostRival: session.isGhostRival,
        result: isDraw ? 'draw' : (isWinner ? 'win' : 'loss'),
        myScore: state.myScore,
        rivalScore: finalRivalScore,
        myCorrectCount: state.myCorrectCount,
        rivalCorrectCount: finalRivalCorrect,
        myTotalTimeMs: state.myTotalTimeMs,
        rivalTotalTimeMs: finalRivalTimeMs,
        rounds: state.roundResults,
        timestamp: DateTime.now(),
      );
      await _repository.writeMatchHistory(
        userId: currentUser.id,
        record: matchRecord,
      );
    }
  }

  Future<void> _finalizeForfeitWin(UserEntity currentUser) async {
    _cancelAllTimersAndSubs();

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
      final session = state.session!;
      await _repository.completeMatch(
        roomCode: session.roomCode,
        currentUser: currentUser,
        isWinner: true,
        isDraw: false,
      );

      final matchRecord = ArenaMatchRecord(
        id: '${session.roomCode}_forfeit_${DateTime.now().millisecondsSinceEpoch}',
        roomCode: session.roomCode,
        opponentName: session.opponentName(currentUser.id),
        opponentPhotoUrl: session.opponentPhotoUrl(currentUser.id),
        opponentRank: session.opponentDuelWins(currentUser.id).arenaRank,
        isGhostRival: session.isGhostRival,
        result: 'win',
        myScore: state.myScore,
        rivalScore: state.rivalScore,
        myCorrectCount: state.myCorrectCount,
        rivalCorrectCount: state.rivalCorrectCount,
        myTotalTimeMs: state.myTotalTimeMs,
        rivalTotalTimeMs: state.rivalTotalTimeMs,
        rounds: state.roundResults,
        timestamp: DateTime.now(),
      );
      await _repository.writeMatchHistory(
        userId: currentUser.id,
        record: matchRecord,
      );
    }
  }
}
