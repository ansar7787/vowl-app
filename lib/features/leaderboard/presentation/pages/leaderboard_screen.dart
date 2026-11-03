import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
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
import 'package:vowl/features/leaderboard/presentation/widgets/leaderboard_podium.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/leaderboard_rank_card.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/leaderboard_rank_tile.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/pages/arena_duel_screen.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/leaderboard_overtake_hud.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/weekly_league_rewards_banner.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/rival_challenge_sheet.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/prestige_trophy_sheet.dart';
import 'package:vowl/features/social_share/domain/entities/share_card_data.dart';
import 'package:vowl/features/social_share/presentation/widgets/share_card_preview_modal.dart';

/// Main leaderboard rankings screen featuring podium top 3 positions,
/// personal rank card, and toggleable standard/kids leaderboards.
class LeaderboardScreen extends StatefulWidget {
  final bool isKids;
  const LeaderboardScreen({super.key, this.isKids = false});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final ValueNotifier<bool> _isKidsMode;

  @override
  void initState() {
    super.initState();
    _isKidsMode = ValueNotifier(widget.isKids);
  }

  @override
  void dispose() {
    _isKidsMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // FIX (MEDIUM-1): Use context.select instead of context.watch to scope
    // rebuilds to only the isMidnight boolean, not the entire ThemeCubit state.
    final isMidnight =
        (Theme.of(context).brightness == Brightness.dark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black);
    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? AppColors.slate900 : AppColors.white);

    return BlocProvider(
      create: (_) =>
          di.sl<LeaderboardBloc>()
            ..add(LoadLeaderboard(isKids: _isKidsMode.value)),
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

                // Content Layer
                Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + 8.h),

                    ValueListenableBuilder<bool>(
                      valueListenable: _isKidsMode,
                      builder: (context, isKidsMode, _) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 4.h,
                          ),
                          child: _LeaderboardToggle(
                            isKidsMode: isKidsMode,
                            onToggle: (bool isKids) {
                              if (isKidsMode == isKids) return;
                              _isKidsMode.value = isKids;
                              context.read<LeaderboardBloc>().add(
                                LoadLeaderboard(isKids: isKids),
                              );
                            },
                          ),
                        );
                      },
                    ),

                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if (state is LeaderboardLoaded) {
                            return _LeaderboardContent(
                              state: state,
                              currentUser: currentUser,
                            );
                          } else if (state is LeaderboardLoading ||
                              state is LeaderboardInitial) {
                            return const LeaderboardShimmerLoading();
                          } else if (state is LeaderboardError) {
                            return _LeaderboardErrorView(
                              message: state.message,
                              onRetry: () =>
                                  context.read<LeaderboardBloc>().add(
                                    LoadLeaderboard(isKids: _isKidsMode.value),
                                  ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
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

  const _LeaderboardContent({required this.state, required this.currentUser});

  @override
  State<_LeaderboardContent> createState() => _LeaderboardContentState();
}

class _LeaderboardContentState extends State<_LeaderboardContent> {
  late final ScrollController _scrollController;
  bool _ownsScrollController = false;

  @override
  void initState() {
    super.initState();
    if (di.sl.isRegistered<ScrollController>(instanceName: 'leaderboard')) {
      _scrollController = di.sl<ScrollController>(instanceName: 'leaderboard');
    } else {
      _scrollController = ScrollController();
      _ownsScrollController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  LeaderboardTimeframe _timeframe = LeaderboardTimeframe.thisWeek;

  /// Deterministic sort ensuring consistency across timeframes:
  /// - Kids: Levels completed (primary), daily streak (tie-breaker), coins (fallback)
  /// - This Week: Weekly XP (primary), daily streak (tie-breaker), levels, total XP
  /// - All-Time: Lifetime total XP (primary), daily streak (tie-breaker), levels
  List<UserEntity> get _sortedUsers {
    final list = List<UserEntity>.from(widget.state.users);
    if (widget.state.isKids) {
      list.sort((a, b) {
        final aLevels = a.kidsTotalLevelsCompleted;
        final bLevels = b.kidsTotalLevelsCompleted;
        if (bLevels != aLevels) return bLevels.compareTo(aLevels);
        if (b.currentStreak != a.currentStreak) {
          return b.currentStreak.compareTo(a.currentStreak);
        }
        return b.kidsCoins.compareTo(a.kidsCoins);
      });
    } else if (_timeframe == LeaderboardTimeframe.thisWeek) {
      list.sort((a, b) {
        final aWeekly = a.currentWeeklyExp;
        final bWeekly = b.currentWeeklyExp;
        if (bWeekly != aWeekly) return bWeekly.compareTo(aWeekly);
        if (b.currentStreak != a.currentStreak) {
          return b.currentStreak.compareTo(a.currentStreak);
        }
        if (b.totalLevelsCompleted != a.totalLevelsCompleted) {
          return b.totalLevelsCompleted.compareTo(a.totalLevelsCompleted);
        }
        return b.totalExp.compareTo(a.totalExp);
      });
    } else {
      list.sort((a, b) {
        if (b.totalExp != a.totalExp) {
          return b.totalExp.compareTo(a.totalExp);
        }
        if (b.currentStreak != a.currentStreak) {
          return b.currentStreak.compareTo(a.currentStreak);
        }
        return b.totalLevelsCompleted.compareTo(a.totalLevelsCompleted);
      });
    }
    return list;
  }

  /// Smoothly scrolls the viewport so that the current user's card lands
  /// dead-center in the visible screen (between the top pinned header and bottom bar).
  /// If the user is on the podium (ranks 1-3), it scrolls to the very top.
  /// If the user is unranked, a friendly floating info message is displayed.
  void _scrollToMe() {
    final users = _sortedUsers;
    final rankIndex = users.indexWhere(
      (u) => u.id == widget.currentUser?.id,
    );

    if (rankIndex < 0) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'leaderboard.unranked_info',
              fallback: 'Complete lessons to join the global leaderboard!',
            ),
            style: const TextStyle(fontFamily: 'Outfit'),
          ),
          backgroundColor: AppColors.slate800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          duration: const Duration(seconds: 3),
        ),
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
    final podiumHeight = (screenHeight * 0.40).clamp(220.0, 320.0);

    // Exact cumulative overhead before rank 4-N SliverList:
    // topPadding(16.h) + header(~52.h) + spacing(24.h) + podium + spacing(12.h)
    // + stickyHeaderMaxExtent(145.h) + sectionDivider(38.h)
    final overhead = 16.h + 52.h + 24.h + podiumHeight + 12.h + 145.h + 38.h;

    // Each rank tile slot in SliverList (card height + 10.h bottom spacing)
    final tileHeight = 74.h;
    final tileIndex = rankIndex - 3;
    final tileCenterOffset = overhead + (tileIndex * tileHeight) + (tileHeight / 2.0);

    // Visible viewport dimensions
    final viewportHeight = _scrollController.position.hasViewportDimension
        ? _scrollController.position.viewportDimension
        : screenHeight;
    final pinnedHeaderHeight = 88.h;
    final bottomBarPadding = 104.h + MediaQuery.paddingOf(context).bottom;

    // Center point in visible viewport between pinned top header and bottom bar
    final visibleCenter = pinnedHeaderHeight +
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
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser.id).update({
        'claimedWeeklyRewardWeekKeys': updatedKeys,
        if (coins > 0) 'coins': FieldValue.increment(coins),
        if (vipDays > 0) ...{
          'isPremium': true,
          'premiumExpiryDate': Timestamp.fromDate(newExpiry!),
        },
        'lastRewardTimestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.emerald500,
            content: Text(
              '🎉 Reward Claimed! Enjoy your $vipDays day${vipDays > 1 ? "s" : ""} VIP & $coins coins.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[LeaderboardScreen] Claim weekly error: $e');
    }
  }

  void _handleTileTap(UserEntity user, int rank, bool isMe) {
    if (isMe) {
      PrestigeTrophySheet.show(
        context: context,
        user: user,
        rank: rank,
        onShareRank: () => _showShareCard(user, rank),
      );
    } else if (!widget.state.isKids && widget.currentUser != null) {
      RivalChallengeSheet.show(
        context: context,
        rival: user,
        rivalRank: rank,
        currentUser: widget.currentUser!,
        onStartDuel: () => _startDuelWithRival(user, rank),
        onShareRoomCode: () => _shareRoomCodeChallenge(user),
      );
    }
  }

  void _startDuelWithRival(UserEntity rival, int rank) async {
    final currentUser = widget.currentUser;
    if (currentUser == null) return;

    if (currentUser.coins < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need at least 30 coins to enter a duel stake!'),
          backgroundColor: AppColors.rose500,
        ),
      );
      return;
    }

    try {
      final repo = di.sl<ArenaRepository>();
      final session = await repo.challengeRivalDirectly(
        currentUser: currentUser,
        rival: rival,
        rivalRank: rank,
      );
      if (mounted) {
        Navigator.of(context).push(ArenaDuelScreen.route(session: session));
      }
    } catch (e) {
      debugPrint('[LeaderboardScreen] Start duel error: $e');
    }
  }

  void _startQuickMatch() async {
    final currentUser = widget.currentUser;
    if (currentUser == null) return;

    if (currentUser.coins < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need at least 30 coins to enter a duel stake!'),
          backgroundColor: AppColors.rose500,
        ),
      );
      return;
    }

    try {
      final repo = di.sl<ArenaRepository>();
      final session = await repo.quickMatch(
        currentUser: currentUser,
        leaderboardUsers: _sortedUsers,
      );
      if (mounted) {
        Navigator.of(context).push(ArenaDuelScreen.route(session: session));
      }
    } catch (e) {
      debugPrint('[LeaderboardScreen] Quick match error: $e');
    }
  }

  void _shareRoomCodeChallenge(UserEntity rival) async {
    final currentUser = widget.currentUser;
    if (currentUser == null) return;

    if (currentUser.coins < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need at least 30 coins to create a duel stake!'),
          backgroundColor: AppColors.rose500,
        ),
      );
      return;
    }

    try {
      final repo = di.sl<ArenaRepository>();
      final session = await repo.createRoomCode(currentUser: currentUser);
      final message = '⚔️ I bet 30 coins you can\'t beat my score on Vowl!\n'
          'Enter room code ${session.roomCode} to duel me now:\n'
          'https://vowl.app/duel/${session.roomCode}';
      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: '1v1 English Duel Challenge!',
        ),
      );
      if (mounted) {
        Navigator.of(context).push(ArenaDuelScreen.route(session: session));
      }
    } catch (e) {
      debugPrint('[LeaderboardScreen] Share room code error: $e');
    }
  }

  void _showShareCard(UserEntity user, int rank) {
    final data = ShareCardData.fromRank(
      userName: user.safeDisplayName,
      userPhotoUrl: user.photoUrl,
      rank: rank,
      totalXp: user.totalExp,
      streak: user.currentStreak,
      referralCode: user.referralCode,
    );
    ShareCardPreviewModal.show(context: context, data: data);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.state.users.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          final completer = Completer<void>();
          context.read<LeaderboardBloc>().add(
            LoadLeaderboard(completer: completer, isKids: widget.state.isKids),
          );
          await completer.future;
        },
        backgroundColor: Colors.transparent,
        color: AppColors.indigo500,
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
                    const Text(
                      'Complete lessons to appear on the leaderboard!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
    final isWeekly = _timeframe == LeaderboardTimeframe.thisWeek;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final rankIndex = users.indexWhere(
      (u) => u.id == widget.currentUser?.id,
    );
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
            await completer.future;
          },
          backgroundColor: Colors.transparent,
          color: AppColors.indigo500,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Padding to push content slightly below AppBar
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),

              // Header with last-updated timestamp
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: LeaderboardHeader(
                    lastUpdated: widget.state.lastUpdated,
                    isKids: widget.state.isKids,
                  ),
                ),
              ),

              // Timeframe selector (This Week vs All-Time Hall of Fame)
              if (!widget.state.isKids)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 4.h),
                    child: _LeaderboardTimeframeSelector(
                      timeframe: _timeframe,
                      onChanged: (selected) {
                        setState(() => _timeframe = selected);
                      },
                    ),
                  ),
                ),

              // Weekly League Podium Rewards Banner (Visible in Weekly mode)
              if (!widget.state.isKids && isWeekly)
                SliverToBoxAdapter(
                  child: WeeklyLeagueRewardsBanner(
                    currentUser: widget.currentUser,
                    onClaimReward: _handleClaimWeeklyLeagueReward,
                    onQuickMatch: _startQuickMatch,
                  ),
                ),

              // All-Time Hall of Fame Banner (Visible in All-Time mode)
              if (!widget.state.isKids && !isWeekly)
                const SliverToBoxAdapter(
                  child: _HallOfFameBanner(),
                ),

              SliverToBoxAdapter(child: SizedBox(height: 18.h)),

              // Podium (Top 3)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: LeaderboardPodium(
                    top3: users.take(3).toList(),
                    isKids: widget.state.isKids,
                    isWeekly: isWeekly,
                    currentUserId: widget.currentUser?.id,
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 12.h)),

              // Sticky Current User Rank (Pins to top when scrolling)
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyRankCardDelegate(
                  minHeight: 88.h,
                  maxHeight: 145.h,
                  child: LeaderboardRankCard(
                    allUsers: users,
                    isKids: widget.state.isKids,
                    isWeekly: isWeekly,
                    onTap: _scrollToMe,
                  ),
                ),
              ),

              // Overtake Alert HUD (XP gap to next player, dropped rank alert)
              if (!widget.state.isKids && widget.currentUser != null)
                SliverToBoxAdapter(
                  child: LeaderboardOvertakeHud(
                    allUsers: users,
                    currentUser: widget.currentUser!,
                    isWeekly: isWeekly,
                    onOvertakeTap: () => context.push(AppRouter.gamesRoute),
                  ),
                ),

              // Section label with divider
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
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
                        context.tr(
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
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
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
                      final tile = Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 10.h),
                        child: LeaderboardRankTile(
                          user: user,
                          rank: rank,
                          isMe: isMe,
                          isKids: widget.state.isKids,
                          isWeekly: isWeekly,
                          onTap: () => _handleTileTap(user, rank, isMe),
                        ),
                      );

                      // Only animate the first 8 initially visible items on page entry.
                      // Off-screen items scroll into view without animation overhead.
                      // Removed .blurXY() to eliminate GPU rasterization bottlenecks.
                      final animatedTile = (!reduceMotion && index < 8)
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
                                  'leaderboard.kids_subtitle',
                                  fallback:
                                      'See how your child ranks globally!',
                                )
                              : context.tr(
                                  'leaderboard.subtitle',
                                  fallback: 'See how you rank globally!',
                                ),
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
                  height: 120.h + MediaQuery.paddingOf(context).bottom,
                ),
              ),
            ],
          ),
        ),

        // "Find Me" FAB — only visible when user's rank is deep in the list
        if (showFindMe)
          Positioned(
            bottom: 104.h + MediaQuery.paddingOf(context).bottom,
            right: 20.w,
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
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                              .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
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

  _StickyRankCardDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
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
    final backdropColor = (isMidnight
            ? Colors.black
            : (isDark ? AppColors.slate900 : Colors.white))
        .withValues(alpha: isPinned ? 0.96 : 0.7);

    return ClipRect(
      child: Stack(
        children: [
          // Frosted / solid backdrop that fully occludes content beneath
          Positioned.fill(child: Container(color: backdropColor)),
          // Rank card content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24.w,
              vertical: 12.h - (4.h * collapseProgress),
            ),
            child: OverflowBox(
              minHeight: 0,
              maxHeight: double.infinity,
              alignment: Alignment.topCenter,
              child: LeaderboardRankCard(
                allUsers: (child as LeaderboardRankCard).allUsers,
                isKids: (child as LeaderboardRankCard).isKids,
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
    );
  }

  @override
  bool shouldRebuild(_StickyRankCardDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
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

class _LeaderboardToggle extends StatelessWidget {
  final bool isKidsMode;
  final ValueChanged<bool> onToggle;

  const _LeaderboardToggle({required this.isKidsMode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48.h,
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.4)
            : AppColors.slate100,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.slate100,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onToggle(false);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: !isKidsMode ? AppColors.indigo500 : Colors.transparent,
                  borderRadius: BorderRadius.circular(21.r),
                  boxShadow: !isKidsMode
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.public_rounded,
                        color: !isKidsMode
                            ? Colors.white
                            : (isDark ? Colors.white60 : AppColors.slate600),
                        size: 15.r,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        context.tr(
                          'leaderboard.global_ranks',
                          fallback: 'Global Ranks',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                          color: !isKidsMode
                              ? Colors.white
                              : (isDark ? Colors.white60 : AppColors.slate600),
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
                HapticFeedback.lightImpact();
                onToggle(true);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: isKidsMode ? AppColors.rose500 : Colors.transparent,
                  borderRadius: BorderRadius.circular(21.r),
                  boxShadow: isKidsMode
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFFF43F5E,
                            ).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.child_care_rounded,
                        color: isKidsMode
                            ? Colors.white
                            : (isDark ? Colors.white60 : AppColors.slate600),
                        size: 15.r,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        context.tr(
                          'leaderboard.kids_zone',
                          fallback: 'Kids Zone',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                          color: isKidsMode
                              ? Colors.white
                              : (isDark ? Colors.white60 : AppColors.slate600),
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

// ---------------------------------------------------------------------------
// Timeframe enumeration & selector
// ---------------------------------------------------------------------------

enum LeaderboardTimeframe {
  thisWeek,
  allTime,
}

class _LeaderboardTimeframeSelector extends StatelessWidget {
  final LeaderboardTimeframe timeframe;
  final ValueChanged<LeaderboardTimeframe> onChanged;

  const _LeaderboardTimeframeSelector({
    required this.timeframe,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final isWeekly = timeframe == LeaderboardTimeframe.thisWeek;

    return Container(
      height: 38.h,
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: isMidnight
            ? AppColors.midnightSurface
            : (isDark ? const Color(0xFF0F172A) : AppColors.slate100),
        borderRadius: BorderRadius.circular(19.r),
        border: Border.all(
          color: isMidnight
              ? Colors.white.withValues(alpha: 0.12)
              : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate100),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onChanged(LeaderboardTimeframe.thisWeek);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: isWeekly ? AppColors.indigo500 : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: isWeekly
                      ? [
                          BoxShadow(
                            color: AppColors.indigo500.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.zap,
                        size: 13.sp,
                        color: isWeekly ? Colors.white : (isDark ? Colors.white60 : AppColors.slate600),
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        'This Week (League)',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                          color: isWeekly ? Colors.white : (isDark ? Colors.white60 : AppColors.slate600),
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
                HapticFeedback.lightImpact();
                onChanged(LeaderboardTimeframe.allTime);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: !isWeekly ? AppColors.amber500 : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: !isWeekly
                      ? [
                          BoxShadow(
                            color: AppColors.amber500.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.crown,
                        size: 13.sp,
                        color: !isWeekly ? Colors.white : (isDark ? Colors.white60 : AppColors.slate600),
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        'All-Time (Hall of Fame)',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                          color: !isWeekly ? Colors.white : (isDark ? Colors.white60 : AppColors.slate600),
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

// ---------------------------------------------------------------------------
// All-Time Hall of Fame Banner
// ---------------------------------------------------------------------------

class _HallOfFameBanner extends StatelessWidget {
  const _HallOfFameBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final surfaceColor = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? const Color(0xFF0F172A) : Colors.white);
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate100);
    final titleColor = isDark ? Colors.white : AppColors.slate900;
    final subColor = isDark ? AppColors.slate400 : AppColors.slate600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.amber500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(LucideIcons.crown, color: AppColors.amber500, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hall of Fame Masters',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Lifetime XP earned across all quests & practice duels',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
