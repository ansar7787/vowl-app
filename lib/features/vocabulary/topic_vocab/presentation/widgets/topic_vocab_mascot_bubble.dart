import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class TopicVocabMascotBubble extends StatelessWidget {
  final VowlMascotState botState;
  final String topic;
  final bool? lastAnswerCorrect;
  final String topicFact;
  final bool isDark;
  final VoidCallback onTapMascot;

  const TopicVocabMascotBubble({
    super.key,
    required this.botState,
    required this.topic,
    required this.lastAnswerCorrect,
    required this.topicFact,
    required this.isDark,
    required this.onTapMascot,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ScaleButton(
          onTap: onTapMascot,
          child: VowlMascot(state: botState, size: 60.r)
              .animate(target: lastAnswerCorrect == true ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 300.ms,
                curve: Curves.bounceOut,
              )
              .then()
              .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1)),
        ).animate().slideX(begin: -0.2, end: 0),
        SizedBox(width: 10.w),
        Flexible(
          child: Container(
            padding: EdgeInsets.all(12.r),
            margin: EdgeInsets.only(bottom: 20.h),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Text(
              lastAnswerCorrect == null
                  ? "Can you find the word that belongs to the ${topic.toLowerCase()} category?"
                  : (lastAnswerCorrect == true
                      ? "Great! Did you know? $topicFact"
                      : "Don't give up! Look for clues in the ${topic.toLowerCase()} context."),
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ).animate(
            key: ValueKey("${lastAnswerCorrect}_${DateTime.now().millisecondsSinceEpoch ~/ 5000}"),
          ).fadeIn().slideX(begin: 0.1),
        ),
      ],
    );
  }
}
