import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

/// Animated instruction pill informing the user of the next flashcard action.
class FlashcardInstructionBanner extends StatelessWidget {
  final Color primaryColor;
  final bool isFlipped;
  final VocabularyQuest quest;

  const FlashcardInstructionBanner({
    super.key,
    required this.primaryColor,
    required this.isFlipped,
    required this.quest,
  });

  String _formatInstruction(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Tap card to check meaning';
    if (trimmed == trimmed.toUpperCase() && trimmed.length > 2) {
      return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        VowlMotion.lowAnimationModeOverride.value;

    final instructionText = isFlipped
        ? context.tr(
            'instructions.flashcards.swipe_instruction',
            fallback: 'Swipe left to review, right if you got it',
          )
        : _formatInstruction(InstructionHelper.getInstruction(quest));

    final bannerContent = Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: AnimatedSwitcher(
        duration: 300.ms,
        child: KeyedSubtree(
          key: ValueKey<bool>(isFlipped),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                isFlipped ? Icons.swipe_rounded : Icons.touch_app_rounded,
                size: 16.r,
                color: primaryColor,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  instructionText,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                    height: 1.35,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 380.w),
      child: reduceMotion
          ? bannerContent
          : bannerContent
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.2, end: 0),
    );
  }
}
