import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ContextualUsageCard extends StatelessWidget {
  final String question;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final bool? isCorrect;
  final String? selectedOption;

  const ContextualUsageCard({
    super.key,
    required this.question,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.isCorrect,
    required this.selectedOption,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
                width: 0.8.sw,
                height: 180.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.05),
                ),
              )
              .animate(target: isAnswered ? 1 : 0)
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.5, 1.5),
                curve: Curves.easeOutBack,
              ),
          AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                width: 0.88.sw,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(
                    color: color.withValues(alpha: isAnswered ? 0.6 : 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: isAnswered ? 0.3 : 0.05),
                      blurRadius: isAnswered ? 40 : 15,
                      offset: Offset(0, isAnswered ? 15 : 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: color.withValues(alpha: 0.1),
                    ),
                    SizedBox(height: 20.h),
                    RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: _buildSentenceSpans(
                              question,
                              color,
                              isDark,
                            ),
                          ),
                        )
                        .animate(target: isAnswered ? 1 : 0)
                        .shimmer(
                          duration: 1.5.seconds,
                          color: color.withValues(alpha: 0.2),
                        )
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.05, 1.05),
                        ),
                    SizedBox(height: 20.h),
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: color.withValues(alpha: 0.1),
                    ),
                  ],
                ),
              )
              .animate(target: isAnswered ? 1 : 0)
              .custom(
                builder: (context, value, child) => Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX((1 - value) * 0.2),
                  alignment: Alignment.topCenter,
                  child: child,
                ),
              ),
        ],
      ),
    );
  }

  List<TextSpan> _buildSentenceSpans(
    String sentence,
    Color color,
    bool isDark,
  ) {
    final parts = sentence.split("_____");
    List<TextSpan> spans = [];

    for (int i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 19.sp,
            fontWeight: FontWeight.w400,
            color: isDark
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.black87,
            height: 1.5,
          ),
        ),
      );

      if (i < parts.length - 1) {
        spans.add(
          TextSpan(
            text: selectedOption ?? " ________ ",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
              color: isAnswered
                  ? (isCorrect == true ? Colors.greenAccent : Colors.redAccent)
                  : color,
              decoration: isAnswered
                  ? TextDecoration.none
                  : TextDecoration.underline,
            ),
          ),
        );
      }
    }
    return spans;
  }
}
