import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/kids_zone/theme/kids_colors.dart';
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
import 'package:flutter_animate/flutter_animate.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color colorfde68a = Color(0xFFFDE68A);
  static const Color colorfef3c7 = Color(0xFFFEF3C7);
  static const Color colorfca5a5 = Color(0xFFFCA5A5);
  static const Color color93c5fd = Color(0xFF93C5FD);
  static const Color color6ee7b7 = Color(0xFF6EE7B7);
  static const Color colorc4b5fd = Color(0xFFC4B5FD);
}

/// Fashion Wardrobe Theme for Clothing Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsClothingLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsClothingLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'clothing',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Open Closet
            Expanded(
              flex: 5,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildClosetBoard(context, state, quest),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            KidsFittedText(
              context.tr(
                'games.kids_clothing_drag',
                fallback: 'Drag the clothing tag to the closet! ✨',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500, // Reduced from w600
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            // The Clothing Hangers (Options)
            Flexible(
              flex: 5,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // The metal closet rod
                      Positioned(
                        top: 15.h,
                        left: 16.w,
                        right: 16.w,
                        child: Container(
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: AppColors.slate400, // Silver rod
                            borderRadius: BorderRadius.circular(4.r),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: 20.h,
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
                            child: _buildHangerOption(
                              context,
                              state,
                              quest,
                              option,
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
            ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildClosetBoard(
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
          child: Container(
            width: 280.w,
            height: 200.h,
            decoration: BoxDecoration(
              color: isHovering
                  ? _LocalPalette.colorfde68a
                  : _LocalPalette.colorfef3c7, // Light wood inside closet
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isHovering ? AppColors.amber600 : KidsColors.warmAmber,
                width: 8.r, // Reduced from 12.r for a cleaner look
              ), // Dark wood frame
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isHovering ? 0.4 : 0.2),
                  blurRadius: isHovering ? 25 : 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (quest.emoji != null && state.answerStatus == AnswerStatus.correct)
                            Text(
                              quest.emoji!,
                              style: TextStyle(fontSize: 80.sp),
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
                                      : 24.sp,
                                  fontWeight: FontWeight.w600, // Reduced from w700
                                  color: AppColors.amber600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 6,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!state.answerStatus.isAnswered)
                  Positioned(
                    bottom: 12.h,
                    right: 12.w,
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: AppColors.amber600.withValues(alpha: 0.4),
                      size: 28.r,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHangerOption(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
    String text,
    int index,
  ) {
    final colors = [
      _LocalPalette.colorfca5a5, // Light Red
      _LocalPalette.color93c5fd, // Light Blue
      _LocalPalette.color6ee7b7, // Mint
      _LocalPalette.colorc4b5fd, // Light Purple
    ];
    final tagColor = colors[index % colors.length];

    // Split text and emoji to place emoji on a new line and prevent awkward wrapping
    final lastSpaceIndex = text.lastIndexOf(' ');
    String label = text;
    String emoji = '';
    if (lastSpaceIndex != -1 && lastSpaceIndex < text.length - 1) {
      final potentialEmoji = text.substring(lastSpaceIndex + 1);
      // Check if it's an emoji (no letters/numbers)
      if (!RegExp(r'[a-zA-Z0-9]').hasMatch(potentialEmoji)) {
        label = text.substring(0, lastSpaceIndex);
        emoji = potentialEmoji;
      }
    }

    final hangerWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Metal Hanger Hook
        Container(
          width: 20.w,
          height: 15.h,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.slate400, width: 3.r),
              left: BorderSide(color: AppColors.slate400, width: 3.r),
              right: BorderSide(color: AppColors.slate400, width: 3.r),
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
          ),
        ),
        // Wooden Hanger Base
        Container(
          height: 8.h,
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: AppColors.amber600,
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        // Clothing Tag hanging from it
        Container(
          height: 85.h, 
          width: double.infinity, 
          margin: EdgeInsets.symmetric(horizontal: 4.w).copyWith(top: 2.h),
          decoration: BoxDecoration(
            color: tagColor,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  KidsFittedText(
                    label,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp, // Reduced for a professional standard look
                      fontWeight: FontWeight.w500, // Reduced from w600 for standard look
                      color: AppColors.slate900,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2, 
                  ),
                  if (emoji.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      emoji,
                      style: TextStyle(fontSize: 22.sp, height: 1.0),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(
            opacity: 0.9,
            child: SizedBox(
              width: 80.w, // Constrain double.infinity during drag
              child: hangerWidget,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: hangerWidget),
      child: GestureDetector(
        onTap: () {
          if (state.answerStatus.isAnswered) return;
          final isCorrect = (text == quest.correctAnswer);
          if (!isCorrect) {
            di.sl<KidsTTSService>().speak(text);
          }
          context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
        },
        child: hangerWidget
            .animate(delay: (200 + index * 150).ms)
            .shake(
              hz: 2,
              rotation: 0.08,
              offset: Offset.zero,
              duration: 800.ms,
            ),
      ),
    );
  }
}
