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

/// Immersive Storefront Theme for Professions Game
class KidsProfessionsLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsProfessionsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'professions',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 60.h),
            // The Shop Storefront (Target)
            Expanded(
              flex: 6,
              child: Center(
                child: _buildCareerStorefront(context, state, quest),
              ),
            ),
            SizedBox(height: 24.h),
            KidsFittedText(
              context.tr(
                'games.kids_professions_drag',
                fallback: 'Drag the clipboard to the shop! ✨',
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
            // The Job Clipboards (Options)
            Flexible(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16.w,
                  runSpacing: 16.h,
                  children: List.generate(quest.options?.length ?? 0, (index) {
                    final option = quest.options![index];
                    return _buildClipboardOption(
                      context,
                      state,
                      option,
                      quest.correctAnswer == option,
                      index,
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCareerStorefront(
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
                    di.sl<KidsTTSService>().speak(InstructionHelper.getInstruction(quest));
                  }
                },
          child: Container(
            width: 320.w,
            height: 260.h,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: const Color(0xFFFDE047), // Yellow building
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isHovering ? Colors.white : const Color(0xFFCA8A04),
                width: isHovering ? 8 : 6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Striped Awning at the top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: List.generate(8, (index) {
                      return Expanded(
                        child: Container(
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: index % 2 == 0
                                ? const Color(0xFFEF4444)
                                : Colors.white,
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(16.r),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // The Shop Window
                Positioned(
                  top: 60.h,
                  left: 30.w,
                  right: 30.w,
                  bottom: 20.h,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE), // Glass blue
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFF93C5FD),
                        width: 4,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glass glare effect
                        Positioned(
                          top: 10.h,
                          left: 10.w,
                          child: Container(
                            width: 60.w,
                            height: 15.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(5.r),
                            ),
                          ),
                        ),
                        // The emoji / question mark
                        if (quest.emoji != null &&
                            (quest.question == "?" || quest.question == null))
                          state.answerStatus == AnswerStatus.correct
                              ? Text(
                                  quest.emoji!,
                                  style: TextStyle(fontSize: 80.sp),
                                )
                              : ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    const Color(
                                      0xFF1E40AF,
                                    ).withValues(alpha: 0.3),
                                    BlendMode.srcIn,
                                  ),
                                  child: Text(
                                    quest.emoji!,
                                    style: TextStyle(fontSize: 80.sp),
                                  ),
                                ),
                        if (state.answerStatus != AnswerStatus.correct ||
                            (quest.question != "?" && quest.question != null))
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: KidsFittedText(
                              quest.question ?? "?",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize:
                                    (quest.question == "?" ||
                                        quest.question == null)
                                    ? 80.sp
                                    : 32.sp,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1E3A8A).withValues(
                                  alpha:
                                      (quest.question == "?" ||
                                          quest.question == null)
                                      ? 0.7
                                      : 1.0,
                                ),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 6,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClipboardOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    final clipboardWidget = SizedBox(
      width: 100.w,
      height: 130.h,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // The wooden board
          Positioned(
            top: 10.h,
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFB45309), // Dark Wood
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          // The white paper
          Positioned(
            top: 25.h,
            bottom: 10.h,
            left: 10.w,
            right: 10.w,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: KidsFittedText(
                    text,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                  ),
                ),
              ),
            ),
          ),
          // The silver clip
          Positioned(
            top: 0,
            child: Container(
              width: 40.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: const Color(0xFF94A3B8), // Silver metal
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: const Color(0xFF475569), width: 2),
              ),
              child: Center(
                child: Container(
                  width: 20.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(opacity: 0.9, child: clipboardWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: clipboardWidget),
      child: clipboardWidget,
    );
  }
}
