import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class TopicBatchCounter extends StatelessWidget {
  final int count;
  final int total;
  final Color color;

  const TopicBatchCounter({
    super.key,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;

    final progressLabel = context.tr(
      'instructions.topicVocab.words_in_batch',
      fallback: 'Progress',
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.12)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$progressLabel: $count / $total",
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isDark ? Colors.white.withValues(alpha: 0.9) : color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 5.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(total, (i) {
              bool isFilled = i < count;
              final pip = Container(
                width: 14.w,
                height: 3.5.h,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  color: isFilled ? color : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              );
              return reduceMotion
                  ? pip
                  : pip.animate(target: isFilled ? 1 : 0).shimmer(duration: 800.ms);
            }),
          ),
        ],
      ),
    );
  }
}
