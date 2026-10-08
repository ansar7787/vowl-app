import 'package:vowl/core/theme/app_colors.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/social_spark/presentation/widgets/social_spark_painter.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color07070f = Color(0xFF07070F);
}

class SocialSparkGalaxyBoard extends StatelessWidget {
  final List<String> words;
  final Color color;
  final bool isDark;
  final List<int> selectedIndices;
  final bool isAnswered;
  final bool? isCorrect;
  final double pulseValue;
  final Function(int) onStarTap;

  const SocialSparkGalaxyBoard({
    super.key,
    required this.words,
    required this.color,
    required this.isDark,
    required this.selectedIndices,
    required this.isAnswered,
    required this.isCorrect,
    required this.pulseValue,
    required this.onStarTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        
        final int cols = width > 600 ? 5 : (width > 400 ? 4 : 3);
        final double nodeWidth = 108.w;
        final double nodeHeight = 72.h;
        final double hSpacing = math.max(8.w, (width - (cols * nodeWidth)) / (cols + 1));
        final double vSpacing = 24.h;
        
        final int rows = (words.length / cols).ceil();
        final double calculatedHeight = 48.h + (rows * nodeHeight) + ((rows - 1) * vSpacing);
        final double containerHeight = math.max(300.h, calculatedHeight);

        // Organic staggered layout to prevent overlapping for larger word counts
        final List<Offset> starOffsets = [];
        
        for (int i = 0; i < words.length; i++) {
          int row = i ~/ cols;
          int col = i % cols;

          int itemsInThisRow = math.min(cols, words.length - row * cols);
          double rowWidth = (itemsInThisRow * nodeWidth) + ((itemsInThisRow - 1) * hSpacing);
          double startX = (width - rowWidth) / 2;

          double jitterY = (col % 2 == 0) ? 8.h : -8.h;

          double cx = startX + (col * (nodeWidth + hSpacing)) + (nodeWidth / 2);
          double cy = 24.h + (row * (nodeHeight + vSpacing)) + (nodeHeight / 2) + jitterY;

          starOffsets.add(Offset(cx, cy));
        }

        return Container(
          width: width,
          height: containerHeight,
          decoration: BoxDecoration(
            color: isDark
                ? _LocalPalette.color07070f
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(36.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.03),
            ),
          ),
          child: Stack(
            children: [
              // Radial space dust glow
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Interactive laser lines connector paths
              Positioned.fill(
                child: CustomPaint(
                  painter: ConstellationPainter(
                    selectedIndices: selectedIndices,
                    starOffsets: starOffsets,
                    themeColor: color,
                    isAnswered: isAnswered,
                    isCorrect: isCorrect,
                    pulseValue: pulseValue,
                  ),
                ),
              ),

              // Orbiting verbal stars
              ...List.generate(words.length, (i) {
                final Offset pos = starOffsets[i];
                return _buildStarNode(i, words[i], pos, color, isDark);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStarNode(
    int index,
    String text,
    Offset pos,
    Color color,
    bool isDark,
  ) {
    final bool isSelected = selectedIndices.contains(index);
    final int selectOrderIndex = selectedIndices.indexOf(index) + 1;

    Color nodeColor = color;
    if (isAnswered && isSelected) {
      nodeColor = (isCorrect ?? false)
          ? AppColors.gameCorrect
          : AppColors.gameIncorrect;
    }

    return Positioned(
      left: pos.dx - 54.w,
      top: pos.dy - 36.h,
      child:
          ScaleButton(
                onTap: () => onStarTap(index),
                child: Container(
                  width: 108.w,
                  height: 72.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22.r),
                    color: isSelected
                        ? nodeColor
                        : (isDark ? AppColors.deepDark : Colors.white),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : color.withValues(alpha: 0.4),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isSelected ? nodeColor : color).withValues(
                          alpha: isSelected ? 0.4 : 0.1,
                        ),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Tiny connection index tag
                      if (isSelected)
                        Positioned(
                          top: 6.h,
                          left: 8.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              "$selectOrderIndex",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                      // Sparkle particle stars
                      Positioned(
                        right: 8.w,
                        top: 6.h,
                        child: Icon(
                          Icons.star_rounded,
                          size: 12.r,
                          color: isSelected
                              ? Colors.white
                              : color.withValues(alpha: 0.3),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: -4,
                end: 4,
                duration: (1.8 + index * 0.35).seconds,
                curve: Curves.easeInOut,
              )
              .rotate(
                begin: -0.015 - (index % 3) * 0.005,
                end: 0.015 + (index % 3) * 0.005,
                duration: (2.2 + index * 0.4).seconds,
                curve: Curves.easeInOut,
              ),
    );
  }
}
