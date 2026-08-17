import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class KidsRoomMoodIndicator extends StatelessWidget {
  final UserEntity user;

  const KidsRoomMoodIndicator({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final mood = user.kidsBuddyMood;
    final moodData = _getMoodData(mood);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(
              alpha: isDark ? 0.3 : 0.6,
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: moodData.color.withValues(alpha: 0.8),
              width: 2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
                blurRadius: 8,
                spreadRadius: -2,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mood Emoji
              Text(moodData.emoji, style: TextStyle(fontSize: 20.sp))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.15, 1.15),
                    duration: 1.seconds,
                  ),
              SizedBox(width: 8.w),

              // Mood Label
              Text(
                moodData.label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? moodData.color.withValues(alpha: 0.8)
                      : moodData.color,
                  letterSpacing: 1.5,
                ),
              ),

              // Streak Divider
              if (user.kidsCareStreak > 0) ...[
                SizedBox(width: 12.w),
                Container(
                  width: 2.w,
                  height: 20.h,
                  color: Colors.grey.shade300,
                ),
                SizedBox(width: 12.w),

                // Streak Counter
                Row(
                  children: [
                    Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.orange,
                          size: 18.sp,
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1.1, 1.1),
                        ),
                    SizedBox(width: 4.w),
                    Text(
                      "${user.kidsCareStreak}",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _MoodData _getMoodData(String mood) {
    switch (mood) {
      case 'hungry':
        return _MoodData(
          emoji: '🥺',
          label: 'Hungry',
          color: const Color(0xFFF59E0B), // Amber 500
        );
      case 'sleepy':
        return _MoodData(
          emoji: '😴',
          label: 'Sleepy',
          color: const Color(0xFF6366F1), // Indigo 500
        );
      case 'bored':
        return _MoodData(
          emoji: '😒',
          label: 'Bored',
          color: const Color(0xFF8B5CF6), // Violet 500
        );
      case 'excited':
        return _MoodData(
          emoji: '🤩',
          label: 'Excited',
          color: const Color(0xFFEC4899), // Pink 500
        );
      case 'happy':
      default:
        return _MoodData(
          emoji: '😊',
          label: 'Happy',
          color: const Color(0xFF10B981), // Emerald 500
        );
    }
  }
}

class _MoodData {
  final String emoji;
  final String label;
  final Color color;

  _MoodData({required this.emoji, required this.label, required this.color});
}
