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
import 'package:vowl/features/home/presentation/widgets/discovery_deck.dart';
import 'package:vowl/features/home/presentation/widgets/daily_motivation_card.dart';
import 'package:vowl/features/home/presentation/widgets/mystery_chest_dialog.dart';
import 'package:vowl/core/presentation/widgets/ad_reward_card.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_reward_ad_card.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_global_progress_card.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/features/home/presentation/widgets/home_quick_stats.dart';
import 'package:vowl/features/home/presentation/widgets/home_section_header.dart';
import 'package:vowl/features/home/presentation/widgets/inline_notification_card.dart';
import 'package:vowl/features/home/presentation/widgets/daily_words_home_card.dart';
import 'package:vowl/features/home/presentation/widgets/translation_home_card.dart';
import 'package:vowl/features/home/presentation/widgets/vowl_mascot_card.dart';
import 'package:vowl/features/home/presentation/widgets/ai_lab_grid.dart';
import 'package:vowl/core/utils/locale_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _globalRank;
  int? _kidsGlobalRank;
  bool _hasCheckedDailyChestThisSession = false;
  final ValueNotifier<int> _carouselIndex = ValueNotifier(1);
  final PageController _carouselController = PageController(viewportFraction: 0.88, initialPage: 1);

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

  @override
  void dispose() {
    _carouselIndex.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  Future<void> _fetchGlobalRank() async {
    try {
      final repo = di.sl<LeaderboardRepository>();
      final result = await repo.getTopUsers(limit: 100);
      final kidsResult = await repo.getTopKidsUsers(limit: 100);

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
          setState(() => _globalRank = idx >= 0 ? idx + 1 : null);
        }
      });

      kidsResult.fold((_) {}, (data) {
        final sorted = List<UserEntity>.from(data.users)
          ..sort((a, b) {
            final aL = a.kidsTotalLevelsCompleted;
            final bL = b.kidsTotalLevelsCompleted;
            if (bL != aL) return bL.compareTo(aL);
            if (b.kidsCoins != a.kidsCoins) {
              return b.kidsCoins.compareTo(a.kidsCoins);
            }
            if (b.currentStreak != a.currentStreak) {
              return b.currentStreak.compareTo(a.currentStreak);
            }
            return b.totalExp.compareTo(a.totalExp);
          });
        final currentUser = context.read<AuthBloc>().state.user;
        if (currentUser != null && mounted) {
          final idx = sorted.indexWhere((u) => u.id == currentUser.id);
          setState(() => _kidsGlobalRank = idx >= 0 ? idx + 1 : null);
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
                setState(() {
                  _hasCheckedDailyChestThisSession = false;
                  _globalRank = null;
                });
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
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).padding.top + 16.h,
                        ),
                      ),

                      // 1. COMMAND HEADER (Identity & XP)
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        sliver: SliverToBoxAdapter(
                          child: CommandPod(
                            user: user,
                            mode: CommandPodMode.headerOnly,
                          ),
                        ),
                      ),

                      // 2. STREAK
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              SizedBox(height: 12.h), // Reduced from 16.h
                              InlineNotificationCard(
                                streak: user.currentStreak,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 3. DASHBOARD (Stats, Leaderboards & Utility)
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              SizedBox(height: 12.h), // Reduced from 24.h
                              TranslationHomeCard(isDark: isDark),
                              SizedBox(height: 12.h),
                              GlobalProgressCard(
                                user: user,
                                globalRank: _globalRank,
                              ),
                              SizedBox(height: 12.h),
                              HomeQuickStats(user: user),
                              SizedBox(height: 12.h),
                              KidsGlobalProgressCard(
                                user: user,
                                globalRank: _kidsGlobalRank,
                              ),
                              SizedBox(height: 12.h),
                              CommandPod(
                                user: user,
                                mode: CommandPodMode.vaultOnly,
                              ),
                              SizedBox(height: 24.h),
                              const AiLabGrid(),
                            ],
                          ),
                        ),
                      ),

                      // 4. QUEST ARENA (Deep Work, Core Journey)
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
                                badge: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFF59E0B,
                                      ).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome_rounded,
                                        color: const Color(0xFFF59E0B),
                                        size: 10.r,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        context.tr(
                                          'home.quest_arena_steps',
                                          fallback: 'Steps',
                                        ),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFFF59E0B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              BentoArena(user: user),
                            ],
                          ),
                        ),
                      ),

                      // 5. HERO CAROUSEL (Daily Words & Junior Adventure)
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SizedBox(height: 16.h),
                            SizedBox(
                              height: 190.h, // 160.h for card + 30.h for shadow
                              child: PageView(
                                clipBehavior: Clip.none,
                                controller: _carouselController,
                                physics: const BouncingScrollPhysics(),
                                onPageChanged: (idx) {
                                  _carouselIndex.value = idx;
                                },
                                children: [
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 30.h),
                                    child: CommandPod(
                                      user: user,
                                      mode: CommandPodMode.kidsOnly,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 30.h),
                                    child: DailyWordsHomeCard(isDark: isDark),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 30.h),
                                    child: const VowlMascotCard(),
                                  ),
                                ],
                              ),
                            ),
                            ValueListenableBuilder<int>(
                              valueListenable: _carouselIndex,
                              builder: (context, currentIndex, _) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(3, (index) {
                                    final isSelected = index == currentIndex;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutCubic,
                                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                                      height: 6.h,
                                      width: isSelected ? 24.w : 6.w,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF6366F1)
                                            : (isDark ? Colors.white24 : Colors.black12),
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // 6. DISCOVERY HUB (Audio Deck)
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

                      // 7. FOOTER (Quote, Ads)
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            SizedBox(height: 28.h),
                            DailyMotivationCard(
                              streakCount: user.currentStreak,
                            ),
                            SizedBox(height: 24.h),
                            const AdRewardCard(margin: EdgeInsets.zero),
                            SizedBox(height: 16.h),
                            const KidsRewardAdCard(),
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
