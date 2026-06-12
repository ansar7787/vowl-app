import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Displays a coloured difficulty rank badge.
///
/// [difficulty] is clamped to [1, 3] so out-of-range values from the server
/// always produce a valid badge rather than silently falling to the default.
class SpeechDifficultyBadge extends StatelessWidget {
  final int difficulty;

  const SpeechDifficultyBadge({super.key, required this.difficulty});

  // Rank definitions ordered by difficulty level.
  static const _ranks = [
    ('WORD RANK: NOVICE', Color(0xFFFBBF24)), // 1 — Amber
    ('WORD RANK: EXPERT', Color(0xFFF97316)), // 2 — Orange
    ('WORD RANK: MASTER', Color(0xFFEF4444)), // 3 — Red
  ];

  @override
  Widget build(BuildContext context) {
    // FIX: clamp prevents RangeError if server sends 0 or >3.
    final (label, color) = _ranks[(difficulty.clamp(1, 3) - 1)];

    return Semantics(
      label: label,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10.sp,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
