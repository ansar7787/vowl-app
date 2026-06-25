import 'package:flutter/foundation.dart';

/// Holds core static configurations and limits used across the application.
///
/// This class is abstract to prevent instantiation and subclassing.
@immutable
abstract class AppConstants {
  // Private constructor to prevent instantiation.
  const AppConstants._();

  // ==========================================
  // Curriculum & Content Configurations
  // ==========================================

  /// The total number of levels available across all game modes.
  ///
  /// Calculation: 100 levels per game mode x ~200 items each (or similar scaling).
  /// This number should be updated whenever new curriculum content is added.
  static const int totalCurriculumLevels = 20000;

  // ==========================================
  // Performance & UX Configurations
  // ==========================================

  /// The maximum limit for fetching leaderboard entries to ensure high database performance.
  static const int leaderboardLimit = 50;

  /// Cooldown duration (in milliseconds) used for premium haptic feedback loops.
  static const int hapticFeedbackDelayMs = 600;
}
