import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/tension_wave_painter.dart';

class SituationalResponseReactionZone extends StatelessWidget {
  final List<String> options;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final double timerValue;
  final double pulseValue;
  final bool isAnswered;
  final bool? isCorrect;
  final int? selectedOrbIndex;
  final Function(int, int) onOrbTap;

  const SituationalResponseReactionZone({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.timerValue,
    required this.pulseValue,
    required this.isAnswered,
    this.isCorrect,
    this.selectedOrbIndex,
    required this.onOrbTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      height: 380.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF07070F) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double cx = constraints.maxWidth / 2;
          final double cy = constraints.maxHeight / 2;
          final double r = 115.h;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Radar sweep tension background
              Positioned.fill(
                child: CustomPaint(
                  painter: TensionWavePainter(
                    progress: timerValue,
                    pulseValue: pulseValue,
                    themeColor: color,
                    isAnswered: isAnswered,
                    isCorrect: isCorrect,
                  ),
                ),
              ),

              // Central Tension Core
              _buildTensionCoreCenter(cx, cy),

              // Orbiting Reaction Orbs arranged symmetrically using trigonometry
              ...List.generate(options.length, (i) {
                final double angle = -math.pi / 2 + (i * (2 * math.pi / options.length));
                final double targetX = cx + r * math.cos(angle);
                final double targetY = cy + r * math.sin(angle);

                return _buildOrbNode(i, options[i], targetX, targetY, cx, cy);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTensionCoreCenter(double cx, double cy) {
    Color coreColor = color;
    IconData coreIcon = Icons.bolt_rounded;
    String label = "MATRIX ACTIVE";

    if (isAnswered) {
      if (isCorrect ?? false) {
        coreColor = Colors.greenAccent;
        coreIcon = Icons.verified_rounded;
        label = "SYNERGY LOCKED";
      } else {
        coreColor = Colors.redAccent;
        coreIcon = Icons.warning_amber_rounded;
        label = "TENSION OVERLOAD";
      }
    } else {
      coreColor = Color.lerp(color, const Color(0xFFFF3366), timerValue) ?? color;
      if (timerValue > 0.7) {
        coreIcon = Icons.priority_high_rounded;
        label = "TENSION DANGER";
      }
    }

    final double speedFactor = 1.0 + (timerValue * 3.5);
    final double pulseScale = 1.0 + (0.08 * math.sin(pulseValue * speedFactor * math.pi * 2)).abs();

    return Positioned(
      left: cx - 60.r,
      top: cy - 60.r,
      child: Transform.scale(
        scale: pulseScale,
        child: Container(
          width: 120.r,
          height: 120.r,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F0F1F) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: coreColor, width: 3.5),
            boxShadow: [
              BoxShadow(
                color: coreColor.withValues(alpha: 0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(coreIcon, color: coreColor, size: 40.r),
              SizedBox(height: 6.h),
              Text(
                label,
                style: GoogleFonts.shareTechMono(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                  color: coreColor,
                  letterSpacing: 1,
                ),
              ),
              if (!isAnswered) ...[
                SizedBox(height: 4.h),
                Text(
                  "${(12 * (1.0 - timerValue)).ceil()}s",
                  style: GoogleFonts.shareTechMono(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: coreColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrbNode(
    int index,
    String text,
    double targetX,
    double targetY,
    double cx,
    double cy,
  ) {
    final bool isSelected = selectedOrbIndex == index;
    final bool hideOther = isAnswered && !isSelected;

    // Fly animation coords if selected
    final double currentX = isAnswered && isSelected ? cx : targetX;
    final double currentY = isAnswered && isSelected ? cy : targetY;

    Color orbColor = color;
    if (isAnswered && isSelected) {
      orbColor = (isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.fastOutSlowIn,
      left: currentX - 54.r,
      top: currentY - 54.r,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: hideOther ? 0.0 : 1.0,
        child: ScaleButton(
          onTap: () => onOrbTap(index, correctIndex),
          child: Container(
            width: 108.r,
            height: 108.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
              border: Border.all(
                color: isSelected ? orbColor : color.withValues(alpha: 0.5),
                width: isSelected ? 3.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSelected ? orbColor : color).withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ).animate(
          onPlay: (c) => c.repeat(),
        ).moveY(
          begin: -3,
          end: 3,
          duration: (1.5 + index * 0.4).seconds,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }
}
