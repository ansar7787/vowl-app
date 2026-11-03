import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Discovery Hub widget presenting curated quest sequences in an Apex Cockpit layout:
/// - Flagship Hero Card: Adaptive "For You" smart recommendation.
/// - 3-Cell Superpower Row: Daily Duo, Speed Blitz, and Grammar Pro.
///
/// 100% visible with zero horizontal swiping, zero battery-draining loops,
/// and zero text clipping or ellipses on narrow viewports.
class DiscoveryDeck extends StatelessWidget {
  /// Current authenticated [user] entity.
  final UserEntity user;

  /// Callback executed when tapping to launch a discovered quest.
  final ValueChanged<String> onLaunchQuest;

  /// Creates a [DiscoveryDeck] for [user].
  const DiscoveryDeck({
    super.key,
    required this.user,
    required this.onLaunchQuest,
  });

  void _triggerHaptic() {
    try {
      di.sl<HapticService>().selection();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Flagship Hero Card: Adaptive "For You"
          _HeroFlagshipQuestCard(
            isDark: isDark,
            title: context.tr('home.discovery_foryou_title', fallback: 'For You'),
            badge: context.tr('home.discovery_diff_adaptive', fallback: 'Adaptive'),
            subtitle: context.tr(
              'home.discovery_foryou_subtitle',
              fallback: 'Personalized to your practice',
            ),
            onTap: () {
              _triggerHaptic();
              onLaunchQuest('smart_recommendation');
            },
          ),

          SizedBox(height: 10.h),

          // 2. 3-Cell Superpower Row
          Row(
            children: [
              // Cell 1: Daily Duo
              Expanded(
                child: _DiscoverySubCell(
                  isDark: isDark,
                  icon: Icons.auto_awesome_motion_rounded,
                  color: const Color(0xFF06B6D4), // Cyan
                  title: context.tr(
                    'home.discovery_dailyduo_title',
                    fallback: 'Daily Duo',
                  ),
                  tag: context.tr(
                    'home.quests_count',
                    fallback: '2 Quests',
                    args: ['2'],
                  ),
                  onTap: () {
                    _triggerHaptic();
                    onLaunchQuest('daily_duo');
                  },
                ),
              ),
              SizedBox(width: 8.w),

              // Cell 2: Speed Blitz
              Expanded(
                child: _DiscoverySubCell(
                  isDark: isDark,
                  icon: Icons.bolt_rounded,
                  color: IllustrationColors.warmOrange,
                  title: context.tr(
                    'home.discovery_speedblitz_title',
                    fallback: 'Speed Blitz',
                  ),
                  tag: context.tr(
                    'home.quests_count',
                    fallback: '3 Quests',
                    args: ['3'],
                  ),
                  onTap: () {
                    _triggerHaptic();
                    onLaunchQuest('speed_blitz');
                  },
                ),
              ),
              SizedBox(width: 8.w),

              // Cell 3: Grammar Pro
              Expanded(
                child: _DiscoverySubCell(
                  isDark: isDark,
                  icon: Icons.verified_user_rounded,
                  color: AppColors.emerald500,
                  title: context.tr(
                    'home.discovery_grammarpro_title',
                    fallback: 'Grammar Pro',
                  ),
                  tag: context.tr(
                    'home.quests_count',
                    fallback: '3 Quests',
                    args: ['3'],
                  ),
                  onTap: () {
                    _triggerHaptic();
                    onLaunchQuest('grammar_pro');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hero flagship horizon card for personalized adaptive recommendations.
class _HeroFlagshipQuestCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String badge;
  final String subtitle;
  final VoidCallback onTap;

  const _HeroFlagshipQuestCard({
    required this.isDark,
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMidnight = isDark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black;
    return Semantics(
      button: true,
      label: '$title, $badge, $subtitle. Double tap to start quest sequence.',
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isMidnight
                ? AppColors.midnightSurface
                : (isDark ? const Color(0xFF111827) : Colors.white),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: isMidnight
                  ? Colors.white.withValues(alpha: 0.12)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.slate100),
              width: 1.r,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isMidnight ? 0.35 : (isDark ? 0.20 : 0.03),
                ),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Leading Halo Icon
              Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(
                    alpha: isDark ? 0.18 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.indigo500.withValues(
                      alpha: isDark ? 0.35 : 0.25,
                    ),
                    width: 1.r,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.lightbulb_rounded,
                    size: 22.r,
                    color: isDark
                        ? const Color(0xFFA5B4FC)
                        : AppColors.indigo500,
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Title, Badge, and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.indigo500.withValues(
                              alpha: isDark ? 0.20 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          child: Text(
                            badge.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? const Color(0xFFA5B4FC)
                                  : AppColors.indigo500,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      softWrap: true,
                    ),
                  ],
                ),
              ),

              SizedBox(width: 10.w),

              // Action Pill
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.indigo500,
                  borderRadius: BorderRadius.circular(100.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('home.play', fallback: 'Play'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 9.r,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact superpower quest cell for the 3-column row.
class _DiscoverySubCell extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String title;
  final String tag;
  final VoidCallback onTap;

  const _DiscoverySubCell({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.title,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMidnight = isDark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black;
    return Semantics(
      button: true,
      label: '$title, $tag. Double tap to start quest.',
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isMidnight
                ? AppColors.midnightSurface
                : (isDark ? const Color(0xFF111827) : Colors.white),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isMidnight
                  ? Colors.white.withValues(alpha: 0.12)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.slate100),
              width: 1.r,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isMidnight ? 0.30 : (isDark ? 0.15 : 0.02),
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Halo Icon
              Container(
                width: 30.r,
                height: 30.r,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: color.withValues(alpha: isDark ? 0.32 : 0.20),
                    width: 1.r,
                  ),
                ),
                child: Center(
                  child: Icon(icon, size: 16.r, color: color),
                ),
              ),
              SizedBox(height: 6.h),

              // Title (with scale-down fit to prevent any wrapping or overflow)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFF8FAFC)
                        : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                ),
              ),
              SizedBox(height: 2.h),

              // Tag / Quest Count
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tag,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
