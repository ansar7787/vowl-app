import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';

/// Clean, high-end container card for authentication and interactive forms.
///
/// Features a solid, high-contrast base with a whisper-soft border and soft
/// elevation shadow, completely removing legacy animated holographic sheens
/// for a razor-sharp, modern production look.
class HolographicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double? padding;
  final EdgeInsetsGeometry? insets;

  const HolographicCard({
    super.key,
    required this.child,
    this.borderRadius = 40,
    this.padding,
    this.insets,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final backgroundColor = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.slate900 : AppColors.white);

    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? AppColors.slate700 : AppColors.slate100);

    final effectivePadding = insets ??
        EdgeInsets.all(padding?.r ?? AppSpacing.cardSpacious);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius.r),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      padding: effectivePadding,
      child: child,
    );
  }
}
