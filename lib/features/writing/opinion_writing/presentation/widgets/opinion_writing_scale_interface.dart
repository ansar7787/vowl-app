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
      height: 210.h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 20.h,
            child: Container(
              width: 12.w,
              height: 180.h,
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
          Positioned(
            top: 20.h,
            child: AnimatedRotation(
              duration: 600.milliseconds,
              curve: Curves.elasticOut,
              turns: scaleRotation / (2 * 3.14159),
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 250.w,
                height: 250.h,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 250.w,
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
                      ),
                    ),
                    Positioned(left: 0, top: 5.h, child: _buildPan(true)),
                    Positioned(right: 0, top: 5.h, child: _buildPan(false)),
                  ],
                ),
              ),
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
              width: 120.w,
              constraints: BoxConstraints(minHeight: 120.h),
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: highlight
                    ? successColor.withValues(alpha: 0.15)
                    : (isDark ? Colors.black87 : Colors.white),
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
                      child: Column(
                        children: [
                          Icon(
                            Icons.download_rounded,
                            color: isDark ? Colors.white24 : Colors.black26,
                            size: 20.r,
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            "Drop card here",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (args.isNotEmpty)
                    Column(
                      children: args
                          .map(
                            (a) => GestureDetector(
                              onTap: () => onRemoveArg(a, isLeft),
                              child: Container(
                                width: double.infinity,
                                margin: EdgeInsets.only(bottom: 6.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  a,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 10.sp,
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
