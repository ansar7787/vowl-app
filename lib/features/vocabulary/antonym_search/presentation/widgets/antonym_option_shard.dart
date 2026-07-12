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
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: initialPos.dx + offset.dx - 70.w,
      top: initialPos.dy + offset.dy - 35.h,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => onPanStart(),
        onPanUpdate: onPanUpdate,
        onPanEnd: (_) => onPanEnd(),
        child:
            Container(
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
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: BackdropFilter(
                      filter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.05),
                        BlendMode.darken,
                      ),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(10.r),
                          child: FittedBox(
                            child: Text(
                              text.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'RobotoMono',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
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
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: -3, end: 3, duration: (2 + index * 0.4).seconds),
      ),
    );
  }
}
