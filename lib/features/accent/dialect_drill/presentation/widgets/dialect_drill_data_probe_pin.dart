import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vowl/core/theme/vowl_motion.dart';

class DialectDrillDataProbePin extends StatelessWidget {
  final Color color;
  final bool isAnswered;
  final bool? isCorrect;
  final bool hasTargetGlow;
  const DialectDrillDataProbePin({
    super.key,
    required this.color,
    required this.isAnswered,
    required this.isCorrect,
    required this.hasTargetGlow,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    Color pinColor = color;
    if (isAnswered) {
      pinColor = (isCorrect ?? false)
          ? tokens.gameCorrect
          : tokens.gameIncorrect;
    }

    Widget glowWidget = Container(
      width: 72.r,
      height: 72.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: tokens.gameCorrect.withValues(alpha: 0.6),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
    );

    if (!reduceMotion) {
      glowWidget = glowWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.2, 1.2),
            duration: 600.ms,
          );
    }

    Widget iconWidget = Icon(
      isAnswered
          ? ((isCorrect ?? false)
                ? Icons.verified_rounded
                : Icons.warning_amber_rounded)
          : Icons.gps_fixed_rounded,
      size: 32.r,
      color: pinColor,
    );

    if (!reduceMotion) {
      iconWidget = iconWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.1, 1.1),
            duration: 800.ms,
          );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasTargetGlow && !isAnswered) glowWidget,
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              color: pinColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: pinColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: pinColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: iconWidget,
          ),
        ],
      ),
    );
  }
}
