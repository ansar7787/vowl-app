import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TravelDeskStampStation extends StatelessWidget {
  final Color color;
  final bool isDark;
  final Function() onDragStarted;
  final Function() onDragEnded;

  const TravelDeskStampStation({
    super.key,
    required this.color,
    required this.isDark,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;

    final content = Container(
      key: const Key('travel_desk_stamp_station'),
      width: 1.sw,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_rounded, color: color, size: 16.r),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  "STAMP SLAM TERMINAL",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    color: color,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // Metallic mechanical stamp draggable
          Semantics(
            button: true,
            label: 'Mechanical visa stamp',
            child: Draggable<int>(
              data: 99, // Dummy pay payload
              onDragStarted: () {
                onDragStarted();
              },
              onDragEnd: (details) {
                onDragEnded();
              },
              feedback: _buildStampCore(color, isGlowing: true, reduceMotion: reduceMotion),
              childWhenDragging: Opacity(
                opacity: 0.25,
                child: _buildStampCore(color, isGlowing: false, reduceMotion: reduceMotion),
              ),
              child: _buildStampCore(color, isGlowing: false, reduceMotion: reduceMotion),
            ),
          ),

          SizedBox(height: 14.h),
          Text(
            "DRAG STAMP UPWARDS TO SLAM ON TARGET",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );

    return reduceMotion
        ? content
        : content.animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildStampCore(Color color, {required bool isGlowing, required bool reduceMotion}) {
    final stampContainer = Container(
      width: 72.r,
      height: 80.r,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withValues(alpha: 0.75)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isGlowing ? 0.65 : 0.35),
            blurRadius: isGlowing ? 20 : 12,
            offset: const Offset(0, 4),
            spreadRadius: isGlowing ? 2 : 0,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.approval_rounded,
          color: Colors.white,
          size: 32.r,
        ),
      ),
    );

    final animatedStamp = reduceMotion
        ? stampContainer
        : stampContainer
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.05, 1.05),
              duration: 2.seconds,
              curve: Curves.easeInOut,
            );

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          animatedStamp,
          SizedBox(height: 4.h),
          Container(
            width: 86.w,
            height: 10.h,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(5.r),
            ),
          ),
        ],
      ),
    );
  }
}
