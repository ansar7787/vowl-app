import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

class VowelDistinctionPromptCard extends StatelessWidget {
  final String word;
  final Color color;
  final bool isDark;

  const VowelDistinctionPromptCard({
    super.key,
    required this.word,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : color.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: TechPatternOverlay(opacity: 0.04)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Word to identify",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 8.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    word.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
