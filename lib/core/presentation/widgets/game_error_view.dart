import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Standardized in-game error display view presenting unified retry and exit actions across all games.
class GameErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onExit;
  final Color primaryColor;

  const GameErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.onExit,
    this.primaryColor = AppColors.indigo500,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final bodyColor = isDark ? Colors.white70 : Colors.black54;

    final isOffline = message.toLowerCase().contains('internet') ||
        message.toLowerCase().contains('network') ||
        message.toLowerCase().contains('connection') ||
        message.toLowerCase().contains('offline');

    final title = isOffline
        ? context.tr(
            'connectivity.no_internet_title',
            fallback: 'Connection Interrupted',
          )
        : context.tr(
            'game_error.title',
            fallback: 'Quest Unavailable',
          );

    return Semantics(
      label: 'Error: $message',
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ErrorIcon(
                primaryColor: primaryColor,
                isOffline: isOffline,
              ),
              SizedBox(height: 24.h),
              AutoSizeText(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                minFontSize: 16,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  color: bodyColor,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),
              _RetryButton(primaryColor: primaryColor, onRetry: onRetry),
              SizedBox(height: 12.h),
              _ExitButton(
                onExit: onExit ?? () => Navigator.of(context).maybePop(),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ErrorIcon extends StatelessWidget {
  final Color primaryColor;
  final bool isOffline;

  const _ErrorIcon({required this.primaryColor, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
      child: Icon(
        isOffline ? LucideIcons.wifiOff : Icons.error_outline_rounded,
        color: primaryColor,
        size: 54.r,
      ),
    ).animate().shake(duration: 400.ms);
  }
}

class _RetryButton extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onRetry;

  const _RetryButton({required this.primaryColor, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr('common.retry', fallback: 'Retry'),
      child: ScaleButton(
        onTap: onRetry,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 15.h),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh_rounded, color: Colors.white),
              SizedBox(width: 8.w),
              Flexible(
                child: AutoSizeText(
                  context
                      .tr('games.try_again', fallback: 'Try Again')
                      .toUpperCase(),
                  maxLines: 1,
                  minFontSize: 10,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1,
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

class _ExitButton extends StatelessWidget {
  final VoidCallback onExit;
  final bool isDark;

  const _ExitButton({required this.onExit, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onExit,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back_rounded,
              size: 16.r,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            SizedBox(width: 6.w),
            Text(
              context.tr('common.back', fallback: 'Back to Menu'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
