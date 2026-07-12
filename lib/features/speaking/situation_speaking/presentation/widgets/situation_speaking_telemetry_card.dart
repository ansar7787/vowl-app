import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class SituationSpeakingTelemetryCard extends StatelessWidget {
  final String spokenText;
  final bool isDark;

  const SituationSpeakingTelemetryCard({
    super.key,
    required this.spokenText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasInput =
        spokenText != "Calibrating conversational context decoder..." &&
        spokenText != "No voice frequency signature detected.";

    return GlassTile(
      padding: EdgeInsets.all(18.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                hasInput
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                color: Colors.cyanAccent,
                size: 16.r,
              ),
              SizedBox(width: 8.w),
              Text(
                "DECODED VOICE SIGNATURE",
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 10.sp,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            spokenText,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
