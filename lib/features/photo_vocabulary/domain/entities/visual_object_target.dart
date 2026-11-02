import 'package:equatable/equatable.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:vowl/features/photo_vocabulary/utils/photo_vocabulary_dictionary.dart';

/// Represents an identified visual object entity with educational vocabulary annotations.
class VisualObjectTarget extends Equatable {
  /// The primary English label classified by on-device computer vision.
  final String label;

  /// Classification confidence score (0.0 to 1.0).
  final double confidence;

  /// Optional International Phonetic Alphabet (IPA) representation.
  final String? ipa;

  /// CEFR proficiency level (e.g. A1, A2, B1, B2).
  final String? cefr;

  /// Clear, learner-friendly dictionary definition.
  final String definition;

  /// Natural everyday example sentence showcasing the word.
  final String example;

  /// Practical grammar, usage, or collocation tip.
  final String grammarTip;

  /// Part of speech (e.g. noun).
  final String partOfSpeech;

  /// Localized translation of the word, if translated.
  final String? nativeTranslation;

  const VisualObjectTarget({
    required this.label,
    required this.confidence,
    this.ipa,
    this.cefr,
    required this.definition,
    required this.example,
    required this.grammarTip,
    this.partOfSpeech = 'noun',
    this.nativeTranslation,
  });

  /// Factory creating an educational target from Google ML Kit ImageLabel.
  factory VisualObjectTarget.fromImageLabel(ImageLabel label) {
    final entry = PhotoVocabularyDictionary.getEntry(label.label);
    return VisualObjectTarget(
      label: label.label,
      confidence: label.confidence,
      ipa: entry.ipa,
      cefr: entry.cefr,
      definition: entry.definition,
      example: entry.example,
      grammarTip: entry.grammarTip,
    );
  }

  /// Factory creating an educational target from an arbitrary label string and score.
  factory VisualObjectTarget.fromLabel(
    String label, {
    double confidence = 0.95,
  }) {
    final entry = PhotoVocabularyDictionary.getEntry(label);
    return VisualObjectTarget(
      label: label,
      confidence: confidence,
      ipa: entry.ipa,
      cefr: entry.cefr,
      definition: entry.definition,
      example: entry.example,
      grammarTip: entry.grammarTip,
    );
  }

  /// Creates a copy of this object with an updated translation.
  VisualObjectTarget copyWith({
    String? nativeTranslation,
  }) {
    return VisualObjectTarget(
      label: label,
      confidence: confidence,
      ipa: ipa,
      cefr: cefr,
      definition: definition,
      example: example,
      grammarTip: grammarTip,
      partOfSpeech: partOfSpeech,
      nativeTranslation: nativeTranslation ?? this.nativeTranslation,
    );
  }

  @override
  List<Object?> get props => [
        label,
        confidence,
        ipa,
        cefr,
        definition,
        example,
        grammarTip,
        partOfSpeech,
        nativeTranslation,
      ];
}
