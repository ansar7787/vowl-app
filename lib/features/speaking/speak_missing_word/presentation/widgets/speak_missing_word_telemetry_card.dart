import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SpeakMissingWordTelemetryCard extends StatelessWidget {
  final String spokenText;
  final bool isDark;

  const SpeakMissingWordTelemetryCard({
    super.key,
    required this.spokenText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "VOCAL DECRYPTION OUTPUT",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 9.sp,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            spokenText.isEmpty
                ? "Hold record lens and speak full completed sentence..."
                : spokenText,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontStyle: spokenText.isEmpty
                  ? FontStyle.normal
                  : FontStyle.italic,
              color: spokenText.isEmpty
                  ? (isDark ? Colors.white30 : Colors.black38)
                  : (isDark ? Colors.white70 : Colors.black87),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
