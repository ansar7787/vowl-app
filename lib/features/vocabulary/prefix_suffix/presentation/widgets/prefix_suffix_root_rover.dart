import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PrefixSuffixRootRover extends StatelessWidget {
  final String rootWord;
  final Color primaryColor;
  final bool isDark;
  final Offset dragOffset;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  const PrefixSuffixRootRover({
    super.key,
    required this.rootWord,
    required this.primaryColor,
    required this.isDark,
    required this.dragOffset,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          child: Transform.translate(
            offset: dragOffset,
            child: AnimatedScale(
              duration: 150.ms,
              scale: dragOffset == Offset.zero ? 1.0 : 1.15,
              child: Container(
                width: 130.w,
                padding: EdgeInsets.symmetric(vertical: 20.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: primaryColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.4),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.rocket_rounded,
                          color: primaryColor,
                          size: 32.r,
                        ),
                        Positioned(
                          bottom: 0,
                          child:
                              Container(
                                    width: 4.r,
                                    height: 8.r,
                                    decoration: BoxDecoration(
                                      color: Colors.orangeAccent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  )
                                  .animate(onPlay: (c) => c.repeat())
                                  .scaleY(begin: 0.5, end: 1.5)
                                  .fadeOut(),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      rootWord.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(target: dragOffset == Offset.zero ? 1 : 0)
        .shake(duration: 3.seconds, hz: 0.3);
  }
}
