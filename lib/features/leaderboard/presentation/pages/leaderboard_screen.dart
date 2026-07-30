import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
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

class LeaderboardScreen extends StatefulWidget {
  final bool isKids;
  const LeaderboardScreen({super.key, this.isKids = false});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late bool _isKidsMode;

  @override
  void initState() {
    super.initState();
    _isKidsMode = widget.isKids;
  }

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
      create: (_) => di.sl<LeaderboardBloc>()..add(LoadLeaderboard(isKids: _isKidsMode)),
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
                    
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 4.h),
                      child: _LeaderboardToggle(
                        isKidsMode: _isKidsMode,
                        onToggle: (bool isKids) {
                          if (_isKidsMode == isKids) return;
                          setState(() => _isKidsMode = isKids);
                          context.read<LeaderboardBloc>().add(LoadLeaderboard(isKids: isKids));
                        },
                      ),
                    ),
                    
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if (state is LeaderboardLoaded) {
                            return _LeaderboardContent(state: state, currentUser: currentUser);
                          } else if (state is LeaderboardLoading || state is LeaderboardInitial) {
                            return const LeaderboardShimmerLoading();
                          } else if (state is LeaderboardError) {
                            return _LeaderboardErrorView(
                              message: state.message,
                              onRetry: () => context.read<LeaderboardBloc>().add(
                                LoadLeaderboard(isKids: _isKidsMode),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }
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
          LoadLeaderboard(completer: completer, isKids: state.isKids),
        );
        await completer.future;
      },
      backgroundColor: Colors.transparent,
      color: const Color(0xFF6366F1),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // Padding to push content slightly below AppBar
          SliverToBoxAdapter(
            child: SizedBox(height: 16.h),
          ),

          // Header with last-updated timestamp
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: LeaderboardHeader(
                lastUpdated: state.lastUpdated,
                isKids: state.isKids,
              ),
            ),
          ),

          // Podium (Top 3)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: LeaderboardPodium(
                top3: state.users.take(3).toList(),
                isKids: state.isKids,
              ),
            ),
          ),

          // Sticky Current User Rank (Pins to top when scrolling)
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyRankCardDelegate(
              minHeight: 140.h,
              maxHeight: 140.h,
              child: LeaderboardRankCard(
                allUsers: state.users,
                isKids: state.isKids,
              ),
            ),
          ),

          // Section label
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              child: Text(
                context.tr(
                  'leaderboard.top_challengers',
                  fallback: 'Top Challengers',
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white38
                      : Colors.black38,
                  letterSpacing: 2.5,
                ),
              ),
            ),
          ),

          // Rank 4-N list
          if (state.users.length > 3)
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
                    final isLast = userIndex == state.users.length - 1;

                    return RepaintBoundary(
                      // ValueKey prevents animation replay when tiles
                      // are recycled by the SliverChildBuilderDelegate.
                      key: ValueKey('rank_tile_${user.id}'),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 10.h),
                        child:
                            LeaderboardRankTile(user: user, rank: rank, isMe: isMe)
                                .animate()
                                .fadeIn(duration: 250.ms, curve: Curves.easeOut)
                                .slideX(begin: 0.05, end: 0, curve: Curves.easeOut),
                      ),
                    );
                  },
                  childCount: state.users.length - 3,
                ),
              ),
            )
          else
            // Empty state when no users beyond top 3 (e.g. Kids Zone)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 32.w),
                child: Column(
                  children: [
                    Icon(
                      state.isKids ? Icons.child_care_rounded : Icons.emoji_events_outlined,
                      size: 48.r,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white24
                          : Colors.black26,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      state.isKids
                          ? context.tr('leaderboard.kids_empty', fallback: 'Be the first kid on the leaderboard!')
                          : context.tr('leaderboard.empty', fallback: 'Complete more quests to climb the ranks!'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white38
                            : Colors.black38,
                      ),
                    ),
                  ],
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
    // When pinned (shrinkOffset > 0), content scrolls beneath this header.
    // A solid frosted backdrop + bottom shadow prevents the "ghost card"
    // overlap where glassmorphic tiles bleed through.
    final isPinned = shrinkOffset > 0 || overlapsContent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: Stack(
        children: [
          // Frosted backdrop that fully occludes content beneath
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: isPinned ? 24 : 8,
                sigmaY: isPinned ? 24 : 8,
              ),
              child: Container(
                color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                    .withValues(alpha: isPinned ? 0.92 : 0.7),
              ),
            ),
          ),
          // Rank card content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
            child: Center(child: child),
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
                      (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                      (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
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

  const _LeaderboardToggle({
    required this.isKidsMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 48.h,
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: !isKidsMode 
                    ? const Color(0xFF6366F1) 
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(21.r),
                  boxShadow: !isKidsMode ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.public_rounded,
                      color: !isKidsMode ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                      size: 15.r,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'Global Ranks',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w800,
                        fontSize: 13.sp,
                        color: !isKidsMode ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: isKidsMode 
                    ? const Color(0xFFF43F5E) 
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(21.r),
                  boxShadow: isKidsMode ? [
                    BoxShadow(
                      color: const Color(0xFFF43F5E).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.child_care_rounded,
                      color: isKidsMode ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                      size: 15.r,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'Kids Zone',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w800,
                        fontSize: 13.sp,
                        color: isKidsMode ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
