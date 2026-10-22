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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color pinColor = color;
    if (isAnswered) {
      pinColor = (isCorrect ?? false)
          ? tokens.gameCorrect
          : tokens.gameIncorrect;
    }

    Widget glowWidget = Container(
      width: 62.r,
      height: 62.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: tokens.gameCorrect.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
    );

    if (!reduceMotion) {
      glowWidget = glowWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1.15, 1.15),
            duration: 600.ms,
          );
    }

    IconData pinIcon;
    if (isAnswered) {
      pinIcon = (isCorrect ?? false)
          ? Icons.check_circle_rounded
          : Icons.cancel_rounded;
    } else {
      pinIcon = Icons.touch_app_rounded;
    }

    Widget iconWidget = Icon(
      pinIcon,
      size: 24.r,
      color: pinColor,
    );

    if (!reduceMotion && !isAnswered) {
      iconWidget = iconWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1.08, 1.08),
            duration: 900.ms,
          );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasTargetGlow && !isAnswered) glowWidget,
          Container(
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              color: pinColor.withValues(alpha: isDark ? 0.2 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: pinColor, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: pinColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: iconWidget),
          ),
        ],
      ),
    );
  }
}
