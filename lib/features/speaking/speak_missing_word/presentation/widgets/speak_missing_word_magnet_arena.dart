import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/widgets/vortex_painter.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SpeakMissingWordMagnetArena extends StatelessWidget {
  final List<String> dynamicOptions;
  final String? selectedWord;
  final double pullForce;
  final Color primaryColor;
  final bool isDark;
  final AnimationController vortexController;
  final Function(String) onPullStart;
  final VoidCallback onPullEnd;

  const SpeakMissingWordMagnetArena({
    super.key,
    required this.dynamicOptions,
    required this.selectedWord,
    required this.pullForce,
    required this.primaryColor,
    required this.isDark,
    required this.vortexController,
    required this.onPullStart,
    required this.onPullEnd,
  });

  @override
  Widget build(BuildContext context) {
    final double arenaHeight = 240.h;
    final double radius = 100.w;
    final double pullRatio = pullForce;

    // Vortex Center Position relative to the arena Stack
    final Offset localCenter = Offset(0.5.sw - 16.w, arenaHeight / 2);

    return SizedBox(
      height: arenaHeight,
      width: 1.sw,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Spinning cybernetic vortex custom painter background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: vortexController,
              builder: (context, child) {
                // Approximate coordinate mapping for energy beam lines
                Offset? optionOffset;
                if (selectedWord != null) {
                  final int index = dynamicOptions.indexOf(selectedWord!);
                  if (index != -1) {
                    final double angle =
                        (index * 2 * math.pi / dynamicOptions.length) -
                        math.pi / 2;
                    final double currentDist = radius * (1.0 - pullRatio);
                    optionOffset =
                        localCenter +
                        Offset(
                          math.cos(angle) * currentDist,
                          math.sin(angle) * currentDist,
                        );
                  }
                }

                return CustomPaint(
                  painter: VortexPainter(
                    animationTime: vortexController.value,
                    themeColor: primaryColor,
                    pullCenter: selectedWord != null ? localCenter : null,
                    optionPos: optionOffset,
                  ),
                );
              },
            ),
          ),

          // 2. Center vortex black hole icon
          Container(
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade900,
                  border: Border.all(color: primaryColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.blur_circular_rounded,
                  color: Colors.white70,
                  size: 40.r,
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .rotate(duration: const Duration(seconds: 4)),

          // 3. Polar positioned floating options
          ...dynamicOptions.asMap().entries.map((e) {
            final int index = e.key;
            final String word = e.value;

            final double angle =
                (index * 2 * math.pi / dynamicOptions.length) - math.pi / 2;
            final bool isPulled = selectedWord == word;

            final double currentDist = isPulled
                ? radius * (1.0 - pullRatio)
                : radius;

            final double xOffset = math.cos(angle) * currentDist;
            final double yOffset = math.sin(angle) * currentDist;

            return Transform.translate(
              offset: Offset(xOffset, yOffset),
              child: GestureDetector(
                onLongPressStart: (_) => onPullStart(word),
                onLongPressEnd: (_) => onPullEnd(),
                child: ScaleButton(
                  onTap: () {},
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isPulled
                          ? primaryColor.withValues(alpha: 0.25)
                          : (isDark ? const Color(0xFF0F0F1B) : Colors.white),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isPulled
                            ? primaryColor
                            : primaryColor.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      word.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: isPulled
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
