import 'package:equatable/equatable.dart';

/// Tracks a user's progress for a single word through the spaced repetition
/// pipeline (Leitner system).
///
/// Stored as JSON in SharedPreferences under the `daily_words_bank` key.
class WordProgress extends Equatable {
  /// The word ID (e.g. "dw_0001").
  final String wordId;

  /// The word text for quick display without re-loading the full corpus.
  final String word;

  /// ISO-8601 date string when the word was first learned.
  final String learnedDate;

  /// Number of successful review completions.
  final int reviewCount;

  /// Leitner box (0 = new, 1 = day 1, 2 = day 3, 3 = day 7, 4 = day 14, 5 = mastered).
  final int box;

  /// ISO-8601 date string for the next scheduled review.
  final String nextReviewDate;

  /// Last quiz score for this word (0-5 scale).
  final int lastScore;

  const WordProgress({
    required this.wordId,
    required this.word,
    required this.learnedDate,
    this.reviewCount = 0,
    this.box = 0,
    this.nextReviewDate = '',
    this.lastScore = 0,
  });

  factory WordProgress.fromJson(Map<String, dynamic> json) {
    return WordProgress(
      wordId: json['wordId'] as String? ?? '',
      word: json['word'] as String? ?? '',
      learnedDate: json['learnedDate'] as String? ?? '',
      reviewCount: json['reviewCount'] as int? ?? 0,
      box: json['box'] as int? ?? 0,
      nextReviewDate: json['nextReviewDate'] as String? ?? '',
      lastScore: json['lastScore'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'wordId': wordId,
    'word': word,
    'learnedDate': learnedDate,
    'reviewCount': reviewCount,
    'box': box,
    'nextReviewDate': nextReviewDate,
    'lastScore': lastScore,
  };

  WordProgress copyWith({
    String? wordId,
    String? word,
    String? learnedDate,
    int? reviewCount,
    int? box,
    String? nextReviewDate,
    int? lastScore,
  }) {
    return WordProgress(
      wordId: wordId ?? this.wordId,
      word: word ?? this.word,
      learnedDate: learnedDate ?? this.learnedDate,
      reviewCount: reviewCount ?? this.reviewCount,
      box: box ?? this.box,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastScore: lastScore ?? this.lastScore,
    );
  }

  @override
  List<Object?> get props => [wordId, box, reviewCount, nextReviewDate];
}
