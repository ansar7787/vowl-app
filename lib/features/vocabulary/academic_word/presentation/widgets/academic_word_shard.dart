import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/vocabulary/academic_word/academic_word_constants.dart';

/// Draggable / tappable word chip used in the thesis-thrust mechanic.
class AcademicWordShard extends StatelessWidget {
  final int index;
  final String text;
  final Color color;
  final bool isDragging;
  final Offset offset;
  final double maxWidth;
  final double maxHeight;
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
    required this.isDragging,
    required this.offset,
    required this.maxWidth,
    required this.maxHeight,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.initialPosition,
  });

  /// Responsive shard width — used by both this widget and the parent screen.
  static double resolveWidth(double maxWidth) =>
      (140.w).clamp(90.0, (maxWidth * 0.38).clamp(90.0, 160.0));

  /// Responsive shard height — used by both this widget and the parent screen.
  static double resolveHeight(double maxHeight) =>
      (70.h).clamp(44.0, (maxHeight * 0.10).clamp(44.0, 72.0));

  static TextStyle _textStyle(Color textColor) => TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 15,
    fontWeight: FontWeight.w900,
    color: textColor,
    letterSpacing: 1,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dragOffset = isDragging ? offset : Offset.zero;
    final sw = resolveWidth(maxWidth);
    final sh = resolveHeight(maxHeight);

    final shadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDragging ? 0.3 : 0.1),
        blurRadius: isDragging ? 20 : 10,
        offset: Offset(0, isDragging ? 10 : 5),
      ),
    ];

    return Positioned(
          left: (maxWidth / 2) + initialPosition.dx + dragOffset.dx - sw / 2,
          top: (maxHeight / 2) + initialPosition.dy + dragOffset.dy - sh / 2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            onPanStart: onDragStart,
            onPanUpdate: onDragUpdate,
            onPanEnd: onDragEnd,
            child: Container(
              width: sw,
              height: sh,
              decoration: BoxDecoration(
                color: isDark ? AcademicWordColors.shardDark : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isDragging ? color : color.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: shadows,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Text(
                      text.toUpperCase(),
                      style: _textStyle(isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(
          begin: -4,
          end: 4,
          duration: Duration(seconds: 2 + index),
          curve: Curves.easeInOut,
        );
  }
}
