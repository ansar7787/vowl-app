import 'dart:async';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/home/presentation/widgets/global_progress_card.dart';
import 'package:vowl/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:vowl/features/leaderboard/domain/utils/leaderboard_ranking_helper.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/features/home/presentation/widgets/bento_arena.dart';
import 'package:vowl/features/home/presentation/widgets/home_hero_header.dart';
import 'package:vowl/features/home/presentation/widgets/continue_learning_card.dart';
import 'package:vowl/features/home/presentation/widgets/inline_notification_card.dart';
import 'package:vowl/features/home/presentation/widgets/discovery_deck.dart';
import 'package:vowl/features/home/presentation/widgets/daily_motivation_card.dart';
import 'package:vowl/features/home/presentation/widgets/daily_mystery_chest_card.dart';
import 'package:vowl/features/home/presentation/widgets/weekly_league_reward_home_card.dart';
import 'package:vowl/features/home/presentation/widgets/home_section_header.dart';
import 'package:vowl/features/home/presentation/widgets/unified_stats_row.dart';
import 'package:vowl/features/home/presentation/widgets/beginner_milestone_card.dart';
import 'package:vowl/features/home/presentation/widgets/daily_words_sprint_card.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/onboarding_service.dart';
import 'package:vowl/features/referral/domain/repositories/referral_repository.dart';
import 'package:vowl/features/referral/presentation/utils/referral_clipboard_detector.dart';

/// Primary home dashboard screen presenting daily activities, streak stats, and arenas.
class HomeScreen extends StatefulWidget {
  /// Creates a [HomeScreen].
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ValueNotifier<int?> _globalRank = ValueNotifier(null);
  final ValueNotifier<bool> _isRankLoading = ValueNotifier(true);
  bool _bypassBeginnerGate = false;

  final math.Random _random = math.Random();
  late final ConfettiController _confettiController;
  final ValueNotifier<List<Map<String, dynamic>>> _activeCoins = ValueNotifier(
    [],
  );

  static const List<Color> _celebrationConfettiColors = [
    Color(0xFFFFD700), // Brilliant Gold
    AppColors.amber500, // Warm Amber
    AppColors.emerald500, // Emerald Green
    AppColors.rose500, // Festive Rose
    AppColors.violet500, // Royal Violet
    Color(0xFF38BDF8), // Electric Sky Blue
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1400),
    );
    _fetchGlobalRank();
    // Initial check for reward availability
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated) {
        context.read<EconomyBloc>().add(
          const EconomyCheckDailyRewardRequested(),
        );
        if (authState.user != null) {
          OnboardingService.evaluateUserProgress(
            authState.user!.totalLevelsCompleted,
          );
          if (!authState.user!.hasClaimedReferral) {
            ReferralClipboardDetector.checkAndPrompt(
              context: context,
              user: authState.user!,
              onClaim: (code) async {
                final repo = di.sl<ReferralRepository>();
                final result = await repo.claimReferralCode(
                  code: code,
                  user: authState.user!,
                );
                if (mounted) {
                  CustomSnackBar.show(
                    context: context,
                    message: result.message,
                    type: result.success
                        ? CustomSnackBarType.success
                        : CustomSnackBarType.error,
                  );
                  if (result.success) {
                    context.read<AuthBloc>().add(const AuthRefreshUser());
                  }
                }
              },
            );
          }
        }
      }
    });
  }

  Future<void> _fetchGlobalRank() async {
    _isRankLoading.value = true;
    try {
      final repo = di.sl<LeaderboardRepository>();
      final result = await repo.getTopUsers(limit: 100);

      // CRITICAL: this is an async gap — the widget may have been disposed
      // (e.g. the user logged out / navigated away) while the request was
      // in flight. Reading `context` or calling `setState` past this point
      // without checking `mounted` first risks
      // "Looking up a deactivated widget's ancestor is unsafe".
      if (!mounted) return;

      result.fold(
        (_) {
          if (mounted) _isRankLoading.value = false;
        },
        (data) {
          final currentUser = context.read<AuthBloc>().state.user;
          final sorted = LeaderboardRankingHelper.sortAllTime(
            data.users,
            currentUser: currentUser,
          );
          if (currentUser != null && mounted) {
            _globalRank.value = LeaderboardRankingHelper.getRankPosition(
              sorted,
              currentUser.id,
            );
          }
          if (mounted) _isRankLoading.value = false;
        },
      );
    } catch (e) {
      if (mounted) _isRankLoading.value = false;
      // Leaderboard rank is a "nice to have" enhancement on this screen —
      // never let it crash or block the home feed. Keep a debug-only trace
      // so a real regression doesn't go unnoticed during development.
      if (kDebugMode) {
        debugPrint('HomeScreen: failed to fetch global rank: $e');
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _activeCoins.dispose();
    _globalRank.dispose();
    _isRankLoading.dispose();
    super.dispose();
  }

  void _spawnCoins({required Offset originOffset, required int coins}) {
    if (!VowlMotion.shouldReduceMotion(context)) {
      _confettiController.play();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    // Target is the Coins pill inside HomeHeroHeader's top right dual-metric HUD
    final targetOffset = Offset(screenWidth - 48.w, topPadding + 28.h);

    final count = math.min(15, math.max(8, coins ~/ 3));
    final newCoins = <Map<String, dynamic>>[];
    for (int i = 0; i < count; i++) {
      final id = DateTime.now().millisecondsSinceEpoch + i;
      final spreadX = (_random.nextDouble() - 0.5) * 80.w;
      final spreadY = (_random.nextDouble() - 0.5) * 24.h;

      newCoins.add({
        'id': id,
        'startX': originOffset.dx + spreadX,
        'startY': originOffset.dy + spreadY,
        'targetX': targetOffset.dx,
        'targetY': targetOffset.dy,
        'delay': i * 60,
      });
    }
    // Batch assign once — avoids 15 duplicate widget rebuilds
    _activeCoins.value = newCoins;

    // Clean up entire coin layer once the final coin has arrived and show success snackbar
    Future.delayed(Duration(milliseconds: 950 + (count * 60)), () {
      if (mounted) {
        _activeCoins.value = [];
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'home.chest_coins_claimed_snackbar',
            fallback: 'Awesome! You received +{0} coins!',
            args: [coins.toString()],
          ),
          type: CustomSnackBarType.success,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == AuthStatus.authenticated) {
                context.read<EconomyBloc>().add(
                  const EconomyCheckDailyRewardRequested(),
                );
                if (state.user != null) {
                  OnboardingService.evaluateUserProgress(
                    state.user!.totalLevelsCompleted,
                  );
                }
              } else if (state.status == AuthStatus.unauthenticated) {
                context.read<EconomyBloc>().add(const EconomyResetRequested());
                context.read<ProgressionBloc>().add(
                  const ProgressionResetRequested(),
                );
                _globalRank.value = null;
                _isRankLoading.value = false;
              }
            },
          ),
        ],
        // BlocBuilder with buildWhen prevents unrelated AuthState changes
        // from forcing a full rebuild of the heavy widget tree below.
        child: BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (previous, current) =>
              previous.user != current.user ||
              (previous.user == null && previous.message != current.message),
          builder: (context, state) {
            if (state.user == null && state.message != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextButton.icon(
                      onPressed: () =>
                          context.read<AuthBloc>().add(const AuthReloadUser()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            final user = state.user;
            if (user == null) return const HomeShimmerLoading();

            return Stack(
              children: [
                const MeshGradientBackground(showLetters: false),
                RefreshIndicator(
                  onRefresh: () async {
                    context.read<AuthBloc>().add(const AuthReloadUser());
                    // Re-check daily reward availability on pull-to-refresh
                    context.read<EconomyBloc>().add(
                      const EconomyCheckDailyRewardRequested(),
                    );
                    _fetchGlobalRank();
                    await Future.delayed(const Duration(milliseconds: 600));
                  },
                  color: AppColors.indigo500,
                  displacement: 40.h,
                  child: CustomScrollView(
                    controller: di.sl<ScrollController>(instanceName: 'home'),
                    cacheExtent: 350.0,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      // ---------------- Top Safe Area ----------------
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).padding.top + 16.h,
                        ),
                      ),

                      // --------------------------------------------------
                      // 1. HERO HEADER (Identity & XP)
                      // --------------------------------------------------
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.screen,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: HomeHeroHeader(user: user),
                        ),
                      ),

                      // --------------------------------------------------
                      // 1.5 INLINE NOTIFICATION (Conditional)
                      // --------------------------------------------------
                      SliverToBoxAdapter(
                        child: InlineNotificationCard(
                          streak: user.currentStreak,
                        ),
                      ),

                      // --------------------------------------------------
                      // 1.55 WEEKLY LEAGUE REWARD CLAIM (Conditional Inline)
                      // --------------------------------------------------
                      SliverToBoxAdapter(
                        child: WeeklyLeagueRewardHomeCard(user: user),
                      ),

                      // --------------------------------------------------
                      // 1.6 DAILY MYSTERY CHEST (Conditional Inline Claim)
                      // --------------------------------------------------
                      SliverToBoxAdapter(
                        child: DailyMysteryChestCard(onClaimed: _spawnCoins),
                      ),

                      // --------------------------------------------------
                      // 2. PRIMARY CTA — "Continue Learning"
                      // --------------------------------------------------
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.screen,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              SizedBox(height: 16.h),
                              ContinueLearningCard(user: user),
                              SizedBox(height: 14.h),
                              const DailyWordsSprintCard(),
                            ],
                          ),
                        ),
                      ),

                      // --------------------------------------------------
                      // 3. UNIFIED STATS ROW (Streak | Coins | Badges | Level)
                      // --------------------------------------------------
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.screen,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              SizedBox(height: 14.h),
                              ValueListenableBuilder<bool>(
                                valueListenable: _isRankLoading,
                                builder: (context, isRankLoading, _) {
                                  return ValueListenableBuilder<int?>(
                                    valueListenable: _globalRank,
                                    builder: (context, rank, child) {
                                      return UnifiedStatsRow(
                                        user: user,
                                        globalRank: rank,
                                        isRankLoading: isRankLoading,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // --------------------------------------------------
                      // 4. PROGRESSIVE RPG GATING (Beginner Lock vs Full Cockpit)
                      // --------------------------------------------------
                      if (!_bypassBeginnerGate &&
                          user.totalLevelsCompleted < 2) ...[
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.screen,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              children: [
                                SizedBox(height: 24.h),
                                BeginnerMilestoneCard(
                                  user: user,
                                  onUnlockNow: () => setState(
                                    () => _bypassBeginnerGate = true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // --------------------------------------------------
                        // 4. DAILY PRACTICE (Micro-Workouts & Targeted Skill Drills)
                        // --------------------------------------------------
                        HomeSliverSectionHeader(
                          title: context.tr(
                            'home.daily_practice_title',
                            fallback: 'Daily Practice',
                          ),
                          subtitle: context.tr(
                            'home.daily_practice_subtitle',
                            fallback: 'Targeted daily workouts',
                          ),
                          categoryColor: IllustrationColors.brightBlue,
                          onSeeAll: () => context.push(AppRouter.libraryRoute),
                        ),
                        SliverToBoxAdapter(
                          child: DiscoveryDeck(
                            user: user,
                            onLaunchQuest: (id) =>
                                _launchThemedQuest(context, id),
                          ),
                        ),

                        // --------------------------------------------------
                        // 5. CURRICULUM BENTO ARENA + WEAK-SPOT REVIEW
                        // --------------------------------------------------
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.screen,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              children: [
                                SizedBox(height: 24.h),
                                HomeSectionHeader(
                                  title: context.tr(
                                    'home.quest_arena_title',
                                    fallback: 'Quest Arena',
                                  ),
                                  subtitle: context.tr(
                                    'home.quest_arena_subtitle',
                                    fallback: 'Pick up where you left off',
                                  ),
                                  localizedTitleKey: 'home.quest_arena_title',
                                  localizedSubtitleKey:
                                      'home.quest_arena_subtitle',
                                  categoryColor: AppColors.indigo500,
                                  onSeeAll: () =>
                                      context.push(AppRouter.libraryRoute),
                                ),
                                BentoArena(user: user, collapsed: true),
                              ],
                            ),
                          ),
                        ),

                        // --------------------------------------------------
                        // 6. PROGRESS CARD (Total levels + Rank)
                        // --------------------------------------------------
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.screen,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              children: [
                                SizedBox(height: 24.h),
                                ValueListenableBuilder<int?>(
                                  valueListenable: _globalRank,
                                  builder: (context, rank, child) {
                                    return GlobalProgressCard(
                                      user: user,
                                      globalRank: rank,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                      ],

                      // --------------------------------------------------
                      // 7. DAILY NOTE / LANGUAGE NOTE
                      // --------------------------------------------------
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.screen,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            SizedBox(height: 24.h),
                            DailyMotivationCard(
                              streakCount: user.currentStreak,
                            ),
                            SizedBox(
                              height:
                                  120.h +
                                  MediaQuery.paddingOf(context).bottom +
                                  24.h,
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Celebratory Full-Screen Multi-Color Confetti ─────────────
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      colors: _celebrationConfettiColors,
                      numberOfParticles: 30,
                      emissionFrequency: 0.04,
                      gravity: 0.25,
                    ),
                  ),
                ),

                // ── Floating Luxury Gold Coins Trajectory Layer ─────────────
                IgnorePointer(
                  child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: _activeCoins,
                    builder: (context, coins, _) {
                      return Stack(
                        children: coins.map((coin) {
                          return _HomeFloatingCoin(
                            startX: coin['startX'],
                            startY: coin['startY'],
                            targetX: coin['targetX'],
                            targetY: coin['targetY'],
                            delay: coin['delay'],
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _launchThemedQuest(BuildContext context, String questId) async {
    try {
      Haptics.vibrate(HapticsType.medium);
    } catch (e) {
      if (kDebugMode) debugPrint('HomeScreen: haptics unavailable: $e');
    }
    await context.push(
      '${AppRouter.questSequenceRoute}?id=${Uri.encodeQueryComponent(questId)}',
    );
    DiscoveryDeck.notifySequenceCompleted();
  }
}

/// A luxury gold coin widget that arcs smoothly from the mystery chest card
/// into the top-right Coins HUD capsule in [HomeHeroHeader].
class _HomeFloatingCoin extends StatefulWidget {
  final double startX, startY, targetX, targetY;
  final int delay;

  const _HomeFloatingCoin({
    required this.startX,
    required this.startY,
    required this.targetX,
    required this.targetY,
    required this.delay,
  });

  @override
  State<_HomeFloatingCoin> createState() => _HomeFloatingCoinState();
}

class _HomeFloatingCoinState extends State<_HomeFloatingCoin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animX;
  late Animation<double> _animY;
  late Animation<double> _animScale;
  late Animation<double> _animOpacity;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _animX = Tween<double>(begin: widget.startX, end: widget.targetX).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    // Upward curved arc into the top-right coin capsule
    _animY = Tween<double>(
      begin: widget.startY,
      end: widget.targetY,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInQuad));

    _animScale = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.2, end: 1.35),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 0.8),
        weight: 65,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _animOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 70),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _delayTimer = Timer(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _animX.value - 13.r,
          top: _animY.value - 13.r,
          child: Opacity(
            opacity: _animOpacity.value,
            child: Transform.scale(
              scale: _animScale.value,
              child: Container(
                width: 26.r,
                height: 26.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFDF00), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber500.withValues(alpha: 0.45),
                      blurRadius: 8.r,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.5.r,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.paid_rounded,
                    color: Colors.white,
                    size: 15.r,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
