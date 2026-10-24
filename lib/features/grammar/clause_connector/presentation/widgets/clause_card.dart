import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

/// Glassmorphic card displaying an individual clause in connector exercises.
class ClauseCard extends StatelessWidget {
  /// The textual clause content.
  final String text;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Whether midnight contrast theme is enabled.
  final bool isMidnight;

  /// Theme accent color.
  final Color primaryColor;

  /// Creates a [ClauseCard] widget.
  const ClauseCard({
    super.key,
    required this.text,
    required this.isDark,
    this.isMidnight = false,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      borderRadius: BorderRadius.circular(18.r),
      borderColor: primaryColor.withValues(alpha: 0.2),
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.04),
      child: Text(
        text.trim(),
        softWrap: true,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.45,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
