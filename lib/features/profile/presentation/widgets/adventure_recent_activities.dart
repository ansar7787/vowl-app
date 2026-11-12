import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Feed component rendering the user's latest XP-yielding activities.
class AdventureRecentActivities extends StatelessWidget {
  /// Current authenticated [user] entity.
  final UserEntity user;

  /// Creates an [AdventureRecentActivities] widget for [user].
  const AdventureRecentActivities({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Filter to XP-earning activities only
    final activities = user.recentActivities.where((activity) {
      final xpEarned = activity['xpEarned'] as int?;
      if (xpEarned != null) return xpEarned > 0;

      final subtitle = activity['subtitle'] as String? ?? '';
      final lowerSub = subtitle.toLowerCase();
      if (lowerSub.contains('0xp') || lowerSub.contains('0 xp')) {
        return false;
      }
      if (lowerSub.contains('coin') && !lowerSub.contains('xp')) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('adventure.recent_activity', fallback: 'RECENT ACTIVITY'),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white38 : AppColors.slate500,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 16.r),
        if (activities.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.cardSpacious),
              child: Text(
                context.tr(
                  'adventure.no_recent',
                  fallback: 'No recent adventures yet.',
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
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
            separatorBuilder: (context, index) => SizedBox(height: 10.r),
            itemBuilder: (context, index) {
              final activity = activities[index];
              final meta = _getActivityMeta(activity, context);

              final xpEarned = activity['xpEarned'] as int? ?? 0;
              final coinsEarned = activity['coinsEarned'] as int? ?? 0;
              final String subtitle;
              if (xpEarned > 0 && coinsEarned > 0) {
                subtitle = '+$xpEarned XP · +$coinsEarned Coins';
              } else if (xpEarned > 0) {
                subtitle = '+$xpEarned XP';
              } else if (coinsEarned > 0) {
                subtitle = '+$coinsEarned Coins';
              } else {
                subtitle = context.tr(
                  'adventure.completed',
                  fallback: 'Completed',
                );
              }

              return GlassTile(
                blur: 0, // Performance: skip BackdropFilter in list
                padding: EdgeInsets.all(12.r),
                borderRadius: BorderRadius.circular(16.r),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: meta.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(meta.icon, size: 16.r, color: meta.color),
                    ),
                    SizedBox(width: 12.r),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta.title,
                            softWrap: true,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.slate800,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            subtitle,
                            softWrap: true,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.emerald500
                                  : AppColors.emerald600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatRelativeTime(context, activity['timestamp']),
                      style: TextStyle(
                        fontFamily: 'Outfit',
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

  _ActivityMeta _getActivityMeta(
    Map<String, dynamic> activity,
    BuildContext context,
  ) {
    final gameTypeRaw = activity['gameType'] as String? ?? '';
    final type = activity['type'] as String? ?? '';
    final titleKey = activity['titleKey'] as String? ?? '';

    if (gameTypeRaw == 'arenaDuel') {
      return const _ActivityMeta(
        title: 'Arena Duel',
        icon: LucideIcons.swords,
        color: AppColors.indigo500,
      );
    }

    if (gameTypeRaw == 'daily_words' || gameTypeRaw == 'dailyWords') {
      return const _ActivityMeta(
        title: 'Daily Words',
        icon: LucideIcons.calendarCheck,
        color: AppColors.teal500,
      );
    }

    if (gameTypeRaw == 'badgeReward' ||
        gameTypeRaw == 'badge' ||
        type == 'badge' ||
        titleKey == 'activity.badge_unlocked') {
      final badgeName = activity['badgeName'] as String?;
      final title = (badgeName != null && badgeName.isNotEmpty)
          ? badgeName
          : 'Trophy Bounty';
      return _ActivityMeta(
        title: title,
        icon: LucideIcons.award,
        color: AppColors.amber500,
      );
    }

    // Core disciplines
    if (gameTypeRaw == 'wordClash') {
      return const _ActivityMeta(
        title: 'Word Clash',
        icon: LucideIcons.zap,
        color: AppColors.indigo500,
      );
    }
    if (gameTypeRaw == 'phraseDuel') {
      return const _ActivityMeta(
        title: 'Phrase Duel',
        icon: LucideIcons.target,
        color: AppColors.emerald500,
      );
    }
    if (gameTypeRaw == 'sentenceStrike') {
      return const _ActivityMeta(
        title: 'Sentence Strike',
        icon: LucideIcons.flame,
        color: AppColors.rose500,
      );
    }
    if (gameTypeRaw == 'contextBlitz') {
      return const _ActivityMeta(
        title: 'Context Blitz',
        icon: LucideIcons.brainCircuit,
        color: AppColors.blue500,
      );
    }

    // Fallback: clean formatting without raw snake_case
    final String cleanTitle;
    if (gameTypeRaw.isNotEmpty) {
      cleanTitle = gameTypeRaw
          .replaceAll('_', ' ')
          .replaceAllMapped(RegExp(r'(?<=[a-z])[A-Z]'), (m) => ' ${m.group(0)}')
          .split(' ')
          .where((s) => s.isNotEmpty)
          .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
          .join(' ');
    } else if (activity['title'] is String) {
      cleanTitle = activity['title'] as String;
    } else {
      cleanTitle = context.tr(
        'adventure.quest_completed',
        fallback: 'Quest Completed',
      );
    }

    return _ActivityMeta(
      title: cleanTitle,
      icon: LucideIcons.compass,
      color: AppColors.indigo500,
    );
  }

  /// Crash-safe relative time formatter. Handles [Timestamp], [String],
  /// [DateTime], and null without throwing.
  String _formatRelativeTime(BuildContext context, dynamic timestamp) {
    if (timestamp == null) {
      return context.tr('adventure.time_now', fallback: 'Now');
    }

    DateTime? dt;
    try {
      if (timestamp is Timestamp) {
        dt = timestamp.toDate();
      } else if (timestamp is String) {
        dt = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        dt = timestamp;
      }
    } catch (_) {
      dt = null;
    }

    if (dt == null) {
      return context.tr('adventure.time_now', fallback: 'Now');
    }

    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) {
      return context.tr(
        'adventure.time_days_ago',
        args: ['${diff.inDays}'],
        fallback: '${diff.inDays}d ago',
      );
    }
    if (diff.inHours > 0) {
      return context.tr(
        'adventure.time_hours_ago',
        args: ['${diff.inHours}'],
        fallback: '${diff.inHours}h ago',
      );
    }
    if (diff.inMinutes > 0) {
      return context.tr(
        'adventure.time_minutes_ago',
        args: ['${diff.inMinutes}'],
        fallback: '${diff.inMinutes}m ago',
      );
    }
    return context.tr('adventure.time_now', fallback: 'Now');
  }
}

class _ActivityMeta {
  final String title;
  final IconData icon;
  final Color color;

  const _ActivityMeta({
    required this.title,
    required this.icon,
    required this.color,
  });
}
