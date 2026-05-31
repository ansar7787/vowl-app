import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ReviewService {
  final InAppReview _inAppReview = InAppReview.instance;
  static const String _questsCompletedKey = 'review_quests_completed_count';
  static const String _lastPromptTimeKey = 'review_last_prompt_timestamp';

  /// Increments the count of completed quests/levels.
  /// If criteria are met, triggers the Play Store rating popup organically.
  Future<void> notifyQuestCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int currentCount = prefs.getInt(_questsCompletedKey) ?? 0;
      currentCount++;
      await prefs.setInt(_questsCompletedKey, currentCount);

      if (kDebugMode) {
        debugPrint("ReviewService: Quest completed count incremented to $currentCount");
      }

      // Check if organic trigger conditions are met:
      // 1. At least 3 quests successfully completed
      // 2. Cooldown of at least 7 days since last prompt (or never prompted before)
      if (currentCount >= 3) {
        final lastPrompt = prefs.getInt(_lastPromptTimeKey) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        final sevenDaysInMillis = 7 * 24 * 60 * 60 * 1000;

        if (now - lastPrompt >= sevenDaysInMillis) {
          await triggerReviewPrompt();
        }
      }
    } catch (e) {
      debugPrint("ReviewService: Error tracking completed quest: $e");
    }
  }

  /// Triggers the actual system-native rating prompt.
  Future<void> triggerReviewPrompt({bool force = false}) async {
    try {
      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) {
        debugPrint("ReviewService: In-app review is not available on this device.");
        return;
      }

      // Reset count and record prompt timestamp to enforce the organic cooldown
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_questsCompletedKey, 0);
      await prefs.setInt(_lastPromptTimeKey, DateTime.now().millisecondsSinceEpoch);

      if (kDebugMode) {
        debugPrint("ReviewService: Requesting native in-app review popup.");
      }

      await _inAppReview.requestReview();
    } catch (e) {
      debugPrint("ReviewService: Error displaying native review prompt: $e");
    }
  }
}
