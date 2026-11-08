import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Categorizes the styling, iconography, and semantic severity of a [CustomSnackBar].
enum CustomSnackBarType {
  /// Confirms a successful user action or reward claim.
  success,

  /// Alerts the user to a network failure, validation issue, or critical error.
  error,

  /// Provides general contextual information or informational updates.
  info,

  /// Cautions the user regarding an impending action, timeout, or resource warning.
  warning,
}

/// Floating premium snackbar / toast rendered at the root overlay level.
///
/// FIX (OVERLAY-SNACKBAR): Previously delegated to [ScaffoldMessenger], causing
/// alerts to be hidden behind modal bottom sheets and modal barriers (such as during
/// rewarded ad watches and in-app store transactions).
/// Now rendered using [Overlay.of(context, rootOverlay: true)], guaranteeing alerts
/// float smoothly at the top of the screen above all sheets, dialogs, and scrims.
class CustomSnackBar {
  CustomSnackBar._(); // Non-instantiable.

  static String? _lastMessage;
  static CustomSnackBarType? _lastType;
  static int? _lastShownEpochMs;
  static OverlayEntry? _currentEntry;
  static GlobalKey<_ToastOverlayWidgetState>? _activeWidgetKey;

  /// Visible for testing to reset debounce state and active overlays.
  @visibleForTesting
  static void resetDebounce() {
    _lastMessage = null;
    _lastType = null;
    _lastShownEpochMs = null;
    dismissCurrent();
  }

  /// Dismisses any currently visible toast overlay.
  static void dismissCurrent() {
    if (_activeWidgetKey?.currentState != null) {
      _activeWidgetKey!.currentState!.dismissAnimated();
    } else {
      _cleanupEntry();
    }
  }

  static void _cleanupEntry() {
    _activeWidgetKey = null;
    final entry = _currentEntry;
    _currentEntry = null;
    if (entry != null) {
      try {
        if (entry.mounted) {
          entry.remove();
        }
      } catch (_) {}
    }
  }

  /// Shows a themed floating alert above all modal sheets and dialogs.
  ///
  /// [context] must be mounted — this is enforced by an early guard.
  /// [duration] defaults to 3 seconds but can be shortened for ephemeral
  /// confirmations (e.g., clipboard copy).
  static void show({
    required BuildContext context,
    required String message,
    required CustomSnackBarType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastMessage == trimmed &&
        _lastType == type &&
        _lastShownEpochMs != null &&
        (now - _lastShownEpochMs!) < 750) {
      return;
    }
    _lastMessage = trimmed;
    _lastType = type;
    _lastShownEpochMs = now;

    // Dismiss existing toast immediately before presenting a new one.
    _cleanupEntry();

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
        titleKey = 'snackbar.success';
      case CustomSnackBarType.error:
        baseBgColor = isDark ? AppColors.red900 : AppColors.red50;
        accentColor = AppColors.red500;
        icon = Icons.error_rounded;
        titleKey = 'snackbar.error';
      case CustomSnackBarType.warning:
        baseBgColor = isDark ? AppColors.amber900 : AppColors.warningLight;
        accentColor = AppColors.amber500;
        icon = Icons.warning_rounded;
        titleKey = 'snackbar.warning';
      case CustomSnackBarType.info:
        baseBgColor = isDark ? AppColors.blue900 : AppColors.blue50;
        accentColor = AppColors.blue500;
        icon = Icons.info_rounded;
        titleKey = 'snackbar.info';
    }

    final cardBgColor = isDark
        ? baseBgColor.withValues(alpha: 0.92)
        : baseBgColor.withValues(alpha: 0.98);
    final textColor = isDark ? Colors.white : AppColors.slate800;
    final subtextColor = isDark
        ? Colors.white.withValues(alpha: 0.75)
        : AppColors.slate500;

    final title = context.tr(titleKey);

    OverlayState? overlay;
    try {
      overlay =
          Overlay.maybeOf(context, rootOverlay: true) ??
          Overlay.maybeOf(context);
    } catch (_) {
      overlay = null;
    }

    if (overlay == null) {
      // Fallback to standard ScaffoldMessenger if overlay is unreachable.
      final fallbackSnackBar = SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        padding: EdgeInsets.zero,
        content: _buildCardContent(
          title: title,
          message: message,
          cardBgColor: cardBgColor,
          accentColor: accentColor,
          textColor: textColor,
          subtextColor: subtextColor,
          icon: icon,
          isDark: isDark,
          onDismiss: () {
            try {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            } catch (_) {}
          },
        ),
      );
      try {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(fallbackSnackBar);
      } catch (_) {}
      return;
    }

    final widgetKey = GlobalKey<_ToastOverlayWidgetState>();
    _activeWidgetKey = widgetKey;

    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        final topPadding = MediaQuery.viewPaddingOf(overlayContext).top;
        final safeTop = topPadding > 0 ? topPadding + 8.h : 24.h;

        return Positioned(
          top: safeTop,
          left: 16.w,
          right: 16.w,
          child: Material(
            type: MaterialType.transparency,
            child: _ToastOverlayWidget(
              key: widgetKey,
              duration: duration,
              onDismissCompleted: () {
                if (entry?.mounted == true) {
                  try {
                    entry!.remove();
                  } catch (_) {}
                }
                if (_currentEntry == entry) {
                  _currentEntry = null;
                  _activeWidgetKey = null;
                }
              },
              child: Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.up,
                onDismissed: (_) {
                  if (entry?.mounted == true) {
                    try {
                      entry!.remove();
                    } catch (_) {}
                  }
                  if (_currentEntry == entry) {
                    _currentEntry = null;
                    _activeWidgetKey = null;
                  }
                },
                child: _buildCardContent(
                  title: title,
                  message: message,
                  cardBgColor: cardBgColor,
                  accentColor: accentColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  icon: icon,
                  isDark: isDark,
                  onDismiss: () => dismissCurrent(),
                ),
              ),
            ),
          ),
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static Widget _buildCardContent({
    required String title,
    required String message,
    required Color cardBgColor,
    required Color accentColor,
    required Color textColor,
    required Color subtextColor,
    required IconData icon,
    required bool isDark,
    required VoidCallback onDismiss,
  }) {
    return Semantics(
      label: '$title: $message',
      liveRegion: true,
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.35 : 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
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
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              message,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: subtextColor,
                                height: 1.35,
                              ),
                              maxLines: 6,
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
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDismiss,
                  child: Container(
                    width: 44.w,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.close_rounded,
                      color: subtextColor,
                      size: 18.r,
                    ),
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

/// Animates the toast in smoothly from the top, and animates out on dismissal.
class _ToastOverlayWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final VoidCallback onDismissCompleted;

  const _ToastOverlayWidget({
    super.key,
    required this.child,
    required this.duration,
    required this.onDismissCompleted,
  });

  @override
  State<_ToastOverlayWidget> createState() => _ToastOverlayWidgetState();
}

class _ToastOverlayWidgetState extends State<_ToastOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _dismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.6), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dismissTimer?.cancel();
        _dismissTimer = Timer(widget.duration, () {
          dismissAnimated();
        });
      }
    });

    _animController.forward();
  }

  /// Triggers smooth exit animation before removing the entry.
  void dismissAnimated() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    _animController.reverse().then((_) {
      if (mounted) {
        widget.onDismissCompleted();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
