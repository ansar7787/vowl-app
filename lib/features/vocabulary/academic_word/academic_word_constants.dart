import 'package:flutter/material.dart';

abstract final class AcademicWordColors {
  static const Color screenBackground = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color shardDark = Color(0xFF334155);
  static const Color slotError = Colors.red;
}

abstract final class AcademicWordStrings {
  static const String instruction = 'THRUST WORD INTO THE THESIS';
  static const String slotPending = 'THRUST_PENDING';
  static const String completionTitle = 'THESIS COMPLETE!';
}

abstract final class AcademicWordLayout {
  static const double ultraCompactHeight = 420.0;
  static const double compactHeight = 580.0;
}
