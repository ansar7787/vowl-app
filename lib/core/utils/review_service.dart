import 'dart:async';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart';

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
  ///
  /// NOTE: [force] is currently a no-op. There is no internal cooldown
  /// gate inside this method itself to bypass - the only cooldown logic
  /// lives in [notifyQuestCompleted]'s decision of *whether* to call this
  /// method at all. If you have a "Rate Us" button elsewhere that calls
  /// `triggerReviewPrompt(force: true)` expecting it to behave differently
  /// from `triggerReviewPrompt()`, it currently does not - both paths
  /// always attempt the native prompt immediately if available. Flagging
  /// rather than guessing at the intended behavior, since changing this
  /// is a product decision, not a code-correctness fix.
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

      sl<AppLogger>().debug(
        "ReviewService: Quest completed count incremented to $currentCount",
      );

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
      sl<AppLogger>().error(
        "ReviewService: Error tracking completed quest",
        error: e,
      );
    }
  }

  @override
  Future<void> triggerReviewPrompt({bool force = false}) async {
    try {
      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) {
        sl<AppLogger>().debug(
          "ReviewService: In-app review is not available on this device.",
        );
        return;
      }

      // Reset count and record prompt timestamp to enforce the organic cooldown
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(keyQuestsCompleted, 0);
      await prefs.setInt(
        keyLastPromptTime,
        DateTime.now().millisecondsSinceEpoch,
      );

      sl<AppLogger>().debug(
        "ReviewService: Requesting native in-app review popup.",
      );

      await _inAppReview.requestReview();
    } catch (e) {
      sl<AppLogger>().error(
        "ReviewService: Error displaying native review prompt",
        error: e,
      );
    }
  }
}
