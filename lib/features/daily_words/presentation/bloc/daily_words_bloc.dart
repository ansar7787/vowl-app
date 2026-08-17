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

/// User advances to the next word in today's set.
class DailyWordNextRequested extends DailyWordsEvent {
  const DailyWordNextRequested();
}

/// User completes the entire daily set.
class DailySessionCompleted extends DailyWordsEvent {
  const DailySessionCompleted();
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
  });

  /// The currently displayed word, or null if out of bounds.
  DailyWord? get currentWord {
    if (wordSet == null) return null;
    if (currentIndex >= wordSet!.words.length) return null;
    return wordSet!.words[currentIndex];
  }

  /// Total words in today's set.
  int get totalWords => wordSet?.words.length ?? 0;

  /// Whether the user has gone through all today's words.
  bool get isSessionDone =>
      wordSet != null && currentIndex >= wordSet!.words.length;

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
    on<DailyWordNextRequested>(_onNextRequested);
    on<DailySessionCompleted>(_onSessionCompleted);
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

      int startingIndex = 0;
      for (int i = 0; i < wordSet.words.length; i++) {
        final id = wordSet.words[i].id;
        final alreadyLearned = _service.wordBankEntries.any((wp) => wp.wordId == id);
        if (alreadyLearned) {
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
            currentDay: _service.currentDay,
            reviewQueue: _service.wordsForReview,
            masteryStats: _service.masteryStats,
            learnedThisSession: const {},
            errorMessage: null,
          ),
        );
        return;
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
        learnedThisSession: updatedLearned,
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
        await di.sl<NotificationService>().scheduleDailyWordsReminder();
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to schedule reminder: $e');
      }

      emit(
        state.copyWith(
          status: DailyWordsStatus.sessionComplete,
          currentIndex: nextIndex,
          currentDay: _service.currentDay,
        ),
      );
    } else {
      emit(state.copyWith(currentIndex: nextIndex));
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
        currentDay: _service.currentDay,
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
        reviewQueue: _service.wordsForReview,
        masteryStats: _service.masteryStats,
      ),
    );
  }

  Future<void> _onWordBankLoadRequested(
    WordBankLoadRequested event,
    Emitter<DailyWordsState> emit,
  ) async {
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
