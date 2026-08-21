import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';
import 'package:vowl/core/utils/locale_service.dart';

class ConnectedSpeechPromptCard extends StatelessWidget {
  final String word;
  final String? spokenForm;
  final String? phenomenonType;
  final bool isAnswered;
  final Color color;
  final bool isDark;
  final bool isCompact;

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
      width: 342.w,
      padding: EdgeInsets.all(isCompact ? 16.r : 24.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: TechPatternOverlay(opacity: 0.05)),
          Center(
            child: Column(
              children: [
                Text(
                  context.tr('games.target_phrase', fallback: 'TARGET PHRASE'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: isCompact ? 8.sp : 10.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: isCompact ? 4.h : 8.h),
                if (isAnswered && spokenForm != null) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "WRITTEN",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                                color: color.withValues(alpha: 0.7),
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              word.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: isCompact ? 14.sp : 16.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : Colors.black54,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Icon(Icons.arrow_forward_rounded, color: color, size: 20.r),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "SPOKEN",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                                color: color.withValues(alpha: 0.7),
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              spokenForm!.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: isCompact ? 16.sp : 18.sp,
                                fontWeight: FontWeight.w900,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (phenomenonType != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      phenomenonType!.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ] else ...[
                  Text(
                    word.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isCompact ? 22.sp : 28.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: 4,
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
