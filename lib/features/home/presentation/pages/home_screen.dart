import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
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
import 'package:vowl/core/utils/injection_container.dart' as di;

import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/home/presentation/widgets/bento_arena.dart';
import 'package:vowl/features/home/presentation/widgets/home_hero_header.dart';
import 'package:vowl/features/home/presentation/widgets/continue_learning_card.dart';
import 'package:vowl/features/home/presentation/widgets/inline_notification_card.dart';
import 'package:vowl/features/home/presentation/widgets/discovery_deck.dart';
import 'package:vowl/features/home/presentation/widgets/daily_motivation_card.dart';
import 'package:vowl/features/home/presentation/widgets/review_mistakes_home_card.dart';
import 'package:vowl/features/home/presentation/widgets/daily_mystery_chest_card.dart';
import 'package:vowl/features/home/presentation/widgets/home_section_header.dart';
import 'package:vowl/features/home/presentation/widgets/unified_stats_row.dart';
import 'package:vowl/features/home/presentation/widgets/beginner_milestone_card.dart';
import 'package:vowl/features/home/presentation/widgets/tools_strip.dart';
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

  @override
  void initState() {
    super.initState();
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: result.success ? AppColors.emerald500 : AppColors.rose500,
                    ),
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

      result.fold((_) {
        if (mounted) _isRankLoading.value = false;
      }, (data) {
        final sorted = List<UserEntity>.from(data.users)
          ..sort((a, b) {
            final aL = a.totalLevelsCompleted;
            final bL = b.totalLevelsCompleted;
            if (bL != aL) return bL.compareTo(aL);
            if (b.totalExp != a.totalExp) {
              return b.totalExp.compareTo(a.totalExp);
            }
            return b.currentStreak.compareTo(a.currentStreak);
          });
        final currentUser = context.read<AuthBloc>().state.user;
        if (currentUser != null && mounted) {
          final idx = sorted.indexWhere((u) => u.id == currentUser.id);
          _globalRank.value = idx >= 0 ? idx + 1 : null;
        }
        if (mounted) _isRankLoading.value = false;
      });
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
    _globalRank.dispose();
    _isRankLoading.dispose();
    super.dispose();
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
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
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
                      // 1.6 DAILY MYSTERY CHEST (Conditional Inline Claim)
                      // --------------------------------------------------
                      const SliverToBoxAdapter(
                        child: DailyMysteryChestCard(),
                      ),

                      // --------------------------------------------------
                      // 2. PRIMARY CTA — "Continue Learning"
                      // --------------------------------------------------
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              SizedBox(height: 16.h),
                              ContinueLearningCard(user: user),
                            ],
                          ),
                        ),
                      ),

                      // --------------------------------------------------
                      // 3. UNIFIED STATS ROW (Streak | Coins | Badges | Level)
                      // --------------------------------------------------
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              SizedBox(height: 24.h),
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
                      if (!_bypassBeginnerGate && user.totalLevelsCompleted < 2) ...[
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
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
                        // 4. CURRICULUM BENTO ARENA + WEAK-SPOT REVIEW
                        // --------------------------------------------------
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
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
                                if (!user.isKidsModeOnly)
                                  ReviewMistakesHomeCard(user: user),
                              ],
                            ),
                          ),
                        ),

                        // --------------------------------------------------
                        // 5. PROGRESS CARD (Total levels + Rank)
                        // --------------------------------------------------
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
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

                        // --------------------------------------------------
                        // 6. EXPLORE & TOOLS (Horizontal strip)
                        // --------------------------------------------------
                        HomeSliverSectionHeader(
                          title: context.tr(
                            'home.tools_title',
                            fallback: 'Explore & Tools',
                          ),
                          subtitle: context.tr(
                            'home.tools_subtitle',
                            fallback: 'Your learning toolkit',
                          ),
                          categoryColor: AppColors.emerald500,
                          onSeeAll: () => ToolsStrip.showToolsDirectory(context),
                        ),
                        const SliverToBoxAdapter(child: ToolsStrip()),

                        // --------------------------------------------------
                        // 7. DISCOVERY HUB (Quest Recommendations)
                        // --------------------------------------------------
                        HomeSliverSectionHeader(
                          title: context.tr(
                            'home.discovery_hub_title',
                            fallback: 'Discovery Hub',
                          ),
                          subtitle: context.tr(
                            'home.discovery_hub_subtitle',
                            fallback: 'Targeted skill tracks',
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
                      ],

                      // --------------------------------------------------
                      // 8. DAILY NOTE / LANGUAGE NOTE
                      // --------------------------------------------------
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            SizedBox(height: 24.h),
                            DailyMotivationCard(
                              streakCount: user.currentStreak,
                            ),
                            SizedBox(
                              height: 120.h +
                                  MediaQuery.paddingOf(context).bottom +
                                  24.h,
                            ),
                          ]),
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

  void _launchThemedQuest(BuildContext context, String questId) {
    try {
      Haptics.vibrate(HapticsType.medium);
    } catch (e) {
      if (kDebugMode) debugPrint('HomeScreen: haptics unavailable: $e');
    }
    context.push(
      '${AppRouter.questSequenceRoute}?id=${Uri.encodeQueryComponent(questId)}',
    );
  }
}
