import 'dart:ui';
import 'package:equatable/equatable.dart';

/// Represents a single interactable word extracted from an OCR scan.
class ScannedWordToken extends Equatable {
  /// The raw text token as extracted by OCR, including attached punctuation.
  final String text;

  /// Cleaned, lowercase word suitable for dictionary matching and vocabulary storage.
  final String cleanWord;

  /// Bounding box rectangle in image coordinates, if available.
  final Rect? boundingBox;

  /// Optional International Phonetic Alphabet (IPA) representation.
  final String? ipa;

  /// CEFR proficiency level (A1, A2, B1, B2, C1).
  final String? cefr;

  /// Curated or inferred definition of the word in context.
  final String? definition;

  /// Localized translation of the word, if loaded.
  final String? translation;

  /// Practical grammar or usage tip.
  final String? grammarTip;

  /// Part of speech (e.g. noun, verb, adjective).
  final String? partOfSpeech;

  /// Whether this token is an important vocabulary keyword.
  final bool isKeyword;

  const ScannedWordToken({
    required this.text,
    required this.cleanWord,
    this.boundingBox,
    this.ipa,
    this.cefr,
    this.definition,
    this.translation,
    this.grammarTip,
    this.partOfSpeech,
    this.isKeyword = false,
  });

  /// Creates a copy of this token with updated localized fields.
  ScannedWordToken copyWith({
    String? translation,
    String? definition,
    String? ipa,
    String? cefr,
    String? grammarTip,
    String? partOfSpeech,
    bool? isKeyword,
  }) {
    return ScannedWordToken(
      text: text,
      cleanWord: cleanWord,
      boundingBox: boundingBox,
      ipa: ipa ?? this.ipa,
      cefr: cefr ?? this.cefr,
      definition: definition ?? this.definition,
      translation: translation ?? this.translation,
      grammarTip: grammarTip ?? this.grammarTip,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      isKeyword: isKeyword ?? this.isKeyword,
    );
  }

  @override
  List<Object?> get props => [
        text,
        cleanWord,
        boundingBox,
        ipa,
        cefr,
        definition,
        translation,
        grammarTip,
        partOfSpeech,
        isKeyword,
      ];
}
