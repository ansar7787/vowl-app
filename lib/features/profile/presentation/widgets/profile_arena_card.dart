import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/arena/presentation/pages/arena_stats_screen.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

/// Card component showcasing the user's 1v1 Word Arena performance.
///
/// Features:
/// - Total Wins, Total Losses, Win Rate percentage, and Daily Duels played.
/// - Defensive zero-division guard against new accounts (`totalDuels == 0`).
/// - Direct 1-tap navigation trigger with balance verification to enter Arena matchmaking.
class ProfileArenaCard extends StatefulWidget {
  /// Authenticated user entity holding combat stats.
  final UserEntity user;

  /// Creates a [ProfileArenaCard] for [user].
  const ProfileArenaCard({super.key, required this.user});

  @override
  State<ProfileArenaCard> createState() => _ProfileArenaCardState();
}

class _ProfileArenaCardState extends State<ProfileArenaCard> {
  DateTime? _lastTapTime;

  void _enterArena(BuildContext context) {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 750)) {
      return;
    }
    _lastTapTime = now;

    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }

    final liveUser = context.read<AuthBloc>().state.user ?? widget.user;

    // Navigate to Arena Stats screen — coin check happens at Play button there
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(ArenaStatsScreen.route(user: liveUser));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.borderLight);

    final liveUser =
        context.select<AuthBloc, UserEntity?>((bloc) => bloc.state.user) ??
        widget.user;

    final totalDuels = liveUser.duelWins + liveUser.duelLosses;
    final winRate = totalDuels > 0
        ? ((liveUser.duelWins / totalDuels) * 100).toInt()
        : 0;

    return ScaleButton(
      onTap: () => _enterArena(context),
      child: GlassTile(
        borderRadius: BorderRadius.circular(24.r),
        padding: EdgeInsets.all(16.r),
        borderColor: borderColor,
        borderWidth: 1.0,
        blur: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.indigo500, AppColors.violet500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.indigo500.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.swords,
                    color: Colors.white,
                    size: 20.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(
                          'profile.arena_pvp_title',
                          fallback: '1V1 WORD ARENA',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? AppColors.indigo400
                              : AppColors.indigo600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        context.tr(
                          'profile.arena_pvp_subtitle',
                          fallback: 'Live Vocabulary Duels',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14.r,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isMidnight
                      ? Colors.white.withValues(alpha: 0.12)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.slate200),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _statItem(
                      context,
                      context.tr('profile.duel_wins', fallback: 'Victories'),
                      '${liveUser.duelWins}',
                      AppColors.emerald500,
                    ),
                  ),
                  _divider(isDark),
                  Expanded(
                    child: _statItem(
                      context,
                      context.tr('profile.duel_losses', fallback: 'Defeats'),
                      '${liveUser.duelLosses}',
                      AppColors.rose500,
                    ),
                  ),
                  _divider(isDark),
                  Expanded(
                    child: _statItem(
                      context,
                      context.tr('profile.duel_win_rate', fallback: 'Win Rate'),
                      '$winRate%',
                      AppColors.blue500,
                    ),
                  ),
                  _divider(isDark),
                  Expanded(
                    child: _statItem(
                      context,
                      context.tr('profile.duel_today', fallback: 'Today'),
                      '${ArenaStatsScreen.calculateDailyDuelsPlayedToday(liveUser)}',
                      AppColors.amber500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      height: 24.h,
      width: 1,
      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
    );
  }

  Widget _statItem(
    BuildContext context,
    String label,
    String val,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            val,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            softWrap: true,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black45,
            ),
          ),
        ),
      ],
    );
  }
}
