import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

class PhrasalVerbsVaultHandle extends StatelessWidget {
  final String verb;
  final Color color;
  final bool isDark;
  final AnimationController vaultController;

  const PhrasalVerbsVaultHandle({
    super.key,
    required this.verb,
    required this.color,
    required this.isDark,
    required this.vaultController,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // The Outer Rotating Vault Gear
        AnimatedBuilder(
          animation: vaultController,
          builder: (context, child) {
            final unlockRotation = vaultController.value * math.pi * 2.0;
            return Transform.rotate(
              angle: unlockRotation,
              child: Container(
                width: 150.r,
                height: 150.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF151E2E) : Colors.white,
                  border: Border.all(
                    color: color.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: List.generate(8, (i) {
                    return Transform.rotate(
                      angle: i * math.pi / 4,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 10.r,
                          height: 15.r,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 25.seconds),
            );
          },
        ),

        // The Stationary Verb Core
        Container(
          width: 90.r,
          height: 90.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.black : Colors.white,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black54 : Colors.grey.shade300,
                blurRadius: 10,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Center(
            child: AutoSizeText(
              verb.toUpperCase(),
              maxLines: 1,
              minFontSize: 4,
              stepGranularity: 0.5,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
