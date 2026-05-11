import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class QuestOptionCard extends StatelessWidget {
  final String option;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool showResult;
  final bool isHinted;
  final bool isDark;
  final bool isMidnight;
  final Color primaryColor;
  final VoidCallback onTap;

  const QuestOptionCard({
    super.key,
    required this.option,
    required this.index,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.showResult,
    required this.isHinted,
    required this.isDark,
    this.isMidnight = false,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? cardColor;
    if (showResult) {
      if (isSelected) {
        if (isCorrect) {
          cardColor = const Color(0xFF10B981);
        } else if (isWrong) {
          cardColor = const Color(0xFFF43F5E);
        }
      }
    } else if (isHinted) {
      cardColor = primaryColor.withValues(alpha: 0.25);
    } else if (isSelected) {
      cardColor = primaryColor;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: ScaleButton(
        onTap: showResult ? null : onTap,
        child: GlassTile(
          borderRadius: BorderRadius.circular(24.r),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          color: cardColor?.withValues(
            alpha: isSelected ? 0.9 : (isMidnight ? 0.2 : 0.4),
          ),
          glassOpacity: isSelected ? 0.1 : 0.05,
          borderColor: isHinted
              ? primaryColor
              : (isSelected
                    ? Colors.white.withValues(alpha: 0.6)
                    : primaryColor.withValues(alpha: isMidnight ? 0.1 : 0.2)),
          borderWidth: isSelected ? 2.0 : 1.4,
          child: Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isSelected
                          ? Colors.white24
                          : primaryColor.withValues(alpha: 0.1),
                      isSelected
                          ? Colors.white10
                          : primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white24
                        : primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(64 + (index + 1)),
                    style: GoogleFonts.outfit(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : primaryColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 18.w),
              Expanded(
                child: Text(
                  option,
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (showResult
                              ? (isCorrect
                                    ? const Color(0xFF10B981)
                                    : (isWrong
                                          ? const Color(0xFFF43F5E)
                                          : (isMidnight
                                                ? Colors.white70
                                                : (isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.9,
                                                        )
                                                      : Colors.black87))))
                              : (isMidnight
                                    ? Colors.white70
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : Colors.black87))),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (showResult && isSelected)
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.close_rounded,
                  color: isCorrect
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF43F5E),
                  size: 24.r,
                ),
              if (isHinted && !showResult)
                Icon(
                  Icons.lightbulb_rounded,
                  color: primaryColor,
                  size: 20.r,
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.05);
  }
}
