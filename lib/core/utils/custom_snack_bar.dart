import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        baseBgColor = isDark
            ? const Color(0xFF064E3B)
            : const Color(0xFFECFDF5);
        accentColor = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        // FIX (HIGH-2): tr() key instead of hardcoded 'Success'.
        titleKey = 'snackbar.success';
      case CustomSnackBarType.error:
        baseBgColor = isDark
            ? const Color(0xFF7F1D1D)
            : const Color(0xFFFEF2F2);
        accentColor = const Color(0xFFEF4444);
        icon = Icons.error_rounded;
        // FIX (HIGH-2): tr() key instead of hardcoded 'Oops!'.
        titleKey = 'snackbar.error';
      case CustomSnackBarType.warning:
        baseBgColor = isDark
            ? const Color(0xFF78350F)
            : const Color(0xFFFFFBEB);
        accentColor = const Color(0xFFF59E0B);
        icon = Icons.warning_rounded;
        // FIX (HIGH-2): tr() key instead of hardcoded 'Notice'.
        titleKey = 'snackbar.warning';
      case CustomSnackBarType.info:
        baseBgColor = isDark
            ? const Color(0xFF1E3A8A)
            : const Color(0xFFEFF6FF);
        accentColor = const Color(0xFF3B82F6);
        icon = Icons.info_rounded;
        // FIX (HIGH-2): tr() key instead of hardcoded 'Tip'.
        titleKey = 'snackbar.info';
    }

    final cardBgColor = isDark
        ? baseBgColor.withValues(alpha: 0.85)
        : baseBgColor.withValues(alpha: 0.95);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF64748B);

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
