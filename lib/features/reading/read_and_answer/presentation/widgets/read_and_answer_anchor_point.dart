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
          label: 'Question: $question. ${onPlayAudio != null ? "Double tap audio button to listen." : ""}',
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isHovering
                  ? color.withValues(alpha: isDark ? 0.2 : 0.12)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.white.withValues(alpha: 0.85)),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isHovering
                    ? color
                    : color.withValues(alpha: isDark ? 0.15 : 0.1),
                width: isHovering ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHovering
                      ? color.withValues(alpha: 0.25)
                      : color.withValues(alpha: isDark ? 0.05 : 0.03),
                  blurRadius: isHovering ? 20 : 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isHovering
                          ? Icons.file_download_outlined
                          : Icons.help_outline_rounded,
                      color: color,
                      size: 20.r,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    question,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.35,
                    ),
                  ),
                ),
                if (onPlayAudio != null) ...[
                  SizedBox(width: 8.w),
                  Semantics(
                    label: 'Listen to question',
                    button: true,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const ValueKey('read_and_answer_tts_question_button'),
                        borderRadius: BorderRadius.circular(20.r),
                        onTap: onPlayAudio,
                        child: Padding(
                          padding: EdgeInsets.all(6.r),
                          child: Icon(
                            Icons.volume_up_rounded,
                            color: color,
                            size: 22.r,
                          ),
                        ),
                      ),
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
