import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/core/presentation/widgets/vowl_micro_loader.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/leaderboard/domain/utils/weekly_league_reward_helper.dart';

/// Modal bottom sheet showcasing last week's top 10 winners, their ranks,
/// XP earned, and exact prizes awarded.
///
/// Features:
/// 1. Real Weekly Leaderboard Winners only (ranks 1 to 10 strictly ordered).
///    Never displays global all-time rankings or mock/scam data.
/// 2. Strict, unique sequential ranking (1, 2, 3, 4, 5, 6, 7, 8, 9, 10).
/// 3. In-sheet weekly reward claiming with live state transitions, sound & haptic
///    fanfare, and the celebratory champion dialog.
/// 4. Prominent "Claimed" confirmation with exact reward breakdown numbers if
///    the current user has already claimed.
class LastWeekWinnersBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> winners;
  final List<UserEntity>? allUsers;
  final UserEntity? currentUser;
  final String? weekKey;
  final Future<void> Function(int rank, int vipDays, int coins, String weekKey)?
  onClaimReward;

  const LastWeekWinnersBottomSheet({
    super.key,
    required this.winners,
    this.allUsers,
    this.currentUser,
    this.weekKey,
    this.onClaimReward,
  });

  /// Displays the bottom sheet with clean animation and safe-area insets.
  static Future<void> show({
    required BuildContext context,
    required List<Map<String, dynamic>> winners,
    List<UserEntity>? allUsers,
    UserEntity? currentUser,
    String? weekKey,
    Future<void> Function(int rank, int vipDays, int coins, String weekKey)?
    onClaimReward,
  }) {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LastWeekWinnersBottomSheet(
        winners: winners,
        allUsers: allUsers,
        currentUser: currentUser,
        weekKey: weekKey,
        onClaimReward: onClaimReward,
      ),
    );
  }

  @override
  State<LastWeekWinnersBottomSheet> createState() =>
      _LastWeekWinnersBottomSheetState();
}

class _LastWeekWinnersBottomSheetState
    extends State<LastWeekWinnersBottomSheet> {
  bool _isClaiming = false;
  final Set<String> _locallyClaimedWeekKeys = {};

  /// Resolves the weekly winners strictly from legitimate weekly sources:
  /// 1. Official weekly winners list from Cloud Function recap in metadata cache.
  /// 2. Users from [allUsers] who have official [previousRankWeekKey] matching the cycle.
  /// 3. Users from [allUsers] who actually earned XP during last week ([previousWeeklyExp] > 0).
  ///
  /// NEVER falls back to global all-time total XP rankings. If no weekly data
  /// exists yet, returns an empty list so the clean prize distribution is shown.
  List<Map<String, dynamic>> _resolveWinners({
    required String resolvedWeekKey,
    required String prevWeekKey,
    required String curWeekKey,
  }) {
    List<Map<String, dynamic>> candidates = [];

    if (widget.winners.isNotEmpty) {
      candidates = List<Map<String, dynamic>>.from(widget.winners);
    } else if (widget.allUsers != null && widget.allUsers!.isNotEmpty) {
      // Check if users have verified weekly league finish keys
      final weeklyFinisherCandidates = widget.allUsers!.where((u) {
        final matchesWeek =
            u.previousRankWeekKey == resolvedWeekKey ||
            u.previousRankWeekKey == prevWeekKey ||
            u.previousRankWeekKey == curWeekKey;
        return matchesWeek &&
            u.previousRank != null &&
            u.previousRank! >= 1 &&
            u.previousRank! <= 10;
      }).toList();

      if (weeklyFinisherCandidates.isNotEmpty) {
        weeklyFinisherCandidates.sort(
          (a, b) => a.previousRank!.compareTo(b.previousRank!),
        );
        candidates = weeklyFinisherCandidates.map((u) {
          final xp = u.previousWeeklyExp > 0
              ? u.previousWeeklyExp
              : u.currentWeeklyExp;
          return {
            'id': u.id,
            'rank': u.previousRank!,
            'displayName': u.safeDisplayName,
            'photoUrl': u.photoUrl,
            'weeklyXp': xp,
            'currentStreak': u.currentStreak,
            'weekKey': u.previousRankWeekKey ?? resolvedWeekKey,
          };
        }).toList();
      } else {
        // Tertiary fallback: Users who actually earned XP in the previous week
        final earnedWeeklyXpUsers = widget.allUsers!
            .where((u) => u.previousWeeklyExp > 0)
            .toList();

        if (earnedWeeklyXpUsers.isNotEmpty) {
          earnedWeeklyXpUsers.sort((a, b) {
            final xpCmp = b.previousWeeklyExp.compareTo(a.previousWeeklyExp);
            if (xpCmp != 0) return xpCmp;
            final streakCmp = b.currentStreak.compareTo(a.currentStreak);
            if (streakCmp != 0) return streakCmp;
            return b.totalExp.compareTo(a.totalExp);
          });

          candidates = earnedWeeklyXpUsers.take(10).map((u) {
            return {
              'id': u.id,
              'displayName': u.safeDisplayName,
              'photoUrl': u.photoUrl,
              'weeklyXp': u.previousWeeklyExp,
              'currentStreak': u.currentStreak,
              'weekKey': resolvedWeekKey,
            };
          }).toList();
        } else {
          // NO ONE earned weekly XP -> DO NOT SHOW FAKE GLOBAL RANKING!
          candidates = const [];
        }
      }
    }

    if (candidates.isEmpty) return const [];

    // Sort deterministically to eliminate ties and duplicates:
    // 1. Explicit rank if valid and distinct
    // 2. Weekly XP DESC
    // 3. Current Streak DESC
    // 4. Display Name ASC (stable alphabetical tie-breaker)
    final sorted = List<Map<String, dynamic>>.from(candidates);
    sorted.sort((a, b) {
      final aRank = (a['rank'] as num?)?.toInt();
      final bRank = (b['rank'] as num?)?.toInt();
      if (aRank != null && bRank != null && aRank != bRank) {
        return aRank.compareTo(bRank);
      }
      final aXp = (a['weeklyXp'] as num?)?.toInt() ?? 0;
      final bXp = (b['weeklyXp'] as num?)?.toInt() ?? 0;
      if (bXp != aXp) return bXp.compareTo(aXp);
      final aStreak = (a['currentStreak'] as num?)?.toInt() ?? 0;
      final bStreak = (b['currentStreak'] as num?)?.toInt() ?? 0;
      if (bStreak != aStreak) return bStreak.compareTo(aStreak);
      final aName = (a['displayName'] as String?) ?? '';
      final bName = (b['displayName'] as String?) ?? '';
      return aName.compareTo(bName);
    });

    // Ensure strictly unique, sequential ranks 1 to 10 (no duplicate ranks)
    final clamped = sorted.take(10).toList();
    return List.generate(clamped.length, (index) {
      return {
        ...clamped[index],
        'rank': index + 1, // Guaranteed 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
      };
    });
  }

  Future<void> _handleClaim({
    required BuildContext context,
    required UserEntity user,
    required int rank,
    required int vipDays,
    required int coins,
    required String targetWeekKey,
  }) async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);

    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }

    try {
      if (widget.onClaimReward != null) {
        await widget.onClaimReward!(rank, vipDays, coins, targetWeekKey);
      } else {
        await WeeklyLeagueRewardHelper.claimReward(
          context: context,
          user: user,
          rank: rank,
          vipDays: vipDays,
          coins: coins,
          weekKey: targetWeekKey,
          showCelebrationDialog: true,
        );
      }
      if (mounted) {
        setState(() {
          _locallyClaimedWeekKeys.add(targetWeekKey);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final surfaceColor = isMidnight
        ? AppColors.midnightSurface
        : (isDark
            ? const Color(0xFF131A29)
            : (tokens?.surface ?? Colors.white));
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate100);
    final textPrimary = isDark
        ? Colors.white
        : (tokens?.textPrimary ?? const Color(0xFF0F172A));
    final textSecondary = isDark
        ? AppColors.slate400
        : (tokens?.textSecondary ?? const Color(0xFF64748B));

    final systemBottomPadding = math.max(
      MediaQuery.paddingOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );
    final safeBottom =
        (systemBottomPadding > 0 ? systemBottomPadding : 16.h) + 16.h;

    // Real-time user resolution from AuthBloc
    UserEntity? authUser;
    try {
      authUser = context.select<AuthBloc, UserEntity?>((b) => b.state.user);
    } catch (_) {
      authUser = null;
    }
    final effectiveUser = authUser ?? widget.currentUser;

    final prevWeekKey = WeeklyLeagueRewardHelper.getPreviousWeekKey();
    final curWeekKey = WeeklyLeagueRewardHelper.getCurrentWeekKey();
    final resolvedWeekKey = widget.weekKey ??
        effectiveUser?.previousRankWeekKey ??
        prevWeekKey;

    final resolvedWinners = _resolveWinners(
      resolvedWeekKey: resolvedWeekKey,
      prevWeekKey: prevWeekKey,
      curWeekKey: curWeekKey,
    );

    // Identify logged-in user placement & claim status
    final myWinnerIndex = resolvedWinners.indexWhere(
      (w) => w['id'] == effectiveUser?.id,
    );
    final bool isInWinnersList = myWinnerIndex >= 0;

    final int? userRank;
    if (isInWinnersList) {
      userRank = myWinnerIndex + 1;
    } else if (effectiveUser?.previousRank != null &&
        effectiveUser!.previousRank! >= 1 &&
        effectiveUser.previousRank! <= 10 &&
        (effectiveUser.previousRankWeekKey == resolvedWeekKey ||
            effectiveUser.previousRankWeekKey == prevWeekKey ||
            effectiveUser.previousRankWeekKey == curWeekKey ||
            effectiveUser.previousRankWeekKey == null)) {
      userRank = effectiveUser.previousRank;
    } else {
      userRank = null;
    }

    final bool hasUserWon = userRank != null && userRank <= 10;
    final bool isAlreadyClaimed =
        _locallyClaimedWeekKeys.contains(resolvedWeekKey) ||
        (effectiveUser != null &&
            (_locallyClaimedWeekKeys.contains(
                  effectiveUser.previousRankWeekKey,
                ) ||
                effectiveUser.claimedWeeklyRewardWeekKeys.contains(
                  resolvedWeekKey,
                ) ||
                (effectiveUser.previousRankWeekKey != null &&
                    effectiveUser.claimedWeeklyRewardWeekKeys.contains(
                      effectiveUser.previousRankWeekKey,
                    ))));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, safeBottom),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border.all(color: borderColor, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38.w,
                height: 4.5.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.slate300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // Sheet Title & Close Icon
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.trophy,
                    size: 18.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr(
                          'leaderboard.last_week_champions_title',
                          fallback: "Last Week's Champions",
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Weekly League Winners · $resolvedWeekKey',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.06,
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18.r,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Spotlight Banner: User's Weekly Placement & Claim/Claimed State
            if (hasUserWon && effectiveUser != null) ...[
              _buildUserSpotlightBanner(
                context: context,
                user: effectiveUser,
                rank: userRank,
                isClaimed: isAlreadyClaimed,
                weekKey: resolvedWeekKey,
                isDark: isDark,
                textPrimary: textPrimary,
              ),
              SizedBox(height: 14.h),
            ],

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (resolvedWinners.isNotEmpty) ...[
                      ...resolvedWinners.map((winner) {
                        final rank = (winner['rank'] as num?)?.toInt() ?? 10;
                        final name =
                            (winner['displayName'] as String?) ??
                            'Vowl Learner';
                        final photoUrl = winner['photoUrl'] as String?;
                        final weeklyXp =
                            (winner['weeklyXp'] as num?)?.toInt() ?? 0;
                        final isMe = effectiveUser?.id == winner['id'];

                        return _buildWinnerCard(
                          context: context,
                          rank: rank,
                          displayName: name,
                          photoUrl: photoUrl,
                          weeklyXp: weeklyXp,
                          isMe: isMe,
                          isAlreadyClaimed: isAlreadyClaimed,
                          currentUser: effectiveUser,
                          weekKey: resolvedWeekKey,
                          isDark: isDark,
                          isMidnight: isMidnight,
                        );
                      }),
                    ] else ...[
                      // Empty state / Fallback with prize breakdown & user status
                      _buildEmptyFallback(
                        context: context,
                        isDark: isDark,
                        isMidnight: isMidnight,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Got it button
            ScaleButton(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  context.tr('common.got_it', fallback: 'Got It!'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Spotlight card showcasing the logged-in user's placement, prize details,
  /// and direct in-sheet Claim / Claimed state with exact numbers.
  Widget _buildUserSpotlightBanner({
    required BuildContext context,
    required UserEntity user,
    required int rank,
    required bool isClaimed,
    required String weekKey,
    required bool isDark,
    required Color textPrimary,
  }) {
    final Color accentColor;
    final IconData icon;

    switch (rank) {
      case 1:
        accentColor = IllustrationColors.premiumGold;
        icon = LucideIcons.trophy;
        break;
      case 2:
        accentColor = const Color(0xFFC0C0C0);
        icon = LucideIcons.medal;
        break;
      case 3:
        accentColor = const Color(0xFFCD7F32);
        icon = LucideIcons.award;
        break;
      default:
        accentColor = AppColors.indigo500;
        icon = LucideIcons.zap;
    }

    final coins = WeeklyLeagueRewardHelper.getCoins(rank);
    final vipDays = WeeklyLeagueRewardHelper.getVipDays(rank);
    final rankTitle = WeeklyLeagueRewardHelper.getRankTitle(rank);
    final rankSubtitle = WeeklyLeagueRewardHelper.getRankSubtitle(rank);
    final prizeSummary = WeeklyLeagueRewardHelper.getPrizeSummary(rank);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: isDark ? 0.24 : 0.16),
            accentColor.withValues(alpha: isDark ? 0.08 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.55 : 0.45),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.18 : 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Glowing Rank Icon Capsule
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.35),
                      accentColor.withValues(alpha: 0.15),
                    ],
                  ),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20.sp, color: accentColor),
              ),
              SizedBox(width: 10.w),

              // Title and Subtitle Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'YOUR FINISH · RANK #$rank',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'YOU',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w900,
                              color: rank == 1 ? Colors.black : Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      rankTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      '$rankSubtitle · $prizeSummary',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.slate300 : AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Action / Status Pill: Claim Button vs Claimed Confirmation with numbers
          if (!isClaimed) ...[
            ScaleButton(
              onTap: _isClaiming
                  ? null
                  : () => _handleClaim(
                      context: context,
                      user: user,
                      rank: rank,
                      vipDays: vipDays,
                      coins: coins,
                      targetWeekKey: weekKey,
                    ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 9.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _isClaiming
                    ? VowlMicroLoader(
                        size: 15.r,
                        color: rank == 1 ? Colors.black : Colors.white,
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.sparkles,
                              size: 14.sp,
                              color: rank == 1 ? Colors.black : Colors.white,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Claim Reward ($prizeSummary)',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w900,
                                color: rank == 1 ? Colors.black : Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(
                  alpha: isDark ? 0.18 : 0.12,
                ),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.45),
                  width: 1.w,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.checkCheck,
                      size: 14.sp,
                      color: AppColors.emerald500,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      vipDays > 0
                          ? 'Claimed: +$coins Coins · ${vipDays}d VIP'
                          : 'Claimed: +$coins Coins',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.emerald500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWinnerCard({
    required BuildContext context,
    required int rank,
    required String displayName,
    required String? photoUrl,
    required int weeklyXp,
    required bool isMe,
    required bool isAlreadyClaimed,
    required UserEntity? currentUser,
    required String weekKey,
    required bool isDark,
    required bool isMidnight,
  }) {
    final Color rankColor;
    final String rankLabel;
    final IconData rankIcon;

    switch (rank) {
      case 1:
        rankColor = IllustrationColors.premiumGold;
        rankLabel = '1st';
        rankIcon = LucideIcons.trophy;
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0);
        rankLabel = '2nd';
        rankIcon = LucideIcons.medal;
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32);
        rankLabel = '3rd';
        rankIcon = LucideIcons.award;
        break;
      default:
        rankColor = AppColors.indigo500;
        rankLabel = '#$rank';
        rankIcon = LucideIcons.zap;
    }

    final prizeSummary = WeeklyLeagueRewardHelper.getPrizeSummary(rank);
    final cardBg = isMe
        ? (isDark
            ? rankColor.withValues(alpha: 0.15)
            : rankColor.withValues(alpha: 0.1))
        : (isMidnight
            ? const Color(0xFF0F1523)
            : (isDark ? const Color(0xFF1A2338) : const Color(0xFFF8FAFC)));

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isMe
              ? rankColor
              : rankColor.withValues(alpha: isDark ? 0.25 : 0.15),
          width: isMe ? 1.5.w : 1.w,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withValues(alpha: 0.18),
              border: Border.all(
                color: rankColor.withValues(alpha: 0.4),
                width: 1.w,
              ),
            ),
            alignment: Alignment.center,
            child: rank <= 3
                ? Icon(rankIcon, size: 16.sp, color: rankColor)
                : Text(
                    rankLabel,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                      color: rankColor,
                    ),
                  ),
          ),
          SizedBox(width: 10.w),

          // User Avatar
          UserAvatar(
            photoUrl: photoUrl,
            size: 34.r,
            border: Border.all(
              color: rankColor.withValues(alpha: 0.4),
              width: 1.2.r,
            ),
          ),
          SizedBox(width: 10.w),

          // Name and XP
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 1.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: rankColor,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w900,
                            color: rank == 1 ? Colors.black : Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.flame,
                      size: 11.sp,
                      color: AppColors.amber500,
                    ),
                    SizedBox(width: 3.w),
                    Flexible(
                      child: Text(
                        '$weeklyXp XP',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.slate300 : AppColors.slate600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),

          // Prize Pill or In-Card Claim / Claimed Action
          if (isMe) ...[
            if (!isAlreadyClaimed && currentUser != null) ...[
              ScaleButton(
                onTap: _isClaiming
                    ? null
                    : () => _handleClaim(
                        context: context,
                        user: currentUser,
                        rank: rank,
                        vipDays: WeeklyLeagueRewardHelper.getVipDays(rank),
                        coins: WeeklyLeagueRewardHelper.getCoins(rank),
                        targetWeekKey: weekKey,
                      ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        rankColor,
                        rankColor.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(9.r),
                    boxShadow: [
                      BoxShadow(
                        color: rankColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isClaiming
                      ? VowlMicroLoader(
                          size: 12.r,
                          color: rank == 1 ? Colors.black : Colors.white,
                        )
                      : Text(
                          'Claim',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w900,
                            color: rank == 1 ? Colors.black : Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                ),
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.5.h),
                decoration: BoxDecoration(
                  color: AppColors.emerald500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.emerald500.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.checkCheck,
                      size: 10.sp,
                      color: AppColors.emerald500,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'Claimed',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emerald500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: rankColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: rankColor.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Text(
                prizeSummary,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: rankColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyFallback({
    required BuildContext context,
    required bool isDark,
    required bool isMidnight,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Prize structure overview
          Text(
            'Weekly League Prize Tiers',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 8.h),

          _buildTierRow(
            '1st Place',
            '7 Days VIP + 500 Coins + Champion Aura',
            IllustrationColors.premiumGold,
            LucideIcons.trophy,
            isDark,
          ),
          SizedBox(height: 6.h),
          _buildTierRow(
            '2nd Place',
            '3 Days VIP + 300 Coins + Silver Medal',
            const Color(0xFFC0C0C0),
            LucideIcons.medal,
            isDark,
          ),
          SizedBox(height: 6.h),
          _buildTierRow(
            '3rd Place',
            '1 Day VIP + 200 Coins + Bronze Podium',
            const Color(0xFFCD7F32),
            LucideIcons.award,
            isDark,
          ),
          SizedBox(height: 6.h),
          _buildTierRow(
            'Ranks 4-10',
            '100 Coins + Finisher Ribbon',
            AppColors.indigo500,
            LucideIcons.zap,
            isDark,
          ),

          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.04,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.info,
                  size: 14.sp,
                  color: textSecondary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Weekly results finalize every Sunday at 23:59 UTC. Complete quests this week to secure a top 10 spot!',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierRow(
    String title,
    String reward,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              reward,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppColors.slate700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
