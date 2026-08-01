import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class FixTheSentenceWipedAlert extends StatelessWidget {
  final Color primaryColor;

  const FixTheSentenceWipedAlert({super.key, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayColor = isDark ? Colors.greenAccent : const Color(0xFF16A34A);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: displayColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: displayColor,
            size: 16.r,
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              "DECAY WIPED! CHOOSE REPLACEMENT CELL",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
          ),
        ],
      ),
    ).animate().shimmer(duration: const Duration(milliseconds: 1500));
  }
}

class FixTheSentenceCorrectionOptions extends StatelessWidget {
  final List<String> options;
  final String correct;
  final Color color;
  final bool isDark;
  final Function(String, String) onSelect;

  const FixTheSentenceCorrectionOptions({
    super.key,
    required this.options,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      alignment: WrapAlignment.center,
      children: options.map((o) {
        return ScaleButton(
          onTap: () => onSelect(o, correct),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark ? Colors.black87 : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isDark ? 0.35 : 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 14.r, color: color),
                SizedBox(width: 8.w),
                Text(
                  o.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
