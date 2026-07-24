import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ModernFeatureBar extends StatelessWidget {
  const ModernFeatureBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // An ultra-premium 2026 staggered list of glassmorphic feature cards
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFeatureCard(
          context,
          icon: LucideIcons.camera,
          title: context.tr(
            'premium.feature_photo_vocab',
            fallback: 'Photo Vocabulary',
          ),
          subtitle: context.tr(
            'premium.feature_photo_vocab_desc',
            fallback: 'Snap any object and learn its English name instantly using AI.',
          ),
          isDark: isDark,
          customColor: const Color(0xFF14B8A6), // Teal
        ),
        SizedBox(height: 12.h),
        _buildFeatureCard(
          context,
          icon: LucideIcons.scan,
          title: context.tr(
            'premium.feature_scan_learn',
            fallback: 'Scan & Learn',
          ),
          subtitle: context.tr(
            'premium.feature_scan_learn_desc',
            fallback: 'Extract text from books or documents and get instant, real-time AI translations.',
          ),
          isDark: isDark,
          customColor: const Color(0xFF6366F1), // Indigo
        ),
        SizedBox(height: 12.h),
        _buildFeatureCard(
          context,
          icon: LucideIcons.sparkles,
          title: context.tr(
            'premium.feature_translations',
            fallback: 'Instant AI Translations',
          ),
          subtitle: context.tr(
            'premium.feature_translations_desc',
            fallback: 'Ad-free, real-time native hints powered by AI.',
          ),
          isDark: isDark,
        ),
        SizedBox(height: 12.h),
        _buildFeatureCard(
          context,
          icon: LucideIcons.shieldCheck,
          title: context.tr(
            'premium.feature_zero_ads',
            fallback: 'Zero Interruptions',
          ),
          subtitle: context.tr(
            'premium.feature_zero_ads_desc',
            fallback: 'A completely pure, ad-free learning experience.',
          ),
          isDark: isDark,
        ),
        SizedBox(height: 12.h),
        _buildFeatureCard(
          context,
          icon: LucideIcons.brain,
          title: context.tr(
            'premium.feature_ai_tools',
            fallback: 'AI Learning Suite',
          ),
          subtitle: context.tr(
            'premium.feature_ai_tools_desc',
            fallback: 'Unlimited Smart Reply, Photo Vocabulary, Scan & Learn, Entity Highlighter — all ad-free.',
          ),
          isDark: isDark,
        ),
        SizedBox(height: 12.h),
        _buildFeatureCard(
          context,
          icon: LucideIcons.zap,
          title: context.tr(
            'premium.feature_2x_speed',
            fallback: '2x Learning Velocity',
          ),
          subtitle: context.tr(
            'premium.feature_2x_speed_desc',
            fallback:
                'Master concepts twice as fast with advanced XP tracking.',
          ),
          isDark: isDark,
        ),
        SizedBox(height: 12.h),
        _buildFeatureCard(
          context,
          icon: LucideIcons.wifiOff,
          title: context.tr(
            'premium.feature_play_offline',
            fallback: 'Anywhere Offline Mode',
          ),
          subtitle: context.tr(
            'premium.feature_play_offline_desc',
            fallback: 'Download curriculum and learn off the grid.',
          ),
          isDark: isDark,
        ),
        SizedBox(height: 12.h),
        _buildFeatureCard(
          context,
          icon: LucideIcons.gift,
          title: context.tr(
            'premium.feature_vip_loot',
            fallback: 'Daily Elite Loot',
          ),
          subtitle: context.tr(
            'premium.feature_vip_loot_desc',
            fallback: 'Claim 100 free bonus coins every single day.',
          ),
          isDark: isDark,
        ),
        SizedBox(height: 12.h),
        _buildFeatureCard(
          context,
          icon: LucideIcons.unlock,
          title: context.tr(
            'premium.feature_unlimited_levels',
            fallback: 'Unlimited Vault Access',
          ),
          subtitle: context.tr(
            'premium.feature_unlimited_levels_desc',
            fallback: 'Instantly unlock all elite and master difficulty tiers.',
          ),
          isDark: isDark,
        ),
        SizedBox(height: 12.h),
        _buildFeatureCard(
          context,
          icon: LucideIcons.award,
          title: context.tr(
            'premium.feature_vip_badges',
            fallback: 'Golden VIP Badges',
          ),
          subtitle: context.tr(
            'premium.feature_vip_badges_desc',
            fallback:
                'Flaunt your exclusive elite status on the global leaderboards.',
          ),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    Color? customColor,
  }) {
    final primaryColor = customColor ?? const Color(0xFF6366F1); // Default to Indigo

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: isDark
                ? primaryColor.withValues(alpha: 0.1)
                : primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(icon, color: primaryColor, size: 24.r),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 13.sp,
                        height: 1.4,
                      ),
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
