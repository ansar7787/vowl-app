import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OpinionWritingScaleInterface extends StatelessWidget {
  final double scaleRotation;
  final List<String> leftPanArgs;
  final List<String> rightPanArgs;
  final Color color;
  final bool isDark;
  final Function(String, bool) onDropArg;
  final Function(String, bool) onRemoveArg;

  const OpinionWritingScaleInterface({
    super.key,
    required this.scaleRotation,
    required this.leftPanArgs,
    required this.rightPanArgs,
    required this.color,
    required this.isDark,
    required this.onDropArg,
    required this.onRemoveArg,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 12.w,
              height: 160.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.5), color],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(6.r)),
              ),
            ),
          ),
          AnimatedRotation(
            duration: 600.milliseconds,
            curve: Curves.elasticOut,
            turns: scaleRotation / (2 * 3.14159),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 280.w,
                  height: 10.h,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5.r),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                Positioned(left: 0, child: _buildPan(true)),
                Positioned(right: 0, child: _buildPan(false)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPan(bool isLeft) {
    final args = isLeft ? leftPanArgs : rightPanArgs;

    return DragTarget<String>(
      onAcceptWithDetails: (details) => onDropArg(details.data, isLeft),
      builder: (context, candidateData, rejectedData) {
        final highlight = candidateData.isNotEmpty;

        final successColor = isDark
            ? Colors.greenAccent
            : const Color(0xFF16A34A);
        final headerColor = isLeft
            ? successColor
            : (isDark ? Colors.redAccent : const Color(0xFFDC2626));

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 2.w,
              height: 40.h,
              color: color.withValues(alpha: 0.4),
            ),
            Container(
              width: 125.w,
              constraints: BoxConstraints(minHeight: 100.h),
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: isDark ? Colors.black87 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: highlight
                      ? successColor
                      : color.withValues(alpha: args.isNotEmpty ? 0.8 : 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isLeft ? "PROS" : "CONS",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: headerColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(color: color.withValues(alpha: 0.15), height: 8.h),
                  if (args.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: Text(
                        "Drag argument here",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: isDark ? Colors.white24 : Colors.black26,
                          fontSize: 9.sp,
                        ),
                      ),
                    ),
                  Wrap(
                    spacing: 4.w,
                    runSpacing: 4.h,
                    children: args
                        .map(
                          (a) => GestureDetector(
                            onTap: () => onRemoveArg(a, isLeft),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                a,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ).animate().scale().fadeIn(),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
