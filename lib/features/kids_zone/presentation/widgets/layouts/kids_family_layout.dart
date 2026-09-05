import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';

/// Cozy Living Room Theme for Family Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsFamilyLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsFamilyLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'family',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Framed Painting
            Expanded(
              flex: 5,
              child: Center(child: _buildFramedPainting(context, state, quest)),
            ),
            SizedBox(height: 24.h),
            KidsFittedText(
              context.tr(
                'games.kids_family_drag',
                fallback: 'Drag the photo to the frame! ✨',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            // The Polaroid Pictures on Mantle
            Flexible(
              flex: 5,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Wooden Mantlepiece
                  Container(
                    height: 24.h,
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF78350F), // Dark wood mantle
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(4.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  // Polaroids resting on mantle
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 24.h,
                      left: 16.w,
                      right: 16.w,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(quest.options?.length ?? 0, (
                        index,
                      ) {
                        final option = quest.options![index];
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: _buildPolaroidOption(
                              context,
                              state,
                              option,
                              quest.correctAnswer == option,
                              index,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFramedPainting(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
  ) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        final text = details.data;
        final isCorrect = (text == quest.correctAnswer);
        if (!isCorrect) {
          di.sl<KidsTTSService>().speak(text);
        }
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return InkWell(
          onTap: state.answerStatus.isAnswered
              ? null
              : () {
                  if (InstructionHelper.getInstruction(quest).isNotEmpty) {
                    di.sl<KidsTTSService>().speak(
                      InstructionHelper.getInstruction(quest),
                    );
                  }
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 280.w,
            height: 200.h,
            decoration: BoxDecoration(
              color: isHovering
                  ? const Color(0xFFFEF9C3)
                  : const Color(0xFFFEF08A), // Highlight yellow
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(
                color: isHovering
                    ? const Color(0xFFD97706)
                    : const Color(0xFFB45309),
                width: 16.r,
              ), // Ornate wooden frame
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (quest.emoji != null)
                        state.answerStatus == AnswerStatus.correct
                            ? Text(
                                quest.emoji!,
                                style: TextStyle(fontSize: 80.sp),
                              )
                            : ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  const Color(
                                    0xFF78350F,
                                  ).withValues(alpha: 0.15),
                                  BlendMode.srcIn,
                                ),
                                child: Text(
                                  quest.emoji!,
                                  style: TextStyle(fontSize: 80.sp),
                                ),
                              ),
                      if (state.answerStatus != AnswerStatus.correct)
                        KidsFittedText(
                          "?",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 60.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(
                              0xFF78350F,
                            ).withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPolaroidOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    // Slight random rotation for polaroids
    final double rotation = index % 2 == 0 ? -0.05 : 0.05;

    // Extract emoji and text
    final parts = text.split(' ');
    final String emoji = parts.length > 1 ? parts.last : '';
    final String word = parts.length > 1
        ? parts.sublist(0, parts.length - 1).join(' ')
        : text;

    final polaroidWidget = Transform.rotate(
      angle: rotation,
      child: Container(
        height: 110.h,
        width: 90.w,
        padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 20.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          children: [
            // Photo area
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFE2E8F0), // Blank photo grey
                child: Center(
                  child: emoji.isNotEmpty
                      ? Text(emoji, style: TextStyle(fontSize: 32.sp))
                      : Icon(
                          Icons.photo_rounded,
                          color: const Color(0xFF94A3B8),
                          size: 24.r,
                        ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            // Handwriting text
            KidsFittedText(
              word,
              style: TextStyle(
                fontFamily: 'ComicSans', // Or any casual font
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(opacity: 0.9, child: polaroidWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: polaroidWidget),
      child: polaroidWidget,
    );
  }
}
