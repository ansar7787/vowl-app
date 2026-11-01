import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/feature_catalog/feature_directory_bottom_sheet.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

/// Production-hardened Tools & Utilities Hub (Piece 8).
///
/// Implements **Concept 1: Swiss Duo + 2×2 Precision Bento Grid (Zero Scroll Master)**:
/// 1. **Kids Zone (Flagship Swiss Card)**: High-prominence, child-safe phonics & games portal.
/// 2. **Daily Words (Flagship Swiss Card)**: Daily 5-word curated vocabulary accelerator.
/// 3. **2×2 Precision Bento Grid**:
///    - **Photo Vocab** (AI Vision Camera)
///    - **Scan & Learn** (OCR Document Reader)
///    - **Translate** (50+ Languages Offline)
///    - **Word Games** (Word Snap & Word Mixer Modal Launcher)
/// 4. **Compact 32px Directory Pill**: Direct access to all 7 tools and the full catalog.
///
/// Zero horizontal scroll drop-off, single-line typography, zero ellipses, and 320dp small-screen safe.
class ToolsStrip extends StatelessWidget {
  /// Creates a [ToolsStrip] widget.
  const ToolsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      container: true,
      label: context.tr(
        'home.tools_shelf_label',
        fallback: 'Explore & Tools: Daily learning utilities and games',
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 1. SWISS HORIZON CARD 1: KIDS LEARNING ZONE ──────────────────
            _SwissHorizonCard(
              tag: context.tr('home.tools_kids_tag', fallback: 'KIDS'),
              title: context.tr('home.tools_kids_zone', fallback: 'Kids Zone'),
              subtitle: context.tr(
                'home.tools_kids_fun',
                fallback: 'Fun learning games',
              ),
              icon: Icons.child_care_rounded,
              color: AppColors.rose500,
              onTap: () => _handleNavigation(context, AppRouter.kidsZoneRoute),
              isDark: isDark,
            ),
            SizedBox(height: 10.h),

            // ── 2. SWISS HORIZON CARD 2: DAILY VOCABULARY ───────────────────
            _SwissHorizonCard(
              tag: context.tr('home.tools_daily_tag', fallback: 'TODAY'),
              title: context.tr(
                'home.tools_daily_words',
                fallback: 'Daily Words',
              ),
              subtitle: context.tr(
                'home.tools_daily_desc',
                fallback: '5 new words today',
              ),
              icon: Icons.menu_book_rounded,
              color: AppColors.amber500,
              onTap: () => _handleNavigation(context, AppRouter.dailyWordsRoute),
              isDark: isDark,
            ),
            SizedBox(height: 10.h),

            // ── 3. 2×2 PRECISION BENTO SUBGRID (ZERO HORIZONTAL SCROLL) ─────
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
                    onTap: () =>
                        _handleNavigation(context, AppRouter.scanAndLearnRoute),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: _BentoSubCell(
                    tag: context.tr(
                      'home.tools_translate_tag',
                      fallback: 'OFFLINE',
                    ),
                    title: context.tr(
                      'home.translation_title',
                      fallback: 'Translate',
                    ),
                    subtitle: context.tr(
                      'home.tools_translate_sub',
                      fallback: '50+ Languages',
                    ),
                    icon: Icons.translate_rounded,
                    color: AppColors.emerald500,
                    onTap: () =>
                        _handleNavigation(context, AppRouter.translateRoute),
                    isDark: isDark,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _BentoSubCell(
                    tag: context.tr('home.tools_games_tag', fallback: 'GAMES'),
                    title: context.tr(
                      'home.tools_word_games',
                      fallback: 'Word Games',
                    ),
                    subtitle: context.tr(
                      'home.tools_games_sub',
                      fallback: 'Snap & Mixer',
                    ),
                    icon: Icons.extension_rounded,
                    color: IllustrationColors.vibrantPink,
                    onTap: () => _showWordGamesModal(context),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // ── 4. COMPACT 32px DIRECTORY TRIGGER (DISCOVER ALL 7 TOOLS) ────
            _DirectoryPillTrigger(
              isDark: isDark,
              onTap: () => _showToolsDirectoryModal(context),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Navigation & Modal Handlers
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

  void _showWordGamesModal(BuildContext context) {
    try {
      di.sl<HapticService>().selection();
    } catch (_) {}
    _WordGamesBottomSheet.show(context);
  }

  void _showToolsDirectoryModal(BuildContext context) {
    try {
      di.sl<HapticService>().selection();
    } catch (_) {}
    _ToolsDirectoryBottomSheet.show(context);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. SWISS HORIZON CARD (Kids Zone & Daily Words)
// ═══════════════════════════════════════════════════════════════════════════════

class _SwissHorizonCard extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _SwissHorizonCard({
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
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131A29) : Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.30 : 0.22),
              width: 1.2.r,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 10.r,
                offset: Offset(0, 3.r),
              ),
            ],
          ),
          child: Row(
            children: [
              // Tactical Halo Icon Box
              Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.14 : 0.09),
                  borderRadius: BorderRadius.circular(13.r),
                  border: Border.all(
                    color: color.withValues(alpha: isDark ? 0.28 : 0.18),
                    width: 1.r,
                  ),
                ),
                child: Center(child: Icon(icon, color: color, size: 21.r)),
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
                        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: color,
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
// 2. 2×2 BENTO SUB-CELL (Symmetrical, Single Line Text, Zero Ellipses)
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
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: 96.h),
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131A29) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.28 : 0.20),
              width: 1.2.r,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.08 : 0.03),
                blurRadius: 8.r,
                offset: Offset(0, 2.r),
              ),
            ],
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
                    child: Center(child: Icon(icon, color: color, size: 17.r)),
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
// 3. COMPACT 32px DIRECTORY TRIGGER PILL (Sleek, Minimal, Space-Saving)
// ═══════════════════════════════════════════════════════════════════════════════

class _DirectoryPillTrigger extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _DirectoryPillTrigger({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(
        'home.tools_directory_label',
        fallback: 'Directory: Browse all 7 learning tools',
      ),
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(100.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.07),
              width: 1.r,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.grid, size: 13.r, color: AppColors.emerald500),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  context.tr(
                    'home.tools_directory_pill',
                    fallback: 'Directory (7 Tools)',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF475569),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 10.r,
                color: AppColors.emerald500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. WORD GAMES MODAL SHEET (Word Snap & Word Mixer direct selection)
// ═══════════════════════════════════════════════════════════════════════════════

class _WordGamesBottomSheet extends StatelessWidget {
  const _WordGamesBottomSheet();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _WordGamesBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A29) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.r,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20.w,
        14.h,
        20.w,
        MediaQuery.of(context).padding.bottom + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        'home.tools_games_sheet_title',
                        fallback: 'Brain Word Games',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      context.tr(
                        'home.tools_games_sheet_sub',
                        fallback: 'Vocabulary & anagram challenges',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
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
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close_rounded,
                  size: 20.r,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Game 1: Word Snap
          _ModalFeatureRow(
            title: context.tr('home.tools_word_snap', fallback: 'Word Snap'),
            subtitle: context.tr(
              'home.tools_word_snap_tip',
              fallback: 'Match words and definitions against the clock',
            ),
            badge: context.tr('home.tools_snap_badge', fallback: 'MEMORY MATCH'),
            icon: Icons.extension_rounded,
            color: IllustrationColors.vibrantPink,
            isDark: isDark,
            onTap: () {
              Navigator.of(context).pop();
              context.push(AppRouter.wordSnapRoute);
            },
          ),
          SizedBox(height: 10.h),

          // Game 2: Word Mixer
          _ModalFeatureRow(
            title: context.tr('home.tools_word_mixer', fallback: 'Word Mixer'),
            subtitle: context.tr(
              'home.tools_word_mixer_tip',
              fallback: 'Unscramble letters into words under pressure',
            ),
            badge: context.tr(
              'home.tools_mixer_badge',
              fallback: 'ANAGRAM SPRINT',
            ),
            icon: Icons.sort_by_alpha_rounded,
            color: IllustrationColors.richPurple,
            isDark: isDark,
            onTap: () {
              Navigator.of(context).pop();
              context.push(AppRouter.wordMixerRoute);
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. TOOLS DIRECTORY MODAL SHEET (Displays all 7 tools with instant access)
// ═══════════════════════════════════════════════════════════════════════════════

class _ToolsDirectoryBottomSheet extends StatelessWidget {
  const _ToolsDirectoryBottomSheet();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ToolsDirectoryBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tools = [
      _DirectoryItemDef(
        title: context.tr('home.tools_kids_zone', fallback: 'Kids Zone'),
        subtitle: context.tr(
          'home.tools_kids_zone_tip',
          fallback: 'Safe, playful games designed for young learners',
        ),
        badge: 'KIDS PORTAL',
        icon: Icons.child_care_rounded,
        color: AppColors.rose500,
        route: AppRouter.kidsZoneRoute,
      ),
      _DirectoryItemDef(
        title: context.tr('home.tools_daily_words', fallback: 'Daily Words'),
        subtitle: context.tr(
          'home.tools_daily_words_tip',
          fallback: 'Fresh vocabulary words curated every day',
        ),
        badge: 'NEW TODAY',
        icon: Icons.menu_book_rounded,
        color: AppColors.amber500,
        route: AppRouter.dailyWordsRoute,
      ),
      _DirectoryItemDef(
        title: context.tr('home.tools_photo_vocab', fallback: 'Photo Vocab'),
        subtitle: context.tr(
          'home.tools_photo_vocab_tip',
          fallback: 'Point your camera to learn new words instantly',
        ),
        badge: 'AI VISION',
        icon: Icons.camera_alt_rounded,
        color: AppColors.blue500,
        route: AppRouter.photoVocabularyRoute,
      ),
      _DirectoryItemDef(
        title: context.tr('home.tools_scan_learn', fallback: 'Scan & Learn'),
        subtitle: context.tr(
          'home.tools_scan_learn_tip',
          fallback: 'Scan any text to get instant definitions',
        ),
        badge: 'OCR SCAN',
        icon: Icons.document_scanner_rounded,
        color: AppColors.teal500,
        route: AppRouter.scanAndLearnRoute,
      ),
      _DirectoryItemDef(
        title: context.tr('home.translation_title', fallback: 'Translate'),
        subtitle: context.tr(
          'home.tools_translate_tip',
          fallback: 'Offline translation for 50+ languages',
        ),
        badge: 'OFFLINE',
        icon: Icons.translate_rounded,
        color: AppColors.emerald500,
        route: AppRouter.translateRoute,
      ),
      _DirectoryItemDef(
        title: context.tr('home.tools_word_snap', fallback: 'Word Snap'),
        subtitle: context.tr(
          'home.tools_word_snap_tip',
          fallback: 'Match words and meanings in a fast-paced memory game',
        ),
        badge: 'MEMORY GAME',
        icon: Icons.extension_rounded,
        color: IllustrationColors.vibrantPink,
        route: AppRouter.wordSnapRoute,
      ),
      _DirectoryItemDef(
        title: context.tr('home.tools_word_mixer', fallback: 'Word Mixer'),
        subtitle: context.tr(
          'home.tools_word_mixer_tip',
          fallback: 'Combine letters to form words under pressure',
        ),
        badge: 'ANAGRAM SPRINT',
        icon: Icons.sort_by_alpha_rounded,
        color: IllustrationColors.richPurple,
        route: AppRouter.wordMixerRoute,
      ),
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A29) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.r,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20.w,
        14.h,
        20.w,
        MediaQuery.of(context).padding.bottom + 16.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 14.h),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        'home.tools_all_title',
                        fallback: 'Tools & Utilities (7)',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.5.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      context.tr(
                        'home.tools_all_sub',
                        fallback: 'All learning accelerators and tools in Vowl',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
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
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close_rounded,
                  size: 20.r,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Scrollable List of All 7 Tools
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: tools
                    .map(
                      (tool) => Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: _ModalFeatureRow(
                          title: tool.title,
                          subtitle: tool.subtitle,
                          badge: tool.badge,
                          icon: tool.icon,
                          color: tool.color,
                          isDark: isDark,
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push(tool.route);
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Bottom Trigger to Full App Feature Catalog (100+ Features)
          ScaleButton(
            onTap: () {
              Navigator.of(context).pop();
              FeatureDirectoryBottomSheet.show(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1.r,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.compass,
                    size: 15.r,
                    color: AppColors.indigo500,
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      context.tr(
                        'home.tools_browse_full_catalog',
                        fallback: 'Browse 100+ Games & Full App Catalog',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigo500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10.r,
                    color: AppColors.indigo500,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Helper Models & Row Widget for Modal Sheets
// ═══════════════════════════════════════════════════════════════════════════════

class _DirectoryItemDef {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color color;
  final String route;

  const _DirectoryItemDef({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _ModalFeatureRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ModalFeatureRow({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.22 : 0.15),
              width: 1.r,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.14 : 0.09),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: color.withValues(alpha: isDark ? 0.25 : 0.16),
                    width: 1.r,
                  ),
                ),
                child: Center(child: Icon(icon, color: color, size: 18.r)),
              ),
              SizedBox(width: 12.w),
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
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
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
                            color: color.withValues(
                              alpha: isDark ? 0.16 : 0.10,
                            ),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            badge,
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
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
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
              SizedBox(width: 6.w),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11.r,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
