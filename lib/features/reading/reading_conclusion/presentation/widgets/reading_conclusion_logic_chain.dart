import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReadingConclusionLogicChain extends StatelessWidget {
  final List<String> logicChain;
  final Color primaryColor;
  final bool isDark;

  const ReadingConclusionLogicChain({
    super.key,
    required this.logicChain,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (logicChain.isEmpty) return const SizedBox.shrink();

    // Process the logic chain steps, splitting by the '->' delimiter used in the JSON
    final List<String> steps = [];
    for (var chain in logicChain) {
      final parts = chain
          .split('->')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      steps.addAll(parts);
    }

    if (steps.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_alt_rounded,
                  color: primaryColor, size: 24.r),
              SizedBox(width: 8.w),
              Text(
                "LOGICAL DEDUCTION",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...List.generate(steps.length, (index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24.r,
                      height: 24.r,
                      margin: EdgeInsets.only(top: 2.h),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        steps[index],
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                if (index < steps.length - 1)
                  Padding(
                    padding: EdgeInsets.only(left: 11.r, top: 4.h, bottom: 4.h),
                    child: Container(
                      width: 2.w,
                      height: 16.h,
                      color: primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

