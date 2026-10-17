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
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';
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

/// Compact Horizontal Discovery Deck guiding new learners through 5 core ecosystem pillars.
///
/// Features:
/// - Sleek horizontal row layout (avoids pushing Quest Hub down with a long column)
/// - Robust account-level persistence check (prevents uninstall/reinstall exploit loop)
/// - Celebratory Gift Box transformation upon completion
/// - Confetti burst and delightful "eating" collapse animation upon reward claim
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

class _BeginnerDiscoveryCardState extends State<BeginnerDiscoveryCard>
    with TickerProviderStateMixin {
  bool _isDismissed = false;
  bool _rewardClaimed = false;
  bool _isClaiming = false;
  final Map<String, bool> _completedMap = {};

  // Eating / collapse animation controller
  late final AnimationController _eatingController;
  late final Animation<double> _eatingScale;
  late final Animation<double> _eatingOpacity;
  late final Animation<double> _eatingSize;

  // Gift Box one-shot pulse celebration controller
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static const List<_DiscoveryQuest> _quests = [
    _DiscoveryQuest(
      key: 'first_game',
      title: 'Complete 1 Lesson',
      subtitle: 'Play curriculum game',
      icon: LucideIcons.gamepad2,
      route: AppRouter.gamesRoute,
      actionLabel: 'Play',
      themeColor: Color(0xFF6366F1), // Indigo
    ),
    _DiscoveryQuest(
      key: 'photo_vocab',
      title: 'Try Camera AI in Photo Vocab',
      subtitle: 'Discover words with AI',
      icon: LucideIcons.camera,
      route: AppRouter.photoVocabularyRoute,
      actionLabel: 'Try',
      themeColor: Color(0xFF0EA5E9), // Sky Blue
    ),
    _DiscoveryQuest(
      key: 'translate',
      title: 'Test 50+ Offline Languages',
      subtitle: 'Translate without Wi-Fi',
      icon: LucideIcons.languages,
      route: AppRouter.translateRoute,
      actionLabel: 'Translate',
      themeColor: Color(0xFF10B981), // Emerald
    ),
    _DiscoveryQuest(
      key: 'boutique',
      title: 'Visit Buddy Boutique & Pet',
      subtitle: 'Style your mascot pet',
      icon: LucideIcons.sparkles,
      route: AppRouter.vowlMascotRoute,
      actionLabel: 'Visit',
      themeColor: Color(0xFFF59E0B), // Amber
    ),
    _DiscoveryQuest(
      key: 'reports',
      title: 'Check Learning Report & Errors',
      subtitle: 'Track accuracy & errors',
      icon: LucideIcons.barChart2,
      route: AppRouter.progressDashboardRoute,
      actionLabel: 'View',
      themeColor: Color(0xFF8B5CF6), // Purple
    ),
  ];

  bool get _hasClaimedInAccount =>
      widget.user.badges.contains('beginner_discovery_claimed') ||
      widget.user.badges.contains('beginner_discovery_completed') ||
      widget.user.coinHistory.any(
        (entry) =>
            entry['title'] == 'coin_history.beginner_quest_reward' ||
            entry['title'] == 'Beginner Quest Reward',
      );

  @override
  void initState() {
    super.initState();

    if (_hasClaimedInAccount) {
      _isDismissed = true;
      _rewardClaimed = true;
    }

    if (widget.user.totalLevelsCompleted > 0) {
      _completedMap['first_game'] = true;
    }

    // Eating / Collapse animation: Pop slightly, then chomp down to 0 with height collapse
    _eatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _eatingScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.05,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInBack)),
        weight: 75,
      ),
    ]).animate(_eatingController);

    _eatingOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _eatingController,
        curve: const Interval(0.25, 0.95, curve: Curves.easeIn),
      ),
    );

    _eatingSize = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _eatingController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    // Gift box single pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );

    _loadProgress();
  }

  @override
  void dispose() {
    _eatingController.dispose();
    _pulseController.dispose();
    super.dispose();
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

      // ── Account-level Loophole Prevention ────────────────────────────────
      // Check if user already claimed this reward in Firestore:
      if (_hasClaimedInAccount || rewardClaimed || isDismissed) {
        if (_hasClaimedInAccount) {
          await prefs.setBool(BeginnerDiscoveryCard.prefsKeyRewardClaimed, true);
          await prefs.setBool(BeginnerDiscoveryCard.prefsKeyDismissed, true);
        }
        if (mounted) {
          setState(() {
            _rewardClaimed = _hasClaimedInAccount || rewardClaimed;
            _isDismissed = true;
          });
        }
        return;
      }

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

        final allDone = _quests.every((q) => _completedMap[q.key] == true);
        if (allDone && !_rewardClaimed) {
          _pulseController.forward(from: 0.0);
        }
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

        final allDone = _quests.every((q) => _completedMap[q.key] == true);
        if (allDone && !_rewardClaimed) {
          _pulseController.forward(from: 0.0);
        }
      }
    } catch (_) {}
  }

  bool _isNavigating = false;

  Future<void> _handleQuestTap(_DiscoveryQuest quest) async {
    if (_isNavigating) return;
    _isNavigating = true;
    di.sl<HapticService>().light();
    try {
      if (quest.route == AppRouter.gamesRoute &&
          di.sl.isRegistered<ScrollController>(instanceName: 'games')) {
        final sc = di.sl<ScrollController>(instanceName: 'games');
        if (sc.hasClients) {
          await sc.animateTo(
            350.h,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        } else {
          await context.push(quest.route);
        }
      } else {
        await context.push(quest.route);
      }
    } catch (_) {
    } finally {
      _isNavigating = false;
    }

    if (!mounted) return;
    await _saveQuestCompletion(quest.key);
  }

  Future<void> _claimReward() async {
    if (_isClaiming || _rewardClaimed) return;
    _isClaiming = true;

    final economyBloc = context.read<EconomyBloc>();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(BeginnerDiscoveryCard.prefsKeyRewardClaimed, true);
      await prefs.setBool(BeginnerDiscoveryCard.prefsKeyDismissed, true);

      // Economy award
      economyBloc.add(
        const EconomyAddCoinsRequested(
          150,
          title: 'coin_history.beginner_quest_reward',
        ),
      );

      // Server-backed badge award to permanently close exploit loophole
      if (di.sl.isRegistered<GamificationRepository>()) {
        try {
          di.sl<GamificationRepository>().awardBadge(
            'beginner_discovery_claimed',
          );
        } catch (_) {}
      }

      di.sl<HapticService>().success();

      if (!mounted) return;

      // Celebratory Confetti Dialog
      await showDialog(
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
                child: IgnorePointer(child: GameConfetti()),
              ),
            ],
          ),
        ),
      );

      // Trigger delightful "eating" / shrink-disappearance animation
      if (mounted) {
        await _eatingController.forward();
        if (mounted) {
          setState(() {
            _rewardClaimed = true;
            _isDismissed = true;
          });
        }
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
    } catch (_) {}

    if (mounted) {
      await _eatingController.forward();
      if (mounted) {
        setState(() {
          _isDismissed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed || _hasClaimedInAccount) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completedCount = _quests
        .where((q) => _completedMap[q.key] == true)
        .length;
    final progress = (completedCount / _quests.length).clamp(0.0, 1.0);
    final isAllDone = completedCount == _quests.length;
    final canClaim = isAllDone && !_rewardClaimed;

    final Widget cardContent = canClaim
        ? _buildGiftBoxClaimCard(context, isDark)
        : _buildDiscoveryDeck(context, isDark, completedCount, progress);

    return SizeTransition(
      sizeFactor: _eatingSize,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _eatingOpacity,
        child: ScaleTransition(
          scale: _eatingScale,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 8.h),
            child: cardContent,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // State A: Compact Horizontal Discovery Track
  // ---------------------------------------------------------------------------
  Widget _buildDiscoveryDeck(
    BuildContext context,
    bool isDark,
    int completedCount,
    double progress,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 10.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF161928), Color(0xFF10121B)]
              : const [Colors.white, Color(0xFFF8FAFD)],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.indigo500.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header Row ───────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  color: AppColors.indigo500.withValues(alpha: 0.15),
                ),
                child: Icon(
                  LucideIcons.compass,
                  size: 16.r,
                  color: AppColors.indigo500,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr(
                        'beginner_discovery.title',
                        fallback: 'Beginner Discovery Quests',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      '$completedCount of ${_quests.length} Completed',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : AppColors.slate600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              // +150 Coin Pill
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.5.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.amber500.withValues(alpha: 0.2),
                      const Color(0xFFD97706).withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
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
                      size: 12.r,
                      color: AppColors.amber500,
                    ),
                    SizedBox(width: 3.w),
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
              SizedBox(width: 2.w),
              IconButton(
                onPressed: _dismissCard,
                icon: Icon(
                  Icons.close_rounded,
                  size: 16.r,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: BoxConstraints(minWidth: 28.r, minHeight: 28.r),
                tooltip: context.tr('common.dismiss', fallback: 'Dismiss'),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // ── Progress Bar ─────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: Container(
              height: 4.h,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress.clamp(0.04, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.amber400, Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // ── Horizontal Quests Row Deck ────────────────────────────────
          SizedBox(
            height: 148.h,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (int index = 0; index < _quests.length; index++) ...[
                    if (index > 0) SizedBox(width: 10.w),
                    _buildQuestMiniCard(
                      context,
                      _quests[index],
                      index,
                      _completedMap[_quests[index].key] == true,
                      isDark,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),

          // ── Explore Directory Mini Link ──────────────────────────────
          ScaleButton(
            onTap: () {
              di.sl<HapticService>().light();
              FeatureDirectoryBottomSheet.show(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 10.w),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : AppColors.indigo500.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.compass,
                    size: 12.r,
                    color: AppColors.indigo500,
                  ),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      context.tr(
                        'beginner_discovery.explore_directory',
                        fallback:
                            'Explore full directory of all 50+ features & games',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.indigo500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 12.r,
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

  // ---------------------------------------------------------------------------
  // Single Horizontal Quest Mini Card
  // ---------------------------------------------------------------------------
  Widget _buildQuestMiniCard(
    BuildContext context,
    _DiscoveryQuest quest,
    int index,
    bool isDone,
    bool isDark,
  ) {
    final card = Container(
      width: 138.w,
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: isDark
            ? (isDone
                  ? AppColors.emerald500.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.04))
            : (isDone ? const Color(0xFFF0FDF4) : Colors.white),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDone
              ? AppColors.emerald500.withValues(alpha: 0.25)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06)),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Icon & Check/Step Row
          Row(
            children: [
              Container(
                width: 26.r,
                height: 26.r,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  color: isDone
                      ? AppColors.emerald500.withValues(alpha: 0.15)
                      : quest.themeColor.withValues(alpha: 0.15),
                ),
                child: Icon(
                  quest.icon,
                  size: 14.r,
                  color: isDone ? AppColors.emerald500 : quest.themeColor,
                ),
              ),
              const Spacer(),
              if (isDone)
                Container(
                  width: 18.r,
                  height: 18.r,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.emerald500,
                  ),
                  child: Icon(
                    LucideIcons.check,
                    size: 11.r,
                    color: Colors.white,
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.05,
                    ),
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  child: Text(
                    '0${index + 1}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 8.5.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 5.h),

          // Quest Title
          Text(
            quest.title,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              height: 1.15,
              decoration: isDone ? TextDecoration.lineThrough : null,
              color: isDone
                  ? (isDark ? Colors.white38 : Colors.black38)
                  : Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),

          // Quest Subtitle
          Text(
            quest.subtitle,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 9.sp,
              color: isDark ? Colors.white54 : AppColors.slate500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),

          // Uniform Action Button / Done Pill
          if (!isDone)
            Container(
              height: 26.h,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    quest.themeColor,
                    quest.themeColor.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(9.r),
                boxShadow: [
                  BoxShadow(
                    color: quest.themeColor.withValues(alpha: 0.25),
                    blurRadius: 6.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr(
                        'beginner_quest.${quest.key}_action',
                        fallback: quest.actionLabel,
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Icon(
                      LucideIcons.arrowRight,
                      size: 9.r,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 26.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.checkCheck,
                      size: 11.r,
                      color: AppColors.emerald500,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      context.tr('common.done', fallback: 'Done'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    if (isDone) return card;

    return Semantics(
      button: true,
      label: 'Quest ${index + 1}: ${quest.title}',
      child: ScaleButton(
        onTap: () => _handleQuestTap(quest),
        child: card,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // State B: Celebratory Gift Box Claim Card (When 5/5 Quests Completed)
  // ---------------------------------------------------------------------------
  Widget _buildGiftBoxClaimCard(BuildContext context, bool isDark) {
    return Semantics(
      button: true,
      label: context.tr(
        'beginner_discovery.claim_reward',
        fallback: 'Claim 150 Coins Reward',
      ),
      child: ScaleButton(
        onTap: _claimReward,
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF26190B), Color(0xFF17110B)]
                  : const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: AppColors.amber500.withValues(alpha: 0.5),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.amber500.withValues(alpha: 0.18),
                blurRadius: 18.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Bouncing Gift Box
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 46.r,
                      height: 46.r,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.amber500.withValues(alpha: 0.4),
                            blurRadius: 12.r,
                            offset: Offset(0, 3.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        LucideIcons.gift,
                        size: 24.r,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),

                  // Completed Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 5.w,
                                vertical: 1.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.amber500.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(5.r),
                              ),
                              child: Text(
                                '5/5 COMPLETED',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 8.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.amber500,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Icon(
                              LucideIcons.sparkles,
                              size: 12.r,
                              color: AppColors.amber500,
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Gift Box Ready!',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Tap below to unbox 150 Coins',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.5.sp,
                            color: isDark ? Colors.white70 : AppColors.slate600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Interactive Golden Claim Button
              Container(
                width: double.infinity,
                height: 42.h,
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(13.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber500.withValues(alpha: 0.35),
                      blurRadius: 12.r,
                      offset: Offset(0, 3.h),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.monetization_on_rounded,
                        color: Colors.white,
                        size: 17.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        context.tr(
                          'beginner_discovery.claim_reward',
                          fallback: 'Claim 150 Coins Reward',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Icon(
                        LucideIcons.sparkles,
                        color: Colors.white,
                        size: 13.r,
                      ),
                    ],
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
