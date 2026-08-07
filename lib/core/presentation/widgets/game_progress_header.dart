import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// Compact level/progress/lives header shared across all 9 game categories.
///
/// Layout (LTR):  [Back]  [LEVEL N | N% 🔥streak | ████░░ bar]  [♥ N]
/// In RTL locales the Row reverses automatically via [Directionality].
class GameProgressHeader extends StatelessWidget {
  final int level;
  final double progress;
  final int lives;
  final ThemeResult theme;
  final bool isDark;
  final VoidCallback onBack;

  const GameProgressHeader({
    super.key,
    required this.level,
    required this.progress,
    required this.lives,
    required this.theme,
    required this.isDark,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.8)
        : const Color(0xFF0F172A).withValues(alpha: 0.7);
    final progressPercent = (progress.clamp(0.0, 1.0) * 100).toInt();

    // BUG FIX (RTL): Icons.arrow_back_ios_new_rounded is a raw
    // left-pointing glyph, not a direction-aware icon - Flutter only
    // auto-mirrors icons routed through directional-aware widgets like
    // AppBar's back button (BackButtonIcon); a raw Icon() never swaps on
    // its own. In an RTL locale (Arabic), the surrounding Row correctly
    // moves this button to the visual right side of the header via
    // ambient Directionality, but the chevron itself kept pointing left -
    // i.e. towards "forward" for RTL readers - a confusing, mixed-signal
    // affordance. Resolving the correct directional icon explicitly fixes
    // this without any layout changes.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final backIcon = isRtl
        ? Icons.arrow_forward_ios_rounded
        : Icons.arrow_back_ios_new_rounded;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Back button ─────────────────────────────────────────────
          // BUG FIX (ACCESSIBILITY): 44x44 was below the mandatory 48x48dp
          // minimum touch target; the IconButton's own constraints
          // repeated the same 44 value. Both raised to 48 to match the
          // convention already used correctly elsewhere in this codebase
          // (e.g. GameErrorWidget's buttons use `minHeight: 48.h`).
          Semantics(
            button: true,
            label: context.tr('common.back', fallback: 'Back'),
            child: SizedBox(
              width: 48.w,
              height: 48.h,
              child: IconButton(
                onPressed: onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(backIcon, color: titleColor, size: 20.r),
              ),
            ),
          ),
          SizedBox(width: 10.w),

          // ── Level label + progress ──────────────────────────────────
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  context.tr(
                    'game_progress.level_label',
                    fallback: 'Level',
                    args: ['$level'],
                  ),
                  maxLines: 1,
                  minFontSize: 10,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$progressPercent%',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: subColor,
                  ),
                ),
                SizedBox(height: 8.h),
                _ProgressBar(
                  progress: progress,
                  isDark: isDark,
                  progressPercent: progressPercent,
                  themeColor: theme.primaryColor,
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),

          // ── Lives badge ─────────────────────────────────────────────
          _LivesBadge(lives: lives),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _ProgressBar extends StatelessWidget {
  final double progress;
  final bool isDark;
  final int progressPercent;
  final Color themeColor;

  const _ProgressBar({
    required this.progress,
    required this.isDark,
    required this.progressPercent,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final barColor = isDark ? Colors.white : themeColor;

    return Semantics(
      label: context.tr(
        'game_progress.progress_label',
        fallback: 'Progress',
        args: ['$progressPercent'],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3.r),
        child: SizedBox(
          width: double.infinity,
          height: 6.h,
          child: Stack(
            children: [
              // Background track
              Container(
                width: double.infinity,
                height: 6.h,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.08),
              ),
              // Filled portion
              FractionallySizedBox(
                widthFactor: clamped,
                child: Container(
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: barColor,
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivesBadge extends StatelessWidget {
  final int lives;
  const _LivesBadge({required this.lives});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr(
        'game_progress.lives_label',
        fallback: 'Lives',
        args: ['$lives'],
      ),
      child: Container(
        constraints: BoxConstraints(minHeight: 32.h, minWidth: 48.w),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 16.r),
            SizedBox(width: 4.w),
            Text(
              '$lives',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
