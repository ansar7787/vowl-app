import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vowl/core/theme/vowl_motion.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color07070f = Color(0xFF07070F);
}

/// Panel displaying the interviewer's question, demeanor, and real-time reaction.
class JobInterviewInterviewerPanel extends StatelessWidget {
  /// Question text delivered by the interviewer.
  final String text;

  /// Primary theme accent color.
  final Color color;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Interviewer's visual emotional reaction (e.g., 'impressed', 'disappointed').
  final String? reaction;

  /// Creates a [JobInterviewInterviewerPanel] widget.
  const JobInterviewInterviewerPanel({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
    this.reaction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final isPositive = reaction == 'impressed' || reaction == 'interested';
    final isNegative =
        reaction == 'disappointed' ||
        reaction == 'unconvinced' ||
        reaction == 'uncertain' ||
        reaction == 'losing interest';

    final Color activeColor = isPositive
        ? tokens.gameCorrect
        : (isNegative ? tokens.gameIncorrect : color);

    final IconData activeIcon = isPositive
        ? Icons.sentiment_very_satisfied_rounded
        : (isNegative
              ? Icons.sentiment_dissatisfied_rounded
              : Icons.business_center_rounded);

    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    Widget content = Container(
      key: const Key('job_interview_interviewer_panel'),
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark
            ? _LocalPalette.color07070f
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: reaction != null
              ? activeColor.withValues(alpha: 0.3)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                key: const Key('job_interview_interviewer_icon_container'),
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  activeIcon,
                  key: const Key('job_interview_interviewer_icon'),
                  color: activeColor,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reaction != null
                          ? reaction!.toUpperCase()
                          : "HIRING MANAGER",
                      key: const Key('job_interview_interviewer_title'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        color: activeColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      reaction != null
                          ? "INTERVIEWER REACTION"
                          : "INTERVIEW QUESTION",
                      key: const Key('job_interview_interviewer_subtitle'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: activeColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            key: const Key('job_interview_interviewer_text_container'),
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: activeColor.withValues(alpha: 0.08)),
            ),
            child: Text(
              text,
              key: const Key('job_interview_interviewer_question_text'),
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );

    if (reduceMotion) return content;
    return content.animate().fadeIn(duration: 350.ms).slideY(begin: 0.03);
  }
}
