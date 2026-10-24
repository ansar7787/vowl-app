import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Card displaying the practice phrase and phonetic IPA transcription for shadowing.
class ShadowingChallengePromptCard extends StatelessWidget {
  /// Target practice phrase.
  final String word;

  /// International Phonetic Alphabet (IPA) representation.
  final String ipa;

  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Creates a [ShadowingChallengePromptCard] widget.
  const ShadowingChallengePromptCard({
    super.key,
    required this.word,
    required this.ipa,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 18.w),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.06)
            : color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              "Practice Phrase",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              word,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.4,
              ),
            ),
            if (ipa.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: color.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Text(
                  ipa,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

