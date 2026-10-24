import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Card widget presenting the comprehension question following timed passage reading.
class ReadingSpeedQuestionArea extends StatelessWidget {
  /// The comprehension question text.
  final String question;

  /// Theme accent color applied to question card.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Optional callback invoked to read the question aloud.
  final VoidCallback? onPlayAudio;

  /// Creates a [ReadingSpeedQuestionArea] widget.
  const ReadingSpeedQuestionArea({
    super.key,
    required this.question,
    required this.color,
    required this.isDark,
    this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Question: $question',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.04 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 16.r,
                      color: color.withValues(alpha: 0.85),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'QUESTION',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: color.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                if (onPlayAudio != null)
                  GestureDetector(
                    key: const ValueKey('question_audio_button'),
                    onTap: onPlayAudio,
                    child: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.volume_up_rounded,
                        size: 16.r,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              question,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.5.sp,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1B1E2B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
