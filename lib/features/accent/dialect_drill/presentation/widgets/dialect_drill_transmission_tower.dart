import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vowl/core/theme/vowl_motion.dart';

/// Transmission tower card representing an individual dialect option choice.
class DialectDrillTransmissionTower extends StatelessWidget {
  /// Option index.
  final int index;

  /// Option display label.
  final String label;

  /// Maximum container layout width constraint.
  final double maxWidth;

  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Whether this tower is currently hovered or pressed.
  final bool isHovered;

  /// Whether the trial has been answered.
  final bool isAnswered;

  /// Evaluation outcome of the answer (`null` if unanswered).
  final bool? isCorrect;

  /// Index of the actively hovered tower, if any.
  final int? hoveredTowerIndex;

  /// Explicit card width override.
  final double? cardWidth;

  /// Explicit card height override.
  final double? cardHeight;

  /// Creates a [DialectDrillTransmissionTower] widget.
  const DialectDrillTransmissionTower({
    super.key,
    required this.index,
    required this.label,
    required this.maxWidth,
    required this.color,
    required this.isDark,
    required this.isHovered,
    required this.isAnswered,
    required this.isCorrect,
    required this.hoveredTowerIndex,
    this.cardWidth,
    this.cardHeight,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    final bool isSelected = isAnswered && hoveredTowerIndex == index;

    Color towerColor = color;
    if (isSelected) {
      towerColor = (isCorrect ?? false)
          ? tokens.gameCorrect
          : tokens.gameIncorrect;
    } else if (isHovered) {
      towerColor = color;
    } else {
      towerColor = color.withValues(alpha: isDark ? 0.35 : 0.25);
    }

    Color cardBg;
    if (isSelected) {
      final isWin = isCorrect ?? false;
      cardBg = isDark
          ? (isWin
              ? tokens.gameCorrect.withValues(alpha: 0.15)
              : tokens.gameIncorrect.withValues(alpha: 0.15))
          : (isWin
              ? tokens.gameCorrect.withValues(alpha: 0.08)
              : tokens.gameIncorrect.withValues(alpha: 0.08));
    } else if (isHovered) {
      cardBg = isDark
          ? color.withValues(alpha: 0.12)
          : color.withValues(alpha: 0.05);
    } else {
      cardBg = isDark ? const Color(0xFF1E2230) : Colors.white;
    }

    String displayLabel = label.replaceAll(RegExp(r'\(.*\)'), '').trim();

    final effectiveWidth = cardWidth ?? 136.w;
    final effectiveHeight = cardHeight ?? 112.h;

    Widget pulseWidget = Container(
      width: effectiveWidth + 16.w,
      height: effectiveHeight + 16.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        color: towerColor.withValues(alpha: 0.1),
      ),
    );

    if (!reduceMotion) {
      pulseWidget = pulseWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.96, 0.96),
            end: const Offset(1.05, 1.05),
            duration: 800.ms,
          );
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (isHovered || isSelected) pulseWidget,
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: effectiveWidth,
          height: effectiveHeight,
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: (isHovered || isSelected)
                  ? towerColor
                  : color.withValues(alpha: isDark ? 0.3 : 0.2),
              width: (isHovered || isSelected) ? 2.2 : 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? ((isCorrect ?? false)
                        ? tokens.gameCorrect.withValues(alpha: 0.25)
                        : tokens.gameIncorrect.withValues(alpha: 0.25))
                    : (isHovered
                        ? towerColor.withValues(alpha: 0.2)
                        : (isDark
                            ? Colors.black.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.06))),
                blurRadius: isHovered ? 12 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(7.r),
                decoration: BoxDecoration(
                  color: (isHovered || isSelected)
                      ? towerColor.withValues(alpha: isDark ? 0.2 : 0.12)
                      : color.withValues(alpha: isDark ? 0.12 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected
                      ? ((isCorrect ?? false)
                          ? Icons.check_rounded
                          : Icons.close_rounded)
                      : Icons.record_voice_over_rounded,
                  size: 22.r,
                  color: (isHovered || isSelected)
                      ? towerColor
                      : (isDark ? Colors.white70 : color),
                ),
              ),
              SizedBox(height: 10.h),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    displayLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
