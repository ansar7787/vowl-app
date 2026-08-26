import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/features/profile/presentation/bloc/trophy_room_cubit.dart';

class TrophyRoomScreen extends StatelessWidget {
  const TrophyRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Read the user's badges from AuthBloc ONCE when creating the screen
    final badges = context.read<AuthBloc>().state.user?.badges ?? [];

    return BlocProvider(
      create: (_) => TrophyRoomCubit(badges),
      child: const _TrophyRoomView(),
    );
  }
}

class _TrophyRoomView extends StatelessWidget {
  const _TrophyRoomView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;

    return Scaffold(
      backgroundColor: isMidnight ? const Color(0xFF020617) : null,
      body: Stack(
        children: [
          if (!isMidnight)
            // Premium Adult Background (No Kids Renderers)
            MeshGradientBackground(
              colors: isDark
                  ? [
                      const Color(0xFF0F172A),
                      const Color(0xFF1E293B),
                      const Color(0xFF33201C), // Deep gold tint
                    ]
                  : [
                      const Color(0xFFF8FAFC),
                      const Color(0xFFF1F5F9),
                      const Color(0xFFFEF3C7), // Light gold tint
                    ],
            ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context, isDark),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16.h),
                        _buildTrophySummary(context, isDark),
                        SizedBox(height: 32.h),
                        _buildFilterTabs(context, isDark),
                        SizedBox(height: 24.h),
                        _buildStatusMessage(context, isDark),
                      ],
                    ),
                  ),
                ),

                _buildBadgeGrid(context, isDark),

                SliverToBoxAdapter(child: SizedBox(height: 80.h)),
              ],
            ),
          ),
        ],
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
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          size: 20.r,
        ),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      title: Text(
        context.tr('profile.trophy_room', fallback: 'Trophy Room'),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 22.sp,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildTrophySummary(BuildContext context, bool isDark) {
    return BlocBuilder<TrophyRoomCubit, TrophyRoomState>(
      builder: (context, state) {
        final totalEarned = state.allEarnedBadges.length;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('profile.total_earned', fallback: 'Total Earned'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white54 : Colors.black54,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$totalEarned / ${state.totalPossibleBadges}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 36.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 32.r,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          ],
        );
      },
    );
  }

  Widget _buildFilterTabs(BuildContext context, bool isDark) {
    return BlocBuilder<TrophyRoomCubit, TrophyRoomState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              _buildTab(
                context,
                title: context.tr('profile.filter_all', fallback: 'All'),
                isSelected: state.currentFilter == TrophyFilter.all,
                onTap: () => context.read<TrophyRoomCubit>().updateFilter(
                  TrophyFilter.all,
                ),
                isDark: isDark,
              ),
              _buildTab(
                context,
                title: context.tr(
                  'profile.filter_standard',
                  fallback: 'Standard',
                ),
                isSelected: state.currentFilter == TrophyFilter.standard,
                onTap: () => context.read<TrophyRoomCubit>().updateFilter(
                  TrophyFilter.standard,
                ),
                isDark: isDark,
              ),
              _buildTab(
                context,
                title: context.tr(
                  'profile.filter_legendary',
                  fallback: 'Legendary',
                ),
                isSelected: state.currentFilter == TrophyFilter.legendary,
                onTap: () => context.read<TrophyRoomCubit>().updateFilter(
                  TrophyFilter.legendary,
                ),
                isDark: isDark,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
      },
    );
  }

  Widget _buildTab(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: ScaleButton(
        onTap: () {
          Haptics.vibrate(HapticsType.light);
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF334155) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? Colors.white54 : Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMessage(BuildContext context, bool isDark) {
    return BlocBuilder<TrophyRoomCubit, TrophyRoomState>(
      builder: (context, state) {
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
                fallback: 'No trophies unlocked yet.',
              );

        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Row(
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
          ).animate(key: ValueKey(text)).fadeIn().slideX(begin: -0.1),
        );
      },
    );
  }

  Widget _buildBadgeGrid(BuildContext context, bool isDark) {
    return BlocBuilder<TrophyRoomCubit, TrophyRoomState>(
      builder: (context, state) {
        final totalSlots =
            state.filteredEarnedBadges.length +
            state.filteredLockedBadges.length;

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16.r,
              crossAxisSpacing: 16.r,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index < state.filteredEarnedBadges.length) {
                return _buildBadgeCard(
                  state.filteredEarnedBadges[index],
                  isDark,
                  index,
                  state.currentFilter,
                );
              } else {
                final lockedIndex = index - state.filteredEarnedBadges.length;
                return _buildLockedSlot(
                  state.filteredLockedBadges[lockedIndex],
                  isDark,
                  index,
                  state.currentFilter,
                );
              }
            }, childCount: totalSlots),
          ),
        );
      },
    );
  }

  Widget _buildBadgeCard(
    String badgeId,
    bool isDark,
    int index,
    TrophyFilter filter,
  ) {
    final isLegendary = TrophyRoomCubit.isLegendary(badgeId);
    final colorPair = _getCategoryColors(badgeId, isLegendary);

    return ScaleButton(
          key: ValueKey('${filter.name}_${badgeId}_$index'),
          onTap: () => Haptics.vibrate(HapticsType.light),
          child: GlassTile(
            borderRadius: BorderRadius.circular(20.r),
            padding: EdgeInsets.all(2.r),
            borderColor: colorPair[0].withValues(alpha: 0.3),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                gradient: LinearGradient(
                  colors: isLegendary
                      ? [
                          const Color(0xFF451A03).withValues(
                            alpha: isDark ? 0.8 : 0.9,
                          ), // Deep Amber Dark
                          const Color(
                            0xFF78350F,
                          ).withValues(alpha: isDark ? 0.5 : 0.8), // Brown Gold
                        ]
                      : colorPair
                            .map(
                              (c) => c.withValues(alpha: isDark ? 0.15 : 0.4),
                            )
                            .toList(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isLegendary
                      ? const Color(0xFFFFD700).withValues(alpha: 0.8)
                      : colorPair[0].withValues(alpha: 0.5),
                  width: isLegendary ? 2.5 : 1.5,
                ),
                boxShadow: isLegendary
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: 24.h,
                      ), // Push up to leave room for text
                      child: Text(
                        isLegendary ? "👑" : _getCategoryEmoji(badgeId),
                        style: TextStyle(
                          fontSize: isLegendary ? 48.sp : 40.sp,
                          shadows: const [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: 12.h,
                        left: 4.w,
                        right: 4.w,
                      ),
                      child: _buildBadgeText(badgeId, isDark, isLocked: false),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .scale(
          delay: (50 * (index % 6))
              .ms, // Cap delay to avoid huge waits on large lists
          duration: 400.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(delay: (50 * (index % 6)).ms);
  }

  Widget _buildLockedSlot(
    String badgeId,
    bool isDark,
    int index,
    TrophyFilter filter,
  ) {
    return GlassTile(
          key: ValueKey('${filter.name}_locked_$badgeId'),
          borderRadius: BorderRadius.circular(20.r),
          padding: EdgeInsets.all(2.r),
          borderColor: Colors.white.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.black.withValues(alpha: 0.02),
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 24.h),
                    child: Icon(
                      Icons.lock_rounded,
                      color: isDark ? Colors.white24 : Colors.black26,
                      size: 36.r,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: 12.h,
                      left: 4.w,
                      right: 4.w,
                    ),
                    child: _buildBadgeText(badgeId, isDark, isLocked: true),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .scale(
          delay: (50 * (index % 6)).ms,
          duration: 400.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(delay: (50 * (index % 6)).ms);
  }

  List<Color> _getCategoryColors(String badgeId, bool isLegendary) {
    if (isLegendary) {
      return [
        const Color(0xFFFFD700),
        const Color(0xFFF59E0B),
      ]; // Deep Gold Glow
    }

    if (badgeId.contains('speaking')) {
      return [const Color(0xFFF44336), const Color(0xFFD32F2F)]; // Red
    } else if (badgeId.contains('writing')) {
      return [const Color(0xFFFF9800), const Color(0xFFF57C00)]; // Orange
    } else if (badgeId.contains('vocabulary')) {
      return [const Color(0xFF673AB7), const Color(0xFF512DA8)]; // Purple
    } else if (badgeId.contains('reading')) {
      return [const Color(0xFF4CAF50), const Color(0xFF388E3C)]; // Green
    } else if (badgeId.contains('accent')) {
      return [const Color(0xFF00BCD4), const Color(0xFF0097A7)]; // Cyan
    } else if (badgeId.contains('grammar')) {
      return [const Color(0xFF2196F3), const Color(0xFF1976D2)]; // Blue
    } else if (badgeId.contains('listening')) {
      return [const Color(0xFFE91E63), const Color(0xFFC2185B)]; // Pink
    } else if (badgeId.contains('roleplay')) {
      return [const Color(0xFF8BC34A), const Color(0xFF689F38)]; // Lime
    } else if (badgeId.contains('elitemastery')) {
      return [const Color(0xFFFFC107), const Color(0xFFFFA000)]; // Amber
    } else if (badgeId.contains('streak')) {
      return [const Color(0xFF0EA5E9), const Color(0xFF0284C7)]; // Sky Blue
    }

    // Default Silver for unmapped standards
    return [const Color(0xFF94A3B8), const Color(0xFF64748B)];
  }

  String _getCategoryEmoji(String badgeId) {
    if (badgeId.contains('speaking')) return "🎙️";
    if (badgeId.contains('writing')) return "✍️";
    if (badgeId.contains('vocabulary')) return "📖";
    if (badgeId.contains('reading')) return "📚";
    if (badgeId.contains('accent')) return "🗣️";
    if (badgeId.contains('grammar')) return "🧩";
    if (badgeId.contains('listening')) return "🎧";
    if (badgeId.contains('roleplay')) return "🎭";
    if (badgeId.contains('elitemastery')) return "💎";
    if (badgeId.contains('streak')) return "🔥";
    if (badgeId.contains('perfect')) return "🎯";
    if (badgeId.contains('first')) return "🥇";
    if (badgeId.contains('night')) return "🦉";
    if (badgeId.contains('early')) return "🌅";
    if (badgeId.contains('speed')) return "⚡";
    if (badgeId.contains('flawless')) return "✨";
    return "🏆";
  }

  Widget _buildBadgeText(
    String badgeId,
    bool isDark, {
    required bool isLocked,
  }) {
    final parts = badgeId.split('_');
    if (parts.length >= 2) {
      final tier = parts[0].toUpperCase();
      final category = parts.sublist(1).join(' ').toUpperCase();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tier,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isLocked ? 7.sp : 8.sp,
              fontWeight: FontWeight.w800,
              color: isLocked
                  ? (isDark ? Colors.white24 : Colors.black26)
                  : (isDark ? Colors.white54 : Colors.black54),
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            category,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isLocked ? 9.sp : 11.sp,
              fontWeight: FontWeight.w900,
              color: isLocked
                  ? (isDark ? Colors.white30 : Colors.black38)
                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
              height: 1.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else {
      return Text(
        badgeId.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: isLocked ? 9.sp : 11.sp,
          fontWeight: FontWeight.w900,
          color: isLocked
              ? (isDark ? Colors.white30 : Colors.black38)
              : (isDark ? Colors.white : const Color(0xFF0F172A)),
          height: 1.1,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
  }
}
