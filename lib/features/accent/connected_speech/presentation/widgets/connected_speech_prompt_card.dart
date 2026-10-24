import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Central prompt card displaying written vs spoken connected forms and phonological rules.
class ConnectedSpeechPromptCard extends StatelessWidget {
  /// Written citation form of the phrase.
  final String word;

  /// Spoken phonetic or assimilated form of the phrase.
  final String? spokenForm;

  /// Connected speech classification (e.g., assimilation, intrusion).
  final String? phenomenonType;

  /// Whether the user has submitted their answer.
  final bool isAnswered;

  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Whether a compact visual style should be rendered.
  final bool isCompact;

  /// Creates a [ConnectedSpeechPromptCard] widget.
  const ConnectedSpeechPromptCard({
    super.key,
    required this.word,
    this.spokenForm,
    this.phenomenonType,
    this.isAnswered = false,
    required this.color,
    required this.isDark,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 420.w),
      padding: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: isCompact ? 14.h : 18.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.06 : 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.22 : 0.18),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: TechPatternOverlay(opacity: 0.04)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    context.tr(
                      'games.target_phrase',
                      fallback: 'TARGET PHRASE',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isCompact ? 10.sp : 11.sp,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                SizedBox(height: isCompact ? 8.h : 12.h),
                if (isAnswered && spokenForm != null) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: color.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "WRITTEN",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                word.toUpperCase(),
                                textAlign: TextAlign.center,
                                softWrap: true,
                                maxLines: null,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: isCompact ? 14.sp : 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: color,
                            size: 18.r,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "SPOKEN",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                spokenForm!.toUpperCase(),
                                textAlign: TextAlign.center,
                                softWrap: true,
                                maxLines: null,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: isCompact ? 16.sp : 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (phenomenonType != null &&
                      phenomenonType!.trim().isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.16 : 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: color.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        phenomenonType!.toUpperCase(),
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  Text(
                    word.toUpperCase(),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: null,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isCompact ? 22.sp : 26.sp,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: 0.8,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
