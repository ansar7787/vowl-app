import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/locale_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // FIX (MEDIUM-1): Use context.select instead of context.watch to scope
    // rebuilds to only the isMidnight boolean, not the entire ThemeCubit state.
    final isMidnight = context.select<ThemeCubit, bool>(
      (c) => c.state.isMidnight,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? const Color(0xFF0F172A) : Colors.white);

    return BlocProvider(
      create: (_) => di.sl<LeaderboardBloc>()..add(const LoadLeaderboard()),
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
                if (state is LeaderboardLoaded)
                  _LeaderboardContent(state: state, currentUser: currentUser)
                else if (state is LeaderboardLoading ||
                    state is LeaderboardInitial)
                  const LeaderboardShimmerLoading()
                else if (state is LeaderboardError)
                  _LeaderboardErrorView(
                    message: state.message,
                    onRetry: () => context.read<LeaderboardBloc>().add(
                      const LoadLeaderboard(),
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

class _LeaderboardContent extends StatelessWidget {
  final LeaderboardLoaded state;
  final UserEntity? currentUser;

  const _LeaderboardContent({required this.state, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final completer = Completer<void>();
        context.read<LeaderboardBloc>().add(
          LoadLeaderboard(completer: completer),
        );
        await completer.future;
      },
      backgroundColor: Colors.transparent,
      color: const Color(0xFF2563EB),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // Top safe-area padding
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.top + 10.h),
          ),

          // Header with last-updated timestamp
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: LeaderboardHeader(lastUpdated: state.lastUpdated),
            ),
          ),

          // Podium (Top 3)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: LeaderboardPodium(top3: state.users.take(3).toList()),
            ),
          ),

          // Current user rank card
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: LeaderboardRankCard(allUsers: state.users),
            ),
          ),

          // Section label
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              child: Text(
                context.tr('leaderboard.top_challengers'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white24
                      : Colors.black26,
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
                  final isMe = currentUser?.id == user.id;

                  return RepaintBoundary(
                    child:
                        LeaderboardRankTile(user: user, rank: rank, isMe: isMe)
                            .animate(delay: (40 * index).ms)
                            .fadeIn(duration: 300.ms)
                            .slideX(begin: 0.05, end: 0),
                  );
                },
                childCount: state.users.length > 3 ? state.users.length - 3 : 0,
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 120.h)),
        ],
      ),
    );
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
                context.tr('common.retry'),
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
