import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

/// Card widget presenting the scenario prompt text for situation description.
class DescribeSituationPromptCard extends StatelessWidget {
  /// The situation description or prompt text.
  final String prompt;

  /// Theme accent color applied to labels and borders.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Creates a [DescribeSituationPromptCard] widget.
  const DescribeSituationPromptCard({
    super.key,
    required this.prompt,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : color.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: TechPatternOverlay(opacity: 0.05)),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: color,
                      size: 16.r,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "SITUATION PROMPT",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        color: color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(
                      MediaQuery.of(context).textScaler.scale(1).clamp(0.8, 1.3),
                    ),
                  ),
                  child: Text(
                    prompt,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.95)
                          : AppColors.slate900,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                      letterSpacing: 0.2,
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
