import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class YesNoSpeakingAuditionCard extends StatelessWidget {
  final SpeakingQuest quest;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onPlayTts;

  const YesNoSpeakingAuditionCard({
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
                "COMPARE PHRASE STRUCTURES",
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
                        "REPLAY AUDIO",
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
            "WRITTEN TARGET CARD:",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            quest.sampleAnswer ?? "",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
