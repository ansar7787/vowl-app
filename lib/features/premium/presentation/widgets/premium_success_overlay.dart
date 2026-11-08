import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// Celebration overlay shown when a subscription payment succeeds.
class PremiumSuccessOverlay extends StatelessWidget {
  final VoidCallback onBeginAdventure;
  final String? transactionId;

  const PremiumSuccessOverlay({
    super.key,
    required this.onBeginAdventure,
    this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? const Color(0xFF131A29) : Colors.white);
    final borderColor = isDark
        ? AppColors.emerald500.withValues(alpha: 0.35)
        : AppColors.emerald500.withValues(alpha: 0.22);
    final textPrimary = isDark ? Colors.white : AppColors.slate900;
    final textSecondary = isDark ? AppColors.slate300 : AppColors.slate600;
    final textMuted = isDark ? AppColors.slate400 : AppColors.slate500;
    final txnBoxBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : const Color(0xFFF8FAFC);
    final txnBoxBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.slate200;

    Widget iconWidget = Container(
      width: 86.r,
      height: 86.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.emerald400, AppColors.emerald600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald500.withValues(alpha: isDark ? 0.45 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.4)
              : AppColors.emerald500.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: Icon(LucideIcons.checkCircle2, color: Colors.white, size: 40.r),
    );

    if (!reduceMotion) {
      iconWidget = iconWidget
          .animate()
          .scale(duration: 600.ms, curve: Curves.elasticOut)
          .shimmer(duration: 2.seconds, delay: 500.ms);
    }

    Widget titleWidget = ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: isDark
            ? const [AppColors.emerald400, AppColors.emerald500]
            : const [Color(0xFF059669), Color(0xFF047857)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        context.tr('premium.success_title', fallback: 'UPGRADE SUCCESSFUL'),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 24.sp,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.5,
          height: 1.2,
        ),
      ),
    );

    if (!reduceMotion) {
      titleWidget = titleWidget
          .animate()
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.2, end: 0);
    }

    Widget subtitleWidget = AutoSizeText(
      context.tr(
        'premium.success_subtitle',
        fallback:
            'Your upgrade was successful. All elite features are now unlocked.',
      ),
      textAlign: TextAlign.center,
      maxLines: 3,
      minFontSize: 10,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14.5.sp,
        color: textSecondary,
        height: 1.4,
      ),
    );

    if (!reduceMotion) {
      subtitleWidget = subtitleWidget
          .animate()
          .fadeIn(delay: 200.ms)
          .slideY(begin: 0.2, end: 0);
    }

    Widget? txnWidget;
    if (transactionId != null) {
      txnWidget = Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: txnBoxBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: txnBoxBorder),
        ),
        child: Column(
          children: [
            Text(
              context
                  .tr(
                    'premium.transaction_id_label',
                    fallback: 'TRANSACTION ID',
                  )
                  .toUpperCase(),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                color: textMuted,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 6.h),
            SelectableText(
              transactionId!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

      if (!reduceMotion) {
        txnWidget = txnWidget.animate().fadeIn(delay: 400.ms);
      }
    }

    Widget buttonWidget = Semantics(
      button: true,
      label: context.tr(
        'premium.begin_adventure_button',
        fallback: 'BEGIN ADVENTURE',
      ),
      child: ScaleButton(
        onTap: onBeginAdventure,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF10B981,
                ).withValues(alpha: isDark ? 0.4 : 0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.sparkles, size: 16.sp, color: Colors.white),
                SizedBox(width: 8.w),
                Flexible(
                  child: AutoSizeText(
                    context
                        .tr(
                          'premium.begin_adventure_button',
                          fallback: 'BEGIN ADVENTURE',
                        )
                        .toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    minFontSize: 10,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.sp,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!reduceMotion) {
      buttonWidget = buttonWidget
          .animate()
          .fadeIn(delay: 600.ms)
          .slideY(begin: 0.2, end: 0);
    }

    Widget content = Container(
      padding: EdgeInsets.all(AppSpacing.cardSpacious),
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.emerald500.withValues(alpha: 0.15)
                : AppColors.emerald500.withValues(alpha: 0.08),
            blurRadius: isDark ? 50 : 32,
            spreadRadius: isDark ? 10 : 2,
            offset: isDark ? Offset.zero : const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              label: context.tr(
                'premium.success_title',
                fallback: 'UPGRADE SUCCESSFUL',
              ),
              child: iconWidget,
            ),
            SizedBox(height: 24.h),
            titleWidget,
            SizedBox(height: 12.h),
            subtitleWidget,
            if (txnWidget != null) ...[SizedBox(height: 16.h), txnWidget],
            SizedBox(height: 28.h),
            buttonWidget,
          ],
        ),
      ),
    );

    if (!reduceMotion) {
      content = content.animate().fade().scale(
        begin: const Offset(0.95, 0.95),
        curve: Curves.easeOutCubic,
        duration: 400.ms,
      );
    }

    return content;
  }
}
