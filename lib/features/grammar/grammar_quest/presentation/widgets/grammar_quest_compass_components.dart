import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_compass_ticks_painter.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_sentinel_needle_painter.dart';

class CompassHolographicRing extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Animation<double> turns;

  const CompassHolographicRing({
    super.key,
    required this.size,
    required this.primaryColor,
    required this.turns,
  });

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: turns,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.1),
            width: 1.r,
          ),
        ),
        child: CustomPaint(
          painter: CompassTicksPainter(primaryColor.withValues(alpha: 0.2)),
        ),
      ),
    );
  }
}

class CompassStaticDial extends StatelessWidget {
  final double size;
  final Color primaryColor;

  const CompassStaticDial({
    super.key,
    required this.size,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.9,
      height: size * 0.9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [primaryColor.withValues(alpha: 0.05), Colors.transparent],
        ),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
          width: 2.r,
        ),
      ),
    );
  }
}

class CompassQuadrant extends StatelessWidget {
  final double angle;
  final String optionText;
  final bool isSelected;
  final double size;
  final Color primaryColor;
  final bool isDark;
  final bool isCompact;

  const CompassQuadrant({
    super.key,
    required this.angle,
    required this.optionText,
    required this.isSelected,
    required this.size,
    required this.primaryColor,
    required this.isDark,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Selection Beam
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: isSelected ? 1.0 : 0.0,
            child: Container(
              width: isCompact ? 25.w : 40.w,
              height: size * 0.45,
              margin: EdgeInsets.only(bottom: size * 0.45),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    primaryColor.withValues(alpha: 0.0),
                    primaryColor.withValues(alpha: 0.2),
                    primaryColor.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),
          // Option Text (Glass-Morphic Tag - Interior Placement)
          Positioned(
            top: size * 0.1, // Positioning inside the dial
            child: Transform.rotate(
              angle: -angle,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: isSelected ? 1.1 : 1.0,
                child: Container(
                  constraints: BoxConstraints(maxWidth: size * 0.35),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isCompact ? 8.r : 12.r),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 8.w : 12.w,
                          vertical: isCompact ? 4.h : 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withValues(alpha: 0.3)
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.06)),
                          borderRadius: BorderRadius.circular(
                            isCompact ? 8.r : 12.r,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : primaryColor.withValues(alpha: 0.3),
                            width: 1.5.r,
                          ),
                        ),
                        child: Text(
                          optionText,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: isCompact ? 8.sp : 10.sp,
                            fontWeight: FontWeight.w900,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black87),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompassPhotonNeedle extends StatelessWidget {
  final double needleRotation;
  final bool isDragging;
  final double needleHeight;
  final Color primaryColor;
  final bool isCompact;

  const CompassPhotonNeedle({
    super.key,
    required this.needleRotation,
    required this.isDragging,
    required this.needleHeight,
    required this.primaryColor,
    required this.isCompact,
  });

  Widget _buildNeedleShape(Color color, double height, {bool isGlass = false}) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(isCompact ? 20.r : 32.r, height),
        painter: SentinelNeedlePainter(color: color, isGlass: isGlass),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: isDragging ? 50 : 600),
      curve: isDragging ? Curves.linear : Curves.elasticOut,
      tween: Tween<double>(begin: 0, end: needleRotation),
      builder: (context, value, child) {
        return Transform.rotate(angle: value, child: child);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Needle Shadow
          Transform.translate(
            offset: const Offset(3, 3),
            child: _buildNeedleShape(
              Colors.black.withValues(alpha: 0.2),
              needleHeight,
            ),
          ),
          // Asymmetric HUD Vector Needle
          _buildNeedleShape(primaryColor, needleHeight, isGlass: true),
          // Pointer Emitter (Top)
          Positioned(
            top: isCompact ? 2.h : 5.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing Halo (Visual Feedback)
                RepaintBoundary(
                  child:
                      Container(
                            width: isCompact ? 16.r : 24.r,
                            height: isCompact ? 16.r : 24.r,
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.2, 1.2),
                            duration: 1.seconds,
                          )
                          .fadeOut(),
                ),
                // Emitter Core
                RepaintBoundary(
                  child: Container(
                    width: isCompact ? 8.r : 12.r,
                    height: isCompact ? 8.r : 12.r,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor,
                          blurRadius: 15,
                          spreadRadius: 4,
                        ),
                        const BoxShadow(color: Colors.white, blurRadius: 5),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: isCompact ? 2.r : 4.r,
                        height: isCompact ? 2.r : 4.r,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Counter-weight (Bottom Orbital - Minimalist)
          Positioned(
            bottom: 0,
            child: Container(
              width: isCompact ? 10.r : 16.r,
              height: isCompact ? 10.r : 16.r,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Center(
                child: Container(
                  width: isCompact ? 4.r : 6.r,
                  height: isCompact ? 4.r : 6.r,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompassCentralHub extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final bool isCompact;

  const CompassCentralHub({
    super.key,
    required this.size,
    required this.primaryColor,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCompact ? 40.r : 60.r,
      height: isCompact ? 40.r : 60.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1.5.r,
        ),
      ),
      child: Center(
        child: Container(
          width: isCompact ? 6.r : 10.r,
          height: isCompact ? 6.r : 10.r,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
