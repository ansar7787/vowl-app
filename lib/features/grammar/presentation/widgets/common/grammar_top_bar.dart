import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'grammar_heart_count.dart';

/// Top navigation / progress bar for grammar quiz screens.
///
/// **Status-bar padding:**
/// This widget does NOT include a [SafeArea] internally.
/// - If it is already rendered inside a [SafeArea], leave [topInset] at 0
///   (the default) to avoid double-padding.
/// - If it manages its own safe area, pass
///   `MediaQuery.paddingOf(context).top` as [topInset].
class GrammarTopBar extends StatelessWidget {
  final int level;
  final int currentIndex;
  final int totalQuests;
  final double progress;
  final int livesRemaining;
  final bool isDark;
  final bool isMidnight;
  final Color primaryColor;

  /// Additional top inset applied above the bar content.
  /// Defaults to 0 (safe-area is handled by an ancestor widget).
  final double topInset;

  const GrammarTopBar({
    super.key,
    required this.level,
    required this.currentIndex,
    required this.totalQuests,
    required this.progress,
    required this.livesRemaining,
    required this.isDark,
    this.isMidnight = false,
    required this.primaryColor,
    this.topInset = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Centralise theme-dependent colour derivations so isMidnight is applied
    // consistently across all sub-elements.
    final closeButtonBg = isMidnight
        ? Colors.white.withValues(alpha: 0.15)
        : (isDark ? Colors.white10 : Colors.black12);
    final closeIconColor = isMidnight
        ? Colors.white70
        : (isDark ? Colors.white70 : Colors.black54);
    final levelTextColor = isMidnight
        ? Colors.white70
        : (isDark ? Colors.white70 : Colors.black54);
    final progressTextColor = isMidnight
        ? Colors.white54
        : (isDark ? Colors.white54 : Colors.black45);
    final progressBgColor = isMidnight
        ? Colors.white10
        : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05));

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, topInset + 10.h, 20.w, 10.h),
      child: Row(
        children: [
          Semantics(
            label: 'Exit level',
            button: true,
            child: ScaleButton(
              onTap: () => context.pop(),
              child: Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: closeButtonBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 24.r,
                  color: closeIconColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level $level',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: levelTextColor,
                      ),
                    ),
                    Text(
                      '${currentIndex + 1} / $totalQuests',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: progressTextColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Semantics(
                  label:
                      'Level progress: ${(progress * 100).toStringAsFixed(0)} percent',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12.h,
                      backgroundColor: progressBgColor,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          GrammarHeartCount(lives: livesRemaining),
        ],
      ),
    );
  }
}
