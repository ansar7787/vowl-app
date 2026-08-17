import 'package:equatable/equatable.dart';

/// A single word from the Daily 10 Words corpus.
///
/// Immutable value object — parsed from local JSON in
/// `assets/curriculum/daily_words/daily_words_day_XXX.json`.
class DailyWord extends Equatable {
  final String id;
  final String word;
  final String phonetic;
  final String partOfSpeech;
  final String definition;
  final String example;
  final int difficulty;
  final int frequencyRank;

  const DailyWord({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.partOfSpeech,
    required this.definition,
    required this.example,
    required this.difficulty,
    required this.frequencyRank,
  });

  factory DailyWord.fromJson(Map<String, dynamic> json) {
    return DailyWord(
      id: json['id'] as String? ?? '',
      word: json['word'] as String? ?? '',
      phonetic: json['phonetic'] as String? ?? '',
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      example: json['example'] as String? ?? '',
      difficulty: json['difficulty'] as int? ?? 1,
      frequencyRank: json['frequencyRank'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'phonetic': phonetic,
        'partOfSpeech': partOfSpeech,
        'definition': definition,
        'example': example,
        'difficulty': difficulty,
        'frequencyRank': frequencyRank,
      };

  @override
  List<Object?> get props => [id, word, frequencyRank];
}

/// Metadata for a single day's word set.
class DailyWordSet extends Equatable {
  final int day;
  final String theme;
  final List<DailyWord> words;

  const DailyWordSet({
    required this.day,
    required this.theme,
    required this.words,
  });

  factory DailyWordSet.fromJson(Map<String, dynamic> json) {
    return DailyWordSet(
      day: json['day'] as int? ?? 1,
      theme: json['theme'] as String? ?? '',
      words: (json['words'] as List<dynamic>?)
              ?.map(
                (e) => DailyWord.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [day, theme, words];
}

/// A batch of daily word sets, corresponding to a single JSON file
/// (e.g., 10 days of words in one file to minimize file IO).
class DailyWordBatch extends Equatable {
  final List<DailyWordSet> days;

  const DailyWordBatch({required this.days});

  factory DailyWordBatch.fromJson(Map<String, dynamic> json) {
    return DailyWordBatch(
      days: (json['days'] as List<dynamic>?)
              ?.map((e) => DailyWordSet.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [days];
}
