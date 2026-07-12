import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ClozeTestPneumaticPort extends StatelessWidget {
  final String text;
  final String correct;
  final Color color;
  final bool isDark;
  final String? dockedOption;
  final bool isAnswered;
  final Function(String) onDock;

  const ClozeTestPneumaticPort({
    super.key,
    required this.text,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.dockedOption,
    required this.isAnswered,
    required this.onDock,
  });

  @override
  Widget build(BuildContext context) {
    final parts = text.split('____');
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Stack(
        children: [
          const TechPatternOverlay(opacity: 0.05),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: parts[0]),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: DragTarget<String>(
                      onAcceptWithDetails: (details) => onDock(details.data),
                      builder: (context, candidateData, rejectedData) {
                        final bool correctDocked =
                            isAnswered &&
                            dockedOption?.trim().toLowerCase() ==
                                correct.trim().toLowerCase();
                        final bool wrongDocked = isAnswered && !correctDocked;

                        return Container(
                              margin: EdgeInsets.symmetric(horizontal: 8.w),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: correctDocked
                                    ? Colors.greenAccent.withValues(alpha: 0.25)
                                    : (wrongDocked
                                          ? Colors.redAccent.withValues(
                                              alpha: 0.25,
                                            )
                                          : (dockedOption != null
                                                ? color.withValues(alpha: 0.2)
                                                : (isDark
                                                      ? Colors.black45
                                                      : Colors.grey.shade200))),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: correctDocked
                                      ? Colors.greenAccent
                                      : (wrongDocked
                                            ? Colors.redAccent
                                            : (dockedOption != null
                                                  ? color
                                                  : (isDark
                                                        ? Colors.white24
                                                        : Colors.black12))),
                                  width: 2,
                                ),
                                boxShadow: [
                                  if (dockedOption != null)
                                    BoxShadow(
                                      color:
                                          (correctDocked
                                                  ? Colors.greenAccent
                                                  : (wrongDocked
                                                        ? Colors.redAccent
                                                        : color))
                                              .withValues(alpha: 0.3),
                                      blurRadius: 15,
                                    ),
                                ],
                              ),
                              child: Text(
                                dockedOption?.toUpperCase() ?? "DRAG HERE",
                                style: TextStyle(
                                  fontFamily: 'RobotoMono',
                                  fontSize: 12.sp,
                                  color: dockedOption != null
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : (isDark
                                            ? Colors.white30
                                            : Colors.black38),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            )
                            .animate(target: dockedOption != null ? 1 : 0)
                            .shimmer(duration: 1.seconds);
                      },
                    ),
                  ),
                  if (parts.length > 1) TextSpan(text: parts[1]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
