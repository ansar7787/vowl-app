import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Clean, high-end container card for authentication and interactive forms.
///
/// Features a solid, high-contrast base with a whisper-soft border and soft
/// elevation shadow, completely removing legacy animated holographic sheens
/// for a razor-sharp, modern production look.
class HolographicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double padding;

  const HolographicCard({
    super.key,
    required this.child,
    this.borderRadius = 40,
    this.padding = 24,
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

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius.r),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      padding: EdgeInsets.all(padding.r),
      child: child,
    );
  }
}
