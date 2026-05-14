import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/shimmer_image.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import 'package:vowl/features/leaderboard/presentation/bloc/leaderboard_bloc_event_state.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/constants/app_constants.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static const int _totalLevels = AppConstants.totalCurriculumLevels;

  @override
  Widget build(BuildContext context) {
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? const Color(0xFF0F172A) : Colors.white);

    return BlocProvider(
      create: (_) => di.sl<LeaderboardBloc>()..add(LoadLeaderboard()),
      child: Scaffold(
        backgroundColor: bgColor,
        body: BlocBuilder<LeaderboardBloc, LeaderboardState>(
          builder: (context, state) {
            return Stack(
              children: [
                const MeshGradientBackground(showLetters: false),
                if (state is LeaderboardLoaded)
                  RefreshIndicator(
                    onRefresh: () async {
                      context.read<LeaderboardBloc>().add(LoadLeaderboard());
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    backgroundColor: Colors.transparent,
                    color: const Color(0xFF2563EB),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        // Top padding
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.of(context).padding.top + 10.h,
                          ),
                        ),

                        // Header Title
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: _buildHeader(context, state.lastUpdated),
                          ),
                        ),

                        // Podium (Top 3)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: _buildPodium(
                              context,
                              state.users.take(3).toList(),
                            ),
                          ),
                        ),

                        // Current User Rank Card
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 16.h,
                            ),
                            child: _buildMyRankCard(context, state.users),
                          ),
                        ),

                        // Divider label
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 8.h,
                            ),
                            child: Text(
                              'TOP CHALLENGERS',
                              style: GoogleFonts.outfit(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white24 : Colors.black26,
                                letterSpacing: 2.5,
                              ),
                            ),
                          ),
                        ),

                        // Rank 4-N list
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final userIndex = index + 3;
                                if (userIndex >= state.users.length) {
                                  return const SizedBox.shrink();
                                }
                                final user = state.users[userIndex];
                                final rank = userIndex + 1;
                                final currentUser = context
                                    .read<AuthBloc>()
                                    .state
                                    .user;
                                final isMe = currentUser?.id == user.id;

                                return RepaintBoundary(
                                  child:
                                      _buildRankTile(context, user, rank, isMe)
                                          .animate(delay: (40 * index).ms)
                                          .fadeIn(duration: 300.ms)
                                          .slideX(begin: 0.05, end: 0),
                                );
                              },
                              childCount: state.users.length > 3
                                  ? state.users.length - 3
                                  : 0,
                            ),
                          ),
                        ),

                        // Bottom padding
                        SliverToBoxAdapter(child: SizedBox(height: 120.h)),
                      ],
                    ),
                  )
                else if (state is LeaderboardLoading ||
                    state is LeaderboardInitial)
                  const LeaderboardShimmerLoading()
                else if (state is LeaderboardError)
                  Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, DateTime lastUpdated) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeAgo = _formatTimeAgo(lastUpdated);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.leaderboard_rounded,
                color: Colors.white,
                size: 18.r,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LEADERBOARD',
                        style: GoogleFonts.outfit(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          letterSpacing: 1,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 10.r,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              timeAgo,
                              style: GoogleFonts.outfit(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white38 : Colors.black38,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Ranked by total quest experience',
                    style: GoogleFonts.outfit(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) return 'JUST NOW';
    if (difference.inMinutes < 60) return '${difference.inMinutes}M AGO';
    if (difference.inHours < 24) return '${difference.inHours}H AGO';
    return '${difference.inDays}D AGO';
  }

  // ── TOP 3 PODIUM ────────────────────────────────────────────────────────

  Widget _buildPodium(BuildContext context, List<UserEntity> top3) {
    if (top3.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 300.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (top3.length > 1)
            Expanded(child: _buildPodiumSlot(context, top3[1], 2))
          else
            const Expanded(child: SizedBox.shrink()),

          SizedBox(width: 8.w),

          // 1st Place
          Expanded(child: _buildPodiumSlot(context, top3[0], 1)),

          SizedBox(width: 8.w),

          // 3rd Place
          if (top3.length > 2)
            Expanded(child: _buildPodiumSlot(context, top3[2], 3))
          else
            const Expanded(child: SizedBox.shrink()),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPodiumSlot(BuildContext context, UserEntity user, int rank) {
    final isFirst = rank == 1;
    final avatarSize = isFirst ? 72.r : 56.r;
    final podiumHeight = isFirst ? 140.h : (rank == 2 ? 110.h : 90.h);
    final colors = _getRankColors(rank);
    final levelsCleared = user.totalLevelsCompleted;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Crown for #1
        if (isFirst)
          Text('👑', style: TextStyle(fontSize: 22.sp))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: -2,
                end: 2,
                duration: 1500.ms,
                curve: Curves.easeInOut,
              ),

        if (isFirst) SizedBox(height: 2.h),

        // Avatar
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow ring
            Container(
              width: avatarSize + 12,
              height: avatarSize + 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors[0].withValues(alpha: 0.4),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Photo
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors[0].withValues(alpha: 0.7),
                  width: isFirst ? 3 : 2,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(3.r),
                child: ClipOval(
                  child: ShimmerImage(
                    imageUrl: user.photoUrl ?? '',
                    width: avatarSize - 8,
                    height: avatarSize - 8,
                  ),
                ),
              ),
            ),
            // Rank badge
            Positioned(
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  '#$rank',
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 6.h),

        // Podium Column
        Container(
          width: double.infinity,
          height: podiumHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors[0].withValues(alpha: 0.25),
                colors[1].withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            border: Border.all(
              color: colors[0].withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          (user.displayName ?? 'Player')
                              .split(' ')
                              .first
                              .toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: isFirst ? 11.sp : 9.sp,
                            fontWeight: FontWeight.w900,
                            color: MeshGradientBackground.getContrastColor(
                              context,
                            ),
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (user.isPremium)
                      Padding(
                        padding: EdgeInsets.only(left: 4.w),
                        child: Icon(
                          Icons.verified_rounded,
                          color: const Color(0xFFF59E0B),
                          size: isFirst ? 12.r : 10.r,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 2.h),
                // Levels Cleared
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: colors[0].withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '$levelsCleared LVS',
                      style: GoogleFonts.outfit(
                        fontSize: isFirst ? 8.sp : 7.sp,
                        fontWeight: FontWeight.w900,
                        color: colors[0],
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${user.totalExp} XP',
                    style: GoogleFonts.outfit(
                      fontSize: isFirst ? 7.sp : 6.sp,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54
                          : Colors.black45,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── CURRENT USER RANK CARD ──────────────────────────────────────────────

  Widget _buildMyRankCard(BuildContext context, List<UserEntity> allUsers) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = context.read<AuthBloc>().state.user;
    if (currentUser == null) return const SizedBox.shrink();

    final rankIndex = allUsers.indexWhere((u) => u.id == currentUser.id);
    final rank = rankIndex != -1 ? rankIndex + 1 : 0;
    final isRanked = rank > 0;

    final levelsCleared = currentUser.totalLevelsCompleted;
    final progress = (levelsCleared / _totalLevels).clamp(0.0, 1.0);
    final contrastColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark
        ? Colors.white60
        : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: GlassTile(
        padding: EdgeInsets.all(16.r),
        borderRadius: BorderRadius.circular(24.r),
        borderColor: const Color(0xFF2563EB).withValues(alpha: 0.6),
        color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.15 : 0.08),
        borderWidth: 1.5,
        child: Column(
          children: [
            Row(
              children: [
                // Rank number
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isRanked ? '#$rank' : '?',
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                // Avatar
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? Colors.white24
                          : Colors.black.withValues(alpha: 0.05),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: ShimmerImage(
                      imageUrl: currentUser.photoUrl ?? '',
                      width: 40.r,
                      height: 40.r,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRanked ? 'YOUR STANDING' : 'JOIN THE COMPETITION',
                        style: GoogleFonts.outfit(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w900,
                          color: secondaryTextColor,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        currentUser.displayName?.toUpperCase() ?? 'PLAYER',
                        style: GoogleFonts.outfit(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          color: contrastColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Levels badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : const Color(0xFF2563EB).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$levelsCleared',
                        style: GoogleFonts.outfit(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF2563EB),
                          height: 1,
                        ),
                      ),
                      Text(
                        'LEVELS',
                        style: GoogleFonts.outfit(
                          fontSize: 7.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF2563EB).withValues(alpha: 0.7),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Mini progress bar
            Stack(
              children: [
                Container(
                  height: 6.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.02, 1.0),
                  child: Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                      ),
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(1)}% of all quests',
                  style: GoogleFonts.outfit(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: secondaryTextColor.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  '$levelsCleared / $_totalLevels',
                  style: GoogleFonts.outfit(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: secondaryTextColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  // ── RANK TILE (4-10) ────────────────────────────────────────────────────

  Widget _buildRankTile(
    BuildContext context,
    UserEntity user,
    int rank,
    bool isMe,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final levelsCleared = user.totalLevelsCompleted;
    final tierColor = rank <= 10
        ? const Color(0xFF3B82F6)
        : const Color(0xFF94A3B8);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      child: GlassTile(
        padding: EdgeInsets.symmetric(horizontal: 14.r, vertical: 12.r),
        borderRadius: BorderRadius.circular(18.r),
        borderColor: isMe
            ? const Color(0xFF2563EB).withValues(alpha: 0.7)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFCBD5E1)),
        color: isMe
            ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.15 : 0.08)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(
                      alpha: 0.95,
                    )), // Pure white bg for light mode
        borderWidth: isMe ? 1.5 : 1,
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 36.w,
              child: Text(
                '$rank',
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: isMe
                      ? (isDark ? Colors.white : const Color(0xFF2563EB))
                      : (isDark
                            ? tierColor.withValues(alpha: 0.8)
                            : const Color(
                                0xFF334155,
                              )), // High contrast slate for light mode
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 12.w),
            // Avatar
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: tierColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: ShimmerImage(
                  imageUrl: user.photoUrl ?? '',
                  width: 40.r,
                  height: 40.r,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Name & XP
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          (user.displayName ?? 'Player').toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: MeshGradientBackground.getContrastColor(
                              context,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isPremium)
                        Padding(
                          padding: EdgeInsets.only(left: 4.w),
                          child: Icon(
                            Icons.verified_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 14.r,
                          ),
                        ),
                      if (isMe)
                        Padding(
                          padding: EdgeInsets.only(left: 6.w),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'YOU',
                              style: GoogleFonts.outfit(
                                fontSize: 7.sp,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF60A5FA),
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${user.totalExp} XP · ${user.currentStreak}🔥',
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white38
                          : Colors.black54, // Increased contrast for light mode
                    ),
                  ),
                ],
              ),
            ),
            // Levels cleared
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: tierColor.withValues(alpha: 0.15)),
              ),
              child: Text(
                '$levelsCleared LVS',
                style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: tierColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UTILS ───────────────────────────────────────────────────────────────

  List<Color> _getRankColors(int rank) {
    switch (rank) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFF59E0B)];
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF94A3B8)];
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFFA3713B)];
      default:
        return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
    }
  }
}
