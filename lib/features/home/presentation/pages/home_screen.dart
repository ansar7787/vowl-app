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
import 'package:vowl/features/home/presentation/widgets/command_pod.dart';
import 'package:vowl/features/home/presentation/widgets/continue_learning_card.dart';
import 'package:vowl/features/home/presentation/widgets/inline_notification_card.dart';
import 'package:vowl/features/home/presentation/widgets/discovery_deck.dart';
import 'package:vowl/features/home/presentation/widgets/daily_motivation_card.dart';
import 'package:vowl/features/home/presentation/widgets/mystery_chest_dialog.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/features/home/presentation/widgets/home_section_header.dart';
import 'package:vowl/features/home/presentation/widgets/unified_stats_row.dart';
import 'package:vowl/features/home/presentation/widgets/tools_strip.dart';
import 'package:vowl/core/utils/locale_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ValueNotifier<int?> _globalRank = ValueNotifier(null);
  bool _hasCheckedDailyChestThisSession = false;

  @override
  void initState() {
    super.initState();
    _fetchGlobalRank();
    // Initial check for reward availability
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AuthBloc>().state.status == AuthStatus.authenticated) {
        context.read<EconomyBloc>().add(
          const EconomyCheckDailyRewardRequested(),
        );
      }
    });
  }

  Future<void> _fetchGlobalRank() async {
    try {
      final repo = di.sl<LeaderboardRepository>();
      final result = await repo.getTopUsers(limit: 100);

      // CRITICAL: this is an async gap — the widget may have been disposed
      // (e.g. the user logged out / navigated away) while the request was
      // in flight. Reading `context` or calling `setState` past this point
      // without checking `mounted` first risks
      // "Looking up a deactivated widget's ancestor is unsafe".
      if (!mounted) return;

      result.fold((_) {}, (data) {
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
      });
    } catch (e) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? const Color(0xFF0F172A) : Colors.white);

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
              } else if (state.status == AuthStatus.unauthenticated) {
                context.read<EconomyBloc>().add(const EconomyResetRequested());
                context.read<ProgressionBloc>().add(
                  const ProgressionResetRequested(),
                );
                _hasCheckedDailyChestThisSession = false;
                _globalRank.value = null;
              }
            },
          ),
          BlocListener<EconomyBloc, EconomyState>(
            listenWhen: (previous, current) =>
                previous.isDailyRewardAvailable !=
                    current.isDailyRewardAvailable &&
                current.isDailyRewardAvailable,
            listener: (context, state) {
              if (!_hasCheckedDailyChestThisSession) {
                _hasCheckedDailyChestThisSession = true;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const MysteryChestDialog(),
                );
              }
            },
          ),
        ],
        // BlocSelector instead of BlocBuilder: this screen's tree is heavy
        // (custom-painted journey path, PageView carousel, multiple glass
        // panels). Selecting only `state.user` means unrelated AuthState
        // changes (e.g. transient loading flags) no longer force a full
        // rebuild of every widget below.
        child: BlocSelector<AuthBloc, AuthState, UserEntity?>(
          selector: (state) => state.user,
          builder: (context, user) {
            if (user == null) return const HomeShimmerLoading();

            return Stack(
              children: [
                const MeshGradientBackground(showLetters: false),
                RefreshIndicator(
                  onRefresh: () async {
                    context.read<AuthBloc>().add(const AuthReloadUser());
                    _hasCheckedDailyChestThisSession = false;
                    context.read<EconomyBloc>().add(
                      const EconomyCheckDailyRewardRequested(),
                    );
                    await Future.delayed(const Duration(milliseconds: 600));
                  },
                  color: const Color(0xFF6366F1),
                  displacement: 40.h,
                  child: CustomScrollView(
                    controller: di.sl<ScrollController>(instanceName: 'home'),
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // ── Top Safe Area ────────────────────────────────
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).padding.top + 16.h,
                        ),
                      ),

                      // ══════════════════════════════════════════════════
                      // 1. HERO HEADER (Identity & XP)
                      // ══════════════════════════════════════════════════
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        sliver: SliverToBoxAdapter(
                          child: CommandPod(
                            user: user,
                            mode: CommandPodMode.headerOnly,
                          ),
                        ),
                      ),

                      // ══════════════════════════════════════════════════
                      // 1.5 INLINE NOTIFICATION (Conditional)
                      // ══════════════════════════════════════════════════
                      SliverToBoxAdapter(
                        child: InlineNotificationCard(streak: user.currentStreak),
                      ),

                      // ══════════════════════════════════════════════════
                      // 2. PRIMARY CTA — "Continue Learning"
                      // ══════════════════════════════════════════════════
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

                      // ══════════════════════════════════════════════════
                      // 3. UNIFIED STATS ROW (Streak | Coins | Badges | Level)
                      // ══════════════════════════════════════════════════
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              SizedBox(height: 16.h),
                              ValueListenableBuilder<int?>(
                                valueListenable: _globalRank,
                                builder: (context, rank, child) {
                                  return UnifiedStatsRow(
                                    user: user,
                                    globalRank: rank,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ══════════════════════════════════════════════════
                      // 4. JOURNEY PROGRESS (Collapsed BentoArena)
                      // ══════════════════════════════════════════════════
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              SizedBox(height: 24.h),
                              HomeSectionHeader(
                                title: context.tr(
                                  'home.quest_arena_title',
                                  fallback: 'Your Journey',
                                ),
                                subtitle: context.tr(
                                  'home.quest_arena_subtitle',
                                  fallback: 'Continue your adventure',
                                ),
                                localizedTitleKey: 'home.quest_arena_title',
                                localizedSubtitleKey:
                                    'home.quest_arena_subtitle',
                                categoryColor: const Color(0xFF6366F1),
                                onSeeAll: () =>
                                    context.push(AppRouter.libraryRoute),
                              ),
                              SizedBox(height: 16.h),
                              BentoArena(user: user, collapsed: true),
                            ],
                          ),
                        ),
                      ),

                      // ══════════════════════════════════════════════════
                      // 5. PROGRESS CARD (Total levels + Rank)
                      // ══════════════════════════════════════════════════
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

                      // ══════════════════════════════════════════════════
                      // 6. EXPLORE & TOOLS (Horizontal strip)
                      // ══════════════════════════════════════════════════
                      HomeSliverSectionHeader(
                        title: context.tr(
                          'home.tools_title',
                          fallback: 'Explore & Tools',
                        ),
                        subtitle: context.tr(
                          'home.tools_subtitle',
                          fallback: 'Quick access to learning tools',
                        ),
                        categoryColor: const Color(0xFF10B981),
                      ),
                      const SliverToBoxAdapter(child: ToolsStrip()),

                      // ══════════════════════════════════════════════════
                      // 7. DISCOVERY HUB (Quest Recommendations)
                      // ══════════════════════════════════════════════════
                      HomeSliverSectionHeader(
                        title: context.tr(
                          'home.discovery_hub_title',
                          fallback: 'Discovery Hub',
                        ),
                        subtitle: context.tr(
                          'home.discovery_hub_subtitle',
                          fallback: 'Listen and learn new topics',
                        ),
                        categoryColor: const Color(0xFF3B82F6),
                      ),
                      SliverToBoxAdapter(
                        child: DiscoveryDeck(
                          user: user,
                          onLaunchQuest: (id) =>
                              _launchThemedQuest(context, id),
                        ),
                      ),

                      // ══════════════════════════════════════════════════
                      // 8. DAILY WISDOM
                      // ══════════════════════════════════════════════════
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            SizedBox(height: 32.h),
                            DailyMotivationCard(
                              streakCount: user.currentStreak,
                            ),
                            SizedBox(height: 80.h),
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
