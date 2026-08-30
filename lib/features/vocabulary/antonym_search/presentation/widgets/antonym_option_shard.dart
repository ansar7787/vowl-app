import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AntonymOptionShard extends StatelessWidget {
  final int index;
  final String text;
  final Color color;
  final bool isDark;
  final Offset initialPos;
  final Offset offset;
  final bool isDragging;
  final bool isFused;
  final Function() onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function() onPanEnd;
  final Function()? onTap;

  const AntonymOptionShard({
    super.key,
    required this.index,
    required this.text,
    required this.color,
    required this.isDark,
    required this.initialPos,
    required this.offset,
    required this.isDragging,
    required this.isFused,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: isDragging ? Duration.zero : 600.ms,
      curve: Curves.elasticOut,
      left: initialPos.dx + offset.dx,
      top: initialPos.dy + offset.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => onPanStart(),
          onPanUpdate: onPanUpdate,
          onPanEnd: (_) => onPanEnd(),
          onTap: onTap,
          child: Container(
            width: 140.w,
            height: 70.h,
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                  .withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDragging ? color : color.withValues(alpha: 0.2),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDragging ? color.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.1),
                  blurRadius: isDragging ? 25 : 15,
                  offset: isDragging ? const Offset(0, 15) : const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(10.r),
                child: FittedBox(
                  child: Text(
                    text.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          )
          .animate(target: isFused ? 1 : 0)
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(0, 0),
            duration: 400.ms,
            curve: Curves.easeInBack,
          )
          .fadeOut()
          .animate(target: isDragging ? 1 : 0)
          .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 150.ms, curve: Curves.easeOut)
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: isDragging ? 0 : -3, end: isDragging ? 0 : 3, duration: (2 + index * 0.4).seconds),
        ),
      ),
    );
  }
}
