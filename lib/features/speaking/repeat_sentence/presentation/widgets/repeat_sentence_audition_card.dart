import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class RepeatSentenceAuditionCard extends StatelessWidget {
  final GameQuest quest;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onPlayTts;

  const RepeatSentenceAuditionCard({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.all(22.r),
      borderRadius: BorderRadius.circular(32.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TARGET STATEMENT TO REPEAT",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  color: primaryColor,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ScaleButton(
                onTap: onPlayTts,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.volume_up_rounded,
                        color: primaryColor,
                        size: 16.r,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        "LISTEN",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            quest.correctAnswer ?? "",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20.sp,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.35,
            ),
          ),
          if (quest is SpeakingQuest &&
              (quest as SpeakingQuest).pronunciationTips != null) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tips_and_updates_rounded,
                    color: primaryColor,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      (quest as SpeakingQuest).pronunciationTips!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.4,
                      ),
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
}
