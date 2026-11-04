import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';

/// Panel providing detailed cultural, linguistic, and contextual feedback.
class SituationalResponseExplanationPanel extends StatelessWidget {
  /// Active roleplay quest data.
  final RoleplayQuest quest;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Whether the submitted response was correct.
  final bool? isCorrect;

  /// Creates a [SituationalResponseExplanationPanel] widget.
  const SituationalResponseExplanationPanel({
    super.key,
    required this.quest,
    required this.isDark,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final isMidnight = AppTheme.isMidnight(context);
    final Color cardColor = (isCorrect ?? false)
        ? tokens.gameCorrect
        : Colors.orangeAccent;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isMidnight
            ? AppColors.midnightSurface
            : (isDark ? AppColors.slate900 : Colors.white),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                (isCorrect ?? false)
                    ? Icons.verified_rounded
                    : Icons.info_rounded,
                color: cardColor,
                size: 22.r,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  (isCorrect ?? false) ? "Great response!" : "Not quite right!",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            quest.explanation ??
                "Different situations call for different tones. Choosing the right words makes your response natural and polite.",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.85)
                  : Colors.black87,
              height: 1.45,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}
