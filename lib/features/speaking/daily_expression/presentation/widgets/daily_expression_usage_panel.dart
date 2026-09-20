import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color0f0f1a = Color(0xFF0F0F1A);
}

class DailyExpressionUsagePanel extends StatelessWidget {
  final SpeakingQuest quest;
  final Color primaryColor;
  final bool isDark;

  const DailyExpressionUsagePanel({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark
            ? _LocalPalette.color0f0f1a
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white10),
      ),
      child: AnimatedOpacity(
        opacity: 1.0, // Reverted dimming
        duration: const Duration(milliseconds: 300),
        child: Column(
          children: [
            if (quest.explanation != null && quest.explanation!.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_edu_rounded,
                    color: primaryColor,
                    size: 16.r,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "ORIGIN / EXPLANATION",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      color: Colors.grey,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                quest.explanation!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 20.h),
              Divider(color: Colors.white10, height: 1.h),
              SizedBox(height: 20.h),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: primaryColor,
                  size: 16.r,
                ),
                SizedBox(width: 8.w),
                Text(
                  "CONTEXTUAL SAMPLE USAGE",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    color: Colors.grey,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              "\"${quest.sampleUsage ?? 'Sample usage'}\"",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
