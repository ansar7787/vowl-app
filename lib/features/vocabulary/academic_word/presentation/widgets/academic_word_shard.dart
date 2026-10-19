import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
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
      (60.h).clamp(44.0, (maxHeight * 0.10).clamp(44.0, 72.0));

  static TextStyle _textStyle(Color textColor) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: 14.5.sp,
    fontWeight: FontWeight.w700,
    color: textColor,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dragOffset = isDragging ? offset : Offset.zero;
    final sw = resolveWidth(maxWidth);
    final sh = resolveHeight(maxHeight);

    final shadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDragging ? 0.25 : 0.08),
        blurRadius: isDragging ? 18 : 8,
        offset: Offset(0, isDragging ? 8 : 4),
      ),
    ];

    final shard = Positioned(
      left: (maxWidth / 2) + initialPosition.dx + dragOffset.dx - sw / 2,
      top: (maxHeight / 2) + initialPosition.dy + dragOffset.dy - sh / 2,
      child: Semantics(
        button: true,
        label: text,
        child: GestureDetector(
          key: Key('academic_word_shard_$index'),
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
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDragging
                    ? color
                    : color.withValues(alpha: isDark ? 0.35 : 0.25),
                width: isDragging ? 2.0 : 1.5,
              ),
              boxShadow: shadows,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text.toUpperCase(),
                    key: Key('academic_word_shard_text_$index'),
                    style: _textStyle(
                      Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (VowlMotion.lowAnimationModeOverride.value) {
      return shard;
    }

    return shard
        .animate(
          onPlay: (c) => c.repeat(reverse: true),
        )
        .moveY(
          begin: -4,
          end: 4,
          duration: Duration(seconds: 2 + index),
          curve: Curves.easeInOut,
        );
  }
}
