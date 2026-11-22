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
      useSafeArea: true,
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
  /// 1. Computes the exact XP earned during [resolvedWeekKey] using [WeeklyLeagueRewardHelper.getWeeklyExpForWeek].
  /// 2. Pools learners from [effectiveUser], [allUsers], and [winners].
  /// 3. Filters users with weekly XP > 0 (learners who earned 0 XP in that period did not compete).
  /// 4. Strictly sorts descending by:
  ///    - weeklyXp descending (highest XP first)
  ///    - currentStreak descending (tie-breaker)
  ///    - totalExp descending (tie-breaker)
  ///    - displayName ascending (tie-breaker)
  /// 5. Assigns sequential unique ranks 1, 2, 3, ... 10 strictly according to this sorted order.
  ///
  /// NEVER forces arbitrary ranks from previousRank or backfills lower XP users ahead of higher XP users.
  List<Map<String, dynamic>> _resolveWinners({
    required String resolvedWeekKey,
    required String prevWeekKey,
    required String curWeekKey,
    UserEntity? effectiveUser,
  }) {
    final Map<String, Map<String, dynamic>> candidateMap = {};

    void registerUser(UserEntity u) {
      var xp = WeeklyLeagueRewardHelper.getWeeklyExpForWeek(u, resolvedWeekKey);
      if (xp == 0 &&
          u.previousWeeklyExp > 0 &&
          (u.previousRankWeekKey == resolvedWeekKey ||
              u.previousRankWeekKey == prevWeekKey ||
              u.previousRankWeekKey == null)) {
        xp = u.previousWeeklyExp;
      }
      candidateMap[u.id] = {
        'id': u.id,
        'displayName': u.safeDisplayName,
        'photoUrl': u.photoUrl,
        'weeklyXp': xp,
        'currentStreak': u.currentStreak,
        'totalExp': u.totalExp,
        'weekKey': u.previousRankWeekKey ?? resolvedWeekKey,
      };
    }

    if (effectiveUser != null) {
      registerUser(effectiveUser);
    }

    if (widget.allUsers != null) {
      for (final u in widget.allUsers!) {
        if (effectiveUser != null && u.id == effectiveUser.id) continue;
        registerUser(u);
      }
    }

    for (final w in widget.winners) {
      final id = w['id'] as String?;
      if (id == null) continue;
      final winnerXp = (w['weeklyXp'] as num?)?.toInt() ?? 0;
      if (!candidateMap.containsKey(id)) {
        candidateMap[id] = {
          'id': id,
          'displayName': (w['displayName'] as String?) ?? 'Vowl Learner',
          'photoUrl': w['photoUrl'] as String?,
          'weeklyXp': winnerXp,
          'currentStreak': (w['currentStreak'] as num?)?.toInt() ?? 0,
          'totalExp': (w['totalExp'] as num?)?.toInt() ?? 0,
          'weekKey': (w['weekKey'] as String?) ?? resolvedWeekKey,
        };
      } else {
        final existingXp =
            (candidateMap[id]!['weeklyXp'] as num?)?.toInt() ?? 0;
        if (winnerXp > existingXp) {
          candidateMap[id]!['weeklyXp'] = winnerXp;
        }
      }
    }

    final List<Map<String, dynamic>> pool = candidateMap.values.where((c) {
      final xp = (c['weeklyXp'] as num?)?.toInt() ?? 0;
      return xp > 0;
    }).toList();

    if (pool.isEmpty) return const [];

    pool.sort((a, b) {
      final aXp = (a['weeklyXp'] as num?)?.toInt() ?? 0;
      final bXp = (b['weeklyXp'] as num?)?.toInt() ?? 0;
      if (bXp != aXp) return bXp.compareTo(aXp);

      final aStreak = (a['currentStreak'] as num?)?.toInt() ?? 0;
      final bStreak = (b['currentStreak'] as num?)?.toInt() ?? 0;
      if (bStreak != aStreak) return bStreak.compareTo(aStreak);

      final aTotal = (a['totalExp'] as num?)?.toInt() ?? 0;
      final bTotal = (b['totalExp'] as num?)?.toInt() ?? 0;
      if (bTotal != aTotal) return bTotal.compareTo(aTotal);

      final aName = (a['displayName'] as String?) ?? '';
      final bName = (b['displayName'] as String?) ?? '';
      return aName.compareTo(bName);
    });

    final top10 = pool.take(10).toList();
    return List.generate(top10.length, (index) {
      return {
        ...top10[index],
        'rank': index + 1,
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
        ((effectiveUser?.previousRankWeekKey == curWeekKey ||
                effectiveUser?.previousRankWeekKey == prevWeekKey)
            ? effectiveUser!.previousRankWeekKey!
            : prevWeekKey);

    final resolvedWinners = _resolveWinners(
      resolvedWeekKey: resolvedWeekKey,
      prevWeekKey: prevWeekKey,
      curWeekKey: curWeekKey,
      effectiveUser: effectiveUser,
    );

    // Identify logged-in user placement & claim status
    final myWinnerIndex = resolvedWinners.indexWhere(
      (w) => w['id'] == effectiveUser?.id,
    );
    final bool isInWinnersList = myWinnerIndex >= 0;

    final int? userRank = isInWinnersList
        ? ((resolvedWinners[myWinnerIndex]['rank'] as num?)?.toInt() ??
            (myWinnerIndex + 1))
        : (effectiveUser?.previousRank != null &&
                effectiveUser!.previousRank! >= 1 &&
                effectiveUser.previousRank! <= 10 &&
                (effectiveUser.previousRankWeekKey == resolvedWeekKey ||
                    effectiveUser.previousRankWeekKey == prevWeekKey ||
                    effectiveUser.previousRankWeekKey == curWeekKey ||
                    effectiveUser.previousRankWeekKey == null))
            ? effectiveUser.previousRank
            : null;

    final bool hasUserWon = userRank != null && userRank <= 10;
    final bool isAlreadyClaimed =
        _locallyClaimedWeekKeys.contains(resolvedWeekKey) ||
        (effectiveUser != null &&
            effectiveUser.claimedWeeklyRewardWeekKeys.contains(resolvedWeekKey));

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 12.h),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          border: Border.all(color: borderColor, width: 1.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
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
                        WeeklyLeagueRewardHelper.formatWeekDateRange(
                          resolvedWeekKey,
                          locale: Localizations.localeOf(context).toString(),
                        ),
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
                        final isMe = effectiveUser?.id == winner['id'];
                        final name = isMe
                            ? (effectiveUser?.safeDisplayName ??
                                (winner['displayName'] as String?) ??
                                'Vowl Learner')
                            : ((winner['displayName'] as String?) ??
                                'Vowl Learner');
                        final photoUrl = isMe
                            ? (effectiveUser?.photoUrl ??
                                winner['photoUrl'] as String?)
                            : (winner['photoUrl'] as String?);
                        final weeklyXp =
                            (winner['weeklyXp'] as num?)?.toInt() ?? 0;

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
                  color: AppColors.indigo500,
                  borderRadius: BorderRadius.circular(14.r),
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

    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cardBg = isMidnight
        ? const Color(0xFF0F1523)
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC));

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.45 : 0.35),
          width: 1.2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  color: accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.4),
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
                    Text(
                      'YOUR FINISH · RANK #$rank',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        letterSpacing: 0.5,
                      ),
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
                    SizedBox(height: 2.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$rankSubtitle · ',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.slate300
                                  : AppColors.slate600,
                            ),
                          ),
                          if (vipDays > 0) ...[
                            Text(
                              '${vipDays}d VIP · ',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.slate300
                                    : AppColors.slate600,
                              ),
                            ),
                          ],
                          Icon(
                            Icons.monetization_on_rounded,
                            size: 11.5.sp,
                            color: const Color(0xFFF59E0B),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            '+$coins',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
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
                  color: AppColors.indigo500,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignment: Alignment.center,
                child: _isClaiming
                    ? const VowlMicroLoader(
                        size: 15,
                        color: Colors.white,
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.sparkles,
                              size: 14.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              vipDays > 0
                                  ? 'Claim Reward (${vipDays}d VIP · '
                                  : 'Claim Reward (',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Icon(
                              Icons.monetization_on_rounded,
                              size: 12.5.sp,
                              color: const Color(0xFFFDE68A),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              '+$coins)',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFFDE68A),
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
                    Text(
                      'Claimed: ',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.emerald500,
                      ),
                    ),
                    if (vipDays > 0) ...[
                      Text(
                        '${vipDays}d VIP · ',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.emerald500,
                        ),
                      ),
                    ],
                    Icon(
                      Icons.monetization_on_rounded,
                      size: 12.sp,
                      color: AppColors.emerald500,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '+$coins',
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
    final bool isPodium = rank <= 3;

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

    final cardBg = isMe
        ? (isDark
            ? rankColor.withValues(alpha: 0.15)
            : rankColor.withValues(alpha: 0.1))
        : (isMidnight
            ? const Color(0xFF0F1523)
            : (isDark ? const Color(0xFF1A2338) : const Color(0xFFF8FAFC)));

    final double borderWidth = isMe
        ? (rank == 1 ? 1.8.w : (isPodium ? 1.5.w : 1.3.w))
        : (rank == 1 ? 1.4.w : (isPodium ? 1.2.w : 1.w));

    return Container(
      margin: EdgeInsets.only(bottom: isPodium ? 8.h : 6.h),
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: isPodium ? 9.h : 7.5.h,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isMe
              ? rankColor
              : (isPodium
                  ? rankColor.withValues(alpha: isDark ? 0.35 : 0.25)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06))),
          width: borderWidth,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: isPodium ? 32.r : 28.r,
            height: isPodium ? 32.r : 28.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withValues(alpha: isPodium ? 0.18 : 0.12),
              border: Border.all(
                color: rankColor.withValues(alpha: isPodium ? 0.45 : 0.25),
                width: 1.w,
              ),
            ),
            alignment: Alignment.center,
            child: isPodium
                ? Icon(rankIcon, size: 16.sp, color: rankColor)
                : Text(
                    rankLabel,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w900,
                      color: rankColor,
                    ),
                  ),
          ),
          SizedBox(width: 10.w),

          // User Avatar
          UserAvatar(
            photoUrl: photoUrl,
            size: isPodium ? 34.r : 30.r,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: isPodium ? 13.sp : 12.5.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      SizedBox(width: 5.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 1.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: rankColor,
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w900,
                            color: rank == 1 ? Colors.black : Colors.white,
                            letterSpacing: 0.3,
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

          // Prize Pill or In-Card Claimed Status (Hero CTA is on Spotlight Banner)
          if (isMe && isAlreadyClaimed) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                'Claimed',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emerald500,
                ),
              ),
            ),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (WeeklyLeagueRewardHelper.getVipDays(rank) > 0) ...[
                    Text(
                      '${WeeklyLeagueRewardHelper.getVipDays(rank)}d VIP · ',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w800,
                        color: rankColor,
                      ),
                    ),
                  ],
                  Icon(
                    Icons.monetization_on_rounded,
                    size: 11.sp,
                    color: const Color(0xFFF59E0B),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '+${WeeklyLeagueRewardHelper.getCoins(rank)}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
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
          Center(
            child: Container(
              width: 52.r,
              height: 52.r,
              margin: EdgeInsets.only(bottom: 10.h),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.04,
                ),
                border: Border.all(
                  color: textSecondary.withValues(alpha: 0.2),
                  width: 1.2.w,
                ),
              ),
              child: Icon(
                LucideIcons.trophy,
                size: 24.r,
                color: textSecondary,
              ),
            ),
          ),
          Center(
            child: Text(
              'No Finalized Champions Yet',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Center(
            child: Text(
              'Weekly results finalize every Sunday at 23:59 UTC.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ),
          SizedBox(height: 14.h),

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
            title: '1st Place',
            rank: 1,
            color: IllustrationColors.premiumGold,
            icon: LucideIcons.trophy,
            isDark: isDark,
            auraBadge: 'Champion Aura',
          ),
          SizedBox(height: 6.h),
          _buildTierRow(
            title: '2nd Place',
            rank: 2,
            color: const Color(0xFFC0C0C0),
            icon: LucideIcons.medal,
            isDark: isDark,
            auraBadge: 'Silver Medal',
          ),
          SizedBox(height: 6.h),
          _buildTierRow(
            title: '3rd Place',
            rank: 3,
            color: const Color(0xFFCD7F32),
            icon: LucideIcons.award,
            isDark: isDark,
            auraBadge: 'Bronze Podium',
          ),
          SizedBox(height: 6.h),
          _buildTierRow(
            title: 'Ranks 4-10',
            rank: 4,
            color: AppColors.indigo500,
            icon: LucideIcons.zap,
            isDark: isDark,
            auraBadge: 'Finisher Ribbon',
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

  Widget _buildTierRow({
    required String title,
    required int rank,
    required Color color,
    required IconData icon,
    required bool isDark,
    String? auraBadge,
  }) {
    final vipDays = WeeklyLeagueRewardHelper.getVipDays(rank);
    final coins = WeeklyLeagueRewardHelper.getCoins(rank);

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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (vipDays > 0) ...[
                    Text(
                      '${vipDays}d VIP · ',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : AppColors.slate700,
                      ),
                    ),
                  ],
                  Icon(
                    Icons.monetization_on_rounded,
                    size: 11.5.sp,
                    color: const Color(0xFFF59E0B),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '+$coins',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  if (auraBadge != null) ...[
                    Text(
                      ' · $auraBadge',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : AppColors.slate700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
