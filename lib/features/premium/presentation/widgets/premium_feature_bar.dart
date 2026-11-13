import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/illustration_colors.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color06b6d4 = Color(0xFF06B6D4);
  static const Color coloreab308 = Color(0xFFEAB308);
}

/// Feature strip presenting the core VIP value pillars
/// (Zero Ads, 20,000 Levels, Real Accents, and Offline Mode)
/// alongside an expandable detailed perks manifest.
class ModernFeatureBar extends StatefulWidget {
  const ModernFeatureBar({super.key});

  @override
  State<ModernFeatureBar> createState() => _ModernFeatureBarState();
}

class _ModernFeatureBarState extends State<ModernFeatureBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  context
                      .tr('premium.whats_included', fallback: "PREMIUM PERKS")
                      .toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: isDark ? Colors.white70 : AppColors.slate500,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: () {
                  di.sl<HapticService>().selection();
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpanded
                            ? context.tr(
                                'premium.show_less',
                                fallback: 'Show Less',
                              )
                            : context.tr(
                                'premium.view_all_12',
                                fallback: 'View All 12',
                              ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.indigo500,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        _isExpanded
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        color: AppColors.indigo500,
                        size: 13.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // 4 Real Core Pillars: Ultra-Compact 1-Row Strip (Zero Scroll, Zero Clutter, Zero Side-Cutting)
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.slate900.withValues(alpha: 0.7)
                : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark ? Colors.white12 : AppColors.slate200,
              width: 1.2,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: AppColors.slate200.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildPillarItem(
                  context,
                  isDark: isDark,
                  icon: LucideIcons.shieldCheck,
                  iconColor: AppColors.emerald500,
                  title: context.tr(
                    'premium.pillar_zero_ads',
                    fallback: 'Zero Ads',
                  ),
                  subtitle: context.tr(
                    'premium.pillar_zero_ads_sub',
                    fallback: 'No interruptions',
                  ),
                ),
              ),
              _buildPillarDivider(isDark),
              Expanded(
                child: _buildPillarItem(
                  context,
                  isDark: isDark,
                  icon: LucideIcons.unlock,
                  iconColor: AppColors.indigo500,
                  title: context.tr(
                    'premium.pillar_levels',
                    fallback: '20,000 Levels',
                  ),
                  subtitle: context.tr(
                    'premium.pillar_levels_sub',
                    fallback: '100 games unlocked',
                  ),
                ),
              ),
              _buildPillarDivider(isDark),
              Expanded(
                child: _buildPillarItem(
                  context,
                  isDark: isDark,
                  icon: LucideIcons.volume2,
                  iconColor: AppColors.violet500,
                  title: context.tr(
                    'premium.pillar_accents',
                    fallback: 'Real Accents',
                  ),
                  subtitle: context.tr(
                    'premium.pillar_accents_sub',
                    fallback: 'US & UK voices',
                  ),
                ),
              ),
              _buildPillarDivider(isDark),
              Expanded(
                child: _buildPillarItem(
                  context,
                  isDark: isDark,
                  icon: LucideIcons.wifiOff,
                  iconColor: AppColors.amber500,
                  title: context.tr(
                    'premium.pillar_offline',
                    fallback: 'Offline Mode',
                  ),
                  subtitle: context.tr(
                    'premium.pillar_offline_sub',
                    fallback: 'Learn anywhere',
                  ),
                ),
              ),
            ],
          ),
        ),

        // Expandable Full Detailed Manifest (All 12 Perks)
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 14.h),
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.slate900.withValues(alpha: 0.6)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.06),
                width: 1.2,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildListFeature(
                  context,
                  icon: LucideIcons.languages,
                  title: context.tr(
                    'premium.feature_offline_translator',
                    fallback: 'Offline 50+ Languages Translator',
                  ),
                  color: IllustrationColors.brightBlue,
                ),
                _buildListFeature(
                  context,
                  icon: LucideIcons.sparkles,
                  title: context.tr(
                    'premium.feature_translations',
                    fallback: 'Instant AI Translations',
                  ),
                  color: AppColors.rose500,
                ),
                _buildListFeature(
                  context,
                  icon: LucideIcons.volume2,
                  title: context.tr(
                    'premium.feature_world_accents',
                    fallback: 'World Voice Accents (British, US, AU & IN)',
                  ),
                  color: AppColors.violet500,
                ),
                _buildListFeature(
                  context,
                  icon: LucideIcons.shieldCheck,
                  title: context.tr(
                    'premium.feature_zero_ads',
                    fallback: 'ZERO ADS',
                  ),
                  color: AppColors.emerald500,
                ),
                _buildListFeature(
                  context,
                  icon: LucideIcons.swords,
                  title: context.tr(
                    'premium.feature_arena_refuel',
                    fallback: 'Instant 1v1 Arena Refuel (Zero Ads)',
                  ),
                  color: AppColors.indigo500,
                ),
                _buildListFeature(
                  context,
                  icon: LucideIcons.wifiOff,
                  title: context.tr(
                    'premium.feature_play_offline',
                    fallback: 'Play Offline Anywhere',
                  ),
                  color: AppColors.slate500,
                ),
                _buildListFeature(
                  context,
                  icon: LucideIcons.unlock,
                  title: context.tr(
                    'premium.feature_unlimited_levels',
                    fallback: 'UNLIMITED PROGRESS',
                  ),
                  color: _LocalPalette.color06b6d4,
                ),
                _buildListFeature(
                  context,
                  icon: LucideIcons.gift,
                  title: context.tr(
                    'premium.feature_vip_loot',
                    fallback: '100 Free Bonus Coins Daily',
                  ),
                  color: IllustrationColors.vibrantPink,
                ),
                _buildListFeature(
                  context,
                  icon: LucideIcons.calendarClock,
                  title: context.tr(
                    'premium.feature_unlimited_daily_words',
                    fallback: 'Unlimited Daily Words',
                  ),
                  color: AppColors.violet500,
                ),
                _buildListFeature(
                  context,
                  icon: LucideIcons.award,
                  title: context.tr(
                    'premium.feature_vip_badges',
                    fallback: 'VIP BADGES',
                  ),
                  color: _LocalPalette.coloreab308,
                  isLast: true,
                ),
              ],
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  Widget _buildPillarItem(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32.r,
          height: 32.r,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, color: iconColor, size: 16.r),
          ),
        ),
        SizedBox(height: 6.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.slate900,
              height: 1.1,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 9.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : AppColors.slate500,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPillarDivider(bool isDark) {
    return Container(
      width: 1,
      height: 32.h,
      color: isDark ? Colors.white10 : AppColors.slate200,
      margin: EdgeInsets.symmetric(horizontal: 2.w),
    );
  }

  Widget _buildListFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    bool isLast = false,
  }) {
    String formattedTitle = title.trim();
    if (formattedTitle.endsWith('.') ||
        formattedTitle.endsWith('।') ||
        formattedTitle.endsWith('。')) {
      formattedTitle = formattedTitle.substring(0, formattedTitle.length - 1);
    }
    if (formattedTitle.isNotEmpty &&
        formattedTitle == formattedTitle.toUpperCase()) {
      formattedTitle = formattedTitle
          .split(' ')
          .map((word) {
            if (word.isEmpty) return word;
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          })
          .join(' ');
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              formattedTitle,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
