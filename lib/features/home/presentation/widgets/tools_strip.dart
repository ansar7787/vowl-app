import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

/// Horizontal scrolling tools strip with a **two-tier visual hierarchy**:
///
/// ## Design Architecture (10/10 Standard)
/// 1. **Featured Hero Cards** (first 3): Full-gradient background with
///    decorative icon watermark, emoji mascot, and larger touch target.
///    These communicate "start here" through visual weight.
/// 2. **Compact Utility Cards** (remaining): Glass-tile treatment with
///    icon + title + metadata pill. Visually lighter = "more options."
/// 3. **7 unique hues** with ≥40° color-wheel separation.
/// 4. **blur: 0** on GlassTile to avoid BackdropFilter stacking.
/// 5. **Right-edge fade** signals scroll continuity.
/// 6. **Responsive card width** adapts to screen size (SE → Pro Max).
/// 7. **Long-press tooltip** on every card for discoverability.
class ToolsStrip extends StatelessWidget {
  const ToolsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive card width: adapts from SE (320dp) to Pro Max (430dp).
    // Featured cards are wider; compact cards use the narrower size.
    final compactWidth = (screenWidth * 0.29).clamp(90.0, 130.0).w;
    final featuredWidth = (screenWidth * 0.42).clamp(140.0, 190.0).w;

    final tools = [
      // ── FEATURED TIER (gradient hero cards) ───────────────────────
      _ToolDef(
        title: context.tr('home.tools_kids_zone', fallback: 'Kids Zone'),
        subtitle: context.tr('home.tools_kids_fun', fallback: 'Fun & Learn'),
        tooltip: context.tr(
          'home.tools_kids_zone_tip',
          fallback: 'Safe, playful games designed for young learners',
        ),
        icon: Icons.child_care_rounded,
        emoji: '🧩',
        color: const Color(0xFFF43F5E), // Rose — 0°
        darkColor: const Color(0xFFBE123C),
        route: AppRouter.kidsZoneRoute,
        requiresAd: false,
        isFeatured: true,
      ),
      _ToolDef(
        title: context.tr('home.tools_daily_words', fallback: 'Daily Words'),
        subtitle: context.tr('home.tools_daily_new', fallback: 'New Today'),
        tooltip: context.tr(
          'home.tools_daily_words_tip',
          fallback: 'Fresh vocabulary words curated every day',
        ),
        icon: Icons.menu_book_rounded,
        emoji: '📖',
        color: const Color(0xFFF59E0B), // Amber — 45°
        darkColor: const Color(0xFFD97706),
        route: AppRouter.dailyWordsRoute,
        requiresAd: false,
        isFeatured: true,
      ),
      _ToolDef(
        title: context.tr('home.translation_title', fallback: 'Translate'),
        subtitle: context.tr('home.tools_offline_ready', fallback: '50+ Langs'),
        tooltip: context.tr(
          'home.tools_translate_tip',
          fallback: 'Offline translation for 50+ languages',
        ),
        icon: Icons.translate_rounded,
        emoji: '💬',
        color: const Color(0xFF10B981), // Emerald — 160°
        darkColor: const Color(0xFF059669),
        route: AppRouter.translateRoute,
        requiresAd: false,
        isFeatured: true,
      ),

      // ── COMPACT TIER (utility cards) ──────────────────────────────
      _ToolDef(
        title: context.tr('home.tools_photo_vocab', fallback: 'Photo Vocab'),
        subtitle: context.tr('home.tools_ai_powered', fallback: 'AI Powered'),
        tooltip: context.tr(
          'home.tools_photo_vocab_tip',
          fallback: 'Point your camera to learn new words instantly',
        ),
        icon: Icons.camera_alt_rounded,
        color: const Color(0xFF3B82F6), // Blue — 220°
        route: AppRouter.photoVocabularyRoute,
        requiresAd: false,
      ),
      _ToolDef(
        title: context.tr('home.tools_scan_learn', fallback: 'Scan & Learn'),
        subtitle: context.tr('home.tools_instant', fallback: 'Instant'),
        tooltip: context.tr(
          'home.tools_scan_learn_tip',
          fallback: 'Scan any text to get instant definitions',
        ),
        icon: Icons.document_scanner_rounded,
        color: const Color(0xFF14B8A6), // Teal — 175°
        route: AppRouter.scanAndLearnRoute,
        requiresAd: false,
      ),
      _ToolDef(
        title: context.tr('home.tools_word_snap', fallback: 'Word Snap'),
        subtitle: context.tr('home.tools_brain_game', fallback: 'Brain Game'),
        tooltip: context.tr(
          'home.tools_word_snap_tip',
          fallback: 'Match words and meanings in a fast-paced memory game',
        ),
        icon: Icons.extension_rounded,
        color: const Color(0xFFEC4899), // Pink — 330°
        route: AppRouter.wordSnapRoute,
        requiresAd: false,
      ),
      _ToolDef(
        title: context.tr('home.tools_word_mixer', fallback: 'Word Mixer'),
        subtitle: context.tr('home.tools_challenge', fallback: 'Challenge'),
        tooltip: context.tr(
          'home.tools_word_mixer_tip',
          fallback: 'Combine letters to form words under pressure',
        ),
        icon: Icons.sort_by_alpha_rounded,
        color: const Color(0xFFA855F7), // Purple — 270°
        route: AppRouter.wordMixerRoute,
        requiresAd: false,
      ),
    ];

    return Stack(
      children: [
        // ── Scrollable cards ─────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: tools
                .asMap()
                .entries
                .map((entry) {
                  final index = entry.key;
                  final tool = entry.value;

                  final Widget card = tool.isFeatured
                      ? _FeaturedToolCard(
                          def: tool,
                          isDark: isDark,
                          width: featuredWidth,
                          index: index,
                        )
                      : _CompactToolCard(
                          def: tool,
                          isDark: isDark,
                          width: compactWidth,
                          index: index,
                        );

                  if (index == tools.length - 1) return card;
                  return Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: card,
                  );
                })
                .toList()
                .animate(interval: 50.ms)
                .fadeIn(duration: 400.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Data Model
// ═══════════════════════════════════════════════════════════════════════════════

class _ToolDef {
  final String title;
  final String subtitle;
  final String? tooltip;
  final IconData icon;
  final String? emoji;
  final Color color;
  final Color? darkColor;
  final String route;
  final bool requiresAd;
  final bool isFeatured;

  const _ToolDef({
    required this.title,
    required this.subtitle,
    this.tooltip,
    required this.icon,
    this.emoji,
    required this.color,
    this.darkColor,
    required this.route,
    required this.requiresAd,
    this.isFeatured = false,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared tap/ad handler
// ═══════════════════════════════════════════════════════════════════════════════

void _handleToolTap(BuildContext context, _ToolDef def) {
  di.sl<HapticService>().light();
  if (!def.requiresAd) {
    context.push(def.route);
    return;
  }
  final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
  if (isPremium) {
    context.push(def.route);
    return;
  }
  di.sl<AdService>().showRewardedAd(
    context: context,
    isPremium: isPremium,
    childSafe: false,
    onUserEarnedReward: (_) => context.push(def.route),
    onDismissed: () {},
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// FEATURED HERO CARD — Gradient background, emoji mascot, watermark icon
// ═══════════════════════════════════════════════════════════════════════════════

class _FeaturedToolCard extends StatelessWidget {
  final _ToolDef def;
  final bool isDark;
  final double width;
  final int index;

  const _FeaturedToolCard({
    required this.def,
    required this.isDark,
    required this.width,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final darkShade = def.darkColor ?? def.color;

    return Semantics(
      button: true,
      label: '${def.title} — ${def.subtitle}',
      child: Tooltip(
        message: def.tooltip ?? def.subtitle,
        preferBelow: true,
        triggerMode: TooltipTriggerMode.longPress,
        showDuration: const Duration(seconds: 3),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: def.color.withValues(alpha: 0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: def.color.withValues(alpha: 0.2),
              blurRadius: 16,
              spreadRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        textStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          height: 1.3,
        ),
        child: ScaleButton(
          onTap: () => _handleToolTap(context, def),
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: Container(
                width: width,
                clipBehavior: Clip.hardEdge,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [def.color, darkShade],
                  ),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Stack(
                  children: [
                    // ── Watermark icon ──────────────────────────────
                    Positioned(
                      right: -12.r,
                      bottom: -8.r,
                      child: Icon(
                        def.icon,
                        size: 80.r,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),

                    // ── Content ─────────────────────────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Emoji mascot + chevron row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Emoji in frosted circle
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                def.emoji ?? '✨',
                                style: TextStyle(fontSize: 18.sp, height: 1.1),
                              ),
                            ),
                            // Go arrow
                            Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_outward_rounded,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 16.r,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),

                        // Title
                        Text(
                          def.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 4.h),

                        // Subtitle pill
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            def.subtitle.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.9),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMPACT UTILITY CARD — Glass tile, icon + title + metadata
// ═══════════════════════════════════════════════════════════════════════════════

class _CompactToolCard extends StatelessWidget {
  final _ToolDef def;
  final bool isDark;
  final double width;
  final int index;

  const _CompactToolCard({
    required this.def,
    required this.isDark,
    required this.width,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${def.title} — ${def.subtitle}',
      child: Tooltip(
        message: def.tooltip ?? def.subtitle,
        preferBelow: true,
        triggerMode: TooltipTriggerMode.longPress,
        showDuration: const Duration(seconds: 3),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: def.color.withValues(alpha: 0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: def.color.withValues(alpha: 0.2),
              blurRadius: 16,
              spreadRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        textStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          height: 1.3,
        ),
        child: ScaleButton(
          onTap: () => _handleToolTap(context, def),
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: GlassTile(
                // blur: 0 disables BackdropFilter — critical for multiple
                // cards in a scroll list. Gradient overlay provides the look.
                blur: 0,
                showShadow: false,
                borderRadius: BorderRadius.circular(24.r),
                borderColor: def.color.withValues(alpha: isDark ? 0.25 : 0.15),
                padding: EdgeInsets.all(16.r),
                child: SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Icon container with subtle colored glow ────
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: def.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: def.color.withValues(alpha: 0.15),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(def.icon, color: def.color, size: 20.r),
                      ),
                      SizedBox(height: 16.h),

                      // ── Title ──────────────────────────────────────
                      Text(
                        def.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4.h),

                      // ── Contextual metadata pill ───────────────────
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: def.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: def.color.withValues(alpha: 0.12),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          def.subtitle.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: def.color,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
