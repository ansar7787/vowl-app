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
    Color ringColor = color;
    if (mercuryLevel > 0.6) {
      ringColor = Colors.greenAccent;
    } else if (mercuryLevel < 0.3) {
      ringColor = Colors.redAccent;
    }

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Circular Fusion Reactor
          SizedBox(
            width: 72.r,
            height: 72.r,
            child: AnimatedBuilder(
              animation: reactorAnimation,
              builder: (context, child) {
                return CustomPaint(
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
              children: [
                Text(
                  "PROFESSIONAL HARMONICS:",
                  style: TextStyle(fontFamily: 'RobotoMono', 
                    fontSize: 9.sp,
                    color: ringColor,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "${(mercuryLevel * 100).toInt()}% COMPATIBLE",
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 18.sp,
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6.h),
                // Horizontal tracking bar indicator
                Container(
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: mercuryLevel,
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
    );
  }
}
