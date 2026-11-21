import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Celebratory merged banner representing an already-fused thematic cluster
/// with native audio pronunciation support.
class TopicClusterBanner extends StatelessWidget {
  final String categoryName;
  final String emoji;
  final List<String> words;
  final String? explanation;
  final Color accentColor;

  const TopicClusterBanner({
    super.key,
    required this.categoryName,
    required this.emoji,
    required this.words,
    this.explanation,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(emoji, style: TextStyle(fontSize: 18.sp)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: AutoSizeText(
                      categoryName.toUpperCase(),
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  TtsSpeakerButtonWidget(
                    text: words.join(', '),
                    color: accentColor,
                    size: 26.r,
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.emerald500,
                    size: 18.r,
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              AutoSizeText(
                words.join(' • '),
                maxLines: 2,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              if (explanation != null && explanation!.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  explanation!,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms)
        .scale(
          begin: const Offset(0.94, 0.94),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }
}
