import 'dart:async';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Abstract contract defining the In-App review rating system.
///
/// Decouples UI components from store rating native integrations,
/// in accordance with clean SOLID design rules.
abstract class ReviewService {
  /// Factory mapping constructor supporting seamless backwards compatibility for callers.
  factory ReviewService() = InAppReviewService;

  /// Increments the count of completed quests/levels.
  ///
  /// Evaluates and triggers the system-native prompt organically if thresholds are satisfied.
  Future<void> notifyQuestCompleted();

  /// Triggers the actual system-native rating prompt.
  Future<void> triggerReviewPrompt({bool force = false});
}

/// Concrete implementation of [ReviewService] integrating with the `in_app_review` SDK.
class InAppReviewService implements ReviewService {
  final InAppReview _inAppReview = InAppReview.instance;

  // Configuration key constants
  static const String keyQuestsCompleted = 'review_quests_completed_count';
  static const String keyLastPromptTime = 'review_last_prompt_timestamp';

  // Tuning thresholds constants
  static const int minQuestsRequiredThreshold = 3;
  static const int promptCooldownDaysLimit = 7;

  // Serialization future chain to prevent concurrent SharedPreferences race conditions
  Future<void>? _activeChain;

  InAppReviewService();

  @override
  Future<void> notifyQuestCompleted() async {
    final completer = Completer<void>();
    final previousChain = _activeChain;
    _activeChain = completer.future;

    try {
      if (previousChain != null) {
        await previousChain;
      }
      await _executeNotifyQuestCompleted();
    } finally {
      completer.complete();
    }
  }

  Future<void> _executeNotifyQuestCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int currentCount = prefs.getInt(keyQuestsCompleted) ?? 0;
      currentCount++;
      await prefs.setInt(keyQuestsCompleted, currentCount);

      if (kDebugMode) {
        debugPrint("ReviewService: Quest completed count incremented to $currentCount");
      }

      // Check if organic trigger conditions are met:
      // 1. At least 3 quests successfully completed
      // 2. Cooldown of at least 7 days since last prompt (or never prompted before)
      if (currentCount >= minQuestsRequiredThreshold) {
        final lastPrompt = prefs.getInt(keyLastPromptTime) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        const cooldownInMillis = promptCooldownDaysLimit * 24 * 60 * 60 * 1000;

        if (now - lastPrompt >= cooldownInMillis) {
          await triggerReviewPrompt();
        }
      }
    } catch (e) {
      debugPrint("ReviewService: Error tracking completed quest: $e");
    }
  }

  @override
  Future<void> triggerReviewPrompt({bool force = false}) async {
    try {
      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) {
        debugPrint("ReviewService: In-app review is not available on this device.");
        return;
      }

      // Reset count and record prompt timestamp to enforce the organic cooldown
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(keyQuestsCompleted, 0);
      await prefs.setInt(keyLastPromptTime, DateTime.now().millisecondsSinceEpoch);

      if (kDebugMode) {
        debugPrint("ReviewService: Requesting native in-app review popup.");
      }

      await _inAppReview.requestReview();
    } catch (e) {
      debugPrint("ReviewService: Error displaying native review prompt: $e");
    }
  }
}
