import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_painters.dart';

class SynonymWordShard extends StatelessWidget {
  final int index;
  final String text;
  final Color color;
  final bool isDark;
  final Offset initialPos;
  final Offset offset;
  final bool isWarping;
  final bool isActive;
  final double safeWidth;
  final double safeHeight;
  final Function(DragStartDetails) onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final VoidCallback onPanEnd;

  const SynonymWordShard({
    super.key,
    required this.index,
    required this.text,
    required this.color,
    required this.isDark,
    required this.initialPos,
    required this.offset,
    required this.isWarping,
    required this.isActive,
    required this.safeWidth,
    required this.safeHeight,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: safeWidth / 2 + initialPos.dx + offset.dx - 45.w,
      top: safeHeight / 2 + initialPos.dy + offset.dy - 35.h,
      child: GestureDetector(
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: (_) => onPanEnd(),
        child: TweenAnimationBuilder<double>(
          duration: 400.ms,
          curve: Curves.easeOutBack,
          tween: Tween(
            begin: 1.0,
            end: isWarping ? 0.0 : (isActive ? 1.15 : 1.0),
          ),
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: isWarping ? 0.0 : 1.0,
              child: child,
            ),
          ),
          child: Container(
            width: 90.w,
            height: 70.h,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: isActive ? color : color.withValues(alpha: 0.4),
                width: isActive ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isActive ? 0.5 : 0.15),
                  blurRadius: isActive ? 25 : 15,
                  spreadRadius: isActive ? 2 : 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.15,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(90.w, 70.h),
                      painter: TechPatternPainter(color),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.r),
                  child: Text(
                    text.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'RobotoMono', 
                      fontSize: 12.sp,
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: -8,
            end: 8,
            duration: (2 + index * 0.5).seconds,
            curve: Curves.easeInOut,
          )
          .rotate(
            begin: -0.02,
            end: 0.02,
            duration: (3 + index).seconds,
            curve: Curves.easeInOut,
          ),
      ),
    );
  }
}
