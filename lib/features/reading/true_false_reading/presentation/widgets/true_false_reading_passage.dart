import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Card widget presenting the reading passage referenced in the true or false statement.
class TrueFalseReadingPassage extends StatelessWidget {
  /// The full text of the reading passage.
  final String passage;

  /// Theme accent color applied to borders and headings.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Optional callback invoked to read the passage aloud.
  final VoidCallback? onPlayAudio;

  /// Creates a [TrueFalseReadingPassage] widget.
  const TrueFalseReadingPassage({
    super.key,
    required this.passage,
    required this.color,
    required this.isDark,
    this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Passage: $passage.${onPlayAudio != null ? " Double tap audio button to listen." : ""}',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.2 : 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.05 : 0.06),
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
                      Icons.menu_book_rounded,
                      size: 16.r,
                      color: color.withValues(alpha: 0.8),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'PASSAGE',
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
                    key: const ValueKey('passage_audio_button'),
                    onTap: onPlayAudio,
                    child: Padding(
                      padding: EdgeInsets.all(4.r),
                      child: Icon(
                        Icons.volume_up_rounded,
                        size: 20.r,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              passage,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.5.sp,
                height: 1.55,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.92)
                    : const Color(0xFF242838),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
