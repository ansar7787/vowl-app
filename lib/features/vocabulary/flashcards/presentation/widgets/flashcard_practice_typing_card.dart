import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Active recall typing card widget for Flashcard Practice Phase.
class FlashcardPracticeTypingCard extends StatelessWidget {
  final PracticeExercise exercise;
  final TextEditingController textController;
  final bool hasChecked;
  final bool isAnswerCorrect;
  final int shakeCount;
  final bool isDark;
  final VoidCallback onCheck;

  const FlashcardPracticeTypingCard({
    super.key,
    required this.exercise,
    required this.textController,
    required this.hasChecked,
    required this.isAnswerCorrect,
    required this.shakeCount,
    required this.isDark,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sentence prompt
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slate900 : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark ? AppColors.slate800 : AppColors.slate200,
            ),
          ),
          child: Text(
            exercise.sentence ?? exercise.question ?? '',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.slate900,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 20.h),

        // Text input wrapped in shakeable wrapper
        ShakeableWrapper(
          shakeCount: shakeCount,
          child: TextField(
            controller: textController,
            enabled: !hasChecked,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) {
              if (!hasChecked) onCheck();
            },
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
            decoration: InputDecoration(
              hintText: 'Type the missing word from memory...',
              hintStyle: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                color: isDark ? AppColors.slate500 : AppColors.slate400,
              ),
              filled: true,
              fillColor: isDark ? AppColors.slate900 : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: isDark ? AppColors.slate800 : AppColors.slate300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(
                  color: AppColors.indigo500,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
