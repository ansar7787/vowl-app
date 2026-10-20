import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReadAndAnswerAnchorPoint extends StatelessWidget {
  final String question;
  final Color color;
  final bool isDark;
  final VoidCallback? onPlayAudio;
  final ValueChanged<int>? onOptionDropped;
  final bool isAnswered;

  const ReadAndAnswerAnchorPoint({
    super.key,
    required this.question,
    required this.color,
    required this.isDark,
    this.onPlayAudio,
    this.onOptionDropped,
    this.isAnswered = false,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      key: const ValueKey('read_and_answer_drag_target'),
      onWillAcceptWithDetails: (details) => !isAnswered,
      onAcceptWithDetails: (details) => onOptionDropped?.call(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty && !isAnswered;

        return Semantics(
          label:
              'Question: $question. ${onPlayAudio != null ? "Double tap audio button to listen." : ""}',
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isHovering
                  ? color.withValues(alpha: isDark ? 0.2 : 0.1)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isHovering
                    ? color
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : color.withValues(alpha: 0.15)),
                width: isHovering ? 2.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHovering
                      ? color.withValues(alpha: 0.2)
                      : (isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.03)),
                  blurRadius: isHovering ? 16 : 10,
                  offset: const Offset(0, 3),
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
                          color: color,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Question',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    if (onPlayAudio != null)
                      Semantics(
                        label: 'Listen to question',
                        button: true,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: const ValueKey(
                              'read_and_answer_tts_question_button',
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            onTap: onPlayAudio,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.volume_up_rounded,
                                    color: color,
                                    size: 16.r,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Listen',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  question,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.slate900,
                    height: 1.45,
                  ),
                ),
                if (isHovering) ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.file_download_outlined,
                          size: 16.r,
                          color: color,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Drop answer here',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
