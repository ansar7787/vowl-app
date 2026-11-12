import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/daily_words/data/services/daily_words_service.dart';
import 'package:vowl/features/home/presentation/widgets/discovery_deck.dart';

/// Production-hardened Tools & Utilities Hub.
///
/// Implements a unified Swiss Horizon Architecture:
/// 1. **Daily Words (Flagship Swiss Card)**: Daily 5-word curated vocabulary accelerator.
/// 2. **Translate (Flagship Swiss Card)**: Offline 50+ languages translation suite.
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
                // ── 1. SWISS HORIZON CARD 1: DAILY VOCABULARY ───────────────────
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
        onUserEarnedReward: (_) => context.push(route),
        onDismissed: () {},
      );
    } catch (_) {
      context.push(route);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. SWISS HORIZON CARD (Daily Words & Translate)
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
