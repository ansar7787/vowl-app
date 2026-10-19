import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class AntonymOptionShard extends StatelessWidget {
  final int index;
  final String text;
  final Color color;
  final bool isDark;
  final Offset initialPos;
  final Offset offset;
  final bool isDragging;
  final bool isFused;
  final bool isSelected;
  final bool isCompact;
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
    this.isSelected = false,
    this.isCompact = false,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final cardWidth = isCompact ? 116.w : 128.w;
    final cardHeight = isCompact ? 48.h : 54.h;
    final fontSize = isCompact ? 12.5.sp : 13.5.sp;
    final active = isDragging || isSelected;

    Widget content = Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: active
              ? color
              : color.withValues(alpha: isDark ? 0.35 : 0.25),
          width: active ? 2.2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? color.withValues(alpha: isDragging ? 0.35 : 0.25)
                : (isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.08)),
            blurRadius: isDragging ? 20 : (active ? 14 : 8),
            offset: isDragging ? const Offset(0, 10) : const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: 6.h,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.slate900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: 4.h,
              right: 6.w,
              child: Container(
                width: 14.r,
                height: 14.r,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 10.r,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );

    content = content
        .animate(target: isFused ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(0, 0),
          duration: 400.ms,
          curve: Curves.easeInBack,
        )
        .fadeOut()
        .animate(target: active ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.06, 1.06),
          duration: 150.ms,
          curve: Curves.easeOut,
        );

    if (!reduceMotion && !isDragging) {
      content = content
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: -3,
            end: 3,
            duration: (2 + index * 0.4).seconds,
            curve: Curves.easeInOut,
          );
    }

    return AnimatedPositioned(
      duration: isDragging ? Duration.zero : 350.ms,
      curve: Curves.easeOutCubic,
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
          child: content,
        ),
      ),
    );
  }
}
