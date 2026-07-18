import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class VocabularyErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Color primaryColor;

  const VocabularyErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.primaryColor = const Color(0xFF6366F1),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final bodyColor = isDark ? Colors.white70 : Colors.black54;

    return Semantics(
      label: 'Error: $message',
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ErrorIcon(primaryColor: primaryColor),
              SizedBox(height: 24.h),
              Text(
                'Investigation Stalled',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
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
                  fontSize: 16.sp,
                  color: bodyColor,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),
              _RetryButton(primaryColor: primaryColor, onRetry: onRetry),
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

  const _ErrorIcon({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.error_outline_rounded, color: primaryColor, size: 64.r),
    ).animate().shake(duration: 500.ms);
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
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
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
              Text(
                context
                    .tr('games.try_again', fallback: 'Try Again')
                    .toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
