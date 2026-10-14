import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TrueFalseReadingStatement extends StatelessWidget {
  final String statement;
  final Color color;
  final bool isDark;
  final VoidCallback? onPlayAudio;

  const TrueFalseReadingStatement({
    super.key,
    required this.statement,
    required this.color,
    required this.isDark,
    this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Statement: $statement.${onPlayAudio != null ? " Double tap audio button to listen." : ""}',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.4 : 0.2),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: color.withValues(alpha: 0.5),
                  size: 28.r,
                ),
                if (onPlayAudio != null) ...[
                  SizedBox(width: 8.w),
                  GestureDetector(
                    key: const ValueKey('statement_audio_button'),
                    onTap: onPlayAudio,
                    child: Padding(
                      padding: EdgeInsets.all(4.r),
                      child: Icon(
                        Icons.volume_up_rounded,
                        size: 20.r,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              statement,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20.sp,
                height: 1.4,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E1E2C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
