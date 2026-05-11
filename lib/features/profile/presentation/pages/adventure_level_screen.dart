import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/constants/badge_constants.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/ad_reward_card.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:flutter/services.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/presentation/widgets/hint_ad_card.dart';

class AdventureLevelScreen extends StatelessWidget {
  const AdventureLevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final bgColor = isMidnight 
        ? Colors.black 
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

    return Scaffold(
      backgroundColor: bgColor,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) return const SizedBox.shrink();

          final currentLevel = user.level;
          final xpInCurrentLevel = user.totalExp % 100;
          final progress = xpInCurrentLevel / 100;

          return Stack(
            children: [
              const MeshGradientBackground(),
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── SliverAppBar ──
                    SliverAppBar(
                      pinned: true,
                      floating: true,
                      snap: true,
                      automaticallyImplyLeading: false,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      expandedHeight: 80.h,
                      collapsedHeight: 64.h,
                      toolbarHeight: 64.h,
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        title: GlassTile(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 6.h,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 32.r,
                                height: 32.r,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 18.r,
                                  onPressed: () => context.pop(),
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Adventure Level',
                                style: GoogleFonts.outfit(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.monetization_on_rounded,
                                      color: const Color(0xFF10B981),
                                      size: 14.r,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '${user.coins}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Body Content ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24.r, 24.r, 24.r, 0),
                        child: _buildMainLevelCard(
                          context,
                          currentLevel,
                          progress,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.r,
                          vertical: 24.h,
                        ),
                        child: _buildXPProgressDetails(context, user),
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildLevelPerks(context, user)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24.r, 32.h, 24.r, 0),
                        child: _buildMilestones(context, user),
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildHintStore(context, user)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24.r, 24.h, 24.r, 48.h),
                        child: const AdRewardCard(margin: EdgeInsets.zero),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainLevelCard(BuildContext context, int level, double progress) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = const Color(0xFFF59E0B);

    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(32.r),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: color,
                  size: 32.r,
                ),
              ),
              SizedBox(width: 18.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "GLOBAL RANK",
                      style: GoogleFonts.outfit(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "Level $level",
                      style: GoogleFonts.outfit(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          "MASTER EXPLORER",
                          style: GoogleFonts.outfit(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white38 : Colors.black38,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.trending_up_rounded,
                          size: 10.r,
                          color: color.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Stack(
            children: [
              Container(
                height: 10.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(5.r),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 10.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                    ),
                    borderRadius: BorderRadius.circular(5.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildXPProgressDetails(BuildContext context, UserEntity user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final xpInCurrentLevel = user.totalExp % 100;
    final xpNeeded = 100 - xpInCurrentLevel;
    final nextLevel = user.level + 1;

    return GlassTile(
      padding: EdgeInsets.all(20.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: const Color(0xFF3B82F6),
              size: 24.r,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT MILESTONE',
                  style: GoogleFonts.outfit(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF3B82F6),
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Level $nextLevel',
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '$xpNeeded XP more to ascend',
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelPerks(BuildContext context, UserEntity user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final perks = [
      {
        'title': 'Streak Protection',
        'desc': 'No reset on missed days',
        'level': 50,
        'icon': Icons.security_rounded,
        'color': const Color(0xFF10B981),
        'active': user.level >= 50,
      },
      {
        'title': '2x Coin Multiplier',
        'desc': 'Double rewards per quest',
        'level': 100,
        'icon': Icons.stars_rounded,
        'color': const Color(0xFFF59E0B),
        'active': user.level >= 100,
      },
      {
        'title': 'Avatar Aura',
        'desc': 'Holographic status glow',
        'level': 200,
        'icon': Icons.auto_awesome_rounded,
        'color': const Color(0xFF8B5CF6),
        'active': user.level >= 200,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            'LEVEL MASTERY PERKS',
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white38 : const Color(0xFF64748B),
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 140.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            physics: const BouncingScrollPhysics(),
            itemCount: perks.length,
            separatorBuilder: (context, index) => SizedBox(width: 16.w),
            itemBuilder: (context, index) {
              final perk = perks[index];
              final isActive = perk['active'] as bool;
              final color = perk['color'] as Color;

              return GlassTile(
                width: 240.w,
                padding: EdgeInsets.all(20.r),
                borderRadius: BorderRadius.circular(32.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            perk['icon'] as IconData,
                            color: color,
                            size: 20.r,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            isActive ? 'ACTIVE' : 'LOCKED',
                            style: GoogleFonts.outfit(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              color: isActive
                                  ? const Color(0xFF10B981)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      perk['title'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      isActive
                          ? perk['desc'] as String
                          : 'Unlocks at Level ${perk['level']}',
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMilestones(BuildContext context, UserEntity user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badges = BadgeConstants.badges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UPCOMING MILESTONES',
          style: GoogleFonts.outfit(
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white38 : const Color(0xFF64748B),
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 16.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: badges.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final badge = badges[index];
            final milestoneLevel = badge.minLevel ?? 0;
            final bool isReached = user.level >= milestoneLevel;
            final bool isClaimed = user.claimedLevelMilestones.contains(
              milestoneLevel,
            );

            return _buildMilestoneItem(
              context,
              badge.name,
              'Reach Level $milestoneLevel',
              badge.icon,
              badge.color,
              isReached,
              isClaimed,
              milestoneLevel,
            ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05);
          },
        ),
      ],
    );
  }

  Widget _buildMilestoneItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    bool isReached,
    bool isClaimed,
    int level,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: (isReached && !isClaimed)
          ? () {
              context.read<ProgressionBloc>().add(
                ProgressionClaimLevelMilestoneRequested(
                  level,
                  250, // Standard reward
                ),
              );
            }
          : null,
      child: GlassTile(
        padding: EdgeInsets.all(16.r),
        borderRadius: BorderRadius.circular(20.r),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: (isReached ? color : Colors.grey).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: isReached ? color : Colors.grey.withValues(alpha: 0.5),
                size: 24.r,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? (isReached ? Colors.white : Colors.white38)
                          : (isReached
                                ? const Color(0xFF1E293B)
                                : Colors.black26),
                    ),
                  ),
                  Text(
                    isClaimed ? 'Reward Claimed' : description,
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isClaimed)
              Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
                size: 24.r,
              )
            else if (isReached)
              Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'CLAIM',
                      style: GoogleFonts.outfit(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(duration: 2000.ms)
            else
              Icon(
                Icons.lock_outline_rounded,
                color: isDark ? Colors.white24 : Colors.black12,
                size: 20.r,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintStore(BuildContext context, UserEntity user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hints = [
      {
        'title': 'Strategic Pack',
        'desc': 'Get 5 Hints',
        'cost': 5000,
        'amount': 5,
        'icon': Icons.lightbulb_outline_rounded,
        'color': const Color(0xFFFBBF24),
      },
      {
        'title': 'Grand Master',
        'desc': 'Get 25 Hints',
        'cost': 20000,
        'amount': 25,
        'icon': Icons.auto_awesome_rounded,
        'color': const Color(0xFFF59E0B),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 0),
          child: Text(
            'HINT SHOP',
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white38 : const Color(0xFF64748B),
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: HintAdCard(
            title: 'Quick Hint',
            subtitle: 'Watch ad for +1 Hint',
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 90.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            physics: const BouncingScrollPhysics(),
            itemCount: hints.length,
            separatorBuilder: (context, index) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final item = hints[index];
              return GlassTile(
                width: 160.w,
                padding: EdgeInsets.all(12.r),
                borderRadius: BorderRadius.circular(20.r),
                child: InkWell(
                  onTap: () => _purchaseHint(
                    context,
                    user,
                    item['cost'] as int,
                    item['amount'] as int,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: (item['color'] as Color).withValues(
                            alpha: 0.1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 18.r,
                          color: item['color'] as Color,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item['title'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${item['cost']} Coins',
                              style: GoogleFonts.outfit(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _purchaseHint(
    BuildContext context,
    UserEntity user,
    int cost,
    int amount,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (user.coins < cost) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient Vowl Coins! Needed: $cost',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          child: GlassTile(
            borderRadius: BorderRadius.circular(32.r),
            padding: EdgeInsets.all(24.r),
            borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lightbulb_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 40.r,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  amount > 5 ? 'GRAND MASTER PACK' : 'STRATEGIC HINT PACK',
                  style: GoogleFonts.outfit(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Exchange $cost Vowl Coins for ${amount == 1 ? "1 hint" : "$amount hints"}.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 32.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text('CANCEL'),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context.read<EconomyBloc>().add(
                            EconomyPurchaseHintRequested(cost, hintAmount: amount),
                          );
                          HapticFeedback.heavyImpact();
                          _showSuccessSnackbar(context, amount);
                        },
                        child: Text('CONFIRM'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, int amount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'INVENTORY UPDATED: +$amount HINTS',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

