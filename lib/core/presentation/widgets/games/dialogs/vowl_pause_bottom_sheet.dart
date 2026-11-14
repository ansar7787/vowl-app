import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/layout/game_briefing_scope.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/category_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Modal bottom sheet presented when the player pauses an active game.
///
/// Features:
/// - Freezes game timers and animations.
/// - Resume: Dismisses sheet and resumes the game session.
/// - Briefing: Opens the level rules and pedagogical objectives modal without cluttering the HUD.
/// - Restart: Resets question state and begins the level fresh.
/// - Quit: Safely navigates the player back to the category map.
class VowlPauseBottomSheet extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;
  final VoidCallback? onBriefing;
  final String? category;

  const VowlPauseBottomSheet({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
    this.onBriefing,
    this.category,
  });

  /// Displays the pause menu sheet.
  ///
  /// Automatically resolves [onBriefing] from [GameBriefingScope] if not provided explicitly.
  /// Defaults [onResume] to a no-op and [onQuit] to a standard navigator pop to eliminate boilerplate.
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onResume,
    required VoidCallback onRestart,
    VoidCallback? onQuit,
    VoidCallback? onBriefing,
    String? category,
  }) {
    final effectiveBriefing = onBriefing ??
        (GameBriefingScope.of(context) != null
            ? () => GameBriefingScope.show(context)
            : null);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => VowlPauseBottomSheet(
        onResume: onResume ?? () {},
        onRestart: onRestart,
        onQuit: onQuit ?? () => Navigator.of(context).pop(),
        onBriefing: effectiveBriefing,
        category: category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final sheetBg = isMidnight ? Colors.black : (isDark ? const Color(0xFF131B2B) : Colors.white);
    final accentColor = category != null
        ? CategoryColors.forCategory(category!)
        : AppColors.indigo500;

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 36.h),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle Pill ──────────────────────────────────────────────
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 20.h),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // ── Title & Status ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pause_circle_filled_rounded, color: accentColor, size: 28.r),
              SizedBox(width: 8.w),
              Text(
                context.tr('games.game_paused', fallback: 'GAME PAUSED'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.slate900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            context.tr('games.pause_subtitle', fallback: 'Timer is frozen. Your current score is safe.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? AppColors.slate400 : AppColors.slate600,
            ),
          ),

          SizedBox(height: 24.h),

          // ── Action 1: Resume Playing ──────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onResume();
              },
              icon: Icon(Icons.play_arrow_rounded, size: 24.r, color: Colors.white),
              label: Text(
                context.tr('games.resume', fallback: 'RESUME PLAYING'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ),

          // ── Action 2: View Rules & Briefing (when available) ─────────
          if (onBriefing != null) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onBriefing!();
                },
                icon: Icon(
                  Icons.info_outline_rounded,
                  size: 20.r,
                  color: accentColor,
                ),
                label: Text(
                  context.tr('games.view_briefing', fallback: 'LEVEL RULES & BRIEFING'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: accentColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: accentColor.withValues(alpha: isDark ? 0.45 : 0.35),
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
            ),
          ],

          SizedBox(height: 12.h),

          // ── Action 3: Restart Level ──────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onRestart();
              },
              icon: Icon(
                Icons.refresh_rounded,
                size: 20.r,
                color: isDark ? Colors.white : AppColors.slate800,
              ),
              label: Text(
                context.tr('games.restart_level', fallback: 'RESTART LEVEL'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.slate800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ),

          SizedBox(height: 12.h),

          // ── Action 3: Quit to Map ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onQuit();
              },
              icon: Icon(Icons.exit_to_app_rounded, size: 20.r, color: AppColors.rose500),
              label: Text(
                context.tr('common.quit_to_map', fallback: 'QUIT TO MAP'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.rose500,
                ),
              ),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
