import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class TopicVocabOptionCard extends StatelessWidget {
  final int index;
  final String option;
  final bool isCorrect;
  final bool isSelected;
  final bool isAlreadyWrong;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onTap;
  final Function(String) onSpeak;

  const TopicVocabOptionCard({
    super.key,
    required this.index,
    required this.option,
    required this.isCorrect,
    required this.isSelected,
    required this.isAlreadyWrong,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ScaleButton(
        onTap: isAlreadyWrong ? null : onTap,
        child: Opacity(
          opacity: isAlreadyWrong ? 0.5 : 1.0,
          child: GlassTile(
            borderRadius: BorderRadius.circular(24.r),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
            borderColor: isSelected
                ? (isCorrect ? Colors.greenAccent : Colors.redAccent)
                : isAlreadyWrong
                    ? Colors.redAccent.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
            color: isSelected
                ? (isCorrect
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2))
                : primaryColor.withValues(alpha: 0.08),
            child: Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isCorrect ? Colors.greenAccent : Colors.redAccent)
                        : isAlreadyWrong
                            ? Colors.redAccent.withValues(alpha: 0.2)
                            : isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isAlreadyWrong
                        ? Icon(Icons.close, size: 20.r, color: Colors.white70)
                        : Text(
                            String.fromCharCode(65 + index),
                            style: GoogleFonts.outfit(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    option,
                    style: GoogleFonts.outfit(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                      color: isAlreadyWrong
                          ? (isDark ? Colors.white38 : Colors.black38)
                          : (isDark ? Colors.white : const Color(0xFF1E293B)),
                      decoration: isAlreadyWrong ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => onSpeak(option),
                  icon: Icon(
                    Icons.volume_up_rounded,
                    color: isSelected
                        ? Colors.white70
                        : (isDark ? Colors.white24 : Colors.black12),
                    size: 20.r,
                  ),
                ),
                if (isSelected)
                  Icon(
                    isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                    size: 28.r,
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (300 + (index * 80)).ms).slideX(begin: 0.1);
  }
}
