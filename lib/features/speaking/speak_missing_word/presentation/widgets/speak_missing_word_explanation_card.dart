import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

class SpeakMissingWordExplanationCard extends StatelessWidget {
  final GameQuest quest;
  final bool isCorrect;
  final bool isDark;

  const SpeakMissingWordExplanationCard({
    super.key,
    required this.quest,
    required this.isCorrect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isCorrect
        ? Colors.greenAccent
        : Colors.orangeAccent;

    return Container(
          width: 1.sw,
          padding: EdgeInsets.all(22.r),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131326) : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: cardColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: cardColor.withValues(alpha: 0.15),
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    isCorrect ? Icons.verified_rounded : Icons.info_rounded,
                    color: cardColor,
                    size: 24.r,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    isCorrect ? "Alignment Successful!" : "Alignment Failure!",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                quest.explanation ??
                    "Correlating target blank options with spoken phrase structures reinforces robust memory synapses.",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.35,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideY(begin: 0.05);
  }
}
