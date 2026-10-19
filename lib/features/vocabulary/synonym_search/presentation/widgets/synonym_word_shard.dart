import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_painters.dart';

class SynonymWordShard extends StatelessWidget {
  final int index;
  final String text;
  final Color color;
  final bool isDark;
  final Offset initialPos;
  final ValueNotifier<Offset> offsetNotifier;
  final ValueNotifier<bool> isWarpingNotifier;
  final ValueNotifier<int?> activeIndexNotifier;
  final bool isCompact;
  final Function(DragStartDetails) onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final VoidCallback onPanEnd;
  final VoidCallback? onTap;

  const SynonymWordShard({
    super.key,
    required this.index,
    required this.text,
    required this.color,
    required this.isDark,
    required this.initialPos,
    required this.offsetNotifier,
    required this.isWarpingNotifier,
    required this.activeIndexNotifier,
    required this.isCompact,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final minWidth = isCompact ? 84.w : 96.w;
    final maxWidth = isCompact ? 112.w : 124.w;
    final minHeight = isCompact ? 44.h : 50.h;
    final fontSize = isCompact ? 12.5.sp : 14.sp;
    final paddingH = isCompact ? 10.w : 12.w;
    final paddingV = isCompact ? 6.h : 8.h;

    Widget shardContent = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: (_) => onPanEnd(),
      onTap: onTap,
      child: ValueListenableBuilder<bool>(
        valueListenable: isWarpingNotifier,
        builder: (context, isWarping, _) {
          return ValueListenableBuilder<int?>(
            valueListenable: activeIndexNotifier,
            builder: (context, activeIndex, _) {
              final isActive = activeIndex == index;
              return TweenAnimationBuilder<double>(
                duration: 350.ms,
                curve: Curves.easeOutCubic,
                tween: Tween(
                  begin: 1.0,
                  end: isWarping ? 0.0 : (isActive ? 1.08 : 1.0),
                ),
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: isWarping ? 0.0 : 1.0,
                    child: child,
                  ),
                ),
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: minWidth,
                    minHeight: minHeight,
                    maxWidth: maxWidth,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Theme.of(context).colorScheme.surface
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isActive
                          ? color
                          : color.withValues(alpha: isDark ? 0.35 : 0.25),
                      width: isActive ? 2.2 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isActive
                            ? color.withValues(alpha: 0.45)
                            : (isDark
                                ? Colors.black.withValues(alpha: 0.25)
                                : color.withValues(alpha: 0.08)),
                        blurRadius: isActive ? 18 : 8,
                        spreadRadius: isActive ? 2 : 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.06,
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: TechPatternPainter(color),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: paddingH,
                          vertical: paddingV,
                        ),
                        child: AutoSizeText(
                          text.toUpperCase(),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          minFontSize: 10,
                          stepGranularity: 0.5,
                          wrapWords: true,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: fontSize,
                            color: isDark ? Colors.white : AppColors.slate900,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (isActive)
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
                ),
              );
            },
          );
        },
      ),
    );

    if (!reduceMotion) {
      shardContent = shardContent
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: -5,
            end: 5,
            duration: (2 + index * 0.4).seconds,
            curve: Curves.easeInOut,
          );
    }

    return ValueListenableBuilder<Offset>(
      valueListenable: offsetNotifier,
      builder: (context, offset, child) {
        return Positioned(
          left: initialPos.dx + offset.dx,
          top: initialPos.dy + offset.dy,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: child,
          ),
        );
      },
      child: shardContent,
    );
  }
}
