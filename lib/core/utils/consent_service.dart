import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages GDPR/UMP ad consent using Google's User Messaging Platform.
///
/// Must be called before [AdService.init()] to ensure ads are loaded
/// with the correct consent configuration. EU/EEA users will see a
/// consent dialog on first launch; subsequent launches use cached consent.
class ConsentService {
  static bool _isConsentObtained = false;

  /// Whether consent has been obtained (or is not required).
  static bool get isConsentObtained => _isConsentObtained;

  /// Requests consent info update and shows form if required.
  ///
  /// Returns when consent is obtained, not required, or the request fails
  /// (fail-open: ads will use non-personalized mode as fallback).
  static Future<void> requestConsent() async {
    final completer = Completer<void>();

    try {
      final params = ConsentRequestParameters();

      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          // Consent info updated — check if form is available
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            await _showConsentForm();
            if (!completer.isCompleted) completer.complete();
          } else {
            _isConsentObtained = true;
            if (!completer.isCompleted) completer.complete();
          }
        },
        (error) {
          // Fail-open: don't block app startup if UMP fails
          if (kDebugMode) {
            debugPrint(
              'ConsentService: UMP error (${error.errorCode}): ${error.message}',
            );
          }
          _isConsentObtained = true;
          if (!completer.isCompleted) completer.complete();
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('ConsentService: Exception: $e');
      _isConsentObtained = true;
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future;
  }

  static Future<void> _showConsentForm() async {
    final completer = Completer<void>();

    ConsentForm.loadAndShowConsentFormIfRequired((formError) {
      if (formError != null && kDebugMode) {
        debugPrint(
          'ConsentService: Form error (${formError.errorCode}): ${formError.message}',
        );
      }
      // Whether form was shown or not, we proceed
      _isConsentObtained = true;
      completer.complete();
    });

    return completer.future;
  }

  /// Resets consent info (for testing or when user requests it from Settings).
  static void reset() {
    ConsentInformation.instance.reset();
    _isConsentObtained = false;
  }
}
