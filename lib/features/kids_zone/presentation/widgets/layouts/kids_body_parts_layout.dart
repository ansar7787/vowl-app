import 'package:vowl/core/theme/app_colors.dart';
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

class _LocalPalette {
  _LocalPalette._();
  static const Color color38bdf8 = Color(0xFF38BDF8);
  static const Color colorfde68a = Color(0xFFFDE68A);
  static const Color colorfca5a5 = Color(0xFFFCA5A5);
  static const Color color6ee7b7 = Color(0xFF6EE7B7);
  static const Color color93c5fd = Color(0xFF93C5FD);
}

/// Friendly Clinic Theme for Body Parts Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsBodyPartsLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsBodyPartsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'body_parts',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The X-Ray Board
            Expanded(
              flex: 5,
              child: Center(child: _buildXRayBoard(context, state, quest)),
            ),
            SizedBox(height: 24.h),
            KidsFittedText(
              context.tr(
                'games.kids_body_parts_drag',
                fallback: 'Place the correct band-aid on the X-Ray.',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            // The Band-aids (Options)
            Flexible(
              flex: 5,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Clinic Desk (Clean white/blue)
                  Container(
                    height: 30.h,
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8.r),
                      ),
                      border: Border.all(color: AppColors.slate300, width: 2),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 10.h,
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
                            child: _buildBandaidOption(
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

  Widget _buildXRayBoard(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
  ) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        final text = details.data;
        final isCorrect = (text == quest.correctAnswer);
        if (!isCorrect) {
          final lastSpace = text.lastIndexOf(' ');
          final wordOnly = lastSpace != -1 ? text.substring(0, lastSpace) : text;
          di.sl<KidsTTSService>().speak(wordOnly);
        }
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final bool isCorrect = state.answerStatus == AnswerStatus.correct;
        
        return Semantics(
          label: 'X-Ray board',
          hint: 'Drag a band-aid here to answer',
          child: InkWell(
            onTap: state.answerStatus.isAnswered
                ? null
                : () {
                    if (InstructionHelper.getInstruction(quest).isNotEmpty) {
                      di.sl<KidsTTSService>().speak(
                        InstructionHelper.getInstruction(quest),
                      );
                    }
                  },
            borderRadius: BorderRadius.circular(12.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: 320.w,
                maxHeight: 220.h,
              ),
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              decoration: BoxDecoration(
                color: isHovering ? AppColors.slate800 : AppColors.slate900,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isHovering
                      ? _LocalPalette.color38bdf8
                      : AppColors.slate300,
                  width: 12.r,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _LocalPalette.color38bdf8.withValues(
                      alpha: isHovering ? 0.6 : 0.3,
                    ),
                    blurRadius: isHovering ? 30 : 15,
                    spreadRadius: isHovering ? 10 : 2,
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: isCorrect && quest.emoji != null
                        ? Text(
                            quest.emoji!,
                            key: const ValueKey('correct_emoji'),
                            style: TextStyle(fontSize: 80.sp),
                            textAlign: TextAlign.center,
                          )
                        : KidsFittedText(
                            quest.question ?? "?",
                            key: const ValueKey('question_text'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: (quest.question == "?" || quest.question == null) ? 70.sp : 24.sp,
                              fontWeight: FontWeight.w600,
                              color: isHovering ? Colors.white : Colors.white.withValues(alpha: 0.8),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 4,
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBandaidOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    return _KidsBandaidDraggable(
      text: text,
      index: index,
      onTap: state.answerStatus.isAnswered ? null : () {
        if (!isCorrect) {
          final lastSpace = text.lastIndexOf(' ');
          final wordOnly = lastSpace != -1 ? text.substring(0, lastSpace) : text;
          di.sl<KidsTTSService>().speak(wordOnly);
        }
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
    );
  }
}

class _KidsBandaidDraggable extends StatelessWidget {
  final String text;
  final int index;
  final VoidCallback? onTap;

  const _KidsBandaidDraggable({
    required this.text,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bandaidWidget = _KidsBandaidUI(text: text, index: index, width: constraints.maxWidth);
        
        return Draggable<String>(
          data: text,
          feedback: Material(
            color: Colors.transparent,
            child: Transform.scale(
              scale: 1.05,
              child: Opacity(opacity: 0.9, child: _KidsBandaidUI(text: text, index: index, width: constraints.maxWidth)),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: bandaidWidget),
          child: GestureDetector(
            onTap: onTap,
            child: Semantics(
              button: true,
              hint: 'Double tap to select this answer without dragging',
              child: bandaidWidget,
            ),
          ),
        );
      },
    );
  }
}

class _KidsBandaidUI extends StatelessWidget {
  final String text;
  final int index;
  final double width;

  const _KidsBandaidUI({
    required this.text,
    required this.index,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    const colors = [
      _LocalPalette.colorfde68a, // Light tan
      _LocalPalette.colorfca5a5, // Pinkish
      _LocalPalette.color6ee7b7, // Mint green (fun kid bandaid)
      _LocalPalette.color93c5fd, // Light blue
    ];
    final bandaidColor = colors[index % colors.length];

    return Container(
      height: 70.h,
      width: width, // Responsive width
      decoration: BoxDecoration(
        color: bandaidColor,
        borderRadius: BorderRadius.circular(35.r), // True pill shape for 70.h height
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Band-aid dots texture
          Positioned(left: 12.w, top: 20.h, child: const _BandaidDot()),
          Positioned(left: 12.w, bottom: 20.h, child: const _BandaidDot()),
          Positioned(right: 12.w, top: 20.h, child: const _BandaidDot()),
          Positioned(right: 12.w, bottom: 20.h, child: const _BandaidDot()),

          // White pad in the middle
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 18.w),
              padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Builder(
                builder: (context) {
                  final lastSpace = text.lastIndexOf(' ');
                  final wordText = lastSpace != -1 ? text.substring(0, lastSpace) : text;
                  final emojiText = lastSpace != -1 ? text.substring(lastSpace + 1) : '';

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: KidsFittedText(
                          wordText,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate900,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1, // Force word onto one line, preventing awkward wrapping
                        ),
                      ),
                      if (emojiText.isNotEmpty)
                        Text(
                          emojiText,
                          style: TextStyle(fontSize: 16.sp, height: 1.1),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BandaidDot extends StatelessWidget {
  const _BandaidDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4.r,
      height: 4.r,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
    );
  }
}
