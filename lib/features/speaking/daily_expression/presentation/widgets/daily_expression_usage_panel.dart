import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color0f0f1a = Color(0xFF0F0F1A);
}

/// Panel displaying contextual usage examples, origins, and explanations for the daily expression.
class DailyExpressionUsagePanel extends StatelessWidget {
  /// Active speaking quest entity.
  final SpeakingQuest quest;

  /// Primary theme accent color.
  final Color primaryColor;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Creates a [DailyExpressionUsagePanel].
  const DailyExpressionUsagePanel({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('daily_expression_usage_panel'),
      width: 1.sw,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: isDark
            ? _LocalPalette.color0f0f1a
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
        ),
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
                  Flexible(
                    child: Text(
                      "Origin",
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                        letterSpacing: 0.5,
                      ),
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
                  height: 1.45,
                ),
              ),
              SizedBox(height: 14.h),
              Divider(
                color: isDark ? Colors.white10 : Colors.black12,
                height: 28.h,
              ),
              SizedBox(height: 14.h),
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
                Flexible(
                  child: Text(
                    "Example sentence",
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.black54,
                      letterSpacing: 0.5,
                    ),
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
                fontSize: 15.sp,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
