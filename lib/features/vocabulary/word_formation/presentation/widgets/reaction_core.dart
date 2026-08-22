import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/controllers/word_formation_controller.dart';

class ReactionCore extends StatelessWidget {
  final GameQuest? quest;
  final String root;
  final String? suffix;
  final Color color;
  final bool isDark;
  final WordFormationController controller;

  const ReactionCore({
    super.key,
    required this.quest,
    required this.root,
    required this.suffix,
    required this.color,
    required this.isDark,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180.h,
      width: 1.sw,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Energy Field Glow - RepaintBoundary for optimization
          RepaintBoundary(
            child: Container(
              width: 200.r,
              height: 200.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.2, 1.2),
                  duration: 2.seconds,
                ),
          ),

          // Hexagonal Chamber
          RepaintBoundary(
            child: Container(
              width: 240.w,
              height: 140.h,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30.r),
                child: Stack(
                  children: [
                    // Dynamic Liquid/Energy Background
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              color.withValues(alpha: 0.05),
                              color.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Word Text with Shimmer
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                (((controller.isAnswered && controller.isCorrect == true) || controller.isFirstStagePassed)
                                        ? (quest?.correctAnswer ?? "")
                                        : root)
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                          ).animate().fadeIn().shimmer(duration: 2.seconds),
                          if (suffix != null && !controller.isAnswered && !controller.isFirstStagePassed) ...[
                            SizedBox(height: 8.h),
                            Icon(
                              Icons.add_rounded,
                              color: color,
                              size: 20.r,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  suffix!.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ).animate().slideY(begin: 0.5, end: 0),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: -5,
                end: 5,
                duration: 3.seconds,
                curve: Curves.easeInOutQuad,
              ),

          // Particle Orbits - Optimized with RepaintBoundary
          ...List.generate(3, (index) {
            return RepaintBoundary(child: _buildEnergyOrbit(index, color));
          }),
        ],
      ),
    );
  }

  Widget _buildEnergyOrbit(int index, Color color) {
    final duration = (2 + index).seconds;
    return Container(
      width: (260 + (index * 20)).w,
      height: (160 + (index * 20)).h,
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        borderRadius: BorderRadius.circular(100.r),
      ),
    ).animate(onPlay: (c) => c.repeat()).rotate(duration: duration);
  }
}
