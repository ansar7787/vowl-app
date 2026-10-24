import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Card displaying the contextual usage question prompt and fill-in sentence with audio TTS playback.
class ContextualUsageCard extends StatelessWidget {
  /// The question prompt or fill-in sentence template.
  final String question;

  /// Theme accent color for cards, borders, and audio triggers.
  final Color color;

  /// Whether dark theme is enabled.
  final bool isDark;

  /// Whether the user has submitted an answer for this trial.
  final bool isAnswered;

  /// Whether the submitted response was correct, or `null` if pending.
  final bool? isCorrect;

  /// The candidate option word selected by the user.
  final String? selectedOption;

  /// Creates a [ContextualUsageCard] widget.
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
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget cardContent = AnimatedContainer(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(
            alpha: isAnswered ? 0.5 : (isDark ? 0.25 : 0.18),
          ),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : color).withValues(
              alpha: isAnswered ? 0.12 : 0.05,
            ),
            blurRadius: isAnswered ? 24 : 16,
            offset: Offset(0, isAnswered ? 8 : 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Sentence Context',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: color,
                    ),
                  ),
                ),
              ),
              ScaleButton(
                onTap: () {
                  if (di.sl.isRegistered<SoundService>()) {
                    final speechSentence = question.replaceAll(
                      RegExp(r'_+'),
                      selectedOption ?? 'blank',
                    );
                    di.sl<SoundService>().playTts(speechSentence);
                  }
                },
                child: Semantics(
                  label: 'Listen to sentence',
                  button: true,
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: 18.r,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Text.rich(
            TextSpan(
              children: _buildSentenceSpans(
                question,
                color,
                isDark,
              ),
            ),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
          SizedBox(height: 6.h),
        ],
      ),
    );

    if (!reduceMotion) {
      cardContent = cardContent
          .animate(target: isAnswered ? 1 : 0)
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.02, 1.02),
            curve: Curves.easeOutCubic,
            duration: 300.ms,
          );
    }

    return Center(
      child: cardContent,
    );
  }

  List<TextSpan> _buildSentenceSpans(
    String sentence,
    Color color,
    bool isDark,
  ) {
    final parts = sentence.split(RegExp(r'_+'));
    final List<TextSpan> spans = [];

    for (int i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 17.5.sp,
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white.withValues(alpha: 0.95)
                : const Color(0xFF1E293B),
            height: 1.55,
          ),
        ),
      );

      if (i < parts.length - 1) {
        final displayText = selectedOption != null
            ? " ${_formatOptionInSentence(selectedOption!)} "
            : "  _______  ";

        spans.add(
          TextSpan(
            text: displayText,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 17.5.sp,
              fontWeight: FontWeight.w700,
              color: isAnswered
                  ? (isCorrect == true
                      ? AppColors.gameCorrect
                      : AppColors.gameIncorrect)
                  : color,
              decoration: isAnswered
                  ? TextDecoration.none
                  : TextDecoration.underline,
              decorationColor: color.withValues(alpha: 0.4),
              decorationThickness: 2,
            ),
          ),
        );
      }
    }
    return spans;
  }

  String _formatOptionInSentence(String option) {
    if (option.isEmpty) return option;
    if (option == option.toUpperCase() && option.length > 1) {
      return option.toLowerCase();
    }
    return option;
  }
}
