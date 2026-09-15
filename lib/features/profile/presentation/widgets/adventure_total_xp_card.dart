import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class AdventureTotalXpCard extends StatelessWidget {
  final UserEntity user;

  const AdventureTotalXpCard({super.key, required this.user});

  static const _accent = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalXP = user.totalExp;
    final currentLevel = user.level;
    final xpPerLevel = UserGameConstants.kXpPerLevel;
    final xpInCurrentLevel = totalXP - ((currentLevel - 1) * xpPerLevel);
    final progressToNext = (xpInCurrentLevel / xpPerLevel).clamp(0.0, 1.0);

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
                      _accent.withValues(alpha: 0.2),
                      _accent.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: _accent.withValues(alpha: 0.2)),
                ),
                child: Icon(
                  Icons.auto_fix_high_rounded,
                  color: _accent,
                  size: 32.r,
                ),
              ),
              SizedBox(width: 18.r),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        'adventure.total_experience',
                        fallback: 'TOTAL EXPERIENCE',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: _accent,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 2.r),
                    Text(
                      '${NumberFormat('#,###').format(totalXP)} XP',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 4.r),
                    Row(
                      children: [
                        Text(
                          _getMotivationalText(context, user),
                          style: TextStyle(
                            fontFamily: 'Outfit',
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
                          color: _accent.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.r),
          // ── Level progress bar ──
          Row(
            children: [
              Text(
                context.tr(
                  'adventure.level_label',
                  args: ['$currentLevel'],
                  fallback: 'LVL $currentLevel',
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: _accent,
                ),
              ),
              SizedBox(width: 12.r),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: LinearProgressIndicator(
                    value: progressToNext,
                    backgroundColor: _accent.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                    minHeight: 8.r,
                  ),
                ),
              ),
              SizedBox(width: 12.r),
              Text(
                '$xpInCurrentLevel/$xpPerLevel',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Dynamic motivational text based on real user data — avoids
  /// habituation from static encouragement (variable reward psychology).
  String _getMotivationalText(BuildContext context, UserEntity user) {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayXp = user.dailyXpHistory[todayKey] ?? 0;

    if (user.isDoubleXPActive) {
      return context.tr(
        'adventure.motivation_double_xp',
        fallback: '2X XP ACTIVE',
      );
    }
    if (todayXp > 0) {
      return context.tr(
        'adventure.motivation_today_xp',
        args: ['$todayXp'],
        fallback: '+$todayXp XP TODAY',
      );
    }
    if (user.currentStreak >= 7) {
      return context.tr(
        'adventure.motivation_streak',
        args: ['${user.currentStreak}'],
        fallback: '${user.currentStreak}-DAY STREAK',
      );
    }
    if (user.totalExp >= 10000) {
      return context.tr(
        'adventure.motivation_legendary',
        fallback: 'LEGENDARY EXPLORER',
      );
    }
    if (user.totalExp >= 5000) {
      return context.tr(
        'adventure.motivation_rising',
        fallback: 'RISING ADVENTURER',
      );
    }
    if (user.totalExp >= 1000) {
      return context.tr(
        'adventure.motivation_momentum',
        fallback: 'BUILDING MOMENTUM',
      );
    }
    return context.tr(
      'adventure.motivation_begin',
      fallback: 'YOUR JOURNEY BEGINS',
    );
  }
}
