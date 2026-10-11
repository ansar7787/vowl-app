import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/feature_catalog/feature_directory_bottom_sheet.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/modern_game_dialog.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class _DiscoveryQuest {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final String actionLabel;
  final Color themeColor;

  const _DiscoveryQuest({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.actionLabel,
    required this.themeColor,
  });
}

/// 7-Day Beginner Discovery Quests card guiding new learners through 5 core ecosystem pillars.
class BeginnerDiscoveryCard extends StatefulWidget {
  final UserEntity user;

  const BeginnerDiscoveryCard({super.key, required this.user});

  static const String prefsKeyPrefix = 'beginner_discovery_quest_';
  static const String prefsKeyRewardClaimed =
      'beginner_discovery_reward_claimed';
  static const String prefsKeyDismissed = 'beginner_discovery_card_dismissed';

  @override
  State<BeginnerDiscoveryCard> createState() => _BeginnerDiscoveryCardState();
}

class _BeginnerDiscoveryCardState extends State<BeginnerDiscoveryCard> {
  bool _isDismissed = false;
  bool _rewardClaimed = false;
  bool _isClaiming = false;
  final Map<String, bool> _completedMap = {};

  static const List<_DiscoveryQuest> _quests = [
    _DiscoveryQuest(
      key: 'first_game',
      title: 'Complete 1 Lesson',
      subtitle: 'Play any quest from the 100+ Games curriculum',
      icon: LucideIcons.gamepad2,
      route: AppRouter.gamesRoute,
      actionLabel: 'Play',
      themeColor: Color(0xFF6366F1), // Indigo
    ),
    _DiscoveryQuest(
      key: 'photo_vocab',
      title: 'Try Camera AI in Photo Vocab',
      subtitle: 'Identify real-world objects using on-device vision ML',
      icon: LucideIcons.camera,
      route: AppRouter.photoVocabularyRoute,
      actionLabel: 'Try',
      themeColor: Color(0xFF0EA5E9), // Sky Blue
    ),
    _DiscoveryQuest(
      key: 'translate',
      title: 'Test 50+ Offline Languages',
      subtitle: 'Translate sentences without needing internet access',
      icon: LucideIcons.languages,
      route: AppRouter.translateRoute,
      actionLabel: 'Translate',
      themeColor: Color(0xFF10B981), // Emerald
    ),
    _DiscoveryQuest(
      key: 'boutique',
      title: 'Visit Buddy Boutique & Pet',
      subtitle: 'Explore outfits, skins, and accessories for your mascot',
      icon: LucideIcons.sparkles,
      route: AppRouter.vowlMascotRoute,
      actionLabel: 'Visit',
      themeColor: Color(0xFFF59E0B), // Amber
    ),
    _DiscoveryQuest(
      key: 'reports',
      title: 'Check Learning Report & Errors',
      subtitle: 'Review accuracy stats and previously missed questions',
      icon: LucideIcons.barChart2,
      route: AppRouter.progressDashboardRoute,
      actionLabel: 'View',
      themeColor: Color(0xFF8B5CF6), // Purple
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void didUpdateWidget(covariant BeginnerDiscoveryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user.totalLevelsCompleted > 0 &&
        _completedMap['first_game'] != true) {
      _saveQuestCompletion('first_game');
    }
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDismissed =
          prefs.getBool(BeginnerDiscoveryCard.prefsKeyDismissed) ?? false;
      final rewardClaimed =
          prefs.getBool(BeginnerDiscoveryCard.prefsKeyRewardClaimed) ?? false;

      final Map<String, bool> map = {};
      for (final quest in _quests) {
        if (quest.key == 'first_game' && widget.user.totalLevelsCompleted > 0) {
          map[quest.key] = true;
          await prefs.setBool(
            '${BeginnerDiscoveryCard.prefsKeyPrefix}${quest.key}',
            true,
          );
        } else {
          map[quest.key] =
              prefs.getBool(
                '${BeginnerDiscoveryCard.prefsKeyPrefix}${quest.key}',
              ) ??
              false;
        }
      }

      if (mounted) {
        setState(() {
          _isDismissed = isDismissed;
          _rewardClaimed = rewardClaimed;
          _completedMap.addAll(map);
        });
      }
    } catch (_) {}
  }

  Future<void> _saveQuestCompletion(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${BeginnerDiscoveryCard.prefsKeyPrefix}$key', true);
      if (mounted) {
        setState(() {
          _completedMap[key] = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleQuestTap(_DiscoveryQuest quest) async {
    di.sl<HapticService>().light();
    await context.push(quest.route);

    if (!mounted) return;
    await _saveQuestCompletion(quest.key);
  }

  Future<void> _claimReward() async {
    if (_isClaiming || _rewardClaimed) return;
    _isClaiming = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(BeginnerDiscoveryCard.prefsKeyRewardClaimed, true);

      if (mounted) {
        setState(() {
          _rewardClaimed = true;
          _isClaiming = false;
        });

        // Real economy coin award
        context.read<EconomyBloc>().add(
          const EconomyAddCoinsRequested(
            150,
            title: 'coin_history.beginner_quest_reward',
          ),
        );
        di.sl<HapticService>().success();

        // Celebratory Dialog matching Golden Key reward style (DRY)
        showDialog(
          context: context,
          builder: (ctx) => Material(
            type: MaterialType.transparency,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ModernGameDialog(
                  title: context.tr(
                    'beginner_discovery.claim_dialog_title',
                    fallback: '150 COINS CLAIMED!',
                  ),
                  description: context.tr(
                    'beginner_discovery.claim_dialog_desc',
                    fallback:
                        'You completed all 5 Beginner Discovery Quests! 150 coins have been added to your vault.',
                  ),
                  buttonText: context.tr('store.awesome', fallback: 'AWESOME'),
                  isSuccess: true,
                  customIcon: Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.amber500.withValues(alpha: 0.4),
                          blurRadius: 18.r,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.monetization_on_rounded,
                      size: 48.r,
                      color: Colors.white,
                    ),
                  ),
                  onButtonPressed: () => Navigator.of(ctx).pop(),
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: GameConfetti(),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {
      _isClaiming = false;
    }
  }

  Future<void> _dismissCard() async {
    di.sl<HapticService>().light();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(BeginnerDiscoveryCard.prefsKeyDismissed, true);
      if (mounted) {
        setState(() {
          _isDismissed = true;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completedCount =
        _quests.where((q) => _completedMap[q.key] == true).length;
    final progress = (completedCount / _quests.length).clamp(0.0, 1.0);
    final isAllDone = completedCount == _quests.length;
    final canClaim = isAllDone && !_rewardClaimed;

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? (isAllDone && _rewardClaimed
                  ? const [Color(0xFF13221C), Color(0xFF0F1713)]
                  : canClaim
                      ? const [Color(0xFF241A12), Color(0xFF17141C)]
                      : const [Color(0xFF161928), Color(0xFF10121B)])
              : (isAllDone && _rewardClaimed
                  ? const [Color(0xFFF0FDF4), Color(0xFFE8F7EE)]
                  : canClaim
                      ? const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)]
                      : const [Colors.white, Color(0xFFF8FAFD)]),
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isAllDone && _rewardClaimed
              ? AppColors.emerald500.withValues(alpha: 0.35)
              : canClaim
                  ? AppColors.amber500.withValues(alpha: 0.45)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.indigo500.withValues(alpha: 0.12)),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: canClaim
                ? AppColors.amber500.withValues(alpha: 0.12)
                : (isAllDone
                    ? AppColors.emerald500.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: isDark ? 0.3 : 0.04)),
            blurRadius: 20.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Icon Squircle
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  color: isAllDone && _rewardClaimed
                      ? AppColors.emerald500.withValues(alpha: 0.15)
                      : canClaim
                          ? AppColors.amber500.withValues(alpha: 0.18)
                          : AppColors.indigo500.withValues(alpha: 0.15),
                ),
                child: Icon(
                  isAllDone && _rewardClaimed
                      ? LucideIcons.award
                      : canClaim
                          ? LucideIcons.sparkles
                          : LucideIcons.compass,
                  size: 20.r,
                  color: isAllDone && _rewardClaimed
                      ? AppColors.emerald500
                      : canClaim
                          ? AppColors.amber500
                          : AppColors.indigo500,
                ),
              ),
              SizedBox(width: 12.w),

              // Title and Subtitle in Expanded
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAllDone && _rewardClaimed
                          ? context.tr(
                              'beginner_discovery.completed_title',
                              fallback: 'Explorer Master',
                            )
                          : context.tr(
                              'beginner_discovery.title',
                              fallback: 'Beginner Discovery Quests',
                            ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isAllDone && _rewardClaimed
                          ? context.tr(
                              'beginner_discovery.completed_subtitle',
                              fallback:
                                  '150 Coins claimed! You unlocked Vowl.',
                            )
                          : canClaim
                              ? context.tr(
                                  'beginner_discovery.reward_unlocked_subtitle',
                                  fallback:
                                      'All 5 done! Tap below to claim 150 Coins 🎉',
                                )
                              : context.tr(
                                  'beginner_discovery.progress_status',
                                  args: ['$completedCount', '${_quests.length}'],
                                  fallback:
                                      '$completedCount of ${_quests.length} Completed',
                                ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        color: canClaim
                            ? AppColors.amber500
                            : isAllDone && _rewardClaimed
                                ? AppColors.emerald500
                                : isDark
                                    ? Colors.white60
                                    : Colors.black54,
                        fontWeight: canClaim || (isAllDone && _rewardClaimed)
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // Right-side Reward Pill & Dismiss Button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_rewardClaimed)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.amber500.withValues(alpha: 0.2),
                            const Color(0xFFD97706).withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: AppColors.amber500.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on_rounded,
                            size: 13.r,
                            color: AppColors.amber500,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '+150',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.amber500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(width: 4.w),
                  IconButton(
                    onPressed: _dismissCard,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 16.r,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 26.r,
                      minHeight: 26.r,
                    ),
                    tooltip: 'Dismiss',
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // ── Progress Bar & Percentage ─────────────────────────────────
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    height: 7.h,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isAllDone
                                ? const [AppColors.emerald400, AppColors.emerald500]
                                : const [AppColors.amber400, Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w800,
                  color: isAllDone ? AppColors.emerald500 : AppColors.amber500,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // ── Quests Mission Items ──────────────────────────────────────
          ..._quests.map((quest) {
            final isDone = _completedMap[quest.key] == true;
            return Container(
              margin: EdgeInsets.only(bottom: 9.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: isDark
                    ? (isDone
                        ? Colors.white.withValues(alpha: 0.02)
                        : Colors.white.withValues(alpha: 0.04))
                    : (isDone
                        ? const Color(0xFFF8FAFC)
                        : Colors.white),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark
                      ? (isDone
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.white.withValues(alpha: 0.06))
                      : (isDone
                          ? Colors.black.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.05)),
                ),
              ),
              child: Row(
                children: [
                  // Icon Squircle
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: isDone
                          ? AppColors.emerald500.withValues(alpha: 0.15)
                          : quest.themeColor.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      isDone ? LucideIcons.check : quest.icon,
                      size: 17.r,
                      color: isDone ? AppColors.emerald500 : quest.themeColor,
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.title,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w700,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            color: isDone
                                ? (isDark ? Colors.white38 : Colors.black38)
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          quest.subtitle,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.5.sp,
                            color: isDark ? Colors.white54 : AppColors.slate500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),

                  // Action Button or Done Badge
                  if (!isDone)
                    ScaleButton(
                      onTap: () => _handleQuestTap(quest),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 13.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.indigo600, Color(0xFF4F46E5)],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.indigo500.withValues(alpha: 0.3),
                              blurRadius: 8.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              quest.actionLabel,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Icon(
                              LucideIcons.arrowRight,
                              size: 11.r,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald500.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.checkCheck,
                            size: 13.r,
                            color: AppColors.emerald500,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Done',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.emerald500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),

          // ── Interactive Claim Button (When 5/5 and Unclaimed) ───────────
          if (canClaim) ...[
            SizedBox(height: 8.h),
            ScaleButton(
              onTap: _claimReward,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber500.withValues(alpha: 0.4),
                      blurRadius: 16.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(5.r),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.monetization_on_rounded,
                        color: const Color(0xFFD97706),
                        size: 18.r,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Flexible(
                      child: Text(
                        context.tr(
                          'beginner_discovery.claim_reward',
                          fallback: 'Claim 150 Coins Reward',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      LucideIcons.sparkles,
                      color: Colors.white,
                      size: 16.r,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Claimed Trophy Banner (When Claimed & Done) ────────────────
          if (isAllDone && _rewardClaimed) ...[
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(
                  alpha: isDark ? 0.12 : 0.08,
                ),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.trophy,
                    color: AppColors.emerald500,
                    size: 16.r,
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      context.tr(
                        'beginner_discovery.reward_claimed',
                        fallback: '150 Coins Claimed • All Quests Completed ✨',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emerald500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 12.h),

          // ── Bottom Feature Directory Link ──────────────────────────────
          ScaleButton(
            onTap: () {
              di.sl<HapticService>().light();
              FeatureDirectoryBottomSheet.show(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : AppColors.indigo500.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.indigo500.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.compass,
                    size: 14.r,
                    color: AppColors.indigo500,
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      context.tr(
                        'beginner_discovery.explore_directory',
                        fallback:
                            'Explore full directory of all 50+ features & games',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigo500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 14.r,
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
