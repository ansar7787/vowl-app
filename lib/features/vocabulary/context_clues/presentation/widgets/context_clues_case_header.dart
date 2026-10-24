import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';

/// Case file header badge and level counter for the context clues investigation.
class ContextCluesCaseHeader extends StatelessWidget {
  /// The active difficulty level.
  final int level;

  /// The active quest item index.
  final int questIndex;

  /// Theme accent color for badge backgrounds and text.
  final Color color;

  /// Creates a [ContextCluesCaseHeader] widget.
  const ContextCluesCaseHeader({
    super.key,
    required this.level,
    required this.questIndex,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final headerContent = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Text(
              "CONTEXT CLUES",
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                letterSpacing: 1.2,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            "Level $level • Clue ${questIndex + 1}",
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              color: tokens?.textSecondary ?? color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (reduceMotion) return headerContent;
    return headerContent.animate().fadeIn().slideY(begin: -0.15);
  }
}
