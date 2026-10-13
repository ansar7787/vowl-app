import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/daily_words/data/services/daily_words_service.dart';
import 'package:vowl/features/daily_words/domain/entities/daily_word.dart';
import 'package:vowl/features/daily_words/domain/entities/word_progress.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/notification_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// EVENTS
// ═══════════════════════════════════════════════════════════════════════════════

abstract class DailyWordsEvent extends Equatable {
  const DailyWordsEvent();
  @override
  List<Object?> get props => [];
}

/// Initialises the service and loads today's words.
class DailyWordsLoadRequested extends DailyWordsEvent {
  final bool isPremium;
  const DailyWordsLoadRequested({this.isPremium = false});
  @override
  List<Object?> get props => [isPremium];
}

/// User taps "I know this word" or swipes to mark a word as learned.
class DailyWordMarkedLearned extends DailyWordsEvent {
  final DailyWord word;
  const DailyWordMarkedLearned(this.word);
  @override
  List<Object?> get props => [word];
}

/// User taps "Review Later" or skips a word.
class DailyWordMarkedReviewLater extends DailyWordsEvent {
  final DailyWord word;
  const DailyWordMarkedReviewLater(this.word);
  @override
  List<Object?> get props => [word];
}

/// User advances to the next word in today's set.
class DailyWordNextRequested extends DailyWordsEvent {
  const DailyWordNextRequested();
}

/// User navigates back to the previous word in today's set.
class DailyWordPreviousRequested extends DailyWordsEvent {
  const DailyWordPreviousRequested();
}

/// User completes the entire daily set.
class DailySessionCompleted extends DailyWordsEvent {
  const DailySessionCompleted();
}

/// User restarts / reviews today's session from the completion screen.
class DailySessionRestartRequested extends DailyWordsEvent {
  const DailySessionRestartRequested();
}

/// User reviews a word from the spaced-repetition queue.
class DailyWordReviewed extends DailyWordsEvent {
  final String wordId;
  final bool correct;
  const DailyWordReviewed({required this.wordId, required this.correct});
  @override
  List<Object?> get props => [wordId, correct];
}

/// Loads the Word Bank / review queue.
class WordBankLoadRequested extends DailyWordsEvent {
  final String query;
  final bool isPremium;
  const WordBankLoadRequested({this.query = '', this.isPremium = false});
  @override
  List<Object?> get props => [query, isPremium];
}

/// Resets all progress (e.g. on account deletion).
class DailyWordsResetRequested extends DailyWordsEvent {
  const DailyWordsResetRequested();
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════════════════════════

enum DailyWordsStatus { initial, loading, loaded, sessionComplete, error }

class DailyWordsState extends Equatable {
  final DailyWordsStatus status;
  final DailyWordSet? wordSet;
  final int currentIndex;
  final int streak;
  final int longestStreak;
  final int totalWordsLearned;
  final int currentDay;
  final List<WordProgress> wordBankEntries;
  final List<WordProgress> reviewQueue;
  final Map<String, int> masteryStats;
  final String? errorMessage;
  final Set<String> learnedThisSession;
  final Set<String> reviewedThisSession;

  const DailyWordsState({
    this.status = DailyWordsStatus.initial,
    this.wordSet,
    this.currentIndex = 0,
    this.streak = 0,
    this.longestStreak = 0,
    this.totalWordsLearned = 0,
    this.currentDay = 1,
    this.wordBankEntries = const [],
    this.reviewQueue = const [],
    this.masteryStats = const {},
    this.errorMessage,
    this.learnedThisSession = const {},
    this.reviewedThisSession = const {},
  });

  /// The currently displayed word, or null if out of bounds.
  DailyWord? get currentWord {
    if (wordSet == null) return null;
    if (currentIndex >= wordSet!.words.length) return null;
    return wordSet!.words[currentIndex];
  }

  /// Total words in today's set.
  int get totalWords => wordSet?.words.length ?? 0;

  /// Whether the user can navigate back to the previous word in the session.
  bool get canGoPrevious => currentIndex > 0 && status == DailyWordsStatus.loaded;

  /// Whether the user has gone through all today's words.
  bool get isSessionDone =>
      wordSet != null && currentIndex >= wordSet!.words.length;

  /// Clamped/wrapped day (1..750) for asset resolution.
  int get effectiveDay => ((currentDay - 1) % 750) + 1;

  /// Multi-year mastery cycle (Cycle 1 for days 1..750, Cycle 2 for 751..1500, etc.).
  int get cycle => ((currentDay - 1) ~/ 750) + 1;

  DailyWordsState copyWith({
    DailyWordsStatus? status,
    DailyWordSet? wordSet,
    int? currentIndex,
    int? streak,
    int? longestStreak,
    int? totalWordsLearned,
    int? currentDay,
    List<WordProgress>? wordBankEntries,
    List<WordProgress>? reviewQueue,
    Map<String, int>? masteryStats,
    String? errorMessage,
    Set<String>? learnedThisSession,
    Set<String>? reviewedThisSession,
  }) {
    return DailyWordsState(
      status: status ?? this.status,
      wordSet: wordSet ?? this.wordSet,
      currentIndex: currentIndex ?? this.currentIndex,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalWordsLearned: totalWordsLearned ?? this.totalWordsLearned,
      currentDay: currentDay ?? this.currentDay,
      wordBankEntries: wordBankEntries ?? this.wordBankEntries,
      reviewQueue: reviewQueue ?? this.reviewQueue,
      masteryStats: masteryStats ?? this.masteryStats,
      errorMessage: errorMessage ?? this.errorMessage,
      learnedThisSession: learnedThisSession ?? this.learnedThisSession,
      reviewedThisSession: reviewedThisSession ?? this.reviewedThisSession,
    );
  }

  @override
  List<Object?> get props => [
    status,
    wordSet,
    currentIndex,
    streak,
    longestStreak,
    totalWordsLearned,
    currentDay,
    wordBankEntries,
    reviewQueue,
    masteryStats,
    errorMessage,
    learnedThisSession,
    reviewedThisSession,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// BLOC
// ═══════════════════════════════════════════════════════════════════════════════

class DailyWordsBloc extends Bloc<DailyWordsEvent, DailyWordsState> {
  final DailyWordsService _service;

  DailyWordsBloc({required DailyWordsService service})
    : _service = service,
      super(const DailyWordsState()) {
    on<DailyWordsLoadRequested>(_onLoadRequested);
    on<DailyWordMarkedLearned>(_onWordMarkedLearned);
    on<DailyWordMarkedReviewLater>(_onWordMarkedReviewLater);
    on<DailyWordNextRequested>(_onNextRequested);
    on<DailyWordPreviousRequested>(_onPreviousRequested);
    on<DailySessionCompleted>(_onSessionCompleted);
    on<DailySessionRestartRequested>(_onSessionRestartRequested);
    on<DailyWordReviewed>(_onWordReviewed);
    on<WordBankLoadRequested>(_onWordBankLoadRequested);
    on<DailyWordsResetRequested>(_onResetRequested);
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onLoadRequested(
    DailyWordsLoadRequested event,
    Emitter<DailyWordsState> emit,
  ) async {
    emit(state.copyWith(status: DailyWordsStatus.loading));

    try {
      await _service.init();
      final wordSet = await _service.loadTodaysWords(
        isPremium: event.isPremium,
      );

      if (wordSet == null || wordSet.words.isEmpty) {
        emit(
          state.copyWith(
            status: DailyWordsStatus.error,
            errorMessage: 'No words available for today. Check back tomorrow!',
          ),
        );
        return;
      }

      if (_service.isTodayCompleted) {
        emit(
          state.copyWith(
            status: DailyWordsStatus.sessionComplete,
            wordSet: wordSet,
            currentIndex: wordSet.words.length,
            streak: _service.streak,
            longestStreak: _service.longestStreak,
            totalWordsLearned: _service.totalWordsLearned,
            currentDay: _service.completedDay > 0
                ? _service.completedDay
                : _service.currentDay,
            reviewQueue: _service.wordsForReview,
            masteryStats: _service.masteryStats,
            learnedThisSession: wordSet.words.map((w) => w.id).toSet(),
            errorMessage: null,
          ),
        );
        return;
      }

      // O(1) hash map lookup per word instead of repeated O(N log N) sorting
      int startingIndex = 0;
      for (int i = 0; i < wordSet.words.length; i++) {
        final id = wordSet.words[i].id;
        if (_service.hasWordEntry(id)) {
          startingIndex = i + 1;
        } else {
          break;
        }
      }

      if (startingIndex >= wordSet.words.length) {
        emit(
          state.copyWith(
            status: DailyWordsStatus.sessionComplete,
            wordSet: wordSet,
            currentIndex: startingIndex,
            streak: _service.streak,
            longestStreak: _service.longestStreak,
            totalWordsLearned: _service.totalWordsLearned,
            currentDay: _service.completedDay > 0
                ? _service.completedDay
                : _service.currentDay,
            reviewQueue: _service.wordsForReview,
            masteryStats: _service.masteryStats,
            learnedThisSession: const {},
            errorMessage: null,
          ),
        );
        return;
      }

      try {
        final dueWordsList =
            _service.wordsForReview.map((w) => w.word).toList();
        await di.sl<NotificationService>().scheduleDailyWordsReminder(
          dueWords: dueWordsList,
          streak: _service.streak,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to schedule reminder on load: $e');
      }

      emit(
        state.copyWith(
          status: DailyWordsStatus.loaded,
          wordSet: wordSet,
          currentIndex: startingIndex,
          streak: _service.streak,
          longestStreak: _service.longestStreak,
          totalWordsLearned: _service.totalWordsLearned,
          currentDay: _service.currentDay,
          reviewQueue: _service.wordsForReview,
          masteryStats: _service.masteryStats,
          learnedThisSession: const {},
          errorMessage: null,
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('DailyWordsBloc: load failed: $e');
      emit(
        state.copyWith(
          status: DailyWordsStatus.error,
          errorMessage: 'Failed to load daily words. Please try again.',
        ),
      );
    }
  }

  Future<void> _onWordMarkedLearned(
    DailyWordMarkedLearned event,
    Emitter<DailyWordsState> emit,
  ) async {
    await _service.markWordLearned(event.word);
    final updatedLearned = Set<String>.from(state.learnedThisSession)
      ..add(event.word.id);

    emit(
      state.copyWith(
        totalWordsLearned: _service.totalWordsLearned,
        masteryStats: _service.masteryStats,
        wordBankEntries: _service.wordBankEntries,
        learnedThisSession: updatedLearned,
      ),
    );
  }

  Future<void> _onWordMarkedReviewLater(
    DailyWordMarkedReviewLater event,
    Emitter<DailyWordsState> emit,
  ) async {
    await _service.markWordNeedsReview(event.word);
    final updatedReviewed = Set<String>.from(state.reviewedThisSession)
      ..add(event.word.id);

    emit(
      state.copyWith(
        masteryStats: _service.masteryStats,
        wordBankEntries: _service.wordBankEntries,
        reviewQueue: _service.wordsForReview,
        reviewedThisSession: updatedReviewed,
      ),
    );
  }

  Future<void> _onNextRequested(
    DailyWordNextRequested event,
    Emitter<DailyWordsState> emit,
  ) async {
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.totalWords) {
      // Session complete
      await _service.completeDailySession();
      try {
        final dueWordsList =
            _service.wordsForReview.map((w) => w.word).toList();
        await di.sl<NotificationService>().scheduleDailyWordsReminder(
          dueWords: dueWordsList,
          streak: _service.streak,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to schedule reminder: $e');
      }

      emit(
        state.copyWith(
          status: DailyWordsStatus.sessionComplete,
          currentIndex: nextIndex,
          currentDay: _service.completedDay > 0
              ? _service.completedDay
              : _service.currentDay,
        ),
      );
    } else {
      emit(state.copyWith(currentIndex: nextIndex));
    }
  }

  void _onPreviousRequested(
    DailyWordPreviousRequested event,
    Emitter<DailyWordsState> emit,
  ) {
    if (state.currentIndex > 0) {
      emit(state.copyWith(currentIndex: state.currentIndex - 1));
    }
  }

  Future<void> _onSessionCompleted(
    DailySessionCompleted event,
    Emitter<DailyWordsState> emit,
  ) async {
    await _service.completeDailySession();
    emit(
      state.copyWith(
        status: DailyWordsStatus.sessionComplete,
        currentDay: _service.completedDay > 0
            ? _service.completedDay
            : _service.currentDay,
      ),
    );
  }

  void _onSessionRestartRequested(
    DailySessionRestartRequested event,
    Emitter<DailyWordsState> emit,
  ) {
    emit(
      state.copyWith(
        status: DailyWordsStatus.loaded,
        currentIndex: 0,
        learnedThisSession: const {},
        reviewedThisSession: const {},
      ),
    );
  }

  Future<void> _onWordReviewed(
    DailyWordReviewed event,
    Emitter<DailyWordsState> emit,
  ) async {
    await _service.recordReview(event.wordId, correct: event.correct);
    emit(
      state.copyWith(
        wordBankEntries: _service.wordBankEntries,
        reviewQueue: _service.wordsForReview,
        masteryStats: _service.masteryStats,
      ),
    );
  }

  Future<void> _onWordBankLoadRequested(
    WordBankLoadRequested event,
    Emitter<DailyWordsState> emit,
  ) async {
    // Ensure service is initialized if opened directly from WordBank route
    await _service.init();
    if (_service.todaysWords == null) {
      await _service.loadTodaysWords(isPremium: event.isPremium);
    }
    final results = _service.searchWordBank(
      event.query,
      isPremium: event.isPremium,
    );
    emit(
      state.copyWith(
        wordBankEntries: results,
        reviewQueue: _service.wordsForReview,
        masteryStats: _service.masteryStats,
      ),
    );
  }

  Future<void> _onResetRequested(
    DailyWordsResetRequested event,
    Emitter<DailyWordsState> emit,
  ) async {
    await _service.reset();
    emit(const DailyWordsState());
  }
}
