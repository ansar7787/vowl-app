import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Card widget presenting the reading passage with optional audio and karaoke sync.
class ReadAndAnswerFloatingPassage extends StatelessWidget {
  /// The full text of the reading passage.
  final String text;

  /// Theme accent color applied to borders and controls.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Optional callback invoked to read the passage aloud.
  final VoidCallback? onPlayAudio;

  /// Optional notifier broadcasting the currently spoken karaoke word.
  final ValueNotifier<String?>? activeWordNotifier;

  /// Creates a [ReadAndAnswerFloatingPassage] widget.
  const ReadAndAnswerFloatingPassage({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
    this.onPlayAudio,
    this.activeWordNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Reading passage: $text. ${onPlayAudio != null ? "Double tap audio button to listen." : ""}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : color.withValues(alpha: 0.12),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (onPlayAudio != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_stories_rounded,
                        size: 16.r,
                        color: color.withValues(alpha: 0.85),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Passage',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: color.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  Semantics(
                    label: 'Listen to passage',
                    button: true,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const ValueKey(
                          'read_and_answer_tts_passage_button',
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: onPlayAudio,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.volume_up_rounded,
                                color: color,
                                size: 16.r,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Listen',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
            ],
            if (activeWordNotifier != null)
              ValueListenableBuilder<String?>(
                valueListenable: activeWordNotifier!,
                builder: (context, activeWord, _) {
                  return _buildKaraokeText(text, activeWord, isDark);
                },
              )
            else
              Text(
                text,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  height: 1.6,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.92)
                      : AppColors.slate800,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKaraokeText(String text, String? activeWord, bool isDark) {
    if (activeWord == null || activeWord.trim().isEmpty) {
      return Text(
        text,
        softWrap: true,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16.sp,
          height: 1.6,
          color: isDark
              ? Colors.white.withValues(alpha: 0.92)
              : AppColors.slate800,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    final cleanActive = activeWord.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
    final tokens = text.split(' ');

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16.sp,
          height: 1.6,
          color: isDark
              ? Colors.white.withValues(alpha: 0.92)
              : AppColors.slate800,
          fontWeight: FontWeight.w400,
        ),
        children: tokens.asMap().entries.map((entry) {
          final token = entry.value;
          final isLast = entry.key == tokens.length - 1;
          final cleanToken = token.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
          final isMatch = cleanToken.isNotEmpty && cleanToken == cleanActive;

          return TextSpan(
            text: isLast ? token : '$token ',
            style: isMatch
                ? TextStyle(
                    backgroundColor: color.withValues(alpha: 0.25),
                    color: color,
                    fontWeight: FontWeight.w600,
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }
}
