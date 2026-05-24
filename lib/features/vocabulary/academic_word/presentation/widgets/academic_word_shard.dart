import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class AcademicWordShard extends StatelessWidget {
  final int index;
  final String text;
  final Color color;
  final bool isDark;
  final bool isDragging;
  final Offset offset;
  final BoxConstraints constraints;
  final VoidCallback onTap;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final Offset initialPosition;

  const AcademicWordShard({
    super.key,
    required this.index,
    required this.text,
    required this.color,
    required this.isDark,
    required this.isDragging,
    required this.offset,
    required this.constraints,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.initialPosition,
  });

  @override
  Widget build(BuildContext context) {
    final dragOffset = isDragging ? offset : Offset.zero;

    return Positioned(
      left: (constraints.maxWidth / 2) + initialPosition.dx + dragOffset.dx - 70.w,
      top: (constraints.maxHeight / 2) + initialPosition.dy + dragOffset.dy - 35.h,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onPanStart: onDragStart,
        onPanUpdate: onDragUpdate,
        onPanEnd: onDragEnd,
        child: Container(
          width: 140.w,
          height: 70.h,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isDragging ? color : color.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDragging ? 0.3 : 0.1),
                blurRadius: isDragging ? 20 : 10,
                offset: Offset(0, isDragging ? 10 : 5),
              ),
            ],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Text(
                  text.toUpperCase(),
                  style: GoogleFonts.shareTechMono(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    )
    .animate(onPlay: (c) => c.repeat(reverse: true))
    .moveY(
      begin: -5.h,
      end: 5.h,
      duration: (2 + index).seconds,
      curve: Curves.easeInOut,
    );
  }
}
