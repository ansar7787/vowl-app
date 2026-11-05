import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Discovery Hub / Daily Practice widget presenting curated quest sequences in an Apex Cockpit layout:
/// - Flagship Hero Card: Adaptive "Smart Focus" recommendation.
/// - 3-Cell Superpower Row: Daily Workout, Rapid Recall, and Sentence Lab.
///
/// Features real-world daily completion status:
/// - Completing a sequence records today's date in local storage.
/// - Cards reflect "COMPLETED TODAY ✓" / "COMPLETED ✓" with emerald accents.
/// - Automatically resets the next day at midnight (date-based comparison).
/// - Unlocked for unlimited re-practice at any time without blocking eager learners.
/// - 100% visible with zero horizontal swiping, zero battery-draining loops,
///   and zero text clipping or ellipses on narrow viewports.
class DiscoveryDeck extends StatefulWidget {
  /// Global notifier to trigger UI refresh across any mounted [DiscoveryDeck]
  /// when a sequence finishes without needing full route rebuilding.
  static final ValueNotifier<int> dailyCompletionNotifier = ValueNotifier<int>(0);

  /// Notifies all active [DiscoveryDeck] instances to refresh their daily completion state.
  static void notifySequenceCompleted() {
    dailyCompletionNotifier.value++;
  }

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

  @override
  State<DiscoveryDeck> createState() => _DiscoveryDeckState();
}

class _DiscoveryDeckState extends State<DiscoveryDeck> {
  Map<String, bool> _completedSequences = const {
    'smart_recommendation': false,
    'daily_duo': false,
    'speed_blitz': false,
    'grammar_pro': false,
  };

  @override
  void initState() {
    super.initState();
    DiscoveryDeck.dailyCompletionNotifier.addListener(_refreshCompletion);
    _refreshCompletion();
  }

  @override
  void didUpdateWidget(DiscoveryDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _refreshCompletion();
    }
  }

  @override
  void dispose() {
    DiscoveryDeck.dailyCompletionNotifier.removeListener(_refreshCompletion);
    super.dispose();
  }

  Future<void> _refreshCompletion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final userId = widget.user.id;
      final newMap = <String, bool>{};
      for (final id in [
        'smart_recommendation',
        'daily_duo',
        'speed_blitz',
        'grammar_pro',
      ]) {
        final val = prefs.getString('vowl_sequence_completed_${id}_$userId');
        newMap[id] = val == todayStr;
      }
      if (mounted) {
        setState(() {
          _completedSequences = newMap;
        });
      }
    } catch (_) {}
  }

  void _triggerHaptic() {
    try {
      di.sl<HapticService>().selection();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSmartFocusDone = _completedSequences['smart_recommendation'] ?? false;
    final isDailyWorkoutDone = _completedSequences['daily_duo'] ?? false;
    final isRapidRecallDone = _completedSequences['speed_blitz'] ?? false;
    final isSentenceLabDone = _completedSequences['grammar_pro'] ?? false;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Flagship Hero Card: Adaptive "Smart Focus"
          _HeroFlagshipQuestCard(
            isDark: isDark,
            isCompleted: isSmartFocusDone,
            title: context.tr('home.discovery_smartfocus_title', fallback: 'Smart Focus'),
            badge: isSmartFocusDone
                ? context.tr('home.discovery_completed_badge', fallback: 'COMPLETED TODAY ✓')
                : context.tr('home.discovery_smartfocus_badge', fallback: 'Adaptive AI'),
            subtitle: context.tr(
              'home.discovery_smartfocus_subtitle',
              fallback: 'Targeted practice for your weakest skills',
            ),
            onTap: () {
              _triggerHaptic();
              widget.onLaunchQuest('smart_recommendation');
            },
          ),

          SizedBox(height: 10.h),

          // 2. 3-Cell Superpower Row
          Row(
            children: [
              // Cell 1: Daily Workout
              Expanded(
                child: _DiscoverySubCell(
                  isDark: isDark,
                  isCompleted: isDailyWorkoutDone,
                  icon: Icons.auto_awesome_motion_rounded,
                  color: const Color(0xFF06B6D4), // Cyan
                  title: context.tr(
                    'home.discovery_dailyworkout_title',
                    fallback: 'Daily Workout',
                  ),
                  tag: isDailyWorkoutDone
                      ? context.tr('home.discovery_completed_today', fallback: 'COMPLETED ✓')
                      : context.tr(
                          'home.discovery_dailyworkout_tag',
                          fallback: '2 Steps',
                        ),
                  onTap: () {
                    _triggerHaptic();
                    widget.onLaunchQuest('daily_duo');
                  },
                ),
              ),
              SizedBox(width: 8.w),

              // Cell 2: Rapid Recall
              Expanded(
                child: _DiscoverySubCell(
                  isDark: isDark,
                  isCompleted: isRapidRecallDone,
                  icon: Icons.bolt_rounded,
                  color: IllustrationColors.warmOrange,
                  title: context.tr(
                    'home.discovery_rapidrecall_title',
                    fallback: 'Rapid Recall',
                  ),
                  tag: isRapidRecallDone
                      ? context.tr('home.discovery_completed_today', fallback: 'COMPLETED ✓')
                      : context.tr(
                          'home.discovery_rapidrecall_tag',
                          fallback: 'Speed Drill',
                        ),
                  onTap: () {
                    _triggerHaptic();
                    widget.onLaunchQuest('speed_blitz');
                  },
                ),
              ),
              SizedBox(width: 8.w),

              // Cell 3: Sentence Lab
              Expanded(
                child: _DiscoverySubCell(
                  isDark: isDark,
                  isCompleted: isSentenceLabDone,
                  icon: Icons.architecture_rounded,
                  color: AppColors.emerald500,
                  title: context.tr(
                    'home.discovery_sentencelab_title',
                    fallback: 'Sentence Lab',
                  ),
                  tag: isSentenceLabDone
                      ? context.tr('home.discovery_completed_today', fallback: 'COMPLETED ✓')
                      : context.tr(
                          'home.discovery_sentencelab_tag',
                          fallback: 'Syntax',
                        ),
                  onTap: () {
                    _triggerHaptic();
                    widget.onLaunchQuest('grammar_pro');
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
  final bool isCompleted;
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
    this.isCompleted = false,
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
              color: isCompleted
                  ? (isDark
                      ? AppColors.emerald500.withValues(alpha: 0.35)
                      : AppColors.emerald500.withValues(alpha: 0.30))
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
              // Leading Halo Icon
              Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.emerald500.withValues(
                          alpha: isDark ? 0.20 : 0.14,
                        )
                      : AppColors.indigo500.withValues(
                          alpha: isDark ? 0.18 : 0.12,
                        ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.emerald500.withValues(
                            alpha: isDark ? 0.40 : 0.28,
                          )
                        : AppColors.indigo500.withValues(
                            alpha: isDark ? 0.35 : 0.25,
                          ),
                    width: 1.r,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.lightbulb_rounded,
                    size: 22.r,
                    color: isCompleted
                        ? (isDark ? const Color(0xFF6EE7B7) : AppColors.emerald500)
                        : (isDark
                            ? const Color(0xFFA5B4FC)
                            : AppColors.indigo500),
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
                            color: isCompleted
                                ? AppColors.emerald500.withValues(
                                    alpha: isDark ? 0.22 : 0.14,
                                  )
                                : AppColors.indigo500.withValues(
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
                              color: isCompleted
                                  ? (isDark
                                      ? const Color(0xFF6EE7B7)
                                      : AppColors.emerald500)
                                  : (isDark
                                      ? const Color(0xFFA5B4FC)
                                      : AppColors.indigo500),
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
                  color: isCompleted ? AppColors.emerald500 : AppColors.indigo500,
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
  final bool isCompleted;
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
    this.isCompleted = false,
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
              color: isCompleted
                  ? (isDark
                      ? AppColors.emerald500.withValues(alpha: 0.35)
                      : AppColors.emerald500.withValues(alpha: 0.30))
                  : (isMidnight
                      ? Colors.white.withValues(alpha: 0.12)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.slate100)),
              width: 1.r,
            ),
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
                  color: isCompleted
                      ? AppColors.emerald500.withValues(
                          alpha: isDark ? 0.20 : 0.12,
                        )
                      : color.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.emerald500.withValues(
                            alpha: isDark ? 0.40 : 0.25,
                          )
                        : color.withValues(alpha: isDark ? 0.32 : 0.20),
                    width: 1.r,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isCompleted ? Icons.check_rounded : icon,
                    size: 16.r,
                    color: isCompleted
                        ? (isDark ? const Color(0xFF6EE7B7) : AppColors.emerald500)
                        : color,
                  ),
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

              // Tag / Quest Count / Completion Status
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tag,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: isCompleted
                        ? (isDark ? const Color(0xFF6EE7B7) : AppColors.emerald500)
                        : color,
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
