import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/core/presentation/widgets/ad_reward_card.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/theme/theme_cubit.dart';

class AdventureXPScreen extends StatelessWidget {
  const AdventureXPScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocListener<ProgressionBloc, ProgressionState>(
      listener: (context, state) {
        if (state.message != null) {
          final isError =
              state.message!.contains('not enough') ||
              state.message!.contains('failed');

          HapticFeedback.lightImpact();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: Colors.white,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      state.message!,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: isError
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(20.r),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Builder(
        builder: (context) {
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
                                  'Adventure XP',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
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
                          child: _buildTotalXPCard(context, user),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          child: _buildDailyXPChart(
                            context,
                            user.dailyXpHistory,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.r),
                          child: _buildMasteryGrid(context, user),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.h),
                          child: _buildAdventureStore(context, user),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.r),
                          child: _buildRecentActivities(context, user),
                        ),
                      ),
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
    },
  ),
);
}

  Widget _buildTotalXPCard(BuildContext context, UserEntity user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalXP = user.totalExp;
    final color = const Color(0xFF6366F1);

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
                  Icons.auto_fix_high_rounded,
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
                      "TOTAL EXPERIENCE",
                      style: GoogleFonts.outfit(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "$totalXP XP",
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
                          "KEEP EXPLORING!",
                          style: GoogleFonts.outfit(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white38 : Colors.black38,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.insights_rounded,
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
        ],
      ),
    );
  }

  Widget _buildDailyXPChart(BuildContext context, Map<String, int> history) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    const color = Color(0xFF6366F1);

    int maxXP = 100;
    final last7DaysXP = List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final xp = history[dateKey] ?? 0;
      if (xp > maxXP) maxXP = xp;
      return xp;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            'DAILY XP HISTORY',
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white38 : const Color(0xFF64748B),
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          physics: const BouncingScrollPhysics(),
          child: GlassTile(
            width: 320.w,
            padding: EdgeInsets.all(20.r),
            borderRadius: BorderRadius.circular(32.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final xp = last7DaysXP[index];
                final heightFactor = (xp / maxXP).clamp(0.05, 1.0);
                final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                return Column(
                  children: [
                    Container(
                      height: 80.h,
                      width: 36.w,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: heightFactor,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: xp > 0
                                  ? [color, color.withValues(alpha: 0.6)]
                                  : [
                                      Colors.grey.withValues(alpha: 0.1),
                                      Colors.grey.withValues(alpha: 0.2),
                                    ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: xp > 0
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      days[index],
                      style: GoogleFonts.outfit(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMasteryGrid(BuildContext context, UserEntity user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = QuestType.values.map((type) {
      final name = type.name;
      final displayTitle = name[0].toUpperCase() + name.substring(1);
      final progress = user.getCategoryProgress(type);

      // Calculate total levels for this category
      int levelsCompleted = 0;
      for (final subtype in type.subtypes) {
        final completed = user.completedLevels[subtype.name] ?? [];
        levelsCompleted += completed.length;
      }

      IconData icon;
      Color color;
      switch (type) {
        case QuestType.speaking:
          icon = Icons.mic_rounded;
          color = const Color(0xFFEF4444);
          break;
        case QuestType.listening:
          icon = Icons.headphones_rounded;
          color = const Color(0xFF06B6D4);
          break;
        case QuestType.reading:
          icon = Icons.menu_book_rounded;
          color = const Color(0xFF3B82F6);
          break;
        case QuestType.writing:
          icon = Icons.edit_rounded;
          color = const Color(0xFF10B981);
          break;
        case QuestType.grammar:
          icon = Icons.book_rounded;
          color = const Color(0xFF8B5CF6);
          break;
        case QuestType.vocabulary:
          icon = Icons.psychology_rounded;
          color = const Color(0xFFF59E0B);
          break;
        case QuestType.accent:
          icon = Icons.graphic_eq_rounded;
          color = const Color(0xFFF43F5E);
          break;
        case QuestType.roleplay:
          icon = Icons.groups_rounded;
          color = const Color(0xFF6366F1);
          break;
        case QuestType.eliteMastery:
          icon = Icons.workspace_premium_rounded;
          color = const Color(0xFFFFD700);
          break;
      }

      return {
        'name': displayTitle,
        'icon': icon,
        'progress': progress,
        'levels': levelsCompleted,
        'color': color,
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LANGUAGE MASTERY',
          style: GoogleFonts.outfit(
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white38 : const Color(0xFF64748B),
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 16.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12.r,
            crossAxisSpacing: 12.r,
            childAspectRatio: 1.3,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final prog = cat['progress'] as int;
            String levelLabel = 'Novice';
            if (prog >= 80) {
              levelLabel = 'Master';
            } else if (prog >= 40) {
              levelLabel = 'Adept';
            }

            return GlassTile(
              padding: EdgeInsets.all(16.r),
              borderRadius: BorderRadius.circular(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: (cat['color'] as Color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          cat['icon'] as IconData,
                          size: 18.r,
                          color: cat['color'] as Color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$prog%',
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          color: cat['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    cat['name'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${cat['levels']} levels · ',
                        style: GoogleFonts.outfit(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      Text(
                        levelLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: (cat['color'] as Color).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: LinearProgressIndicator(
                      value: prog / 100,
                      backgroundColor: (cat['color'] as Color).withValues(
                        alpha: 0.1,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        cat['color'] as Color,
                      ),
                      minHeight: 6.h,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdventureStore(BuildContext context, UserEntity user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final offers = [
      {
        'title': 'Streak Shield',
        'desc': 'Protects progress (+1 Freeze)',
        'cost': 400,
        'icon': Icons.shield_rounded,
        'color': const Color(0xFF10B981),
        'type': 'shield',
      },
      {
        'title': 'Time Warp',
        'desc': '2x Multiplier (1hr active)',
        'cost': 250,
        'icon': Icons.timer_outlined,
        'color': const Color(0xFF3B82F6),
        'type': 'warp',
        'active':
            user.doubleXPExpiry != null &&
            user.doubleXPExpiry!.isAfter(DateTime.now()),
      },
      {
        'title': 'Golden Scroll',
        'desc': 'Permanent 1.1x XP boost',
        'cost': 2000,
        'icon': Icons.auto_awesome,
        'color': const Color(0xFF8B5CF6),
        'type': 'scroll',
        'locked': user.level < 200 || !user.isPremium,
        'active': user.hasPermanentXPBoost,
      },
    ];

    return BlocBuilder<ProgressionBloc, ProgressionState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADVENTURE STORE',
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white38 : const Color(0xFF64748B),
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Boost your progress with legendary items',
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 100.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                physics: const BouncingScrollPhysics(),
                itemCount: offers.length,
                separatorBuilder: (context, index) => SizedBox(width: 12.w),
                itemBuilder: (context, index) {
                  final item = offers[index];
                  final isLocked = item['locked'] as bool? ?? false;
                  final isCurrentlyActive = item['active'] == true;

                  return Opacity(
                    opacity: isLocked ? 0.6 : 1.0,
                    child: GestureDetector(
                      onTap: isLocked || isCurrentlyActive
                          ? null
                          : () {
                              if (item['type'] == 'shield') {
                                context.read<ProgressionBloc>().add(
                                  ProgressionPurchaseStreakFreezeRequested(item['cost'] as int),
                                );
                              } else if (item['type'] == 'warp') {
                                context.read<ProgressionBloc>().add(
                                  ProgressionActivateDoubleXPRequested(item['cost'] as int),
                                );
                              } else if (item['type'] == 'scroll') {
                                context.read<ProgressionBloc>().add(
                                  ProgressionPurchasePermanentXPBoostRequested(item['cost'] as int),
                                );
                              }
                            },
                      child: GlassTile(
                        width: 200.w,
                        padding: EdgeInsets.all(12.r),
                        borderRadius: BorderRadius.circular(24.r),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.r),
                              decoration: BoxDecoration(
                                color: (item['color'] as Color).withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                size: 20.r,
                                color: item['color'] as Color,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item['title'] as String,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (state.lastPurchaseType == item['type'] &&
                                      state.lastPurchaseSuccess != null)
                                    Text(
                                      state.lastPurchaseSuccess!
                                          ? 'BOUGHT!'
                                          : 'LACKING COINS',
                                      style: GoogleFonts.outfit(
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.w900,
                                        color: state.lastPurchaseSuccess!
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                      ),
                                    )
                                  else
                                    Text(
                                      isLocked
                                          ? 'Premium Lvl 200'
                                          : isCurrentlyActive
                                          ? 'ITEM ACTIVE'
                                          : '${item['cost']} Coins',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w700,
                                        color: isLocked
                                            ? Colors.red.withValues(alpha: 0.7)
                                            : isCurrentlyActive
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF10B981),
                                      ),
                                    ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    item['desc'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivities(BuildContext context, UserEntity user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activities = user.recentActivities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT ACTIVITY',
          style: GoogleFonts.outfit(
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white38 : const Color(0xFF64748B),
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 16.h),
        if (activities.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Text(
                'No recent adventures yet.',
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: activities.length > 5 ? 5 : activities.length,
            separatorBuilder: (context, index) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return GlassTile(
                padding: EdgeInsets.all(12.r),
                borderRadius: BorderRadius.circular(16.r),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        activity['type'] == 'quest'
                            ? Icons.explore_rounded
                            : Icons.shopping_bag_rounded,
                        size: 16.r,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] ?? 'Adventure',
                            style: GoogleFonts.outfit(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            activity['subtitle'] ?? 'Just completed',
                            style: GoogleFonts.outfit(
                              fontSize: 11.sp,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatRelativeTime(activity['timestamp']),
                      style: GoogleFonts.outfit(
                        fontSize: 10.sp,
                        color: isDark ? Colors.white24 : Colors.black26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatRelativeTime(dynamic timestamp) {
    if (timestamp == null) return 'Now';
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is String) {
      dt = DateTime.parse(timestamp);
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return 'Now';
    }

    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

