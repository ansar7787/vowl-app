import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/daily_words/data/services/daily_words_service.dart';
import 'package:vowl/features/home/presentation/widgets/discovery_deck.dart';

/// Production-hardened Tools & Utilities Hub (The 7 Apex Tools & Word Games).
///
/// Implements a unified Swiss Horizon + Precision Bento Architecture with Arcade Vault expansion:
/// 1. **Kids Zone (Flagship Swiss Card)**: High-prominence, child-safe phonics & games portal.
/// 2. **Daily Words (Flagship Swiss Card)**: Daily 5-word curated vocabulary accelerator.
/// 3. **Translate (Flagship Swiss Card)**: Offline 50+ languages translation suite.
/// 4. **Photo Vocab & Scan & Learn (2-Column Bento Subgrid)**:
///    - **Photo Vocab** (AI Vision Camera)
///    - **Scan & Learn** (OCR Document Reader)
/// 5. **Word Games Arcade Vault (Inline Bento Expansion)**:
///    - Tucked in default state with a gaming-themed Arcade Vault bar.
///    - Smoothly unfolds into full-size 2-column Bento cards:
///      - **Word Snap** (Speed Match Memory Challenge)
///      - **Word Mixer** (Sprint Anagram Challenge)
class ToolsStrip extends StatefulWidget {
  /// Whether the strip starts in collapsed state (default: true).
  final bool collapsed;

  /// Optional external notifier controlling expanded state.
  final ValueNotifier<bool>? isExpandedNotifier;

  /// Creates a [ToolsStrip] widget.
  const ToolsStrip({super.key, this.collapsed = true, this.isExpandedNotifier});

  /// Global expansion notifier shared across the home screen.
  static final ValueNotifier<bool> globalExpansionNotifier =
      ValueNotifier<bool>(false);

  /// Toggles the tools strip expansion with selection haptics.
  static void toggleExpanded([BuildContext? context]) {
    try {
      di.sl<HapticService>().selection();
    } catch (_) {}
    globalExpansionNotifier.value = !globalExpansionNotifier.value;
  }

  /// Expands the tools directory inline.
  static void showToolsDirectory(BuildContext context) {
    try {
      di.sl<HapticService>().selection();
    } catch (_) {}
    globalExpansionNotifier.value = true;
  }

  @override
  State<ToolsStrip> createState() => _ToolsStripState();
}

class _ToolsStripState extends State<ToolsStrip> {
  late final ValueNotifier<bool> _isExpanded;

  @override
  void initState() {
    super.initState();
    DiscoveryDeck.dailyCompletionNotifier.addListener(
      _onDailyCompletionChanged,
    );
    if (widget.isExpandedNotifier != null) {
      _isExpanded = widget.isExpandedNotifier!;
    } else {
      _isExpanded = ToolsStrip.globalExpansionNotifier;
      _isExpanded.value = !widget.collapsed;
    }
  }

  void _onDailyCompletionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    DiscoveryDeck.dailyCompletionNotifier.removeListener(
      _onDailyCompletionChanged,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isDailyWordsDone =
        di.sl.isRegistered<DailyWordsService>() &&
        di.sl<DailyWordsService>().isTodayCompleted;

    return Semantics(
      container: true,
      label: context.tr(
        'home.tools_shelf_label',
        fallback: 'Explore & Tools: Daily learning utilities and games',
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: ValueListenableBuilder<bool>(
          valueListenable: _isExpanded,
          builder: (context, isExpanded, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 1. SWISS HORIZON CARD 1: KIDS LEARNING ZONE ──────────────────
                _SwissHorizonCard(
                  tag: context.tr('home.tools_kids_tag', fallback: 'KIDS'),
                  title: context.tr(
                    'home.tools_kids_zone',
                    fallback: 'Kids Zone',
                  ),
                  subtitle: context.tr(
                    'home.tools_kids_fun',
                    fallback: 'Fun learning games',
                  ),
                  icon: Icons.child_care_rounded,
                  color: AppColors.rose500,
                  onTap: () =>
                      _handleNavigation(context, AppRouter.kidsZoneRoute),
                  isDark: isDark,
                ),
                SizedBox(height: 10.h),

                // ── 2. SWISS HORIZON CARD 2: DAILY VOCABULARY ───────────────────
                _SwissHorizonCard(
                  tag: isDailyWordsDone
                      ? context.tr(
                          'home.tools_daily_completed',
                          fallback: 'COMPLETED ✓',
                        )
                      : context.tr('home.tools_daily_tag', fallback: 'TODAY'),
                  title: context.tr(
                    'home.tools_daily_words',
                    fallback: 'Daily Words',
                  ),
                  subtitle: isDailyWordsDone
                      ? context.tr(
                          'home.tools_daily_all_learned',
                          fallback: 'All 5 words mastered today!',
                        )
                      : context.tr(
                          'home.tools_daily_desc',
                          fallback: '5 new words today',
                        ),
                  icon: Icons.menu_book_rounded,
                  color: AppColors.amber500,
                  onTap: () =>
                      _handleNavigation(context, AppRouter.dailyWordsRoute),
                  isDark: isDark,
                  isCompleted: isDailyWordsDone,
                ),
                SizedBox(height: 10.h),

                // ── 3. SWISS HORIZON CARD 3: OFFLINE TRANSLATION ────────────────
                _SwissHorizonCard(
                  tag: context.tr(
                    'home.tools_translate_tag',
                    fallback: 'OFFLINE',
                  ),
                  title: context.tr(
                    'home.translation_title',
                    fallback: 'Translate',
                  ),
                  subtitle: context.tr(
                    'home.tools_translate_tip',
                    fallback: 'Offline translation for 50+ languages',
                  ),
                  icon: Icons.translate_rounded,
                  color: AppColors.emerald500,
                  onTap: () =>
                      _handleNavigation(context, AppRouter.translateRoute),
                  isDark: isDark,
                ),
                SizedBox(height: 10.h),

                // ── 4. 2-COLUMN BENTO ROW 1: PHOTO VOCAB & SCAN & LEARN ─────────
                Row(
                  children: [
                    Expanded(
                      child: _BentoSubCell(
                        tag: context.tr(
                          'home.tools_photo_tag',
                          fallback: 'AI VISION',
                        ),
                        title: context.tr(
                          'home.tools_photo_vocab',
                          fallback: 'Photo Vocab',
                        ),
                        subtitle: context.tr(
                          'home.tools_photo_sub',
                          fallback: 'AI Camera',
                        ),
                        icon: Icons.camera_alt_rounded,
                        color: AppColors.blue500,
                        onTap: () => _handleNavigation(
                          context,
                          AppRouter.photoVocabularyRoute,
                        ),
                        isDark: isDark,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _BentoSubCell(
                        tag: context.tr(
                          'home.tools_scan_tag',
                          fallback: 'OCR SCAN',
                        ),
                        title: context.tr(
                          'home.tools_scan_learn',
                          fallback: 'Scan & Learn',
                        ),
                        subtitle: context.tr(
                          'home.tools_scan_sub',
                          fallback: 'Text Reader',
                        ),
                        icon: Icons.document_scanner_rounded,
                        color: AppColors.teal500,
                        onTap: () => _handleNavigation(
                          context,
                          AppRouter.scanAndLearnRoute,
                        ),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                // ── 5. EXPANDED 2-COLUMN BENTO ROW 2: WORD SNAP & WORD MIXER ─────
                AnimatedSize(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: isExpanded
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: 10.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _BentoSubCell(
                                    tag: context.tr(
                                      'home.tools_snap_badge',
                                      fallback: 'MEMORY MATCH',
                                    ),
                                    title: context.tr(
                                      'home.tools_word_snap',
                                      fallback: 'Word Snap',
                                    ),
                                    subtitle: context.tr(
                                      'home.tools_word_snap_tip',
                                      fallback: 'Speed match challenge',
                                    ),
                                    icon: Icons.extension_rounded,
                                    color: IllustrationColors.vibrantPink,
                                    onTap: () => _handleNavigation(
                                      context,
                                      AppRouter.wordSnapRoute,
                                    ),
                                    isDark: isDark,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: _BentoSubCell(
                                    tag: context.tr(
                                      'home.tools_mixer_badge',
                                      fallback: 'ANAGRAM SPRINT',
                                    ),
                                    title: context.tr(
                                      'home.tools_word_mixer',
                                      fallback: 'Word Mixer',
                                    ),
                                    subtitle: context.tr(
                                      'home.tools_word_mixer_tip',
                                      fallback: 'Anagram sprint challenge',
                                    ),
                                    icon: Icons.sort_by_alpha_rounded,
                                    color: IllustrationColors.richPurple,
                                    onTap: () => _handleNavigation(
                                      context,
                                      AppRouter.wordMixerRoute,
                                    ),
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                SizedBox(height: 10.h),

                // ── 6. THE ARCADE VAULT STRIP (Dedicated Gaming Drawer) ──────────
                _ArcadeVaultStrip(
                  isExpanded: isExpanded,
                  isDark: isDark,
                  onToggle: () {
                    try {
                      di.sl<HapticService>().selection();
                    } catch (_) {}
                    _isExpanded.value = !_isExpanded.value;
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Navigation & Reward Interstitial Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  void _handleNavigation(
    BuildContext context,
    String route, {
    bool requiresAd = false,
  }) {
    try {
      di.sl<HapticService>().selection();
    } catch (_) {}

    if (!requiresAd) {
      context.push(route);
      return;
    }

    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
    if (isPremium) {
      context.push(route);
      return;
    }

    try {
      di.sl<AdService>().showRewardedAd(
        context: context,
        isPremium: isPremium,
        childSafe: false,
        onUserEarnedReward: (_) => context.push(route),
        onDismissed: () {},
      );
    } catch (_) {
      context.push(route);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. SWISS HORIZON CARD (Kids Zone, Daily Words & Translate)
// ═══════════════════════════════════════════════════════════════════════════════

class _SwissHorizonCard extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;
  final bool isCompleted;

  const _SwissHorizonCard({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isMidnight
                ? AppColors.midnightSurface
                : (isDark ? const Color(0xFF131A29) : Colors.white),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: isCompleted
                  ? AppColors.emerald500.withValues(alpha: isDark ? 0.22 : 0.16)
                  : (isMidnight
                        ? Colors.white.withValues(alpha: 0.12)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.slate100)),
              width: 1.r,
            ),
          ),
          child: Row(
            children: [
              // Tactical Halo Icon Box with overlaid completion badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42.r,
                    height: 42.r,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? color.withValues(alpha: isDark ? 0.18 : 0.12)
                          : color.withValues(alpha: isDark ? 0.14 : 0.09),
                      borderRadius: BorderRadius.circular(13.r),
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.emerald500.withValues(
                                alpha: isDark ? 0.45 : 0.30,
                              )
                            : color.withValues(alpha: isDark ? 0.28 : 0.18),
                        width: 1.r,
                      ),
                    ),
                    child: Center(
                      child: Icon(icon, color: color, size: 21.r),
                    ),
                  ),
                  if (isCompleted)
                    Positioned(
                      top: -3.r,
                      right: -3.r,
                      child: Container(
                        width: 14.r,
                        height: 14.r,
                        decoration: BoxDecoration(
                          color: AppColors.emerald500,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF131A29)
                                : Colors.white,
                            width: 1.5.r,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.emerald500.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 9.r,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 12.w),

              // Text Hierarchy (Tag on top so title has 100% width, never wraps)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.emerald500.withValues(
                                alpha: isDark ? 0.20 : 0.12,
                              )
                            : color.withValues(alpha: isDark ? 0.16 : 0.10),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: isCompleted
                              ? (isDark
                                    ? const Color(0xFF6EE7B7)
                                    : AppColors.emerald500)
                              : color,
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // Action Arrow Circle
              Container(
                width: 26.r,
                height: 26.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: isDark ? 0.12 : 0.08),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11.r,
                    color: color,
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

// ═══════════════════════════════════════════════════════════════════════════════
// 2. 2×2 BENTO SUB-CELL (Photo Vocab, Scan & Learn, Word Snap, Word Mixer)
// ═══════════════════════════════════════════════════════════════════════════════

class _BentoSubCell extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _BentoSubCell({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: 96.h),
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: isMidnight
                ? AppColors.midnightSurface
                : (isDark ? const Color(0xFF131A29) : Colors.white),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isMidnight
                  ? Colors.white.withValues(alpha: 0.12)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.slate100),
              width: 1.r,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Cell Header (Halo Icon + Mini Tag Pill)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.14 : 0.09),
                      borderRadius: BorderRadius.circular(9.r),
                      border: Border.all(
                        color: color.withValues(alpha: isDark ? 0.25 : 0.16),
                        width: 1.r,
                      ),
                    ),
                    child: Center(
                      child: Icon(icon, color: color, size: 17.r),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.14 : 0.08),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w800,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // Title and 1-Line Helper
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. THE ARCADE VAULT STRIP (Dedicated Gaming Drawer for Word Snap & Mixer)
// ═══════════════════════════════════════════════════════════════════════════════

class _ArcadeVaultStrip extends StatelessWidget {
  final bool isExpanded;
  final bool isDark;
  final VoidCallback onToggle;

  const _ArcadeVaultStrip({
    required this.isExpanded,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    return Semantics(
      button: true,
      label: isExpanded
          ? 'Collapse Word Games Arcade'
          : 'Expand Arcade Vault: 2 speed word games',
      child: ScaleButton(
        onTap: onToggle,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isMidnight
                ? AppColors.midnightSurface
                : (isDark ? const Color(0xFF131A29) : Colors.white),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isMidnight
                  ? IllustrationColors.vibrantPink.withValues(
                      alpha: isExpanded ? 0.35 : 0.20,
                    )
                  : (isDark
                        ? IllustrationColors.vibrantPink.withValues(
                            alpha: isExpanded ? 0.30 : 0.16,
                          )
                        : IllustrationColors.vibrantPink.withValues(
                            alpha: 0.18,
                          )),
              width: 1.r,
            ),
            boxShadow: isExpanded
                ? [
                    BoxShadow(
                      color: IllustrationColors.vibrantPink.withValues(
                        alpha: isDark ? 0.12 : 0.06,
                      ),
                      blurRadius: 16.r,
                      offset: Offset(0, 4.h),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Vibrant Gaming Icon Halo
              Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      IllustrationColors.vibrantPink.withValues(alpha: 0.20),
                      IllustrationColors.richPurple.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: IllustrationColors.vibrantPink.withValues(
                      alpha: isDark ? 0.35 : 0.22,
                    ),
                    width: 1.r,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.sports_esports_rounded,
                    size: 17.r,
                    color: IllustrationColors.vibrantPink,
                  ),
                ),
              ),
              SizedBox(width: 10.w),

              // Title and helper
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            context.tr(
                              'home.tools_arcade_vault',
                              fallback: 'ARCADE VAULT',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: isDark ? Colors.white : AppColors.slate900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 1.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: IllustrationColors.richPurple.withValues(
                              alpha: isDark ? 0.20 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            isExpanded ? 'ACTIVE' : '2 GAMES',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: IllustrationColors.richPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isExpanded
                          ? context.tr(
                              'home.tools_arcade_expanded',
                              fallback: 'Word Snap & Word Mixer ready to play',
                            )
                          : context.tr(
                              'home.tools_arcade_teaser',
                              fallback: 'Speed vocabulary & anagram challenges',
                            ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.slate400 : AppColors.slate500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // Toggle Pill
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: isExpanded
                      ? IllustrationColors.vibrantPink.withValues(
                          alpha: isDark ? 0.16 : 0.10,
                        )
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : AppColors.slate100),
                  borderRadius: BorderRadius.circular(100.r),
                  border: Border.all(
                    color: isExpanded
                        ? IllustrationColors.vibrantPink.withValues(
                            alpha: isDark ? 0.35 : 0.22,
                          )
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : AppColors.slate200),
                    width: 1.r,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isExpanded
                          ? context.tr('home.tools_fold', fallback: 'Fold')
                          : context.tr(
                              'home.tools_unfold',
                              fallback: 'Unfold +2',
                            ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: isExpanded
                            ? IllustrationColors.vibrantPink
                            : (isDark ? Colors.white70 : AppColors.slate700),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 15.r,
                        color: isExpanded
                            ? IllustrationColors.vibrantPink
                            : (isDark ? Colors.white70 : AppColors.slate700),
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
