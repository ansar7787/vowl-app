import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/core/presentation/widgets/ad_reward_card.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/theme/theme_cubit.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      toolbarHeight: 70.h,
                      automaticallyImplyLeading: false,
                      title: GlassTile(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        borderRadius: BorderRadius.circular(24.r),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32.r,
                              height: 32.r,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 18.r,
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Daily Streak',
                              style: GoogleFonts.outfit(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            _buildCoinsChip(user),
                          ],
                        ),
                      ),
                    ),

                    // ── Body Content ──
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 40.h),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildHeroStreak(context, user),
                          SizedBox(height: 24.h),
                          _buildGlassSection(
                            context,
                            title: 'Activity Heatmap',
                            icon: LucideIcons.calendar,
                            child: _buildModernCalendar(context, user),
                          ),
                          SizedBox(height: 32.h),
                          _buildStreakMilestones(context, user),
                          SizedBox(height: 32.h),
                          _buildEngagementShop(context, user),
                          SizedBox(height: 24.h),
                          const AdRewardCard(margin: EdgeInsets.zero),
                          SizedBox(height: 40.h),
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
    );
  }

  Widget _buildCoinsChip(UserEntity user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.15),
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
    );
  }

  Widget _buildHeroStreak(BuildContext context, UserEntity user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = user.currentStreak;
    final color = const Color(0xFFFF5F6D);

    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(32.r),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                    width: 100.r,
                    height: 100.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.2, 1.2),
                    duration: 2.seconds,
                    curve: Curves.easeInOut,
                  )
                  .fadeIn(duration: 1.seconds),
              Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, const Color(0xFFFFC371)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 4,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.flame,
                      color: Colors.white,
                      size: 40.r,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            "$streak",
            style: GoogleFonts.outfit(
              fontSize: 56.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              height: 1.0,
            ),
          ).animate().fadeIn().scale(duration: 600.ms),
          Text(
            "DAY STREAK",
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 4,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.sparkles, color: color, size: 14.r),
                SizedBox(width: 8.w),
                Text(
                  "YOU'RE ON FIRE!",
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassTile(
      padding: EdgeInsets.all(20.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.blueAccent : Colors.blue).withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 14.r,
                  color: isDark ? Colors.blueAccent : Colors.blue,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.6),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          child,
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05);
  }

  Widget _buildModernCalendar(BuildContext context, UserEntity user) {
    final now = DateTime.now();
    // Activity Heatmap Logic: Show the last 7 days ending today
    final startOfHeatmap = now.subtract(const Duration(days: 6));
    final history = user.dailyXpHistory;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final day = startOfHeatmap.add(Duration(days: index));
        final dateKey = DateFormat('yyyy-MM-dd').format(day);
        final xp = history[dateKey] ?? 0;
        final isToday =
            day.day == now.day &&
            day.month == now.month &&
            day.year == now.year;

        // Robust check for today's completion: either XP > 0 or lastLoginDate is today and currentStreak > 0
        final bool isSameLoginDay =
            user.lastLoginDate != null &&
            user.lastLoginDate!.day == now.day &&
            user.lastLoginDate!.month == now.month &&
            user.lastLoginDate!.year == now.year;

        final isPlayed =
            xp > 0 || (isToday && isSameLoginDay && user.currentStreak > 0);
        final isFuture = day.isAfter(now);

        return Expanded(
          child: Column(
            children: [
              Text(
                DateFormat('E').format(day)[0],
                style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  color: isToday
                      ? Colors.blueAccent
                      : Colors.white.withValues(alpha: 0.3),
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 10.h),
              _buildDayIndicator(context, isPlayed, isToday, isFuture, xp),
              SizedBox(height: 10.h),
              Text(
                '${day.day}',
                style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
                  color: isToday ? Colors.blueAccent : null,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDayIndicator(
    BuildContext context,
    bool isPlayed,
    bool isToday,
    bool isFuture,
    int xp,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 36.r,
      height: 36.r,
      decoration: BoxDecoration(
        gradient: (!isFuture && isPlayed)
            ? const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEF4444)],
              )
            : null,
        color: isFuture
            ? (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05))
            : (!isPlayed
                  ? (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05))
                  : null),
        shape: BoxShape.circle,
        border: (isToday && !isFuture)
            ? Border.all(color: Colors.blueAccent, width: 2)
            : (isFuture
                  ? Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    )
                  : (isPlayed
                        ? null
                        : Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05),
                          ))),
        boxShadow: (!isFuture && isPlayed)
            ? [
                BoxShadow(
                  color: const Color(0xFFF97316).withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ]
            : (isToday && !isFuture
                  ? [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null),
      ),
      child: Center(
        child: isFuture
            ? null
            : (isPlayed
                  ? Icon(LucideIcons.flame, color: Colors.white, size: 18.r)
                  : (isToday
                        ? Icon(
                                LucideIcons.circle,
                                color: Colors.blueAccent,
                                size: 8.r,
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.2, 1.2),
                                duration: 1.seconds,
                              )
                        : null)),
      ),
    );
  }

  Widget _buildEngagementShop(BuildContext context, UserEntity user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STREAK BOOSTERS',
              style: GoogleFonts.outfit(
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.circleDollarSign,
                    color: Colors.green,
                    size: 16.r,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${user.coins}',
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ).animate().shimmer(duration: 3.seconds, color: Colors.white24),
          ],
        ),
        SizedBox(height: 24.h),
        _buildShopItem(
          context,
          title: 'STREAK REPAIR',
          subtitle: 'Melt the ice and restore your flame from yesterday.',
          icon: LucideIcons.flame,
          color: const Color(0xFFFF5F6D),
          cost: 200,
          currentCoins: user.coins,
          isDisabled:
              user.currentStreak >
              0, // Logic: Only repair if streak is lost (reset to 1 or 0)
          onTap: user.currentStreak > 0
              ? null
              : () => _handlePurchase(
                  context,
                  name: 'Streak Repair',
                  cost: 200,
                  currentCoins: user.coins,
                  action: () => context.read<ProgressionBloc>().add(
                    const ProgressionRepairStreakRequested(200),
                  ),
                ),
          onAdTap: user.currentStreak > 0
              ? null
              : () {
                  final adService = di.sl<AdService>();
                  adService.showRewardedAd(
                    isPremium: user.isPremium,
                    onDismissed: () {},
                    onUserEarnedReward: (reward) {
                      context.read<ProgressionBloc>().add(
                        const ProgressionRepairStreakWithAdRequested(),
                      );
                      Haptics.vibrate(HapticsType.success);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("STREAK REPAIRED! 🔥"),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                  );
                },
        ),
        SizedBox(height: 16.h),
        _buildShopItem(
          context,
          title: 'STREAK SHIELD',
          subtitle: 'A mystical barrier that prevents streak loss.',
          icon: LucideIcons.shieldCheck,
          color: const Color(0xFF38BDF8),
          cost: 150,
          count: user.streakFreezes,
          currentCoins: user.coins,
          onTap: () => _handlePurchase(
            context,
            name: 'Streak Shield',
            cost: 150,
            currentCoins: user.coins,
            action: () => context.read<ProgressionBloc>().add(
              const ProgressionPurchaseStreakFreezeRequested(150),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildShopItem(
          context,
          title: 'DOUBLE XP BOOST',
          subtitle: 'Double the wisdom, double the progress for 24h.',
          icon: LucideIcons.zap,
          color: const Color(0xFFFCD34D),
          cost: 300,
          isActive: user.isDoubleXPActive,
          activeUntil: user.doubleXPExpiry,
          currentCoins: user.coins,
          onTap: () => _handlePurchase(
            context,
            name: 'Double XP',
            cost: 300,
            currentCoins: user.coins,
            action: () => context.read<ProgressionBloc>().add(
              const ProgressionActivateDoubleXPRequested(300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakMilestones(BuildContext context, UserEntity user) {
    // Dynamic Milestone Logic: Starter set + Periodic Centuries + Yearly Bonuses
    final List<Map<String, int>> milestones = [];
    final Set<int> addedDays = {};

    void addMilestone(int d) {
      if (!addedDays.contains(d)) {
        int reward;
        if (d % 365 == 0) {
          reward = 5000; // Premium Yearly Reward
        } else {
          reward = d * 10; // Scaling reward
        }
        milestones.add({'days': d, 'reward': reward});
        addedDays.add(d);
      }
    }

    // 1. Add Starter Set
    [10, 50, 100, 200, 300, 365].forEach(addMilestone);

    // 2. Add All Previously Claimed (to ensure they don't disappear)
    user.claimedStreakMilestones.forEach(addMilestone);

    // 3. Procedural Logic: Add next milestones based on current streak
    int current = user.currentStreak;

    // Add the most recent milestone reached (if not in starter)
    int lastCentury = (current ~/ 100) * 100;
    if (lastCentury > 0) addMilestone(lastCentury);

    // Add next 2 future "Centuries"
    int nextCentury = ((current ~/ 100) + 1) * 100;
    addMilestone(nextCentury);
    addMilestone(nextCentury + 100);

    // Add next "Yearly"
    int nextYear = ((current ~/ 365) + 1) * 365;
    addMilestone(nextYear);

    // Sort to ensure chronological order
    milestones.sort((a, b) => a['days']!.compareTo(b['days']!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STREAK MILESTONES',
          style: GoogleFonts.outfit(
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 16.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          child: Row(
            children: milestones.map((m) {
              final days = m['days'] as int;
              final reward = m['reward'] as int;
              final isReached = user.currentStreak >= days;
              final isClaimed = user.claimedStreakMilestones.contains(days);
              final isNext =
                  !isReached &&
                  (milestones.firstWhere(
                        (element) =>
                            (element['days'] as int) > user.currentStreak,
                        orElse: () => milestones.last,
                      )['days'] ==
                      days);

              return Container(
                width: 120.w,
                margin: EdgeInsets.only(right: 12.w),
                child: Stack(
                  children: [
                    Container(
                      width: 120.w,
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: isReached
                            ? Colors.amber.withValues(alpha: 0.1)
                            : (isNext
                                  ? Colors.blue.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.03)),
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(
                          color: isClaimed
                              ? Colors.amber.withValues(alpha: 0.3)
                              : (isReached
                                    ? Colors.amber
                                    : (isNext
                                          ? Colors.blue.withValues(alpha: 0.4)
                                          : Colors.white.withValues(
                                              alpha: 0.1,
                                            ))),
                          width: isNext ? 2 : 1,
                        ),
                        boxShadow: isNext
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: (isReached ? Colors.amber : Colors.grey)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isClaimed
                                  ? LucideIcons.checkCircle
                                  : LucideIcons.gift,
                              color: isReached ? Colors.amber : Colors.grey,
                              size: 20.r,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            days % 365 == 0
                                ? '${(days / 365).toInt()} YEAR${days / 365 == 1 ? '' : 'S'}'
                                : '$days DAYS',
                            style: GoogleFonts.outfit(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                              color: isReached ? Colors.amber : Colors.grey,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '+$reward COINS',
                            style: GoogleFonts.outfit(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: isReached
                                  ? Colors.amber.withValues(alpha: 0.7)
                                  : Colors.grey.withValues(alpha: 0.5),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          if (isReached && !isClaimed)
                            ElevatedButton(
                                  onPressed: () => context.read<ProgressionBloc>().add(
                                    ProgressionClaimStreakMilestoneRequested(
                                      days,
                                      reward,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 8.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'CLAIM',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                )
                                .animate(onPlay: (c) => c.repeat())
                                .shimmer(duration: 2.seconds)
                          else if (isClaimed)
                            Text(
                              'CLAIMED',
                              style: GoogleFonts.outfit(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.amber.withValues(alpha: 0.5),
                              ),
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
                              child: LinearProgressIndicator(
                                value: user.currentStreak / days,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isNext ? Colors.blue : Colors.grey,
                                ),
                                minHeight: 4.h,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isNext)
                      Positioned.fill(
                        child: IgnorePointer(
                          child:
                              Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24.r),
                                    ),
                                  )
                                  .animate(onPlay: (c) => c.repeat())
                                  .shimmer(
                                    duration: 3.seconds,
                                    color: Colors.blue.withValues(alpha: 0.1),
                                  ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _handlePurchase(
    BuildContext context, {
    required String name,
    required int cost,
    required int currentCoins,
    required VoidCallback action,
  }) async {
    if (_isProcessing) return; // Anti-spam protection

    if (currentCoins < cost) {
      Haptics.vibrate(HapticsType.error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20.r,
              ),
              SizedBox(width: 12.w),
              Text(
                "Insufficient Vowl Coins! Needed: $cost",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20.r),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    Haptics.vibrate(HapticsType.heavy);
    
    // Execute purchase
    action();

    // Show premium success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(4.r),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: Colors.white, size: 16.r),
            ),
            SizedBox(width: 12.w),
            Text(
              "$name Activated!",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 12.sp,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: EdgeInsets.all(20.r),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
    );

    // Release lock after a short delay to allow UI to sync
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _isProcessing = false);
  }

  Widget _buildShopItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int cost,
    required int currentCoins,
    required VoidCallback? onTap,
    VoidCallback? onAdTap,
    int? count,
    bool isActive = false,
    bool isDisabled = false,
    DateTime? activeUntil,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canAfford = currentCoins >= cost;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(24.r),
          child: Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isDisabled
                    ? Colors.white.withValues(alpha: 0.05)
                    : (canAfford
                          ? color.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2)),
                width: 1.5,
              ),
              boxShadow: [
                if (canAfford)
                  BoxShadow(
                    color: color.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Row(
              children: [
                !isDisabled
                    ? Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(icon, color: color, size: 24.r),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.1, 1.1),
                            duration: 2.seconds,
                          )
                    : Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.grey, size: 24.r),
                      ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (count != null && count > 0) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'x$count',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDisabled ? Colors.grey : color,
                                ),
                              ),
                            ),
                          ],
                          if (isActive || isDisabled) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isActive
                                             ? const Color(0xFF10B981)
                                             : Colors.grey)
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                isActive ? 'ACTIVE' : 'NOT NEEDED',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isActive
                                      ? const Color(0xFF10B981)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          color: isDisabled
                              ? Colors.grey.withValues(alpha: 0.5)
                              : (isDark ? Colors.white54 : Colors.black54),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isActive && activeUntil != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          "Expires ${DateFormat('MMM d, h:mm a').format(activeUntil)}",
                          style: GoogleFonts.outfit(
                            fontSize: 10.sp,
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isDisabled && !isActive) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: canAfford ? color.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: canAfford ? color.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.circleDollarSign,
                          color: canAfford ? color : Colors.red,
                          size: 14.r,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '$cost',
                          style: GoogleFonts.outfit(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: canAfford ? color : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (onAdTap != null && !isDisabled) ...[
                  SizedBox(width: 8.w),
                  InkWell(
                    onTap: onAdTap,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.playCircle,
                            color: Colors.amber,
                            size: 12.r,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'FREE',
                            style: GoogleFonts.outfit(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

