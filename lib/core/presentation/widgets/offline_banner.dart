import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/offline_play_gate_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

/// A slim, reactive pill banner displayed at the top of the screen when
/// a free user is playing without internet connectivity.
///
/// Features:
/// - Real-time reactive updates via [OfflinePlayGateService] (instantly reflects decrements 3 -> 2 -> 1).
/// - Non-blocking interaction with smooth animated transitions.
/// - Interactive tap opens a compact bottom sheet explaining that reconnecting restores unlimited free play.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    bool isPremium = false;
    try {
      isPremium = context.select(
        (AuthBloc bloc) => bloc.state.user?.isPremium ?? false,
      );
    } catch (_) {}
    if (isPremium) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: OfflinePlayGateService.instance,
      builder: (context, _) {
        final gate = OfflinePlayGateService.instance;
        final remaining = gate.remainingOfflinePlays;
        final max = OfflinePlayGateService.maxOfflineLevels;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isUrgent = remaining <= 1;

        final Color accentColor =
            isUrgent ? Colors.orangeAccent : Colors.amber;

        final String bannerText;
        if (remaining == 0) {
          bannerText = context.tr(
            'connectivity.offline_quota_exhausted_pill',
            fallback: 'Offline · 0 plays left',
          );
        } else if (remaining == 1) {
          bannerText = context.tr(
            'connectivity.offline_single_play_left',
            fallback: 'Offline · 1 play left!',
          );
        } else {
          bannerText = context.tr(
            'connectivity.offline_banner_with_count',
            args: [remaining.toString(), max.toString()],
            fallback: 'Playing offline · $remaining/$max plays left',
          );
        }

        return SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: ScaleButton(
                onTap: () => _showOfflineQuotaInfoSheet(
                  context,
                  remaining: remaining,
                  max: max,
                  isDark: isDark,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 7.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.slate800.withValues(alpha: 0.92)
                          : Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: accentColor.withValues(alpha: isUrgent ? 0.6 : 0.35),
                        width: isUrgent ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUrgent ? LucideIcons.alertTriangle : LucideIcons.wifiOff,
                          color: accentColor,
                          size: 15.r,
                        ),
                        SizedBox(width: 7.w),
                        Flexible(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.2),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              bannerText,
                              key: ValueKey<int>(remaining),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.slate900,
                                decoration: TextDecoration.none,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Icon(
                          LucideIcons.chevronRight,
                          color: isDark ? Colors.white38 : AppColors.slate400,
                          size: 13.r,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 350.ms)
            .slideY(begin: -0.6, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }

  static void _showOfflineQuotaInfoSheet(
    BuildContext context, {
    required int remaining,
    required int max,
    required bool isDark,
  }) {
    Haptics.vibrate(HapticsType.selection);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.slate900 : Colors.white).withValues(
                  alpha: 0.95,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                border: Border(
                  top: BorderSide(
                    color: Colors.amber.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // Sheet handle
                    Container(
                      width: 40.w,
                      height: 4.h,
                      margin: EdgeInsets.only(bottom: 16.h),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : AppColors.slate300,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),

                    // Header with Icon
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.amber.withValues(alpha: 0.15),
                          ),
                          child: Icon(
                            LucideIcons.wifiOff,
                            color: Colors.amber,
                            size: 20.r,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bottomSheetContext.tr(
                                  'connectivity.offline_info_sheet_title',
                                  fallback: 'Offline Free Plays',
                                ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.slate900,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                bottomSheetContext.tr(
                                  'connectivity.offline_info_sheet_quota',
                                  args: [remaining.toString(), max.toString()],
                                  fallback: '$remaining of $max free offline plays left',
                                ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // Reassurance card: Online is always unlimited
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.emerald950.withValues(alpha: 0.35)
                            : AppColors.emerald50.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isDark
                              ? AppColors.emerald500.withValues(alpha: 0.35)
                              : AppColors.emerald400.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.infinity,
                            color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                            size: 20.r,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              bottomSheetContext.tr(
                                'connectivity.offline_info_sheet_online_perk',
                                fallback:
                                    'Connect to Wi-Fi or mobile data anytime to restore unlimited free play!',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : AppColors.slate800,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10.h),

                    // Premium Card: Unlimited offline anywhere
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.amber.withValues(alpha: 0.08)
                            : Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.crown,
                            color: Colors.amber,
                            size: 20.r,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              bottomSheetContext.tr(
                                'connectivity.offline_info_sheet_premium_perk',
                                fallback:
                                    'Premium members enjoy unlimited offline play with zero ads.',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : AppColors.slate800,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(bottomSheetContext).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : AppColors.slate300,
                              ),
                            ),
                            child: Text(
                              bottomSheetContext.tr('common.got_it', fallback: 'Got it'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.slate800,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(bottomSheetContext).pop();
                              AppRouter.router.push(AppRouter.premiumRoute);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[600],
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                            child: Text(
                              bottomSheetContext.tr(
                                'connectivity.go_premium',
                                fallback: 'View Premium',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ),
            ),
          ),
        );
      },
    );
  }
}
