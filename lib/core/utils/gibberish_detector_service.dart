import 'package:flutter/material.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class GibberishDetectorService {
  /// Analyzes a string for keyboard mashing, repeated words, and vowel absence.
  /// Returns `true` if it passes as natural English, `false` if it is rejected.
  /// Automatically shows the appropriate CustomSnackBar and triggers haptics.
  static bool isNaturalSentence(BuildContext context, String rawText) {
    final hapticService = di.sl<HapticService>();
    final wordsList = rawText.split(RegExp(r'\s+'));
    if (wordsList.isEmpty) return true;

    int wordsWithVowels = 0;
    int maxRepetitions = 0;
    int currentRepetitions = 1;

    for (int i = 0; i < wordsList.length; i++) {
      final w = wordsList[i];

      if (w.length > 25) {
        CustomSnackBar.show(
          context: context,
          message: "Please write natural words. That word is too long!",
          type: CustomSnackBarType.warning,
        );
        hapticService.selection();
        return false;
      }

      if (RegExp(r'(.)\1{2,}').hasMatch(w)) {
        CustomSnackBar.show(
          context: context,
          message: "No keyboard mashing allowed! Please write real words.",
          type: CustomSnackBarType.warning,
        );
        hapticService.selection();
        return false;
      }

      if (RegExp(r'[aeiouy]', caseSensitive: false).hasMatch(w)) {
        wordsWithVowels++;
      }

      if (i > 0) {
        if (w.toLowerCase() == wordsList[i - 1].toLowerCase()) {
          currentRepetitions++;
          if (currentRepetitions > maxRepetitions) {
            maxRepetitions = currentRepetitions;
          }
        } else {
          currentRepetitions = 1;
        }
      }
    }

    if (maxRepetitions > 3) {
      CustomSnackBar.show(
        context: context,
        message:
            "Please write a natural sentence without repeating the same word!",
        type: CustomSnackBarType.warning,
      );
      hapticService.selection();
      return false;
    }

    if ((wordsWithVowels / wordsList.length) < 0.5) {
      CustomSnackBar.show(
        context: context,
        message:
            "Your answer looks like gibberish. Please write a real sentence!",
        type: CustomSnackBarType.warning,
      );
      hapticService.selection();
      return false;
    }

    final uniqueWords = wordsList.map((w) => w.toLowerCase()).toSet();
    if ((uniqueWords.length / wordsList.length) < 0.4) {
      CustomSnackBar.show(
        context: context,
        message: "Please write a natural sentence. Too many repeated words!",
        type: CustomSnackBarType.warning,
      );
      hapticService.selection();
      return false;
    }

    return true;
  }
}
