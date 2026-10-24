import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Card widget displaying the scenario or topic prompt for the journal entry.
class DailyJournalPrompt extends StatelessWidget {
  /// The journal topic or scenario description.
  final String text;

  /// The primary theme accent color for borders and gradients.
  final Color primaryColor;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Creates a [DailyJournalPrompt] widget.
  const DailyJournalPrompt({
    super.key,
    required this.text,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    Widget iconWidget = Icon(
      Icons.edit_note_rounded,
      color: Colors.amberAccent,
      size: 26.r,
    );
    if (!reduceMotion) {
      iconWidget = iconWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 3.seconds);
    }

    return Container(
      key: const Key('daily_journal_prompt'),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: isDark ? 0.18 : 0.12),
            primaryColor.withValues(alpha: isDark ? 0.05 : 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.28),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: TechPatternOverlay(opacity: 0.05)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: iconWidget,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  text,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white.withValues(alpha: 0.88) : const Color(0xFF1E293B),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
