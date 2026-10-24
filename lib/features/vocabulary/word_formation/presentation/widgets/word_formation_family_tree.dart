import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Pedagogical card showcasing the morphological word family tree of related derivations.
class WordFormationFamilyTree extends StatelessWidget {
  /// Collection of derived words within the morphological family.
  final List<String> familyTree;

  /// Theme accent color.
  final Color color;

  /// Creates a [WordFormationFamilyTree] widget.
  const WordFormationFamilyTree({
    super.key,
    required this.familyTree,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;

    final content = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_rounded, color: color, size: 18.r),
              SizedBox(width: 8.w),
              Text(
                "WORD FAMILY",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: familyTree.map((word) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link_rounded, color: color, size: 13.r),
                    SizedBox(width: 4.w),
                    Text(
                      word,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.slate900,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );

    if (reduceMotion) {
      return content;
    }

    return content
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}
