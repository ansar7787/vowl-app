import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class TopicContainmentBin extends StatelessWidget {
  final int index;
  final String label;
  final Color color;
  final bool isDark;
  final List<String> words;
  final bool isHinted;

  const TopicContainmentBin({
    super.key,
    required this.index,
    required this.label,
    required this.color,
    required this.isDark,
    required this.words,
    required this.isHinted,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;
    const IconData bucketIcon = Icons.folder_open_rounded;

    final outerContainer = Container(
      width: 130.w,
      height: 155.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(14.r),
          bottom: Radius.circular(24.r),
        ),
        border: Border.all(
          color: isHinted
              ? Colors.white
              : color.withValues(alpha: 0.4),
          width: isHinted ? 3.0 : 1.5,
        ),
        boxShadow: [
          if (isHinted)
            const BoxShadow(
              color: Colors.white,
              blurRadius: 20,
              spreadRadius: 1,
            ),
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
    );

    return SizedBox(
      width: 136.w,
      height: 172.h,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          reduceMotion
              ? outerContainer
              : outerContainer
                  .animate(target: isHinted ? 1 : 0)
                  .shimmer(
                    duration: 1.seconds,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),

          Positioned(
            bottom: 8.h,
            child: Container(
              width: 114.w,
              height: 124.h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: Stack(
                  children: [
                    _buildPlasmaFill(context, color),
                    Padding(
                      padding: EdgeInsets.all(10.r),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: words.reversed
                            .take(4)
                            .map(
                              (w) => Padding(
                                padding: EdgeInsets.only(bottom: 4.h),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 11.r,
                                        color: color.withValues(alpha: 0.95),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        w.toUpperCase(),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 11.sp,
                                          color: Colors.white.withValues(alpha: 0.95),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 6.h,
              ),
              constraints: BoxConstraints(maxWidth: 128.w),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(bucketIcon, color: Colors.white, size: 13),
                  SizedBox(width: 5.w),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlasmaFill(BuildContext context, Color color) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;

    final container = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            color.withValues(alpha: 0.3),
            color.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
    );

    if (reduceMotion) {
      return Positioned.fill(child: container);
    }

    return Positioned.fill(
      child: container
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            duration: 3.seconds,
            color: Colors.white.withValues(alpha: 0.1),
          ),
    );
  }
}
