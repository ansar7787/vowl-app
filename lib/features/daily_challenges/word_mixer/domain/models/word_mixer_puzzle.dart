import 'package:flutter/material.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';

/// Represents a validated, sanitized, anti-leak, and pedagogically rich Word Mixer puzzle.
///
/// Encapsulates curriculum data, phonetic transcription, part of speech, CEFR level,
/// contextual cloze sentences, example usage, and difficulty metrics.
@immutable
class WordMixerPuzzle {
  final int id;
  final String word;
  final String phonetic;
  final String partOfSpeech;
  final String cefrLevel;
  final String difficultyLabel;
  final Color difficultyColor;
  final String rawHint;
  final String cleanHint;
  final String maskedHint;
  final String exampleSentence;
  final String clozeSentence;
  final List<String> synonyms;
  final List<String> syllables;
  final List<String> tags;
  final String firstLetter;
  final int letterCount;

  const WordMixerPuzzle({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.partOfSpeech,
    required this.cefrLevel,
    required this.difficultyLabel,
    required this.difficultyColor,
    required this.rawHint,
    required this.cleanHint,
    required this.maskedHint,
    required this.exampleSentence,
    required this.clozeSentence,
    required this.synonyms,
    required this.syllables,
    required this.tags,
    required this.firstLetter,
    required this.letterCount,
  });

  bool get hasPhonetic =>
      phonetic.trim().isNotEmpty && !phonetic.contains('[placeholder');

  bool get hasExample =>
      exampleSentence.trim().isNotEmpty && !exampleSentence.contains('[placeholder');

  bool get hasSynonyms => synonyms.isNotEmpty;

  bool get hasSyllables => syllables.isNotEmpty;

  /// Formatted phonetic display string, falling back to syllabified uppercase if unpopulated.
  String get displayPhonetic {
    if (hasPhonetic) return phonetic;
    if (hasSyllables) return syllables.join(' • ').toUpperCase();
    return word;
  }

  factory WordMixerPuzzle.fromMap(Map<String, dynamic> map) {
    final id = map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}') ?? 1;
    final word = (map['word'] as String? ?? '').trim().toUpperCase();
    final rawHint = (map['hint'] as String? ?? map['definition'] as String? ?? '').trim();

    // 1. Sanitize the hint text (spacing, OCR artifacts, citations, brackets)
    final clean = _sanitizeHint(rawHint);

    // 2. Eliminate answer leakage: mask any accidental appearance of the target word
    final masked = _maskAnswerOccurrences(word, clean);

    // 3. Compute length & difficulty
    final length = word.replaceAll(' ', '').length;
    final first = word.isNotEmpty ? word[0] : '';
    final diffLabel = (map['difficulty'] as String?) ?? _computeDifficultyLabel(length);
    final diffColor = _computeDifficultyColor(diffLabel, length);

    // 4. Extract enhanced curriculum fields with intelligent fallbacks
    final rawPhonetic = (map['phonetic'] as String? ?? '').trim();
    final rawPos = (map['partOfSpeech'] as String? ?? map['part_of_speech'] as String? ?? '').trim();
    final pos = rawPos.isNotEmpty && !rawPos.contains('[placeholder')
        ? rawPos.toLowerCase()
        : _inferPartOfSpeech(clean);

    final rawCefr = (map['cefrLevel'] as String? ?? map['cefr_level'] as String? ?? '').trim();
    final cefr = rawCefr.isNotEmpty && !rawCefr.contains('[placeholder')
        ? rawCefr.toUpperCase()
        : _computeCefr(length);

    final rawEx = (map['example'] as String? ?? map['example_sentence'] as String? ?? '').trim();
    final example = rawEx.isNotEmpty && !rawEx.contains('[placeholder') ? rawEx : '';

    final rawCloze = (map['clozeSentence'] as String? ?? map['cloze_sentence'] as String? ?? '').trim();
    final cloze = rawCloze.isNotEmpty && !rawCloze.contains('[placeholder')
        ? rawCloze
        : 'The definition of ______ is: $masked';

    final rawSynonyms = (map['synonyms'] as List<dynamic>?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty && !e.contains('[placeholder'))
            .toList() ??
        <String>[];

    final rawSyllables = (map['syllables'] as List<dynamic>?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty && !e.contains('[placeholder'))
            .toList() ??
        <String>[];

    final rawTags = (map['tags'] as List<dynamic>?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        <String>['daily_challenge', 'word_mixer'];

    return WordMixerPuzzle(
      id: id,
      word: word,
      phonetic: rawPhonetic,
      partOfSpeech: pos,
      cefrLevel: cefr,
      difficultyLabel: diffLabel,
      difficultyColor: diffColor,
      rawHint: rawHint,
      cleanHint: clean.isNotEmpty ? clean : 'Unscramble the letters to discover the word.',
      maskedHint: masked.isNotEmpty ? masked : 'Unscramble the letters to discover the word.',
      exampleSentence: example,
      clozeSentence: cloze,
      synonyms: rawSynonyms,
      syllables: rawSyllables,
      tags: rawTags,
      firstLetter: first,
      letterCount: length,
    );
  }

  /// Cleans scanning glitches, OCR concatenated words, brackets, and citations.
  static String _sanitizeHint(String raw) {
    if (raw.isEmpty) return '';

    String text = raw;

    // Fix missing spaces after punctuation from OCR scans
    text = text.replaceAllMapped(
      RegExp(r'([a-zA-Z]),([a-zA-Z])'),
      (m) => '${m[1]}, ${m[2]}',
    );
    text = text.replaceAllMapped(
      RegExp(r'([a-zA-Z])\.([a-zA-Z])'),
      (m) => '${m[1]}. ${m[2]}',
    );
    text = text.replaceAllMapped(
      RegExp(r'([a-zA-Z]);([a-zA-Z])'),
      (m) => '${m[1]}; ${m[2]}',
    );
    text = text.replaceAllMapped(
      RegExp(r'([a-zA-Z]):([a-zA-Z])'),
      (m) => '${m[1]}: ${m[2]}',
    );

    // Strip bracketed lexicographical notes like [Obs.], [Scot.], [Written also ...]
    text = text.replaceAll(RegExp(r'\[.*?\]'), '');

    // Strip quotes and dashes
    text = text.replaceAll(RegExp(r'[""“”]'), '');
    text = text.replaceAll('--', ', ');

    // Normalize whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  /// Replaces any case-insensitive occurrence of the target word with `______`
  /// to ensure the hint provides pedagogical meaning without spoiling the answer.
  static String _maskAnswerOccurrences(String targetWord, String text) {
    if (targetWord.isEmpty || text.isEmpty) return text;

    final escaped = RegExp.escape(targetWord);
    final regex = RegExp(escaped, caseSensitive: false);

    return text.replaceAll(regex, '______');
  }

  static String _inferPartOfSpeech(String definition) {
    final lower = definition.toLowerCase();
    if (lower.startsWith('to ') || lower.contains('to cause to') || lower.contains('to make')) {
      return 'verb';
    }
    if (lower.startsWith('pertaining to') ||
        lower.startsWith('relating to') ||
        lower.startsWith('characteristic of') ||
        lower.startsWith('having ') ||
        lower.startsWith('of or ') ||
        lower.contains('resembling')) {
      return 'adjective';
    }
    if (lower.startsWith('in a ') || lower.endsWith('ly.')) {
      return 'adverb';
    }
    return 'noun';
  }

  static String _computeDifficultyLabel(int length) {
    if (length <= 4) return 'Easy';
    if (length <= 6) return 'Medium';
    if (length <= 8) return 'Hard';
    return 'Expert';
  }

  static String _computeCefr(int length) {
    if (length <= 4) return 'A2';
    if (length <= 6) return 'B1';
    if (length <= 8) return 'B2';
    if (length <= 10) return 'C1';
    return 'C2';
  }

  static Color _computeDifficultyColor(String label, int length) {
    final normalized = label.toLowerCase();
    if (normalized == 'easy' || length <= 4) return AppColors.emerald500;
    if (normalized == 'medium' || length <= 6) return AppColors.amber500;
    if (normalized == 'hard' || length <= 8) return IllustrationColors.warmOrange;
    return AppColors.red500;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordMixerPuzzle &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          word == other.word;

  @override
  int get hashCode => id.hashCode ^ word.hashCode;
}
