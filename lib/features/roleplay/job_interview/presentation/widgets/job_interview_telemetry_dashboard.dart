import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_fusion_painter.dart';

class JobInterviewTelemetryDashboard extends StatelessWidget {
  final Color color;
  final bool isDark;
  final double mercuryLevel;
  final Animation<double> reactorAnimation;

  const JobInterviewTelemetryDashboard({
    super.key,
    required this.color,
    required this.isDark,
    required this.mercuryLevel,
    required this.reactorAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    Color ringColor = color;
    if (mercuryLevel > 0.6) {
      ringColor = tokens.gameCorrect;
    } else if (mercuryLevel < 0.3) {
      ringColor = tokens.gameIncorrect;
    }

    return Container(
      key: const Key('job_interview_telemetry_dashboard'),
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : color.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Semantics(
        label:
            "Professionalism level is at ${(mercuryLevel * 100).round()} percent",
        excludeSemantics: true,
        child: Row(
          children: [
            // Circular Score Ring
            SizedBox(
              key: const Key('job_interview_reactor_box'),
              width: 72.r,
              height: 72.r,
              child: AnimatedBuilder(
                animation: reactorAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    key: const Key('job_interview_reactor_painter'),
                    painter: ProfessionalismFusionPainter(
                      animationValue: reactorAnimation.value,
                      professionalismLevel: mercuryLevel,
                      themeColor: color,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "INTERVIEW SCORE",
                    key: const Key('job_interview_telemetry_harmonics_label'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      color: ringColor,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "${(mercuryLevel * 100).round()}% SCORE",
                    key: const Key('job_interview_telemetry_percentage_text'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  // Horizontal progress indicator bar
                  Container(
                    key: const Key('job_interview_telemetry_progress_bar'),
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: mercuryLevel.clamp(0.0, 1.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: ringColor,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
