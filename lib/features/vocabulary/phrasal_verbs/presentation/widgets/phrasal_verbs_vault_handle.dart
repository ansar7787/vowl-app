import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        // The Outer Accent Ring
        AnimatedBuilder(
          animation: vaultController,
          builder: (context, child) {
            final unlockRotation = vaultController.value * math.pi * 2.0;
            return Transform.rotate(
              angle: unlockRotation,
              child: Container(
                width: 140.r,
                height: 140.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? color.withValues(alpha: 0.05)
                      : color.withValues(alpha: 0.03),
                  border: Border.all(
                    color: color.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: List.generate(8, (i) {
                    return Transform.rotate(
                      angle: i * math.pi / 4,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 4.r,
                          height: 10.r,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),

        // The Stationary Verb Core Card
        Container(
          width: 96.r,
          height: 96.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border.all(color: color, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: AutoSizeText(
                verb.toUpperCase(),
                maxLines: 1,
                minFontSize: 12,
                stepGranularity: 0.5,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
