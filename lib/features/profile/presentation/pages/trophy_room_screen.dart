import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/profile/domain/models/trophy_metadata.dart';
import 'package:vowl/features/profile/presentation/bloc/trophy_room_cubit.dart';
import 'package:vowl/features/profile/presentation/widgets/trophy_dossier_sheet.dart';
import 'package:vowl/features/profile/presentation/widgets/trophy_hero_showcase.dart';
import 'package:vowl/features/profile/presentation/widgets/trophy_medallion_artwork.dart';
import 'package:vowl/features/profile/presentation/widgets/next_in_reach_radar.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Grand Trophy Sanctuary screen showcasing earned and locked achievements,
/// hero showcase pedestals, goal acceleration radar, and interactive dossiers.
class TrophyRoomScreen extends StatelessWidget {
  /// Creates a [TrophyRoomScreen].
  const TrophyRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Read the user and badges from AuthBloc
    final user = context.read<AuthBloc>().state.user;
    final badges = user?.badges ?? [];

    return BlocProvider(
      create: (_) => TrophyRoomCubit(badges, user: user),
      child: const _TrophyRoomView(),
    );
  }
}

class _TrophyRoomView extends StatelessWidget {
  const _TrophyRoomView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        final u = authState.user;
        if (u != null) {
          context.read<TrophyRoomCubit>().updateUser(badges: u.badges, user: u);
        }
      },
      child: Scaffold(
        backgroundColor: isMidnight ? Colors.black : null,
        body: Stack(
          children: [
            if (!isMidnight)
              MeshGradientBackground(
                colors: isDark
                    ? [
                        const Color(0xFF0B101D),
                        const Color(0xFF0F172A),
                        const Color(0xFF0B101D),
                      ]
                    : [Colors.white, const Color(0xFFF8FAFC), Colors.white],
              ),

            SafeArea(
              child: CustomScrollView(
                cacheExtent: 600.0,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  _buildSliverAppBar(context, isDark),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: BlocBuilder<TrophyRoomCubit, TrophyRoomState>(
                        builder: (context, state) {
                          final hasEarned = state.allEarnedBadges.isNotEmpty;
                          final nextBadgeId = state.nextInReachBadgeId;
                          final showRadar =
                              state.nextInReachProgress > 0.0 &&
                              nextBadgeId != null &&
                              !state.allEarnedBadges.contains(nextBadgeId);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4.h),
                              _buildTrophySummary(context, state, isDark),

                              if (hasEarned) ...[
                                SizedBox(height: 6.h),
                                TrophyHeroShowcase(
                                  pinnedBadgeIds: state.pinnedBadgeIds,
                                  user: state.user,
                                  onTogglePin: (id) => context
                                      .read<TrophyRoomCubit>()
                                      .togglePin(id),
                                ),
                              ],

                              if (showRadar) ...[
                                SizedBox(height: 6.h),
                                NextInReachRadar(
                                  badgeId: nextBadgeId,
                                  progress: state.nextInReachProgress,
                                  user: state.user,
                                ),
                              ],

                              SizedBox(height: 8.h),
                              _buildFilterTabs(context, state, isDark),

                              if (state.currentFilter ==
                                  TrophyFilter.standard) ...[
                                SizedBox(height: 6.h),
                                _buildSubCategoryChips(context, state, isDark),
                              ],

                              SizedBox(height: 6.h),
                              _buildStatusMessage(context, state, isDark),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  _buildBadgeGrid(context, isDark, isMidnight),

                  SliverToBoxAdapter(child: SizedBox(height: 80.h)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      pinned: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white : AppColors.slate900,
          size: 20.r,
        ),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      title: Text(
        context.tr('profile.trophy_room', fallback: 'MY TROPHY ROOM'),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 22.sp,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : AppColors.slate900,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildTrophySummary(
    BuildContext context,
    TrophyRoomState state,
    bool isDark,
  ) {
    final totalEarned = state.allEarnedBadges.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('profile.total_earned', fallback: 'Total Earned'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white54 : Colors.black54,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 2.h),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$totalEarned',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.slate900,
                        height: 1.1,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${state.totalPossibleBadges}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white30 : Colors.black38,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              LayoutBuilder(
                builder: (context, constraints) {
                  final progress = state.totalPossibleBadges > 0
                      ? totalEarned / state.totalPossibleBadges
                      : 0.0;
                  return Container(
                    height: 8.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate800 : AppColors.slate200,
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          width: constraints.maxWidth * progress,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.r),
                            color: AppColors.indigo500,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.indigo500.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(width: 24.w),
        Builder(
          builder: (context) {
            final trophyIcon = Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.indigo500,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.indigo500.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 26.r,
              ),
            );
            return VowlMotion.shouldReduceMotion(context)
                ? trophyIcon
                : trophyIcon.animate().scale(
                    duration: 600.ms,
                    curve: Curves.easeOutCubic,
                  );
          },
        ),
      ],
    );
  }

  Widget _buildFilterTabs(
    BuildContext context,
    TrophyRoomState state,
    bool isDark,
  ) {
    final isLegendary = state.currentFilter == TrophyFilter.legendary;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final trackBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark
              ? AppColors.midnightNavy.withValues(alpha: 0.75)
              : Colors.black.withValues(alpha: 0.04));

    final trackBorder = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate200);

    final tabs = Container(
      height: 44.h,
      width: double.infinity,
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: trackBg,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: trackBorder, width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: isLegendary ? tabWidth : 0,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: isLegendary ? AppColors.gold : AppColors.indigo500,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: isLegendary
                            ? AppColors.gold.withValues(alpha: 0.35)
                            : AppColors.indigo500.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _buildSlidingTab(
                    title: context.tr(
                      'profile.filter_standard',
                      fallback: 'Standard',
                    ),
                    isSelected: !isLegendary,
                    isDark: isDark,
                    activeColor: Colors.white,
                    onTap: () => context.read<TrophyRoomCubit>().updateFilter(
                      TrophyFilter.standard,
                    ),
                  ),
                  _buildSlidingTab(
                    title: context.tr(
                      'profile.filter_legendary',
                      fallback: 'Legendary',
                    ),
                    isSelected: isLegendary,
                    isDark: isDark,
                    activeColor: AppColors.slate950,
                    onTap: () => context.read<TrophyRoomCubit>().updateFilter(
                      TrophyFilter.legendary,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    if (VowlMotion.shouldReduceMotion(context)) return tabs;
    return tabs.animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildSlidingTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    Color activeColor = Colors.white,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.vibrate(HapticsType.light);
          onTap();
        },
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? activeColor
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
            child: Text(title),
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoryChips(
    BuildContext context,
    TrophyRoomState state,
    bool isDark,
  ) {
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final categories = [
      ('all', 'All (40)'),
      ('skills', 'Skills (27)'),
      ('streaks', 'Streaks (3)'),
      ('milestones', 'Milestones (10)'),
    ];

    final containerBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03));

    final containerBorder = isMidnight
        ? Colors.white.withValues(alpha: 0.10)
        : (isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.slate200);

    return Container(
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: containerBorder, width: 1.0),
      ),
      child: Row(
        children: categories.map((cat) {
          final isSelected = state.activeCategory == cat.$1;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Haptics.vibrate(HapticsType.light);
                context.read<TrophyRoomCubit>().updateCategory(cat.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(vertical: 7.h),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.indigo500 : AppColors.indigo500)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.indigo500.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Text(
                      cat.$2,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white60 : AppColors.slate600),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusMessage(
    BuildContext context,
    TrophyRoomState state,
    bool isDark,
  ) {
    if (state.filteredEarnedBadges.isNotEmpty) {
      return const SizedBox.shrink();
    }

    final text = state.currentFilter == TrophyFilter.legendary
        ? context.tr(
            'profile.no_legendary',
            fallback: 'No legendary trophies unlocked yet.',
          )
        : context.tr(
            'profile.no_trophies',
            fallback:
                'No trophies yet. Complete lessons to unlock your first trophy!',
          );

    final messageRow = Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 16.r,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ),
      ],
    );

    final animatedMessage = VowlMotion.shouldReduceMotion(context)
        ? messageRow
        : messageRow.animate(key: ValueKey(text)).fadeIn().slideX(begin: -0.1);

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: animatedMessage,
    );
  }

  Widget _buildBadgeGrid(BuildContext context, bool isDark, bool isMidnight) {
    return BlocBuilder<TrophyRoomCubit, TrophyRoomState>(
      builder: (context, state) {
        final totalSlots =
            state.filteredEarnedBadges.length +
            state.filteredLockedBadges.length;

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14.r,
              crossAxisSpacing: 14.r,
              childAspectRatio: 0.76,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < state.filteredEarnedBadges.length) {
                  return _buildBadgeCard(
                    context,
                    state.filteredEarnedBadges[index],
                    isDark,
                    isMidnight,
                    index,
                    state,
                  );
                } else {
                  final lockedIndex = index - state.filteredEarnedBadges.length;
                  return _buildLockedSlot(
                    context,
                    state.filteredLockedBadges[lockedIndex],
                    isDark,
                    isMidnight,
                    index,
                    state,
                  );
                }
              },
              childCount: totalSlots,
              addRepaintBoundaries: true,
              addAutomaticKeepAlives: false,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgeCard(
    BuildContext context,
    String badgeId,
    bool isDark,
    bool isMidnight,
    int index,
    TrophyRoomState state,
  ) {
    final metadata = TrophyMetadata.forId(badgeId);
    final isLegendary = TrophyRoomCubit.isLegendary(badgeId);
    final borderColor = isLegendary
        ? AppColors.gold.withValues(alpha: 0.8)
        : (isMidnight
              ? Colors.white.withValues(alpha: 0.12)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.slate200));

    final cardBgColor = isLegendary
        ? (isDark ? const Color(0xFF1E1408) : const Color(0xFFFFFBEB))
        : (isMidnight
              ? AppColors.midnightSurface
              : (isDark
                    ? AppColors.midnightNavy.withValues(alpha: 0.90)
                    : Colors.white));

    return ScaleButton(
      key: ValueKey('${state.currentFilter.name}_${badgeId}_$index'),
      onTap: () {
        Haptics.vibrate(HapticsType.light);
        TrophyDossierSheet.show(
          context: context,
          metadata: metadata,
          isEarned: true,
          user: state.user,
          isPinned: state.pinnedBadgeIds.contains(badgeId),
          onTogglePin: () => context.read<TrophyRoomCubit>().togglePin(badgeId),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          color: cardBgColor,
          border: Border.all(
            color: borderColor,
            width: isLegendary ? 1.5 : 1.0,
          ),
          boxShadow: isLegendary
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: TrophyMedallionArtwork(
                  metadata: metadata,
                  isEarned: true,
                  size: isLegendary ? 54.0 : 48.0,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 10.h, left: 4.w, right: 4.w),
                child: _buildBadgeText(
                  badgeId,
                  isDark,
                  isLocked: false,
                  isLegendary: isLegendary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedSlot(
    BuildContext context,
    String badgeId,
    bool isDark,
    bool isMidnight,
    int index,
    TrophyRoomState state,
  ) {
    final metadata = TrophyMetadata.forId(badgeId);
    final isLegendary = TrophyRoomCubit.isLegendary(badgeId);
    final borderColor = isLegendary
        ? (isDark
              ? AppColors.gold.withValues(alpha: 0.35)
              : const Color(0xFFD97706).withValues(alpha: 0.35))
        : (isMidnight
              ? Colors.white.withValues(alpha: 0.12)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.slate200));
    final bgColor = isLegendary
        ? (isDark ? const Color(0xFF161005) : const Color(0xFFFFFDF5))
        : (isMidnight
              ? AppColors.midnightSurface
              : (isDark
                    ? AppColors.midnightNavy.withValues(alpha: 0.60)
                    : Colors.white));

    return ScaleButton(
      key: ValueKey('${state.currentFilter.name}_locked_$badgeId'),
      onTap: () {
        Haptics.vibrate(HapticsType.light);
        TrophyDossierSheet.show(
          context: context,
          metadata: metadata,
          isEarned: false,
          user: state.user,
          isPinned: false,
          onTogglePin: () {},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          color: bgColor,
          border: Border.all(
            color: borderColor,
            width: isLegendary ? 1.2 : 1.0,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: isLegendary
                    ? AppColors.gold.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: TrophyMedallionArtwork(
                  metadata: metadata,
                  isEarned: false,
                  size: 44.0,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 10.h, left: 4.w, right: 4.w),
                child: _buildBadgeText(
                  badgeId,
                  isDark,
                  isLocked: true,
                  isLegendary: isLegendary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeText(
    String badgeId,
    bool isDark, {
    required bool isLocked,
    required bool isLegendary,
  }) {
    final metadata = TrophyMetadata.forId(badgeId);
    final visuals = TierVisuals.forTier(metadata.tier, isDark);
    final canonical = TrophyRoomCubit.canonicalizeBadgeId(badgeId);
    final parts = canonical.split('_');

    if (parts.length >= 2) {
      final tier = parts[0].toUpperCase();
      final category = parts.sublist(1).join(' ').toUpperCase();

      final Color tierColor;
      final Color categoryColor;

      if (isLocked) {
        tierColor = isLegendary
            ? (isDark
                  ? AppColors.gold.withValues(alpha: 0.5)
                  : const Color(0xFFB45309).withValues(alpha: 0.55))
            : (isDark ? Colors.white38 : Colors.black38);
        categoryColor = isDark ? Colors.white60 : Colors.black54;
      } else if (isLegendary) {
        tierColor = isDark ? AppColors.gold : const Color(0xFFB45309);
        categoryColor = isDark ? Colors.white : AppColors.slate900;
      } else {
        tierColor = visuals.tierBadgeColor;
        categoryColor = isDark ? Colors.white : AppColors.slate900;
      }

      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tier,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isLocked ? 7.5.sp : 8.5.sp,
                fontWeight: FontWeight.w800,
                color: tierColor,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              category,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isLocked ? 9.5.sp : 11.sp,
                fontWeight: FontWeight.w900,
                color: categoryColor,
                height: 1.1,
                shadows: (isDark && !isLocked)
                    ? const [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    } else {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          badgeId.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: isLocked ? 9.5.sp : 11.sp,
            fontWeight: FontWeight.w900,
            color: isLocked
                ? (isDark ? Colors.white60 : Colors.black54)
                : (isDark ? Colors.white : AppColors.slate900),
            height: 1.1,
            shadows: (isDark && !isLocked)
                ? const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
  }
}
