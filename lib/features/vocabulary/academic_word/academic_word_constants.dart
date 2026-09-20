import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

abstract final class AcademicWordColors {
  static const Color cardDark = AppColors.slate800;
  static const Color shardDark = AppColors.slate700;
  static const Color slotError = Colors.red;
}

abstract final class AcademicWordStrings {
  static const String slotPending = 'THRUST_PENDING';
}

abstract final class AcademicWordLayout {
  static const double ultraCompactHeight = 420.0;
  static const double compactHeight = 580.0;
}
