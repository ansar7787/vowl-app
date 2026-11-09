import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import 'package:vowl/features/leaderboard/presentation/bloc/leaderboard_bloc_event_state.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/leaderboard_header.dart';
import 'package:vowl/features/leaderboard/domain/utils/leaderboard_ranking_helper.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/leaderboard_podium.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/leaderboard_rank_card.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/leaderboard_rank_tile.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/leaderboard_overtake_hud.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/weekly_league_rewards_banner.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/rival_challenge_sheet.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/prestige_trophy_sheet.dart';
import 'package:vowl/features/leaderboard/domain/entities/leaderboard_timeframe.dart';
import 'package:vowl/features/social_share/domain/entities/share_card_data.dart';
import 'package:vowl/features/social_share/presentation/widgets/share_card_preview_modal.dart';
export 'package:vowl/features/leaderboard/domain/entities/leaderboard_timeframe.dart';

/// Main leaderboard rankings screen featuring podium top 3 positions,
/// personal rank card, and toggleable standard/kids leaderboards.
class LeaderboardScreen extends StatefulWidget {
  final bool isKids;
  final LeaderboardTimeframe initialTimeframe;
  final bool? showBackButton;

  const LeaderboardScreen({
    super.key,
    this.isKids = false,
    this.initialTimeframe = LeaderboardTimeframe.thisWeek,
    this.showBackButton,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late LeaderboardTimeframe _timeframe;

  @override
  void initState() {
    super.initState();
    _timeframe = widget.initialTimeframe;
  }

  @override
  void didUpdateWidget(covariant LeaderboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTimeframe != oldWidget.initialTimeframe) {
      setState(() {
        _timeframe = widget.initialTimeframe;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Scoped rebuilds to only the isMidnight boolean, not the entire ThemeCubit state.
    final isMidnight =
        (Theme.of(context).brightness == Brightness.dark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black);
    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? AppColors.slate900 : AppColors.white);

    return BlocProvider(
      create: (_) =>
          di.sl<LeaderboardBloc>()..add(LoadLeaderboard(isKids: widget.isKids)),
      child: Scaffold(
        backgroundColor: bgColor,
        body: BlocBuilder<LeaderboardBloc, LeaderboardState>(
          builder: (context, state) {
            final currentUser = context.select<AuthBloc, UserEntity?>(
              (bloc) => bloc.state.user,
            );

            return Stack(
              children: [
                const MeshGradientBackground(showLetters: false),

                // Content Layer — guarded by top SafeArea so sticky header & content never overlap the status bar
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      if (widget.showBackButton ?? widget.isKids) ...[
                        Padding(
                          padding: EdgeInsets.only(
                            top: 6.h,
                            left: 12.w,
                            right: AppSpacing.screen,
                            bottom: 4.h,
                          ),
                          child: Row(
                            children: [
                              Semantics(
                                button: true,
                                label: context.tr(
                                  'common.back',
                                  fallback: widget.isKids
                                      ? 'Back to Kids Zone'
                                      : 'Back to Home',
                                ),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go(
                                        widget.isKids
                                            ? AppRouter.kidsZoneRoute
                                            : AppRouter.homeRoute,
                                      );
                                    }
                                  },
                                  child: Container(
                                    constraints: BoxConstraints(
                                      minHeight: 44.r,
                                      minWidth: 44.r,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Directionality.of(context) ==
                                                  TextDirection.rtl
                                              ? Icons.arrow_forward_ios_rounded
                                              : Icons
                                                    .arrow_back_ios_new_rounded,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.slate900,
                                          size: 18.r,
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          widget.isKids
                                              ? 'Kids Zone'
                                              : context.tr(
                                                  'nav.home',
                                                  fallback: 'Home',
                                                ),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white70
                                                : AppColors.slate600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!widget.isKids &&
                          (state is LeaderboardLoading ||
                              state is LeaderboardInitial)) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.screen,
                            vertical: 8.h,
                          ),
                          child: _LeaderboardHeroSwitch(
                            timeframe: _timeframe,
                            onChanged: (selected) {
                              setState(() => _timeframe = selected);
                            },
                          ),
                        ),
                      ],

                      Expanded(
                        child: Builder(
                          builder: (context) {
                            if (state is LeaderboardLoaded) {
                              return _LeaderboardContent(
                                state: state,
                                currentUser: currentUser,
                                timeframe: _timeframe,
                                showBackButton:
                                    widget.showBackButton ?? widget.isKids,
                                onTimeframeChanged: (selected) {
                                  setState(() => _timeframe = selected);
                                },
                              );
                            } else if (state is LeaderboardLoading ||
                                state is LeaderboardInitial) {
                              return const LeaderboardShimmerLoading();
                            } else if (state is LeaderboardError) {
                              return _LeaderboardErrorView(
                                message: state.message,
                                onRetry: () =>
                                    context.read<LeaderboardBloc>().add(
                                      LoadLeaderboard(isKids: widget.isKids),
                                    ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded content — extracted to reduce BlocBuilder body complexity
// ---------------------------------------------------------------------------
class _LeaderboardContent extends StatefulWidget {
  final LeaderboardLoaded state;
  final UserEntity? currentUser;
  final LeaderboardTimeframe timeframe;
  final ValueChanged<LeaderboardTimeframe>? onTimeframeChanged;
  final bool showBackButton;

  const _LeaderboardContent({
    required this.state,
    required this.currentUser,
    this.timeframe = LeaderboardTimeframe.thisWeek,
    this.onTimeframeChanged,
    this.showBackButton = false,
  });

  @override
  State<_LeaderboardContent> createState() => _LeaderboardContentState();
}

class _LeaderboardContentState extends State<_LeaderboardContent> {
  late final ScrollController _scrollController;
  bool _ownsScrollController = false;
  bool _initialAnimateComplete = false;
  Timer? _entranceTimer;

  @override
  void initState() {
    super.initState();
    if (di.sl.isRegistered<ScrollController>(instanceName: 'leaderboard')) {
      _scrollController = di.sl<ScrollController>(instanceName: 'leaderboard');
    } else {
      _scrollController = ScrollController();
      _ownsScrollController = true;
    }
    // Only run entrance animations once on initial screen mount.
    // Recycled tiles during scrolling will render statically at native 120 FPS.
    _entranceTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _initialAnimateComplete = true);
      }
    });
  }

  @override
  void dispose() {
    _entranceTimer?.cancel();
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  /// Deterministic sort ensuring consistency across timeframes via [LeaderboardRankingHelper]:
  /// - Kids: Levels completed (primary), daily streak (tie-breaker), coins (fallback)
  /// - This Week: Weekly XP (primary), daily streak (tie-breaker), levels, total XP
  /// - All-Time: Lifetime total XP (primary), daily streak (tie-breaker), levels
  List<UserEntity> get _sortedUsers {
    if (widget.state.isKids) {
      return LeaderboardRankingHelper.sortKids(
        widget.state.users,
        currentUser: widget.currentUser,
      );
    } else if (widget.timeframe == LeaderboardTimeframe.thisWeek) {
      return LeaderboardRankingHelper.sortWeekly(
        widget.state.users,
        currentUser: widget.currentUser,
      );
    } else {
      return LeaderboardRankingHelper.sortAllTime(
        widget.state.users,
        currentUser: widget.currentUser,
      );
    }
  }

  /// Smoothly scrolls the viewport so that the current user's card lands
  /// dead-center in the visible screen (between the top pinned header and bottom bar).
  /// If the user is on the podium (ranks 1-3), it scrolls to the very top.
  /// If the user is unranked, a friendly floating info message is displayed.
  void _scrollToMe() {
    final users = _sortedUsers;
    final rankIndex = users.indexWhere((u) => u.id == widget.currentUser?.id);

    if (rankIndex < 0) {
      HapticFeedback.lightImpact();
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'leaderboard.unranked_info',
          fallback: 'Complete lessons to join the global leaderboard!',
        ),
        type: CustomSnackBarType.info,
      );
      return;
    }

    HapticFeedback.mediumImpact();

    if (!_scrollController.hasClients) return;

    // User is on the podium (ranks 1-3): scroll smoothly to top to view podium
    if (rankIndex < 3) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    // Responsive height of the podium (matches LeaderboardPodium formula)
    final screenHeight = MediaQuery.sizeOf(context).height;
    final podiumHeight = (screenHeight * 0.24).clamp(185.0, 210.0);
    final isWeekly = widget.timeframe == LeaderboardTimeframe.thisWeek;
    final bannerHeight = (!widget.state.isKids && isWeekly) ? 106.h : 0.0;
    final overtakeHudHeight =
        (!widget.state.isKids && widget.currentUser != null) ? 96.h : 0.0;

    final switchHeight = widget.state.isKids ? 0.0 : (48.h + 18.h);
    final topPadding = widget.state.isKids ? 16.h : 8.h;

    // Exact cumulative overhead before rank 4-N SliverList:
    // topPadding + header(~52.h) + switch(66.h) + banner + spacing(14.h) + podium + spacing(12.h)
    // + stickyHeaderMaxExtent(122.h) + spacing(6.h) + overtakeHud + sectionDivider(38.h)
    final overhead =
        topPadding +
        52.h +
        switchHeight +
        bannerHeight +
        14.h +
        podiumHeight +
        12.h +
        122.h +
        6.h +
        overtakeHudHeight +
        38.h;

    // Each rank tile slot in SliverList (card height + 10.h bottom spacing)
    final tileHeight = 74.h;
    final tileIndex = rankIndex - 3;
    final divisionDividerOffset =
        (!widget.state.isKids && isWeekly && tileIndex >= 7) ? 20.h : 0.0;
    final tileCenterOffset =
        overhead +
        divisionDividerOffset +
        (tileIndex * tileHeight) +
        (tileHeight / 2.0);

    // Visible viewport dimensions
    final viewportHeight = _scrollController.position.hasViewportDimension
        ? _scrollController.position.viewportDimension
        : screenHeight;
    final pinnedHeaderHeight = 70.h;
    final bottomBarPadding =
        (widget.showBackButton ? 24.h : 110.h) +
        MediaQuery.paddingOf(context).bottom;

    // Center point in visible viewport between pinned top header and bottom bar
    final visibleCenter =
        pinnedHeaderHeight +
        ((viewportHeight - pinnedHeaderHeight - bottomBarPadding) / 2.0);

    // Scroll offset so tile's vertical center lands exactly on visibleCenter
    final targetOffset = (tileCenterOffset - visibleCenter).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleClaimWeeklyLeagueReward(
    int rank,
    int vipDays,
    int coins,
    String weekKey,
  ) async {
    final currentUser = widget.currentUser;
    if (currentUser == null) return;

    final now = DateTime.now();
    final DateTime? newExpiry;
    if (vipDays > 0) {
      if (currentUser.isPremium &&
          currentUser.premiumExpiryDate != null &&
          currentUser.premiumExpiryDate!.isAfter(now)) {
        newExpiry = currentUser.premiumExpiryDate!.add(Duration(days: vipDays));
      } else {
        newExpiry = now.add(Duration(days: vipDays));
      }
    } else {
      newExpiry = null;
    }

    final updatedKeys = [...currentUser.claimedWeeklyRewardWeekKeys, weekKey];
    final coinHistoryEntry = {
      'titleKey': 'coin_history.weekly_league_reward',
      'amount': coins,
      'isEarned': true,
      'timestamp': Timestamp.now(),
    };
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.id)
          .update({
            'claimedWeeklyRewardWeekKeys': updatedKeys,
            if (coins > 0) ...{
              'coins': FieldValue.increment(coins),
              'coinHistory': FieldValue.arrayUnion([coinHistoryEntry]),
            },
            if (vipDays > 0) ...{
              'isPremium': true,
              'premiumExpiryDate': Timestamp.fromDate(newExpiry!),
            },
            'lastRewardTimestamp': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        di.sl<HapticService>().success();
        if (di.sl.isRegistered<SoundService>()) {
          di.sl<SoundService>().playCoinTally(count: 8);
        }
        context.read<AuthBloc>().add(const AuthRefreshUser());
        context.read<AuthBloc>().add(const AuthReloadUser());
        CustomSnackBar.show(
          context: context,
          message:
              '🎉 Reward Claimed! Enjoy your $vipDays day${vipDays > 1 ? "s" : ""} VIP & $coins coins.',
          type: CustomSnackBarType.success,
        );
      }
    } catch (e) {
      debugPrint('[LeaderboardScreen] Claim weekly error: $e');
    }
  }

  void _handleTileTap(UserEntity user, int rank, bool isMe) {
    final isWeekly = widget.timeframe == LeaderboardTimeframe.thisWeek;
    if (isMe) {
      PrestigeTrophySheet.show(
        context: context,
        user: user,
        rank: rank,
        isWeekly: isWeekly,
        isKids: widget.state.isKids,
        onShareRank: () => _showShareCard(user, rank),
      );
    } else if (!widget.state.isKids && widget.currentUser != null) {
      final myRank =
          _sortedUsers.indexWhere((u) => u.id == widget.currentUser!.id) + 1;
      RivalChallengeSheet.show(
        context: context,
        rival: user,
        rivalRank: rank,
        currentUser: widget.currentUser!,
        currentUserRank: myRank > 0 ? myRank : null,
        isWeekly: isWeekly,
        onStartDuel: () {
          if (di.sl.isRegistered<HapticService>()) {
            di.sl<HapticService>().selection();
          }
          context.go(AppRouter.gamesRoute);
        },
        onShareChallenge: () =>
            _showShareCard(widget.currentUser!, myRank > 0 ? myRank : 1),
      );
    }
  }

  void _showShareCard(UserEntity user, int rank) {
    final isKids = widget.state.isKids;
    final isWeekly = widget.timeframe == LeaderboardTimeframe.thisWeek;
    final score = isKids
        ? user.kidsTotalStars
        : (isWeekly ? user.currentWeeklyExp : user.totalExp);
    final data = ShareCardData.fromRank(
      userName: user.safeDisplayName,
      userPhotoUrl: user.photoUrl,
      rank: rank,
      totalXp: score,
      streak: user.currentStreak,
      referralCode: user.referralCode,
    );
    ShareCardPreviewModal.show(context: context, data: data);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    if (widget.state.users.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          final completer = Completer<void>();
          context.read<LeaderboardBloc>().add(
            LoadLeaderboard(completer: completer, isKids: widget.state.isKids),
          );
          context.read<AuthBloc>().add(const AuthRefreshUser());
          await completer.future;
        },
        color: AppColors.indigo500,
        backgroundColor: isMidnight
            ? AppColors.midnightSurface
            : (isDark ? AppColors.slate800 : Colors.white),
        displacement: 36.h,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No rankings yet',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.state.isKids
                          ? context.tr(
                              'leaderboard.kids_empty',
                              fallback: 'Be the first kid on the leaderboard!',
                            )
                          : context.tr(
                              'leaderboard.empty_subtitle',
                              fallback:
                                  'Complete lessons to appear on the leaderboard!',
                            ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final users = _sortedUsers;
    final isWeekly = widget.timeframe == LeaderboardTimeframe.thisWeek;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final rankIndex = users.indexWhere((u) => u.id == widget.currentUser?.id);
    final showFindMe = rankIndex >= 6; // Only show if not naturally visible

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            final completer = Completer<void>();
            context.read<LeaderboardBloc>().add(
              LoadLeaderboard(
                completer: completer,
                isKids: widget.state.isKids,
              ),
            );
            context.read<AuthBloc>().add(const AuthRefreshUser());
            await completer.future;
          },
          color: AppColors.indigo500,
          backgroundColor: isMidnight
              ? AppColors.midnightSurface
              : (isDark ? AppColors.slate800 : Colors.white),
          displacement: 36.h,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Top spacing
              SliverToBoxAdapter(
                child: SizedBox(height: widget.state.isKids ? 16.h : 8.h),
              ),

              // 1. Header with last-updated timestamp
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: LeaderboardHeader(
                    lastUpdated: widget.state.lastUpdated,
                    isKids: widget.state.isKids,
                    timeframe: widget.timeframe,
                    onSync: () async {
                      final completer = Completer<void>();
                      context.read<LeaderboardBloc>().add(
                        LoadLeaderboard(
                          isKids: widget.state.isKids,
                          completer: completer,
                        ),
                      );
                      await completer.future;
                    },
                  ),
                ),
              ),

              // 2. Timeframe Hero Switch (Weekly League vs Hall of Fame)
              if (!widget.state.isKids && widget.onTimeframeChanged != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.screen,
                      right: AppSpacing.screen,
                      top: 14.h,
                      bottom: 4.h,
                    ),
                    child: _LeaderboardHeroSwitch(
                      timeframe: widget.timeframe,
                      onChanged: widget.onTimeframeChanged!,
                    ),
                  ),
                ),

              // 3. Weekly League Podium Rewards Banner (Visible in Weekly mode)
              if (!widget.state.isKids && isWeekly)
                SliverToBoxAdapter(
                  child: WeeklyLeagueRewardsBanner(
                    currentUser: widget.currentUser,
                    onClaimReward: _handleClaimWeeklyLeagueReward,
                  ),
                ),

              SliverToBoxAdapter(child: SizedBox(height: 14.h)),

              // Podium (Top 3)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: RepaintBoundary(
                    child: LeaderboardPodium(
                      top3: users.take(3).toList(),
                      isKids: widget.state.isKids,
                      isWeekly: isWeekly,
                      currentUserId: widget.currentUser?.id,
                      onUserTap: (user, rank, isMe) =>
                          _handleTileTap(user, rank, isMe),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 12.h)),

              // Sticky Current User Rank (Pins to top when scrolling)
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyRankCardDelegate(
                  minHeight: 70.h,
                  maxHeight: 122.h,
                  isWeekly: isWeekly,
                  child: LeaderboardRankCard(
                    allUsers: users,
                    isKids: widget.state.isKids,
                    isWeekly: isWeekly,
                    onTap: _scrollToMe,
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 6.h)),

              // Overtake Alert HUD (XP gap to next player, dropped rank alert)
              if (!widget.state.isKids && widget.currentUser != null)
                SliverToBoxAdapter(
                  child: LeaderboardOvertakeHud(
                    allUsers: users,
                    currentUser: widget.currentUser!,
                    isWeekly: isWeekly,
                    onOvertakeTap: () => context.go(AppRouter.gamesRoute),
                  ),
                ),

              // Section label with divider
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                    vertical: 12.h,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.indigo500.withValues(alpha: 0.8),
                              IllustrationColors.brightBlue.withValues(
                                alpha: 0.4,
                              ),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        widget.state.isKids
                            ? 'Top Explorers'
                            : context.tr(
                                'leaderboard.top_challengers',
                                fallback: 'Top Challengers',
                              ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white60 : AppColors.slate600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.06),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Rank 4-N list
              if (users.length > 3)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final userIndex = index + 3;
                      if (userIndex >= users.length) {
                        return const SizedBox.shrink();
                      }
                      final user = users[userIndex];
                      final rank = userIndex + 1;
                      final isMe = widget.currentUser?.id == user.id;
                      final isLast = userIndex == users.length - 1;

                      final reduceMotion = VowlMotion.shouldReduceMotion(
                        context,
                      );
                      Widget? dividerBeforeTile;
                      if (!widget.state.isKids && isWeekly && rank == 11) {
                        dividerBeforeTile = Padding(
                          padding: EdgeInsets.only(top: 4.h, bottom: 10.h),
                          child: Row(
                            children: [
                              Container(
                                width: 6.r,
                                height: 6.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? AppColors.slate500
                                      : AppColors.slate400,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                '🏃 Contender Zone · Push for Top 10',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark
                                      ? AppColors.slate400
                                      : AppColors.slate500,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.08),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final tile = Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 10.h),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ?dividerBeforeTile,
                            LeaderboardRankTile(
                              user: user,
                              rank: rank,
                              isMe: isMe,
                              isKids: widget.state.isKids,
                              isWeekly: isWeekly,
                              onTap: () => _handleTileTap(user, rank, isMe),
                            ),
                          ],
                        ),
                      );

                      // Only animate the first 8 initially visible items on page entry.
                      // After initial entrance, recycled items render statically for 120 FPS scrolling.
                      // Removed .blurXY() to eliminate GPU rasterization bottlenecks.
                      final animatedTile =
                          (!reduceMotion &&
                              !_initialAnimateComplete &&
                              index < 8)
                          ? tile
                                .animate()
                                .fadeIn(
                                  duration: const Duration(milliseconds: 300),
                                  delay: Duration(milliseconds: index * 35),
                                  curve: Curves.easeOut,
                                )
                                .slideX(
                                  begin: 0.08,
                                  end: 0,
                                  duration: const Duration(milliseconds: 350),
                                  delay: Duration(milliseconds: index * 35),
                                  curve: Curves.easeOutCubic,
                                )
                          : tile;

                      return RepaintBoundary(
                        key: ValueKey('rank_tile_${user.id}'),
                        child: animatedTile,
                      );
                    }, childCount: widget.state.users.length - 3),
                  ),
                )
              else
                // Empty state when no users beyond top 3 (e.g. Kids Zone)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 48.h,
                      horizontal: 32.w,
                    ),
                    child: Column(
                      children: [
                        // Animated trophy icon — isolated in RepaintBoundary
                        RepaintBoundary(
                          child: reduceMotion
                              ? Icon(
                                  widget.state.isKids
                                      ? Icons.child_care_rounded
                                      : Icons.emoji_events_outlined,
                                  size: 56.r,
                                  color: isDark
                                      ? const Color(
                                          0xFF6366F1,
                                        ).withValues(alpha: 0.4)
                                      : const Color(
                                          0xFF6366F1,
                                        ).withValues(alpha: 0.3),
                                )
                              : Icon(
                                      widget.state.isKids
                                          ? Icons.child_care_rounded
                                          : Icons.emoji_events_outlined,
                                      size: 56.r,
                                      color: isDark
                                          ? const Color(
                                              0xFF6366F1,
                                            ).withValues(alpha: 0.4)
                                          : const Color(
                                              0xFF6366F1,
                                            ).withValues(alpha: 0.3),
                                    )
                                    .animate(
                                      onPlay: (c) => c.repeat(reverse: true),
                                    )
                                    .scaleXY(
                                      begin: 0.95,
                                      end: 1.05,
                                      duration: 1800.ms,
                                    )
                                    .fade(begin: 0.7, end: 1.0),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          widget.state.isKids
                              ? context.tr(
                                  'leaderboard.kids_empty',
                                  fallback:
                                      'Be the first kid on the leaderboard!',
                                )
                              : context.tr(
                                  'leaderboard.empty',
                                  fallback:
                                      'Complete more quests to climb the ranks!',
                                ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : AppColors.slate700,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          widget.state.isKids
                              ? context.tr(
                                  'leaderboard.kids_subtitle_short',
                                  fallback: 'Star Vault rankings',
                                )
                              : (widget.timeframe ==
                                      LeaderboardTimeframe.allTime
                                  ? context.tr(
                                      'leaderboard.all_time_subtitle_short',
                                      fallback: 'All-time rankings',
                                    )
                                  : context.tr(
                                      'leaderboard.weekly_subtitle_short',
                                      fallback: "This week's rankings",
                                    )),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height:
                      (widget.showBackButton ? 36.h : 120.h) +
                      MediaQuery.paddingOf(context).bottom,
                ),
              ),
            ],
          ),
        ),

        // "Find Me" FAB — only visible when user's rank is deep in the list
        if (showFindMe)
          Positioned(
            bottom:
                (widget.showBackButton ? 24.h : 104.h) +
                MediaQuery.paddingOf(context).bottom,
            right: AppSpacing.screen,
            child: Semantics(
              button: true,
              label: context.tr(
                'leaderboard.find_me_label',
                fallback: 'Scroll to my rank (#{0})',
                args: ['${rankIndex + 1}'],
              ),
              child: GestureDetector(
                onTap: _scrollToMe,
                child:
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.indigo500,
                            IllustrationColors.brightBlue,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.my_location_rounded,
                            color: Colors.white,
                            size: 16.r,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '#${rankIndex + 1}',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ).animateIf(
                      context,
                      (w) => w
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 800.ms)
                          .slideY(
                            begin: 0.3,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky Header Delegate for Rank Card
// ---------------------------------------------------------------------------

class _StickyRankCardDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;
  final bool isWeekly;

  _StickyRankCardDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
    this.isWeekly = true,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => math.max(maxHeight, minHeight);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    // When pinned (shrinkOffset > 10), content scrolls beneath this header.
    // A solid frosted backdrop + bottom shadow prevents the "ghost card"
    // overlap where glassmorphic tiles bleed through.
    final collapseProgress = (shrinkOffset / (maxExtent - minExtent)).clamp(
      0.0,
      1.0,
    );
    final isPinned = collapseProgress > 0.5 || overlapsContent;

    // PERF: Avoid heavy BackdropFilter(sigma: 24) on every scroll frame.
    // When pinned, a solid high-opacity color (0.96) occludes content beneath
    // cleanly without forcing expensive GPU offscreen render passes during scroll.
    final backdropColor =
        (isMidnight
                ? Colors.black
                : (isDark ? AppColors.slate900 : Colors.white))
            .withValues(alpha: isPinned ? 0.96 : 0.7);

    return RepaintBoundary(
      child: ClipRect(
        child: Stack(
          children: [
            // Frosted / solid backdrop that fully occludes content beneath
            Positioned.fill(child: Container(color: backdropColor)),
            // Rank card content — centered vertically with generous padding
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: 6.h,
              ),
              child: OverflowBox(
                minHeight: 0,
                maxHeight: double.infinity,
                alignment: Alignment.center,
                child: LeaderboardRankCard(
                  allUsers: (child as LeaderboardRankCard).allUsers,
                  isKids: (child as LeaderboardRankCard).isKids,
                  isWeekly: isWeekly,
                  collapseProgress: collapseProgress,
                  onTap: (child as LeaderboardRankCard).onTap,
                ),
              ),
            ),
            // Bottom shadow/divider — only visible when pinned
            if (isPinned)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        (isDark ? Colors.white : Colors.black).withValues(
                          alpha: 0.08,
                        ),
                        (isDark ? Colors.white : Colors.black).withValues(
                          alpha: 0.08,
                        ),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.2, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyRankCardDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        isWeekly != oldDelegate.isWeekly ||
        child != oldDelegate.child;
  }
}

// ---------------------------------------------------------------------------
// Error view with retry — previously just a plain Text
// ---------------------------------------------------------------------------

class _LeaderboardErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LeaderboardErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48.r,
              color: Colors.red.withValues(alpha: 0.6),
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                context.tr('common.retry', fallback: 'Retry'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Primary Hero Segmented Switch: Weekly League vs Hall of Fame
// ---------------------------------------------------------------------------

class _LeaderboardHeroSwitch extends StatelessWidget {
  final LeaderboardTimeframe timeframe;
  final ValueChanged<LeaderboardTimeframe> onChanged;

  const _LeaderboardHeroSwitch({
    required this.timeframe,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final isWeekly = timeframe == LeaderboardTimeframe.thisWeek;

    return Container(
      height: 48.h,
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: isMidnight
            ? AppColors.midnightSurface
            : (isDark ? const Color(0xFF0F172A) : AppColors.slate100),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isMidnight
              ? Colors.white.withValues(alpha: 0.12)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.slate200),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isWeekly) return;
                HapticFeedback.lightImpact();
                onChanged(LeaderboardTimeframe.thisWeek);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  gradient: isWeekly
                      ? const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isWeekly ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.zap,
                        size: 15.sp,
                        color: isWeekly
                            ? Colors.white
                            : (isDark ? Colors.white60 : AppColors.slate600),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        context.tr(
                          'leaderboard.weekly_league',
                          fallback: 'Weekly League',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                          color: isWeekly
                              ? Colors.white
                              : (isDark ? Colors.white70 : AppColors.slate700),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isWeekly) return;
                HapticFeedback.lightImpact();
                onChanged(LeaderboardTimeframe.allTime);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  gradient: !isWeekly
                      ? const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: !isWeekly ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.trophy,
                        size: 15.sp,
                        color: !isWeekly
                            ? Colors.white
                            : (isDark ? Colors.white60 : AppColors.slate600),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        context.tr(
                          'leaderboard.hall_of_fame',
                          fallback: 'Hall of Fame',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                          color: !isWeekly
                              ? Colors.white
                              : (isDark ? Colors.white70 : AppColors.slate700),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
