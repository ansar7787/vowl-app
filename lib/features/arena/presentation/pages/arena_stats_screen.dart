import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/arena/presentation/pages/arena_matchmaking_screen.dart';
import 'package:vowl/features/arena/presentation/utils/arena_network_helper.dart';
import 'package:vowl/features/arena/presentation/utils/arena_refuel_helper.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

/// Next-generation 2026 Arena stats screen.
///
/// Built for 120 FPS fluid rendering:
/// - Flattened single-layer cards (no heavy card-inside-card nesting).
/// - Clean outer shadows and borders matching the Vowl design language.
/// - Fully cached user avatar via [UserAvatar] ([CachedNetworkImage]).
/// - Centered 4-card metric grid for athletic balance.
/// - Human, authentic game copy (zero robotic/AI buzzwords).
/// - Adaptive light, dark, and midnight mode surfaces.
/// - Shimmer loading skeleton support for smooth transitions.
class ArenaStatsScreen extends StatelessWidget {
  final UserEntity user;
  final bool isLoading;

  const ArenaStatsScreen({
    super.key,
    required this.user,
    this.isLoading = false,
  });

  /// Accurately computes how many 1v1 Arena matches the user has played today.
  ///
  /// Combines timestamp verification from the authentic [coinHistory] ledger
  /// with calendar day validation of [lastDuelDate], avoiding any legacy
  /// accumulation bugs.
  static int calculateDailyDuelsPlayedToday(UserEntity user) {
    final now = DateTime.now();

    // 1. Count actual duel transactions recorded today in coinHistory
    int matchesTodayFromHistory = 0;
    for (final entry in user.coinHistory) {
      final titleKey = entry['titleKey'] as String? ?? '';
      final isDuelEvent = titleKey.contains('arena_duel_win') ||
          titleKey.contains('arena_duel_perfect') ||
          titleKey.contains('arena_duel_consolation') ||
          titleKey.contains('arena_duel_refund');
      if (!isDuelEvent) continue;

      final rawDate = entry['date'] ?? entry['timestamp'];
      if (rawDate == null) continue;
      try {
        DateTime dt;
        if (rawDate is DateTime) {
          dt = rawDate;
        } else if (rawDate is String) {
          dt = DateTime.parse(rawDate);
        } else {
          final dynamic ts = rawDate;
          dt = ts.toDate() as DateTime;
        }
        final localDt = dt.toLocal();
        if (localDt.year == now.year &&
            localDt.month == now.month &&
            localDt.day == now.day) {
          matchesTodayFromHistory++;
        }
      } catch (_) {}
    }

    if (matchesTodayFromHistory > 0) {
      return matchesTodayFromHistory;
    }

    // 2. Validate calendar day of lastDuelDate if recorded
    final lastDuel = user.lastDuelDate?.toLocal();
    if (lastDuel != null) {
      final bool isDuelToday = lastDuel.year == now.year &&
          lastDuel.month == now.month &&
          lastDuel.day == now.day;

      // If last duel was definitively on an earlier date, count is strictly 0
      if (!isDuelToday) {
        return 0;
      }
    }

    // If the user has coinHistory records but none from today, and no duel timestamp today:
    if (user.coinHistory.isNotEmpty && lastDuel == null) {
      return 0;
    }

    // 3. Fallback to dailyDuelsPlayedToday, guarding against legacy all-time duplication
    if (user.dailyDuelsPlayedToday > 0) {
      final totalDuels = user.duelWins + user.duelLosses;
      if (totalDuels > 0 && user.dailyDuelsPlayedToday >= totalDuels) {
        return 1;
      }
      return user.dailyDuelsPlayedToday;
    }

    return 0;
  }

  /// Static route builder.
  static Route<void> route({required UserEntity user}) {
    return MaterialPageRoute<void>(
      builder: (_) => ArenaStatsScreen(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMidnight = AppTheme.isMidnight(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => prev.user != curr.user,
      builder: (context, authState) {
        final liveUser = authState.user ?? user;
        final totalDuels = liveUser.duelWins + liveUser.duelLosses;
        final double winRateRatio = totalDuels > 0
            ? (liveUser.duelWins / totalDuels)
            : 0.0;
        final int winRatePercent = (winRateRatio * 100).round();

        return Scaffold(
          backgroundColor: isMidnight
              ? Colors.black
              : (isDark ? AppColors.ultraDeep : AppColors.slate50),
          body: Stack(
            children: [
              // 1. Ambient Background (Repaint isolated)
              const Positioned.fill(
                child: RepaintBoundary(
                  child: MeshGradientBackground(auraColor: AppColors.indigo500),
                ),
              ),

              // 2. Safe Area Content
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // iOS-style Top Bar
                    RepaintBoundary(
                      child: _ArenaAppBar(
                        coins: liveUser.coins,
                        isDark: isDark,
                        isMidnight: isMidnight,
                      ),
                    ),

                    // Scrollable Body
                    Expanded(
                      child: isLoading
                          ? _ArenaStatsShimmer(isDark: isDark)
                          : SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 12.h),

                                  // Hero Player Card
                                  _ArenaHeroCard(
                                    user: liveUser,
                                    totalDuels: totalDuels,
                                    winRatePercent: winRatePercent,
                                    winRateRatio: winRateRatio,
                                    isDark: isDark,
                                    isMidnight: isMidnight,
                                  ),

                                  SizedBox(height: 14.h),

                                  // 4 Metric Tiles (Centered content)
                                  _ArenaMetricsGrid(
                                    user: liveUser,
                                    winRatePercent: winRatePercent,
                                    isDark: isDark,
                                    isMidnight: isMidnight,
                                  ),

                                  SizedBox(height: 14.h),

                                  // Coin Summary & 5-Round Strip
                                  _ArenaCoinSummaryCard(
                                    user: liveUser,
                                    totalDuels: totalDuels,
                                    isDark: isDark,
                                    isMidnight: isMidnight,
                                  ),

                                  SizedBox(height: 14.h),

                                  // Recent Match Record
                                  _ArenaRecentMatches(
                                    user: liveUser,
                                    isDark: isDark,
                                    isMidnight: isMidnight,
                                  ),

                                  // Clearance for floating bottom dock
                                  SizedBox(height: 96.h + bottomInset),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              // 3. Floating Bottom Dock (Repaint isolated)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: RepaintBoundary(
                  child: _PlayArenaDock(
                    user: liveUser,
                    isDark: isDark,
                    bottomInset: bottomInset,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 1. iOS-style Navigation Bar
// ---------------------------------------------------------------------------

class _ArenaAppBar extends StatelessWidget {
  final int coins;
  final bool isDark;
  final bool isMidnight;

  const _ArenaAppBar({
    required this.coins,
    required this.isDark,
    required this.isMidnight,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate200);

    final cardBg = isMidnight
        ? Colors.black.withValues(alpha: 0.6)
        : (isDark
              ? AppColors.slate800.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.85));

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      child: Row(
        children: [
          // iOS Frosted Glass Back Button
          ScaleButton(
            onTap: () {
              if (di.sl.isRegistered<HapticService>()) {
                di.sl<HapticService>().selection();
              }
              Navigator.of(context).maybePop();
            },
            child: Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(left: 4.w),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16.r,
                    color: isDark ? Colors.white : AppColors.slate800,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Title & Human Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '1v1 Word Arena',
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.slate900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.indigo500, AppColors.violet500],
                          ),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'PVP',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Arena Record',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                  ),
                ),
              ],
            ),
          ),

          // Live Coin Pill
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.amber500.withValues(alpha: 0.35),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.amber500.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🪙', style: TextStyle(fontSize: 13.sp)),
                SizedBox(width: 4.w),
                Text(
                  '$coins',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Hero Player Card (Clean Single Surface - No Nested Cards)
// ---------------------------------------------------------------------------

class _ArenaHeroCard extends StatelessWidget {
  final UserEntity user;
  final int totalDuels;
  final int winRatePercent;
  final double winRateRatio;
  final bool isDark;
  final bool isMidnight;

  const _ArenaHeroCard({
    required this.user,
    required this.totalDuels,
    required this.winRatePercent,
    required this.winRateRatio,
    required this.isDark,
    required this.isMidnight,
  });

  @override
  Widget build(BuildContext context) {
    final Color gaugeColor =
        winRatePercent >= 50 ? AppColors.emerald500 : AppColors.indigo500;

    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.midnightNavy : Colors.white);

    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? gaugeColor.withValues(alpha: 0.25) : AppColors.slate200);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cached User Avatar
          UserAvatar(
            photoUrl: user.photoUrl,
            size: 54.r,
            border: Border.all(
              color: gaugeColor.withValues(alpha: 0.4),
              width: 2,
            ),
          ),

          SizedBox(width: 14.w),

          // Player Name & Real All-time 1v1 Arena Matches Record
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    user.safeDisplayName,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.slate900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.swords,
                      size: 13.r,
                      color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      '$totalDuels ${totalDuels == 1 ? "match" : "matches"} played',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: 10.w),

          // Compact Radial Win Rate Gauge
          _CircularGauge(
            percent: winRatePercent,
            ratio: winRateRatio,
            color: gaugeColor,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Compact Radial Win Gauge
// ---------------------------------------------------------------------------

class _CircularGauge extends StatelessWidget {
  final int percent;
  final double ratio;
  final Color color;
  final bool isDark;

  const _CircularGauge({
    required this.percent,
    required this.ratio,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58.r,
      height: 58.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track
          SizedBox(
            width: 56.r,
            height: 56.r,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 5.r,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.slate200,
            ),
          ),

          // Active Arc
          SizedBox(
            width: 56.r,
            height: 56.r,
            child: CircularProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              strokeWidth: 5.r,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          // Center Text
          Padding(
            padding: EdgeInsets.all(4.r),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.slate900,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'WIN RATE',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 6.5.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white38 : AppColors.slate500,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Centered 4-Metric Grid (Athletic Balance)
// ---------------------------------------------------------------------------

class _ArenaMetricsGrid extends StatelessWidget {
  final UserEntity user;
  final int winRatePercent;
  final bool isDark;
  final bool isMidnight;

  const _ArenaMetricsGrid({
    required this.user,
    required this.winRatePercent,
    required this.isDark,
    required this.isMidnight,
  });

  @override
  Widget build(BuildContext context) {
    final dailyPlayed = ArenaStatsScreen.calculateDailyDuelsPlayedToday(user);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _CenteredMetricTile(
                icon: LucideIcons.trophy,
                label: 'Wins',
                value: '${user.duelWins}',
                subtitle: '+50 coins each',
                color: AppColors.emerald500,
                isDark: isDark,
                isMidnight: isMidnight,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _CenteredMetricTile(
                icon: LucideIcons.shieldAlert,
                label: 'Losses',
                value: '${user.duelLosses}',
                subtitle: '+10 coins each',
                color: AppColors.rose500,
                isDark: isDark,
                isMidnight: isMidnight,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _CenteredMetricTile(
                icon: LucideIcons.percent,
                label: 'Win Rate',
                value: '$winRatePercent%',
                subtitle: 'All time',
                color: AppColors.indigo500,
                isDark: isDark,
                isMidnight: isMidnight,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _CenteredMetricTile(
                icon: LucideIcons.flame,
                label: 'Played Today',
                value: '$dailyPlayed',
                subtitle: 'Daily matches',
                color: AppColors.amber500,
                isDark: isDark,
                isMidnight: isMidnight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CenteredMetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final bool isDark;
  final bool isMidnight;

  const _CenteredMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.isMidnight,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.midnightNavy : Colors.white);

    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.10)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate200);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Centered Icon in soft circle
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18.r, color: color),
          ),

          SizedBox(height: 8.h),

          // Centered Value
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.slate900,
                letterSpacing: -0.5,
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Centered Label
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppColors.slate600,
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Centered Subtitle
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : AppColors.slate400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Coin Summary & 5-Round Preview Strip
// ---------------------------------------------------------------------------

class _ArenaCoinSummaryCard extends StatelessWidget {
  final UserEntity user;
  final int totalDuels;
  final bool isDark;
  final bool isMidnight;

  const _ArenaCoinSummaryCard({
    required this.user,
    required this.totalDuels,
    required this.isDark,
    required this.isMidnight,
  });

  @override
  Widget build(BuildContext context) {
    // 1. All-time career totals based on user's real duel record:
    // 30 coins staked per duel played
    final careerStaked = totalDuels * 30;
    final careerEarned = (user.duelWins * 50) + (user.duelLosses * 10);

    // 2. Incorporate any perfect win bonuses (+60) or recorded stakes from ledger:
    int historyEarned = 0;
    int historyStaked = 0;
    for (final entry in user.coinHistory) {
      final key = entry['titleKey'] as String? ?? '';
      final amt = (entry['amount'] as num?)?.toInt() ?? 0;
      if (key.contains('arena_duel_win') ||
          key.contains('arena_duel_perfect') ||
          key.contains('arena_duel_consolation')) {
        historyEarned += amt;
      } else if (key.contains('arena_duel_stake')) {
        historyStaked += amt.abs();
      }
    }

    final totalEarned = max(careerEarned, historyEarned);
    final totalStaked = max(careerStaked, historyStaked);
    final netCoins = totalEarned - totalStaked;
    final bool isNetPositive = netCoins >= 0;

    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.midnightNavy : Colors.white);

    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.10)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate200);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Arena Coins',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color:
                      (isNetPositive ? AppColors.emerald500 : AppColors.rose500)
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${isNetPositive ? "+" : ""}$netCoins coins',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: isNetPositive
                        ? AppColors.emerald500
                        : AppColors.rose500,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Two-column Breakdown
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      totalEarned > 0 ? '+$totalEarned🪙' : '0🪙',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.emerald500,
                      ),
                    ),
                    Text(
                      'Coins Won',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      totalStaked > 0 ? '-$totalStaked🪙' : '0🪙',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white70 : AppColors.slate700,
                      ),
                    ),
                    Text(
                      'Coins Staked',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // 5-Rounds Preview Strip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.indigo500.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '5 Rounds per Match',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.indigo400
                            : AppColors.indigo600,
                      ),
                    ),
                    Text(
                      'EASY → HARD',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.amber500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      _roundChip('R1 Clash', AppColors.indigo500),
                      SizedBox(width: 4.w),
                      _roundChip('R2 Phrase', AppColors.emerald500),
                      SizedBox(width: 4.w),
                      _roundChip('R3 Strike', AppColors.rose500),
                      SizedBox(width: 4.w),
                      _roundChip('R4 Blitz', AppColors.blue500),
                      SizedBox(width: 4.w),
                      _roundChip('R5 Climax', AppColors.amber500),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 8.5.sp,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Recent Matches
// ---------------------------------------------------------------------------

class _ArenaRecentMatches extends StatelessWidget {
  final UserEntity user;
  final bool isDark;
  final bool isMidnight;

  const _ArenaRecentMatches({
    required this.user,
    required this.isDark,
    required this.isMidnight,
  });

  @override
  Widget build(BuildContext context) {
    // Authentic 1v1 Word Arena activity history:
    // - Entry stakes (-30 coins deducted at enter time)
    // - Victories (+50 / +60 coins)
    // - Defeats / consolations (+10 coins)
    // - Draws / refunds (+30 coins)
    final duelHistory = user.coinHistory.where((entry) {
      final titleKey = entry['titleKey'] as String? ?? '';
      return titleKey.contains('arena_duel_win') ||
          titleKey.contains('arena_duel_perfect') ||
          titleKey.contains('arena_duel_consolation') ||
          titleKey.contains('arena_duel_refund') ||
          titleKey.contains('arena_duel_stake') ||
          titleKey.contains('arena_duel_draw');
    }).toList();

    // Fallback for legacy user accounts that hold duelWins/duelLosses
    // before the coinHistory ledger was introduced:
    final List<Map<String, dynamic>> resolvedHistory;
    if (duelHistory.isNotEmpty) {
      resolvedHistory = duelHistory;
    } else if (user.duelWins > 0 || user.duelLosses > 0) {
      final synthetic = <Map<String, dynamic>>[];
      for (int i = 0; i < user.duelWins && synthetic.length < 10; i++) {
        synthetic.add({
          'titleKey': 'coin_history.arena_duel_win',
          'amount': 50,
          'isEarned': true,
          'date': user.lastDuelDate?.toIso8601String() ?? '',
        });
      }
      for (int i = 0; i < user.duelLosses && synthetic.length < 10; i++) {
        synthetic.add({
          'titleKey': 'coin_history.arena_duel_consolation',
          'amount': 10,
          'isEarned': true,
          'date': user.lastDuelDate?.toIso8601String() ?? '',
        });
      }
      resolvedHistory = synthetic;
    } else {
      resolvedHistory = [];
    }

    // Show up to 10 latest authentic match ledger cards
    final displayHistory = resolvedHistory.take(10).toList();

    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.midnightNavy : Colors.white);

    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.10)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate200);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Matches',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
            if (displayHistory.isNotEmpty)
              Text(
                '${displayHistory.length} matches',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white54 : AppColors.slate500,
                ),
              ),
          ],
        ),

        SizedBox(height: 8.h),

        if (displayHistory.isEmpty)
          Container(
            padding: EdgeInsets.all(22.r),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    LucideIcons.swords,
                    size: 28.r,
                    color: AppColors.indigo500,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'No arena matches yet',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Play a 1v1 match to challenge other players and win coins!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: displayHistory.length,
            separatorBuilder: (_, _) => SizedBox(height: 6.h),
            itemBuilder: (context, index) {
              final entry = displayHistory[index];
              final titleKey = entry['titleKey'] as String? ?? '';
              final amount = (entry['amount'] as num?)?.toInt() ?? 0;
              final rawDate = entry['date'] ?? entry['timestamp'];
              final timeAgo = _formatRelativeTime(rawDate);

              final bool isStake =
                  titleKey.contains('arena_duel_stake') || amount < 0;
              final bool isWin =
                  titleKey.contains('win') || titleKey.contains('perfect');
              final bool isPerfect = titleKey.contains('perfect');
              final bool isDraw =
                  titleKey.contains('refund') || titleKey.contains('draw');
              final bool isLoss = titleKey.contains('consolation') ||
                  (!isStake && !isWin && !isDraw);

              final String label;
              final String subtitle;
              final String amountText;
              final Color statusColor;
              final IconData statusIcon;

              if (isStake) {
                // Entry fee deducted at matchmaking time -> RED color as required
                label = 'Match Entry';
                subtitle = '30 Coins Deducted';
                amountText = '-${amount.abs()}🪙';
                statusColor = AppColors.rose500;
                statusIcon = LucideIcons.arrowDownRight;
              } else if (isPerfect) {
                // Perfect win 5/5 -> GREEN color
                label = 'Perfect Win';
                subtitle = '+$amount Coins • +5 XP';
                amountText = '+$amount🪙';
                statusColor = AppColors.emerald500;
                statusIcon = LucideIcons.crown;
              } else if (isWin) {
                // Victory -> GREEN color
                label = 'Victory';
                subtitle = '+$amount Coins • +5 XP';
                amountText = '+$amount🪙';
                statusColor = AppColors.emerald500;
                statusIcon = LucideIcons.trophy;
              } else if (isLoss) {
                // Defeat / Consolation -> BLUE color as required
                label = 'Defeat';
                subtitle = '+$amount Coins Consolation';
                amountText = '+$amount🪙';
                statusColor = AppColors.blue500;
                statusIcon = LucideIcons.shieldAlert;
              } else {
                // Draw / Refund -> AMBER color
                label = 'Draw';
                subtitle = '+$amount Coins Refunded';
                amountText = '+$amount🪙';
                statusColor = AppColors.amber500;
                statusIcon = LucideIcons.equal;
              }

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: borderColor, width: 1.0),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(7.r),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(statusIcon, size: 15.r, color: statusColor),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w900,
                              color: statusColor,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white60
                                  : AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          amountText,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                        if (timeAgo.isNotEmpty) ...[
                          SizedBox(height: 1.h),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.slate400,
                            ),
                          ),
                        ],
                      ],
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
    if (timestamp == null) return '';
    try {
      DateTime dt;
      if (timestamp is DateTime) {
        dt = timestamp.toLocal();
      } else if (timestamp is String) {
        dt = DateTime.parse(timestamp).toLocal();
      } else if (timestamp is num) {
        dt = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()).toLocal();
      } else {
        final dynamic ts = timestamp;
        dt = (ts.toDate() as DateTime).toLocal();
      }
      final diff = DateTime.now().difference(dt);
      if (diff.isNegative || diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}

// ---------------------------------------------------------------------------
// 7. Floating Bottom Play Dock
// ---------------------------------------------------------------------------

class _PlayArenaDock extends StatelessWidget {
  final UserEntity user;
  final bool isDark;
  final double bottomInset;

  const _PlayArenaDock({
    required this.user,
    required this.isDark,
    required this.bottomInset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h + bottomInset),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? AppColors.ultraDeep : Colors.white).withValues(
              alpha: 0.0,
            ),
            (isDark ? AppColors.ultraDeep : Colors.white).withValues(
              alpha: 0.95,
            ),
            isDark ? AppColors.ultraDeep : Colors.white,
          ],
        ),
      ),
      child: ScaleButton(
        onTap: () => _handlePlay(context),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.indigo500, AppColors.violet500],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.indigo500.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.swords, size: 17.r, color: Colors.white),
                SizedBox(width: 8.w),
                Text(
                  'Play Arena Duel',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '30🪙',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePlay(BuildContext context) async {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }

    if (!await ArenaNetworkHelper.ensureOnline(context)) return;
    if (!context.mounted) return;

    final liveUser = context.read<AuthBloc>().state.user ?? user;
    if (liveUser.coins < 30) {
      ArenaRefuelHelper.showRefuelDialog(context: context, user: liveUser);
      return;
    }

    Navigator.of(
      context,
      rootNavigator: true,
    ).push(ArenaMatchmakingScreen.route(user: liveUser));
  }
}

// ---------------------------------------------------------------------------
// 8. Shimmer Loading Skeleton
// ---------------------------------------------------------------------------

class _ArenaStatsShimmer extends StatelessWidget {
  final bool isDark;

  const _ArenaStatsShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? AppColors.slate800 : AppColors.slate200;
    final highlightColor = isDark ? AppColors.slate700 : const Color(0xFFF8FAFC);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            SizedBox(height: 12.h),
            // Hero card skeleton
            Container(
              height: 86.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22.r),
              ),
            ),
            SizedBox(height: 14.h),
            // 4 tiles skeleton
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 95.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Container(
                    height: 95.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 95.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Container(
                    height: 95.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            // Coin summary skeleton
            Container(
              height: 110.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
