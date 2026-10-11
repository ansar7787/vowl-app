import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class _DiscoveryQuest {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final String actionLabel;

  const _DiscoveryQuest({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.actionLabel,
  });
}

/// Pinned home feed card guiding new learners through 5 core ecosystem pillars.
class BeginnerDiscoveryCard extends StatefulWidget {
  final UserEntity user;

  const BeginnerDiscoveryCard({super.key, required this.user});

  static const String prefsKeyPrefix = 'beginner_discovery_quest_';
  static const String prefsKeyRewardClaimed = 'beginner_discovery_reward_claimed';
  static const String prefsKeyDismissed = 'beginner_discovery_card_dismissed';

  @override
  State<BeginnerDiscoveryCard> createState() => _BeginnerDiscoveryCardState();
}

class _BeginnerDiscoveryCardState extends State<BeginnerDiscoveryCard> {
  bool _isDismissed = false;
  bool _rewardClaimed = false;
  final Map<String, bool> _completedMap = {};

  static const List<_DiscoveryQuest> _quests = [
    _DiscoveryQuest(
      key: 'first_game',
      title: 'Complete 1 Lesson',
      subtitle: 'Play any quest from the 100+ Games curriculum',
      icon: LucideIcons.gamepad2,
      route: AppRouter.gamesRoute,
      actionLabel: 'Play',
    ),
    _DiscoveryQuest(
      key: 'photo_vocab',
      title: 'Try Camera AI in Photo Vocab',
      subtitle: 'Identify real-world objects using on-device vision ML',
      icon: LucideIcons.camera,
      route: AppRouter.photoVocabularyRoute,
      actionLabel: 'Try',
    ),
    _DiscoveryQuest(
      key: 'translate',
      title: 'Test 50+ Offline Languages',
      subtitle: 'Translate sentences without needing internet access',
      icon: LucideIcons.languages,
      route: AppRouter.translateRoute,
      actionLabel: 'Translate',
    ),
    _DiscoveryQuest(
      key: 'boutique',
      title: 'Visit Buddy Boutique & Pet',
      subtitle: 'Explore outfits, skins, and accessories for your mascot',
      icon: LucideIcons.sparkles,
      route: AppRouter.vowlMascotRoute,
      actionLabel: 'Visit',
    ),
    _DiscoveryQuest(
      key: 'reports',
      title: 'Check Learning Report & Errors',
      subtitle: 'Review accuracy stats and previously missed questions',
      icon: LucideIcons.barChart2,
      route: AppRouter.progressDashboardRoute,
      actionLabel: 'View',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDismissed = prefs.getBool(BeginnerDiscoveryCard.prefsKeyDismissed) ?? false;
      final rewardClaimed = prefs.getBool(BeginnerDiscoveryCard.prefsKeyRewardClaimed) ?? false;

      final Map<String, bool> map = {};
      for (final quest in _quests) {
        // If the user already completed a level, automatically mark the first quest complete
        if (quest.key == 'first_game' && widget.user.totalLevelsCompleted > 0) {
          map[quest.key] = true;
          await prefs.setBool('${BeginnerDiscoveryCard.prefsKeyPrefix}${quest.key}', true);
        } else {
          map[quest.key] = prefs.getBool('${BeginnerDiscoveryCard.prefsKeyPrefix}${quest.key}') ?? false;
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

  Future<void> _handleQuestTap(_DiscoveryQuest quest) async {
    di.sl<HapticService>().light();
    await context.push(quest.route);

    // Upon returning from the screen, mark quest as complete
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${BeginnerDiscoveryCard.prefsKeyPrefix}${quest.key}', true);

      if (mounted) {
        setState(() {
          _completedMap[quest.key] = true;
        });
        _checkRewardEligibility();
      }
    } catch (_) {}
  }

  Future<void> _checkRewardEligibility() async {
    final completedCount = _quests.where((q) => _completedMap[q.key] == true).length;
    if (completedCount == _quests.length && !_rewardClaimed) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(BeginnerDiscoveryCard.prefsKeyRewardClaimed, true);

        if (mounted) {
          setState(() {
            _rewardClaimed = true;
          });
          // Real economy coin award
          context.read<EconomyBloc>().add(
                const EconomyAddCoinsRequested(
                  150,
                  title: 'coin_history.beginner_quests_reward',
                ),
              );
          di.sl<HapticService>().success();
        }
      } catch (_) {}
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
    final completedCount = _quests.where((q) => _completedMap[q.key] == true).length;
    final progress = completedCount / _quests.length;
    final isAllDone = completedCount == _quests.length;

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161822) : const Color(0xFFF9FAFD),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isAllDone
              ? AppColors.emerald500.withValues(alpha: 0.4)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06)),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  color: isAllDone
                      ? AppColors.emerald500.withValues(alpha: 0.15)
                      : AppColors.amber500.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAllDone ? LucideIcons.award : LucideIcons.compass,
                  size: 16.r,
                  color: isAllDone ? AppColors.emerald500 : AppColors.amber500,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAllDone
                          ? 'Explorer Master (Completed)'
                          : 'Beginner Discovery Quests',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      isAllDone
                          ? '150 Coins claimed! You unlocked Vowl\'s core.'
                          : '$completedCount of ${_quests.length} Completed',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isAllDone)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.amber500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.gift, size: 11.r, color: AppColors.amber500),
                      SizedBox(width: 4.w),
                      Text(
                        '150 Coins',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber500,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(width: 6.w),
              IconButton(
                onPressed: _dismissCard,
                icon: Icon(
                  Icons.close_rounded,
                  size: 16.r,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 24.r, minHeight: 24.r),
                tooltip: 'Dismiss',
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5.h,
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(
                isAllDone ? AppColors.emerald500 : AppColors.amber500,
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Quest Items
          ..._quests.map((quest) {
            final isDone = _completedMap[quest.key] == true;
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isDark
                    ? (isDone
                        ? Colors.white.withValues(alpha: 0.02)
                        : Colors.white.withValues(alpha: 0.04))
                    : (isDone ? Colors.white : Colors.white),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.04),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26.r,
                    height: 26.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? AppColors.emerald500.withValues(alpha: 0.15)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04)),
                    ),
                    child: Icon(
                      isDone ? LucideIcons.check : quest.icon,
                      size: 13.r,
                      color: isDone
                          ? AppColors.emerald500
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.title,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            color: isDone
                                ? (isDark ? Colors.white38 : Colors.black38)
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          quest.subtitle,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.5.sp,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  if (!isDone)
                    ScaleButton(
                      onTap: () => _handleQuestTap(quest),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          quest.actionLabel,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    Icon(
                      LucideIcons.checkCircle2,
                      size: 16.r,
                      color: AppColors.emerald500,
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

