import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

class SpeakOppositeExplanationCard extends StatelessWidget {
  final GameQuest quest;
  final bool isCorrect;
  final bool isDark;
  final List<String> acceptedAntonyms;

  const SpeakOppositeExplanationCard({
    super.key,
    required this.quest,
    required this.isCorrect,
    required this.isDark,
    required this.acceptedAntonyms,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isCorrect ? Colors.cyanAccent : Colors.redAccent;

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
                isCorrect ? Icons.offline_bolt_rounded : Icons.gavel_rounded,
                color: cardColor,
                size: 24.r,
              ),
              SizedBox(width: 8.w),
              Text(
                isCorrect ? "Opposite Fused!" : "Polar Bridge Collapse",
                style: TextStyle(fontFamily: 'Outfit', 
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            quest.explanation ?? "Identifying direct lexical antonyms enhances cognitive mapping and communication depth.",
            style: TextStyle(fontFamily: 'Outfit', 
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.35,
            ),
          ),
          if (!isCorrect && acceptedAntonyms.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Text(
              "ACCEPTED OPPOSITES:",
              style: TextStyle(fontFamily: 'RobotoMono', 
                fontSize: 10.sp,
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: acceptedAntonyms.map((s) => Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                ),
                child: Text(
                  s,
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 12.sp,
                    color: Colors.redAccent,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.05);
  }
}
