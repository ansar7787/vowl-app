import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

/// Horizontal scrolling tools strip that consolidates TranslationHomeCard
/// and AiLabGrid into a single "Explore & Tools" section.
class ToolsStrip extends StatelessWidget {
  const ToolsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tools = [
      (
        title: context.tr('home.tools_kids_zone', fallback: 'Kids Zone'),
        subtitle: context.tr('home.tools_play', fallback: 'Play'),
        icon: Icons.child_care_rounded,
        color: const Color(0xFFF43F5E), // Rose color for kids
        route: AppRouter.kidsZoneRoute,
        requiresAd: false,
      ),
      (
        title: context.tr('home.tools_daily_words', fallback: 'Daily Words'),
        subtitle: context.tr('home.tools_daily', fallback: 'Daily'),
        icon: Icons.menu_book_rounded,
        color: const Color(0xFFF59E0B),
        route: AppRouter.dailyWordsRoute,
        requiresAd: false,
      ),
      (
        title: context.tr('home.translation_title', fallback: 'Translate'),
        subtitle: context.tr('home.tools_offline', fallback: 'Offline'),
        icon: Icons.translate_rounded,
        color: const Color(0xFF10B981),
        route: AppRouter.translateRoute,
        requiresAd: false,
      ),
      (
        title: context.tr('home.tools_vowl_mascot', fallback: 'Vowl Buddy'),
        subtitle: context.tr('home.tools_pet', fallback: 'Pet'),
        icon: Icons.pets_rounded,
        color: const Color(0xFF8B5CF6), // Purple color for mascot
        route: AppRouter.vowlMascotRoute,
        requiresAd: false,
      ),
      (
        title: context.tr('home.tools_photo_vocab', fallback: 'Photo Vocab'),
        subtitle: context.tr('home.tools_camera', fallback: 'Camera'),
        icon: Icons.camera_alt_rounded,
        color: const Color(0xFF3B82F6),
        route: AppRouter.photoVocabularyRoute,
        requiresAd: false,
      ),
      (
        title: context.tr('home.tools_scan_learn', fallback: 'Scan & Learn'),
        subtitle: context.tr('home.tools_scan', fallback: 'Scanner'),
        icon: Icons.document_scanner_rounded,
        color: const Color(0xFFEAB308), // Yellow color for scanner
        route: AppRouter.scanAndLearnRoute,
        requiresAd: false,
      ),
      (
        title: context.tr('home.tools_word_snap', fallback: 'Word Snap'),
        subtitle: context.tr('home.tools_memory', fallback: 'Memory'),
        icon: Icons.extension_rounded,
        color: const Color(0xFFF59E0B), // Orange color for snap
        route: AppRouter.wordSnapRoute,
        requiresAd: false,
      ),
      (
        title: context.tr('home.tools_word_mixer', fallback: 'Word Mixer'),
        subtitle: context.tr('home.tools_combos', fallback: 'Combos'),
        icon: Icons.sort_by_alpha_rounded,
        color: const Color(0xFFA855F7), // Purple color for mixer
        route: AppRouter.wordMixerRoute,
        requiresAd: false,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tools.asMap().entries.map((entry) {
          final index = entry.key;
          final tool = entry.value;
          final card = _ToolCard(
            title: tool.title,
            subtitle: tool.subtitle,
            icon: tool.icon,
            color: tool.color,
            route: tool.route,
            requiresAd: tool.requiresAd,
            isDark: isDark,
            index: index,
          );
          if (index == tools.length - 1) return card;
          return Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: card,
          );
        }).toList(),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final bool requiresAd;
  final bool isDark;
  final int index;

  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    required this.requiresAd,
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title — $subtitle',
      child: ScaleButton(
        onTap: () {
          di.sl<HapticService>().light();
          if (!requiresAd) {
            context.push(route);
            return;
          }
          final isPremium =
              context.read<AuthBloc>().state.user?.isPremium ?? false;
          if (isPremium) {
            context.push(route);
            return;
          }
          di.sl<AdService>().showRewardedAd(
            context: context,
            isPremium: isPremium,
            childSafe: false,
            onUserEarnedReward: (_) => context.push(route),
            onDismissed: () {},
          );
        },
        child: ExcludeSemantics(
          child: GlassTile(
            showShadow: false,
            borderRadius: BorderRadius.circular(24.r),
            borderColor: color.withValues(alpha: 0.2),
            padding: EdgeInsets.all(16.r),
            child: SizedBox(
              width: 110.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20.r),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      subtitle.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
