import 'package:auto_size_text/auto_size_text.dart';
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
    final width = isCompact ? 80.w : 100.w;
    final height = isCompact ? 55.h : 70.h;
    final fontSize = isCompact ? 10.sp : 12.sp;
    final padding = isCompact ? 4.r : 8.r;

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
      child:
          GestureDetector(
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
                            constraints: BoxConstraints(
                              minWidth: width,
                              minHeight: height,
                              maxWidth: isCompact ? 120.w : 150.w,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18.r),
                              border: Border.all(
                                color: isActive
                                    ? color
                                    : color.withValues(alpha: 0.4),
                                width: isActive ? 3 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(
                                    alpha: isActive ? 0.5 : 0.15,
                                  ),
                                  blurRadius: isActive ? 25 : 15,
                                  spreadRadius: isActive ? 2 : 0,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.15,
                                    child: RepaintBoundary(
                                      child: CustomPaint(
                                        painter: TechPatternPainter(color),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: padding + 4.w, vertical: padding + 2.h),
                                  child: AutoSizeText(
                                    text.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    minFontSize: 8,
                                    stepGranularity: 0.5,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: fontSize,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
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
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
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
    );
  }
}
