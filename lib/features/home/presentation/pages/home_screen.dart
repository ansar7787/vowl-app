import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/features/home/presentation/widgets/global_progress_card.dart';
import 'package:vowl/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/home/presentation/widgets/bento_arena.dart';
import 'package:vowl/features/home/presentation/widgets/command_pod.dart';
import 'package:vowl/features/home/presentation/widgets/discovery_deck.dart';
import 'package:vowl/features/home/presentation/widgets/hoot_of_wisdom.dart';
import 'package:vowl/features/home/presentation/widgets/mystery_chest_dialog.dart';
import 'package:vowl/core/presentation/widgets/ad_reward_card.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_reward_ad_card.dart';



import 'package:vowl/core/theme/theme_cubit.dart';

final ScrollController homeScrollController = ScrollController();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _globalRank;

  bool _hasCheckedDailyChestThisSession = false;

  @override
  void initState() {
    super.initState();
    _fetchGlobalRank();
    // Initial check for reward availability
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthBloc>().state.status == AuthStatus.authenticated) {
        context.read<EconomyBloc>().add(const EconomyCheckDailyRewardRequested());
      }
    });
  }

  Future<void> _fetchGlobalRank() async {
    try {
      final repo = di.sl<LeaderboardRepository>();
      final result = await repo.getTopUsers(limit: 100);
      result.fold((_) {}, (data) {
        final sorted = List<UserEntity>.from(data.users)
          ..sort((a, b) {
            final aL = a.totalLevelsCompleted;
            final bL = b.totalLevelsCompleted;
            if (bL != aL) {
              return bL.compareTo(aL);
            }
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
    } catch (_) {}
  }

  @override
  void dispose() {
    // Note: homeScrollController is global (used by MainWrapper for scroll-to-top)
    // StatefulShellRoute keeps HomeScreen alive, so this dispose rarely fires
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
            listener: (context, state) {
              if (state.status == AuthStatus.authenticated) {
                // Trigger a check whenever user becomes authenticated
                context.read<EconomyBloc>().add(const EconomyCheckDailyRewardRequested());
              } else if (state.status == AuthStatus.unauthenticated) {
                // Reset global blocs that persist outside the widget tree
                context.read<EconomyBloc>().add(const EconomyResetRequested());
                context.read<ProgressionBloc>().add(const ProgressionResetRequested());
                
                // Reset local session flags
                setState(() {
                  _hasCheckedDailyChestThisSession = false;
                  _globalRank = null;
                });
              }
            },
          ),
          BlocListener<EconomyBloc, EconomyState>(
            listenWhen: (previous, current) =>
                previous.isDailyRewardAvailable != current.isDailyRewardAvailable &&
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
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final user = state.user;
            if (user == null) return const HomeShimmerLoading();
  
            return Stack(
              children: [
                const MeshGradientBackground(showLetters: false),
                RefreshIndicator(
                  onRefresh: () async {
                    context.read<AuthBloc>().add(AuthReloadUser());
                    // Allow checking for chest again on manual refresh
                    _hasCheckedDailyChestThisSession = false;
                    // Trigger BLoC re-check
                    context.read<EconomyBloc>().add(const EconomyCheckDailyRewardRequested());
                    await Future.delayed(const Duration(milliseconds: 600));
                  },
                color: const Color(0xFF2563EB),
                displacement: 40.h,
                child: CustomScrollView(
                  controller: homeScrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // 1. TOP MARGIN & STATUS
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).padding.top + 16.h,
                      ),
                    ),

                    // 2. COMMAND HEADER (Identity & XP)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      sliver: SliverToBoxAdapter(
                        child: CommandPod(
                          user: user,
                          mode: CommandPodMode.headerOnly,
                        ),
                      ),
                    ),

                    // 3. GLOBAL PROGRESS + QUICK STATS
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SizedBox(height: 20.h),
                            GlobalProgressCard(
                              user: user,
                              globalRank: _globalRank,
                            ),
                            SizedBox(height: 14.h),
                            _buildQuickStatsRow(context, user),
                          ],
                        ),
                      ),
                    ),

                    // 4. JUNIOR ADVENTURE (Kids Zone)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SizedBox(height: 25.h),
                            _buildSectionHeader(
                              context,
                              'Kids Learning Zone',
                              '22 educational games for early learners',
                              const Color(0xFFF43F5E),
                            ),
                            SizedBox(height: 18.h),
                            CommandPod(
                              user: user,
                              mode: CommandPodMode.kidsOnly,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 5. QUEST ARENA (8-Step Journey)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SizedBox(height: 30.h),
                            _buildSectionHeader(
                              context,
                              'Quest Arena',
                              '9-step real-world journey',
                              const Color(0xFF6366F1),
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
                                      '9 STEPS',
                                      style: GoogleFonts.outfit(
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            BentoArena(user: user),
                          ],
                        ),
                      ),
                    ),

                    // 6. VOWL PRIME & BADGES
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SizedBox(height: 0),
                            _buildSectionHeader(
                              context,
                              'Elite Companion & Stats',
                              'Your mascot and adventure stats',
                              const Color(0xFF10B981),
                            ),
                            SizedBox(height: 12.h),
                            CommandPod(
                              user: user,
                              mode: CommandPodMode.vaultOnly,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 6. DISCOVERY HUB (Audio Deck)
                    _buildSliverSectionHeader(
                      context,
                      'Discovery Hub',
                      '4 curated quest sequences',
                      const Color(0xFF3B82F6),
                    ),
                    SliverToBoxAdapter(
                      child: DiscoveryDeck(
                        user: user,
                        onLaunchQuest: (id) => _launchThemedQuest(context, id),
                      ),
                    ),

                    // 7. FOOTER (Quote, Ads)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          SizedBox(height: 28.h),
                          const HootOfWisdom(),
                          SizedBox(
                            height: 24.h,
                          ), // Space between owls hoot and reward card
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

  Widget _buildSliverSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
    Color categoryColor, {
    VoidCallback? onSeeAll,
  }) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            SizedBox(height: 32.h),
            _buildSectionHeader(
              context,
              title,
              subtitle,
              categoryColor,
              onSeeAll: onSeeAll,
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
    Color categoryColor, {
    VoidCallback? onSeeAll,
    Widget? badge,
  }) {
    final contrastColor = MeshGradientBackground.getContrastColor(context);
    final secondaryColor = contrastColor.withValues(alpha: 0.6);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Premium vertical indicator
        Container(
          width: 4.w,
          height: 32.h,
          decoration: BoxDecoration(
            color: categoryColor,
            borderRadius: BorderRadius.circular(2.r),
            boxShadow: [
              BoxShadow(
                color: categoryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: contrastColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (badge != null) ...[SizedBox(width: 10.w), badge],
                ],
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        ),
        if (onSeeAll != null)
          ScaleButton(
            onTap: onSeeAll,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: categoryColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                'SEE ALL',
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: categoryColor,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickStatsRow(BuildContext context, UserEntity user) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStatTile(
            context,
            'STREAK',
            '${user.currentStreak}',
            Icons.local_fire_department_rounded,
            const Color(0xFFF97316),
            AppRouter.streakRoute,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildMiniStatTile(
            context,
            'COINS',
            '${user.coins}',
            Icons.paid_rounded,
            const Color(0xFF10B981),
            AppRouter.questCoinsRoute,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildMiniStatTile(
            context,
            'KIDS',
            '${user.kidsCoins}',
            Icons.directions_car_rounded,
            const Color(0xFFF43F5E),
            '${AppRouter.kidsZoneRoute}/boutique',
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    String route,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleButton(
      onTap: () => context.push(route),
      child: GlassTile(
        borderRadius: BorderRadius.circular(20.r),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20.r),
            ),
            SizedBox(height: 8.h),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                height: 1.1,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 8.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white38 : Colors.black45,
                letterSpacing: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _launchThemedQuest(BuildContext context, String questId) {
    Haptics.vibrate(HapticsType.medium);
    context.push('${AppRouter.questSequenceRoute}?id=$questId');
  }
}
