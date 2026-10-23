import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Standard, professional card displaying Direct Speech on the front
/// and flipping cleanly to Indirect Speech when answered.
class DirectIndirectSpeechMirror extends StatelessWidget {
  final double rotation;
  final String directText;
  final String indirectText;
  final bool? isCorrect;
  final bool isDark;
  final Color primaryColor;
  final bool isCompact;

  const DirectIndirectSpeechMirror({
    super.key,
    required this.rotation,
    required this.directText,
    required this.indirectText,
    required this.isCorrect,
    required this.isDark,
    required this.primaryColor,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final backColor = (isCorrect == false)
        ? tokens.gameIncorrect
        : tokens.gameCorrect;
    final shouldReduceMotion = VowlMotion.shouldReduceMotion(context);
    final isNarrow = MediaQuery.of(context).size.width < 360;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: rotation),
      duration: shouldReduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      builder: (context, double value, _) {
        final isFront = value < 1.57079632679; // pi / 2
        final currentColor = isFront ? primaryColor : backColor;

        return Center(
          child: Container(
            key: const ValueKey('speech_mirror'),
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: 440.w),
            margin: EdgeInsets.symmetric(horizontal: isNarrow ? 12.w : 20.w),
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Realistic perspective
                ..rotateY(value),
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 16.w : 22.w,
                  vertical: isCompact ? 16.h : 22.h,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: currentColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.25 : 0.05,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Transform(
                  // Counter-rotate text on the back so it reads left-to-right
                  transform: Matrix4.identity()
                    ..rotateY(isFront ? 0 : 3.14159265359),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Speech Mode Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: currentColor.withValues(
                            alpha: isDark ? 0.12 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: currentColor.withValues(
                              alpha: isDark ? 0.25 : 0.2,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFront
                                  ? Icons.record_voice_over_outlined
                                  : Icons.forum_outlined,
                              size: isCompact ? 13.r : 15.r,
                              color: currentColor,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              isFront ? "Direct Speech" : "Indirect Speech",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: isCompact ? 11.sp : 12.sp,
                                fontWeight: FontWeight.w600,
                                color: currentColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isCompact ? 14.h : 18.h),

                      // Main Sentence
                      Text(
                        isFront ? directText : indirectText,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: isCompact ? 16.sp : 18.sp,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
