import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/category_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Standardized, non-intrusive peeking companion widget shared across all game categories.
///
/// Features a compact **Horizontal Companion Row** layout:
/// - Left: Compact speech bubble with rounded glass/card surface and category-accented typography.
/// - Right: Animated companion avatar (38dp standard), anchored on the right edge.
///
/// Ergonomics:
/// - Total height is restricted to 38dp (instead of bloated 85dp vertical columns),
///   completely preventing collisions with question cards and instruction banners below.
/// - Speech bubble contains only clean dialogue text without duplicate mascot emojis.
class VowlPeekingCompanion extends StatelessWidget {
  /// Spoken message from the companion (without duplicate mascot emojis).
  final String message;

  /// Current emotional visual state (happy, thinking, worried, neutral).
  final VowlMascotState mascotState;

  /// The active user mascot identifier (e.g. `'vowl_prime'`).
  final String mascotId;

  /// Game category identifier for theme and color matching.
  final String category;

  /// Mascot visual size in logical pixels (default 38r).
  final double mascotSize;

  /// Optional override for the speech bubble text color.
  final Color? textColorOverride;

  const VowlPeekingCompanion({
    super.key,
    required this.message,
    required this.mascotState,
    required this.mascotId,
    required this.category,
    this.mascotSize = 38.0,
    this.textColorOverride,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = CategoryColors.forCategory(category);
    final resolvedTextColor = textColorOverride ??
        (isDark
            ? (Color.lerp(catColor, Colors.white, 0.35) ?? Colors.white)
            : catColor);

    Widget bubble = Container(
      constraints: BoxConstraints(maxWidth: 155.w),
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : AppColors.slate200,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w700,
          color: resolvedTextColor,
          height: 1.25,
        ),
      ),
    );

    Widget mascot = VowlMascot(
      state: mascotState,
      size: mascotSize.r,
      mascotId: mascotId,
    );

    if (!reduceMotion) {
      mascot = mascot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: 4, duration: 1500.ms, curve: Curves.easeInOut);
    }

    Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        bubble,
        SizedBox(width: 5.w),
        mascot,
      ],
    );

    if (!reduceMotion) {
      row = row.animate().fadeIn(duration: 250.ms).slideX(begin: 0.08, end: 0);
    }

    return RepaintBoundary(
      child: Semantics(
        liveRegion: true,
        label: message,
        excludeSemantics: true,
        child: IgnorePointer(
          child: row,
        ),
      ),
    );
  }
}
