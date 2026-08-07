import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// Service for identifying the language of a given text using Google ML Kit.
///
/// Operates entirely on-device with zero API cost.
class LanguageIdService {
  late final LanguageIdentifier _languageIdentifier;

  LanguageIdService() {
    // We set a confidence threshold of 0.5 to ensure reasonable accuracy.
    _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
  }

  /// Identifies the primary language of the given text.
  ///
  /// Returns the BCP-47 language code (e.g., 'en', 'es', 'fr'),
  /// or 'und' (undetermined) if it cannot be identified with enough confidence.
  Future<String> identifyLanguage(String text) async {
    if (text.trim().isEmpty) return 'und';

    try {
      final String response = await _languageIdentifier.identifyLanguage(text);
      return response;
    } catch (e) {
      di.sl<AppLogger>().error(
        'LanguageIdService: identifyLanguage failed',
        error: e,
      );
      return 'und';
    }
  }

  /// Identifies possible languages of the given text and their confidence scores.
  Future<List<IdentifiedLanguage>> identifyPossibleLanguages(
    String text,
  ) async {
    if (text.trim().isEmpty) return [];

    try {
      final List<IdentifiedLanguage> response = await _languageIdentifier
          .identifyPossibleLanguages(text);
      return response;
    } catch (e) {
      di.sl<AppLogger>().error(
        'LanguageIdService: identifyPossibleLanguages failed',
        error: e,
      );
      return [];
    }
  }

  /// Closes the ML model and releases resources.
  void dispose() {
    _languageIdentifier.close();
  }
}
