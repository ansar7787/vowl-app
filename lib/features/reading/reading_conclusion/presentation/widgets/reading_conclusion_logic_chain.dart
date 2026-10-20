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
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: isDark
            ? primaryColor.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? primaryColor.withValues(alpha: 0.3)
              : primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : primaryColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(5.r),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.psychology_alt_rounded,
                  color: primaryColor,
                  size: 16.r,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  "LOGICAL DEDUCTION",
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...List.generate(steps.length, (index) {
            final isLast = index == steps.length - 1;
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
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        steps[index],
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.88)
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  Padding(
                    padding:
                        EdgeInsets.only(left: 11.r, top: 3.h, bottom: 3.h),
                    child: Container(
                      width: 2.w,
                      height: 16.h,
                      color: primaryColor.withValues(alpha: 0.25),
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
