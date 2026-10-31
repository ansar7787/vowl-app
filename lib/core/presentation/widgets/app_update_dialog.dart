import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_update_service.dart';
import 'package:vowl/core/utils/app_version_helper.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';

/// Modal dialog presenting a flexible or forced application update.
class AppUpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;
  final AppUpdateService? updateService;

  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
    this.updateService,
  });

  /// Displays the [AppUpdateDialog] on top of [context].
  static Future<void> show(
    BuildContext context, {
    required AppUpdateInfo updateInfo,
    AppUpdateService? updateService,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: !updateInfo.isForced,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogContext) => AppUpdateDialog(
        updateInfo: updateInfo,
        updateService: updateService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final service = updateService ?? di.sl<AppUpdateService>();

    final cleanCurrent =
        AppVersionHelper.cleanDisplayVersion(updateInfo.currentVersion);
    final cleanLatest =
        AppVersionHelper.cleanDisplayVersion(updateInfo.latestVersion);

    final title = updateInfo.isForced
        ? context.tr('update.required_title', fallback: 'Update Required')
        : context.tr('update.available_title', fallback: 'New Version Available!');

    final subtitle = updateInfo.isForced
        ? context.tr(
            'update.required_subtitle',
            fallback:
                'A critical update is needed to keep your progress synced and secure.',
          )
        : context.tr(
            'update.available_subtitle',
            fallback: 'Discover the latest quests, enhancements, and speed upgrades!',
          );

    final notes = updateInfo.releaseNotes.trim().isNotEmpty
        ? updateInfo.releaseNotes.trim()
        : context.tr(
            'update.default_notes',
            fallback:
                '• Performance enhancements & smoother animations\n• Leaderboard navigation & theme refinements\n• Bug fixes to keep your learning seamless',
          );

    final card = PopScope(
      canPop: !updateInfo.isForced,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Material(
              color: Colors.transparent,
              child: GlassTile(
                padding: EdgeInsets.all(22.r),
                borderRadius: BorderRadius.circular(28.r),
                blur: 0,
                borderColor: updateInfo.isForced
                    ? AppColors.rose500.withValues(alpha: 0.45)
                    : (isDark
                        ? AppColors.blue500.withValues(alpha: 0.4)
                        : AppColors.indigo500.withValues(alpha: 0.3)),
                color: isMidnight
                    ? AppColors.midnightSurface
                    : (isDark ? AppColors.slate800 : Colors.white),
                borderWidth: 1.5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge Header Icon
                    _buildHeaderBadge(context, reduceMotion),
                    SizedBox(height: 16.h),

                    // Version comparison pill
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: updateInfo.isForced
                            ? AppColors.rose500.withValues(alpha: 0.12)
                            : AppColors.indigo500.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: updateInfo.isForced
                              ? AppColors.rose500.withValues(alpha: 0.25)
                              : AppColors.indigo500.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Text(
                        'v$cleanCurrent  →  v$cleanLatest',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          color: updateInfo.isForced
                              ? AppColors.rose500
                              : (isDark
                                  ? AppColors.blue300
                                  : AppColors.indigo600),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.slate900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 6.h),

                    // Subtitle
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : AppColors.slate600,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // What's new box
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.25)
                            : AppColors.slate100.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 14.r,
                                color: IllustrationColors.premiumGold,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                context.tr(
                                  'update.whats_new',
                                  fallback: "What's New",
                                ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.slate800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            notes,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white60
                                  : AppColors.slate600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await service.launchStore(
                            customUrl: updateInfo.storeUrl,
                          );
                          if (!updateInfo.isForced && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: updateInfo.isForced
                              ? AppColors.rose500
                              : AppColors.indigo500,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.system_update_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              context.tr(
                                'update.update_now',
                                fallback: 'Update Now',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (!updateInfo.isForced) ...[
                      SizedBox(height: 8.h),
                      TextButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await service.recordDismissal(
                            updateInfo.latestVersion,
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(
                          context.tr('update.maybe_later', fallback: 'Maybe Later'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white60 : AppColors.slate500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (reduceMotion) return card;
    return card
        .animate()
        .fadeIn(duration: 250.ms)
        .scaleXY(begin: 0.94, end: 1.0, curve: Curves.easeOutCubic);
  }

  Widget _buildHeaderBadge(BuildContext context, bool reduceMotion) {
    final gradient = updateInfo.isForced
        ? const LinearGradient(
            colors: [AppColors.rose500, IllustrationColors.warmOrange],
          )
        : const LinearGradient(
            colors: [AppColors.indigo500, AppColors.blue500],
          );

    final badge = Container(
      width: 60.r,
      height: 60.r,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (updateInfo.isForced ? AppColors.rose500 : AppColors.indigo500)
                .withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          updateInfo.isForced
              ? Icons.warning_amber_rounded
              : Icons.rocket_launch_rounded,
          color: Colors.white,
          size: 28.r,
        ),
      ),
    );

    if (reduceMotion || VowlMotion.lowAnimationModeOverride.value) {
      return badge;
    }

    return badge
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -2, end: 2, duration: 1600.ms, curve: Curves.easeInOut);
  }
}

