import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Visual color constants specific to the academic word game screen.
abstract final class AcademicWordColors {
  /// Dark card background color.
  static const Color cardDark = AppColors.slate800;

  /// Dark shard background color.
  static const Color shardDark = AppColors.slate700;

  /// Error indicator color for incorrect answer slots.
  static const Color slotError = Colors.red;
}

/// Localized fallback text strings for the academic word game interface.
abstract final class AcademicWordStrings {
  /// Prompt text displayed in an empty drop slot.
  static const String slotPending = 'Drop word here';
}

/// Breakpoint height thresholds for academic word layout responsiveness.
abstract final class AcademicWordLayout {
  /// Screen height breakpoint below which ultra-compact scaling is enabled.
  static const double ultraCompactHeight = 420.0;

  /// Screen height breakpoint below which compact scaling is enabled.
  static const double compactHeight = 580.0;
}
