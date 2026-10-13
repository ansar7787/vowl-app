import 'package:flutter/material.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';

/// Represents a validated, sanitized, anti-leak, and pedagogically rich Word Snap puzzle.
///
/// Encapsulates curriculum data, phonetic transcription, part of speech, CEFR level,
/// cohesive jigsaw assembly sentences, example usage, and difficulty metrics.
@immutable
class WordSnapPuzzle {
  final int id;
  final String word;
  final String phonetic;
  final String partOfSpeech;
  final String cefrLevel;
  final String difficultyLabel;
  final Color difficultyColor;
  final String rawQuestion;
  final String cleanDefinition;
  final String playableSentence;
  final List<String> playableWords;
  final String hintClue;
  final String exampleSentence;
  final String clozeSentence;
  final List<String> synonyms;
  final List<String> syllables;
  final List<String> tags;

  const WordSnapPuzzle({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.partOfSpeech,
    required this.cefrLevel,
    required this.difficultyLabel,
    required this.difficultyColor,
    required this.rawQuestion,
    required this.cleanDefinition,
    required this.playableSentence,
    required this.playableWords,
    required this.hintClue,
    required this.exampleSentence,
    required this.clozeSentence,
    required this.synonyms,
    required this.syllables,
    required this.tags,
  });

  int get letterCount => word.replaceAll(' ', '').length;

  bool get hasPhonetic =>
      phonetic.trim().isNotEmpty && !phonetic.contains('[placeholder');

  bool get hasExample =>
      exampleSentence.trim().isNotEmpty && !exampleSentence.contains('[placeholder');

  bool get hasSynonyms => synonyms.isNotEmpty;

  bool get hasSyllables => syllables.isNotEmpty;

  String get displayPhonetic {
    if (hasPhonetic) return phonetic;
    if (hasSyllables) return syllables.join(' • ').toUpperCase();
    return word;
  }

  /// Creates a [WordSnapPuzzle] from a curriculum JSON map.
  factory WordSnapPuzzle.fromMap(Map<String, dynamic> map) {
    final id = map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}') ?? 1;
    final rawWord = (map['word'] as String? ?? '').trim().toUpperCase();
    final rawQuestion = (map['question'] as String? ?? map['definition'] as String? ?? '').trim();

    // 1. Sanitize the full definition for human reading & display
    final cleanDef = _sanitizeDefinition(rawQuestion);

    // 2. Extract a cohesive, grammatically sound 4–10 word playable sentence
    final playable = _extractPlayableSentence(rawWord, cleanDef);

    // 3. Tokenize words for the jigsaw assembly
    final words = playable
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // 4. Build a tiered hint clue without spoiling the entire puzzle
    final firstWord = words.isNotEmpty ? words.first : '';
    final hint = 'Starts with "$firstWord" • ${words.length} words';

    // 5. Length & Difficulty metrics
    final length = rawWord.replaceAll(' ', '').length;
    final diffLabel = (map['difficulty'] as String?) ?? _computeDifficultyLabel(length);
    final diffColor = _computeDifficultyColor(diffLabel, length);

    // 6. Enhanced fields
    final rawPhonetic = (map['phonetic'] as String? ?? '').trim();
    final rawPos = (map['partOfSpeech'] as String? ?? map['part_of_speech'] as String? ?? '').trim();
    final pos = rawPos.isNotEmpty && !rawPos.contains('[placeholder')
        ? rawPos.toLowerCase()
        : _inferPartOfSpeech(cleanDef);

    final rawCefr = (map['cefrLevel'] as String? ?? map['cefr_level'] as String? ?? '').trim();
    final cefr = rawCefr.isNotEmpty && !rawCefr.contains('[placeholder')
        ? rawCefr.toUpperCase()
        : _computeCefr(length);

    final rawEx = (map['example'] as String? ?? map['example_sentence'] as String? ?? '').trim();
    final example = rawEx.isNotEmpty && !rawEx.contains('[placeholder') ? rawEx : '';

    final rawCloze = (map['clozeSentence'] as String? ?? map['cloze_sentence'] as String? ?? '').trim();
    final cloze = rawCloze.isNotEmpty && !rawCloze.contains('[placeholder')
        ? rawCloze
        : 'The definition of ______ is: $cleanDef';

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
        <String>['daily_challenge', 'word_snap'];

    return WordSnapPuzzle(
      id: id,
      word: rawWord,
      phonetic: rawPhonetic,
      partOfSpeech: pos,
      cefrLevel: cefr,
      difficultyLabel: diffLabel,
      difficultyColor: diffColor,
      rawQuestion: rawQuestion,
      cleanDefinition: cleanDef.isNotEmpty ? cleanDef : 'A vocabulary word challenge.',
      playableSentence: playable,
      playableWords: words,
      hintClue: hint,
      exampleSentence: example,
      clozeSentence: cloze,
      synonyms: rawSynonyms,
      syllables: rawSyllables,
      tags: rawTags,
    );
  }

  /// Cleans scanning, typography, and archaic citation artifacts from the Webster 1913 definition.
  static String _sanitizeDefinition(String raw) {
    if (raw.isEmpty) return '';

    String text = raw;

    // Fix missing spaces after punctuation from OCR/dictionary scans
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

    // Strip bracketed lexicographical notes like [Obs.], [Scot.], [Low], [R.]
    text = text.replaceAll(RegExp(r'\[.*?\]'), '');

    // Strip quotes and dashes
    text = text.replaceAll(RegExp(r'[""“”]'), '');
    text = text.replaceAll('--', ', ');

    // Normalize whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  /// Extracts or synthesizes a clean, grammatically natural 4–10 word phrase
  /// suited for mobile tile arrangement from the dictionary entry.
  static String _extractPlayableSentence(String word, String cleanDef) {
    if (cleanDef.isEmpty) {
      return 'The meaning of $word';
    }

    final rawClauses = cleanDef
        .split(RegExp(r'[;\.]'))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty && !c.startsWith('See ') && !c.startsWith('Written '))
        .toList();

    String candidate = '';

    if (rawClauses.isNotEmpty) {
      for (final clause in rawClauses) {
        final words = clause.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        if (words.length >= 4 && words.length <= 10) {
          candidate = clause;
          break;
        }
      }

      if (candidate.isEmpty) {
        final first = rawClauses.first;
        final firstWords = first.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

        if (firstWords.length > 10) {
          final commaParts = first
              .split(',')
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList();
          if (commaParts.isNotEmpty) {
            final partWords = commaParts.first.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
            if (partWords.length >= 4 && partWords.length <= 10) {
              candidate = commaParts.first;
            }
          }

          if (candidate.isEmpty) {
            final takeCount = firstWords.length >= 8 ? 8 : firstWords.length;
            candidate = firstWords.take(takeCount).join(' ');
          }
        } else if (firstWords.length < 4) {
          if (rawClauses.length > 1) {
            final second = rawClauses[1];
            final secondWords = second.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
            if (secondWords.length >= 4 && secondWords.length <= 10) {
              candidate = second;
            } else if (firstWords.length + secondWords.length <= 10) {
              candidate = '$first and $second';
            }
          }
          if (candidate.isEmpty) {
            final cleanWordLower = word.toLowerCase();
            final term = first.toLowerCase().replaceAll(RegExp(r'[\.,;:]+$'), '');
            candidate = 'The word $cleanWordLower means $term';
          }
        }
      }
    }

    if (candidate.isEmpty) {
      candidate = cleanDef;
    }

    candidate = candidate.replaceAll(RegExp(r'[\.,;:!?]+$'), '').trim();

    final candWords = candidate.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (candWords.length < 4) {
      final cleanWordLower = word.toLowerCase();
      String term = candidate.toLowerCase();
      if (term.startsWith('see ')) {
        final ref = term.substring(4).trim();
        candidate = 'A term related to $ref';
      } else {
        candidate = 'The word $cleanWordLower means $term';
      }
    }

    if (candidate.isNotEmpty) {
      candidate = candidate[0].toUpperCase() + candidate.substring(1);
    }

    return candidate;
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
      other is WordSnapPuzzle &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          word == other.word &&
          playableSentence == other.playableSentence;

  @override
  int get hashCode => id.hashCode ^ word.hashCode ^ playableSentence.hashCode;
}
