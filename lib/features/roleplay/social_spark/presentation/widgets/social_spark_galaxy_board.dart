import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/social_spark/presentation/widgets/social_spark_painter.dart';

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
    return Container(
      width: 1.sw,
      height: 380.h,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF07070F)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          // Deterministic geometric layout to spread stars organically without overlapping
          final List<Offset> starOffsets = List.generate(words.length, (i) {
            double angle = (i * 2 * math.pi / words.length) + (i * 0.15);
            double radiusX = (width / 2) - 60.w;
            double radiusY = (height / 2) - 50.h;

            // Alternating wave depth
            double depth = (i % 2 == 0) ? 0.95 : 0.65;

            double x = (width / 2) + radiusX * depth * math.cos(angle);
            double y = (height / 2) + radiusY * depth * math.sin(angle);
            return Offset(x, y);
          });

          return Stack(
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
          );
        },
      ),
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
      nodeColor = (isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
    }

    return Positioned(
      left: pos.dx - 48.w,
      top: pos.dy - 32.h,
      child:
          ScaleButton(
                onTap: () => onStarTap(index),
                child: Container(
                  width: 96.w,
                  height: 64.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    color: isSelected
                        ? nodeColor
                        : (isDark ? const Color(0xFF0F0F1B) : Colors.white),
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
                          top: 4.h,
                          left: 6.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 1.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              "$selectOrderIndex",
                              style: TextStyle(
                                fontFamily: 'RobotoMono',
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                      // Sparkle particle stars
                      Positioned(
                        right: 6.w,
                        top: 4.h,
                        child: Icon(
                          Icons.star_rounded,
                          size: 10.r,
                          color: isSelected
                              ? Colors.white
                              : color.withValues(alpha: 0.3),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
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
              ),
    );
  }
}
