import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class TopicVocabQuestionCard extends StatelessWidget {
  final String instruction;
  final String? sentence;
  final bool isDark;
  final Color primaryColor;
  final bool? lastAnswerCorrect;
  final Function(String) onSpeak;

  const TopicVocabQuestionCard({
    super.key,
    required this.instruction,
    this.sentence,
    required this.isDark,
    required this.primaryColor,
    required this.lastAnswerCorrect,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(32.r),
      borderColor: primaryColor.withValues(alpha: 0.2),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  instruction,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: () => onSpeak(instruction),
                icon: Icon(Icons.volume_up_rounded, color: primaryColor),
              ),
            ],
          ),
          if (sentence != null) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      sentence!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onSpeak(sentence!),
                    icon: Icon(
                      Icons.volume_up_rounded,
                      color: primaryColor.withValues(alpha: 0.5),
                      size: 18.r,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate(target: lastAnswerCorrect == false ? 1 : 0).shake(
          hz: 4,
          curve: Curves.easeInOutCubic,
          duration: 500.ms,
        );
  }
}
