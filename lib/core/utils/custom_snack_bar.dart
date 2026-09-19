import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';

enum CustomSnackBarType { success, error, info, warning }

/// Floating premium snackbar that renders in the user's language.
///
/// FIX (HIGH-2): All status titles ('Success', 'Oops!', 'Notice', 'Tip')
/// were previously hardcoded English strings. They now go through the
/// localisation system via the existing [LocaleService], matching the
/// 18-language support commitment of the app.
class CustomSnackBar {
  CustomSnackBar._(); // Non-instantiable.

  /// Shows a themed floating alert.
  ///
  /// [context] must be mounted — this is enforced by an early guard.
  /// [duration] defaults to 4 seconds but can be shortened for ephemeral
  /// confirmations (e.g., clipboard copy).
  static void show({
    required BuildContext context,
    required String message,
    required CustomSnackBarType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Type-dependent visual configuration ──────────────────────────────────

    final Color baseBgColor;
    final Color accentColor;
    final IconData icon;
    final String titleKey;

    switch (type) {
      case CustomSnackBarType.success:
        baseBgColor = isDark ? AppColors.emerald950 : AppColors.emerald50;
        accentColor = AppColors.emerald500;
        icon = Icons.check_circle_rounded;
        // FIX (HIGH-2): tr() key instead of hardcoded 'Success'.
        titleKey = 'snackbar.success';
      case CustomSnackBarType.error:
        baseBgColor = isDark ? AppColors.red900 : AppColors.red50;
        accentColor = AppColors.red500;
        icon = Icons.error_rounded;
        // FIX (HIGH-2): tr() key instead of hardcoded 'Oops!'.
        titleKey = 'snackbar.error';
      case CustomSnackBarType.warning:
        baseBgColor = isDark ? AppColors.amber900 : AppColors.warningLight;
        accentColor = AppColors.amber500;
        icon = Icons.warning_rounded;
        // FIX (HIGH-2): tr() key instead of hardcoded 'Notice'.
        titleKey = 'snackbar.warning';
      case CustomSnackBarType.info:
        baseBgColor = isDark ? AppColors.blue900 : AppColors.blue50;
        accentColor = AppColors.blue500;
        icon = Icons.info_rounded;
        // FIX (HIGH-2): tr() key instead of hardcoded 'Tip'.
        titleKey = 'snackbar.info';
    }

    final cardBgColor = isDark
        ? baseBgColor.withValues(alpha: 0.85)
        : baseBgColor.withValues(alpha: 0.95);
    final textColor = isDark ? Colors.white : AppColors.slate800;
    final subtextColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.slate500;

    // Resolve localised title. LocaleService is available without context.
    // Fall back to the raw key string if localisation fails gracefully.
    final title = context.tr(titleKey);

    final snackBar = SnackBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      padding: EdgeInsets.zero,
      content: Semantics(
        // FIX (ACCESSIBILITY): Screen readers now announce both the status
        // category and the message body as a single utterance.
        label: '$title: $message',
        liveRegion: true,
        child: Container(
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: accentColor.withValues(alpha: isDark ? 0.3 : 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Accent side bar
                Container(width: 6.w, color: accentColor),

                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                          child: Icon(icon, color: accentColor, size: 22.r),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                message,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: subtextColor,
                                  height: 1.3,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Dismiss button
                Semantics(
                  label: 'Dismiss',
                  button: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        child: Icon(
                          Icons.close_rounded,
                          color: subtextColor,
                          size: 18.r,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
