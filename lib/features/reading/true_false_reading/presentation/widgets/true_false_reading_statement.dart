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
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.04 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 16.r,
                      color: color.withValues(alpha: 0.8),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'STATEMENT',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: color.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                if (onPlayAudio != null)
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
            ),
            SizedBox(height: 12.h),
            Text(
              statement,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.5.sp,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1B1E2B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
