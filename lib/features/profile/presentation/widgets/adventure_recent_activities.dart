import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/theme/app_colors.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color c_059669 = Color(0xFF059669);
}

class AdventureRecentActivities extends StatelessWidget {
  final UserEntity user;

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
              padding: EdgeInsets.all(24.r),
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

              final gameTypeRaw = activity['gameType'] as String? ?? 'quest';
              final String displayTitle = gameTypeRaw.isNotEmpty
                  ? gameTypeRaw[0].toUpperCase() +
                        gameTypeRaw
                            .substring(1)
                            .replaceAll(RegExp(r'(?=[A-Z])'), ' ')
                  : 'Quest';

              final xpEarned = activity['xpEarned'] as int? ?? 0;
              final String subtitle = '+$xpEarned XP';
              final bool isQuest =
                  activity['type'] == 'quest' ||
                  activity['titleKey'] == 'activity.quest_completed';
              final bool showSubtitle = !isQuest || xpEarned > 0;

              return GlassTile(
                blur: 0, // Performance: skip BackdropFilter in list
                padding: EdgeInsets.all(12.r),
                borderRadius: BorderRadius.circular(16.r),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        // FIX: theme-aware background
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        activity['type'] == 'quest'
                            ? Icons.explore_rounded
                            : Icons.shopping_bag_rounded,
                        size: 16.r,
                        color: isDark ? Colors.white54 : AppColors.slate500,
                      ),
                    ),
                    SizedBox(width: 12.r),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['titleKey'] == 'activity.quest_completed'
                                ? displayTitle
                                : ((activity['title'] as String?)?.replaceAll(
                                        RegExp(
                                          'adventure',
                                          caseSensitive: false,
                                        ),
                                        'Quest',
                                      ) ??
                                      context.tr(
                                        'adventure.quest_completed',
                                        fallback: 'Quest Completed',
                                      )),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.slate800,
                            ),
                          ),
                          if (showSubtitle)
                            Text(
                              isQuest
                                  ? subtitle
                                  : ((activity['subtitle'] as String?)
                                            ?.replaceAll(
                                              RegExp(
                                                'adventure',
                                                caseSensitive: false,
                                              ),
                                              'Quest',
                                            )
                                            .replaceAll(
                                              RegExp(
                                                r'\+?\s*\d+\s*coins?',
                                                caseSensitive: false,
                                              ),
                                              '',
                                            )
                                            .replaceAll(RegExp(r'•|\|'), '')
                                            .trim() ??
                                        context.tr(
                                          'adventure.reward_earned',
                                          fallback: 'Reward Earned',
                                        )),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.emerald500
                                    : _LocalPalette.c_059669,
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

  /// Crash-safe relative time formatter. Handles [Timestamp], [String],
  /// [DateTime], and null without throwing.
  String _formatRelativeTime(BuildContext context, dynamic timestamp) {
    if (timestamp == null) {
      return context.tr('adventure.time_now', fallback: 'Just now');
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
      return context.tr('adventure.time_now', fallback: 'Just now');
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
    return context.tr('adventure.time_now', fallback: 'Just now');
  }
}
