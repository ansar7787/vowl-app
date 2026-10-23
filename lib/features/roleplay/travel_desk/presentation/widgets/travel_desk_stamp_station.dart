import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Bottom station dock containing the draggable customs visa stamp.
class TravelDeskStampStation extends StatelessWidget {
  /// Primary theme accent color.
  final Color color;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Callback fired when stamp dragging begins.
  final Function() onDragStarted;

  /// Callback fired when stamp dragging ends.
  final Function() onDragEnded;

  /// Creates a [TravelDeskStampStation] widget.
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
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "TRAVEL DESK STAMP",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      color: color,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

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
            "DRAG STAMP TO MATCHING DESTINATION",
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              letterSpacing: 0.6,
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
