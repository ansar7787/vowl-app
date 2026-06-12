import 'package:equatable/equatable.dart';
import '../../domain/entities/listening_quest.dart';

/// All possible states emitted by [ListeningBloc].
abstract class ListeningState extends Equatable {
  const ListeningState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any [FetchListeningQuests] event is dispatched.
class ListeningInitial extends ListeningState {
  const ListeningInitial();
}

/// Quests are being fetched from the data layer.
class ListeningLoading extends ListeningState {
  const ListeningLoading();
}

/// Quests have loaded and the game is actively in progress.
class ListeningLoaded extends ListeningState {
  final List<ListeningQuest> quests;
  final int currentIndex;
  final int livesRemaining;

  /// `null` = unanswered · `true` = correct · `false` = wrong.
  ///
  /// This field is **always replaced** by [copyWith] — pass `null` explicitly
  /// to clear it (retry state). No sentinel object is required.
  final bool? lastAnswerCorrect;

  final bool hintUsed;
  final int wrongCount;
  final bool isFinalFailure;

  /// Convenience accessor — safe only when [quests] is non-empty.
  ListeningQuest get currentQuest => quests[currentIndex];

  const ListeningLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    this.lastAnswerCorrect,
    this.hintUsed = false,
    this.wrongCount = 0,
    this.isFinalFailure = false,
  });

  @override
  List<Object?> get props => [
    quests,
    currentIndex,
    livesRemaining,
    lastAnswerCorrect,
    hintUsed,
    wrongCount,
    isFinalFailure,
  ];

  ListeningLoaded copyWith({
    List<ListeningQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool? hintUsed,
    int? wrongCount,
    bool? isFinalFailure,
  }) {
    return ListeningLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      lastAnswerCorrect: lastAnswerCorrect, // intentional: always replaced
      hintUsed: hintUsed ?? this.hintUsed,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
    );
  }
}

/// A recoverable error state with a user-facing message.
class ListeningError extends ListeningState {
  final String message;

  /// Raw exception text. **Never** display this to users — internal use only.
  final String? technicalError;

  const ListeningError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

/// Player successfully completed all questions in the level.
class ListeningGameComplete extends ListeningState {
  final int xpEarned;
  final int coinsEarned;

  /// The canonical quest count for the level (not the retry-inflated total).
  final int questCount;

  const ListeningGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.questCount,
  });

  @override
  List<Object?> get props => [xpEarned, coinsEarned, questCount];
}

/// Player ran out of lives before completing the level.
class ListeningGameOver extends ListeningState {
  /// Full (possibly retry-inflated) quest list preserved for life-restore.
  final List<ListeningQuest> quests;
  final int currentIndex;

  const ListeningGameOver({required this.quests, required this.currentIndex});

  @override
  List<Object?> get props => [quests, currentIndex];
}
