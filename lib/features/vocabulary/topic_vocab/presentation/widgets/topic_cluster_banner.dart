import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Clean, merged category banner representing a completed word group
/// with natural typography, authentic collocations, dynamic symbols, and native audio.
class TopicClusterBanner extends StatelessWidget {
  final String categoryName;
  final String emoji;
  final List<String> words;
  final String? explanation;
  final List<String>? collocations;
  final Color accentColor;

  const TopicClusterBanner({
    super.key,
    required this.categoryName,
    required this.emoji,
    required this.words,
    this.explanation,
    this.collocations,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final banner = Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 28.r,
                height: 28.r,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                alignment: Alignment.center,
                child: emoji.isNotEmpty
                    ? Text(
                        emoji,
                        style: TextStyle(fontSize: 15.sp),
                      )
                    : Icon(
                        Icons.category_rounded,
                        size: 16.r,
                        color: accentColor,
                      ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: AutoSizeText(
                  categoryName,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              TtsSpeakerButtonWidget(
                text: words.join(', '),
                color: accentColor,
                size: 24.r,
              ),
              SizedBox(width: 6.w),
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.emerald500,
                size: 18.r,
              ),
            ],
          ),
          SizedBox(height: 4.h),
          AutoSizeText(
            words.join(' • '),
            maxLines: 2,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          if (collocations != null && collocations!.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 13.r,
                  color: accentColor.withValues(alpha: 0.8),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: AutoSizeText(
                    collocations!.join(' • '),
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: accentColor.withValues(alpha: isDark ? 0.9 : 0.85),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (explanation != null && explanation!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            AutoSizeText(
              explanation!,
              maxLines: 2,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );

    if (VowlMotion.shouldReduceMotion(context)) {
      return banner;
    }

    return banner
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: -0.1, end: 0, duration: 250.ms, curve: Curves.easeOut);
  }
}
