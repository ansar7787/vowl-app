import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Error state widget displayed when a quest fails to load.
///
/// Provides two recovery actions: [onRetry] and [onBack]. Accepts an
/// optional [primaryColor] to match the active game category's theme.
class GameErrorWidget extends StatelessWidget {
  /// Optional override for the card headline. Defaults to localised key.
  final String? title;

  /// Optional override for the body message. Defaults to localised key.
  final String? message;

  final VoidCallback onRetry;
  final VoidCallback onBack;
  final Color primaryColor;

  const GameErrorWidget({
    super.key,
    this.title,
    this.message,
    required this.onRetry,
    required this.onBack,
    this.primaryColor = const Color(0xFF6366F1),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedTitle =
        title ??
        context.tr('game_error.title', fallback: 'Oops! Something went wrong.');
    final resolvedMessage =
        message ??
        context.tr(
          'game_error.message',
          fallback: 'There was a problem loading the game.',
        );

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // FIX (RESPONSIVENESS/ACCESSIBILITY): this card stacks an icon,
          // title, message, and two 48dp+ buttons - genuinely tall content
          // that can exceed a small/landscape/split-screen viewport at
          // high accessibility text scale (up to 3.0x) or with longer
          // translated copy. Same scroll-safe pattern used elsewhere in
          // this codebase: preserves the exact current centered look when
          // content fits, and only scrolls (instead of overflowing) when
          // it doesn't.
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48.h,
              ),
              child: Center(
                child: GlassTile(
                  borderRadius: BorderRadius.circular(32.r),
                  padding: EdgeInsets.all(32.r),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Error icon ──────────────────────────────────────
                      Container(
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.report_gmailerrorred_rounded,
                          size: 48.r,
                          color: Colors.redAccent,
                        ),
                      ).animate().scale(
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      ),

                      SizedBox(height: 24.h),

                      // ── Title ───────────────────────────────────────────
                      Text(
                        resolvedTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // ── Message ─────────────────────────────────────────
                      Text(
                        resolvedMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black54,
                          height: 1.5,
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // ── Retry ────────────────────────────────────────────
                      Semantics(
                        button: true,
                        label: context.tr(
                          'games.try_again',
                          fallback: 'Try Again',
                        ),
                        child: ScaleButton(
                          onTap: onRetry,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            constraints: BoxConstraints(minHeight: 48.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  primaryColor.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              context
                                  .tr('games.try_again', fallback: 'Try Again')
                                  .toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // ── Go back ──────────────────────────────────────────
                      Semantics(
                        button: true,
                        label: context.tr(
                          'common.go_back',
                          fallback: 'Go Back',
                        ),
                        child: ScaleButton(
                          onTap: onBack,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            constraints: BoxConstraints(minHeight: 48.h),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Text(
                              context
                                  .tr('common.go_back', fallback: 'Go Back')
                                  .toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white60 : Colors.black54,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
              ),
            ),
          );
        },
      ),
    );
  }
}
