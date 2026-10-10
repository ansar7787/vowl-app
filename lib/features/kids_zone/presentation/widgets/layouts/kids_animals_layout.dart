import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/haptic_service.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color166534 = Color(0xFF166534);
  static const Color color14532d = Color(0xFF14532D);
  static const Color color15803d = Color(0xFF15803D);
  static const Color colorfef9c3 = Color(0xFFFEF9C3);
  static const Color colorfef3c7 = Color(0xFFFEF3C7);
  static const Color color92400e = Color(0xFF92400E);
  static const Color woodLight = Color(0xFFF59E0B);
  static const Color woodDark = Color(0xFFD97706);
}

/// Jungle Safari Theme for Animals Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsAnimalsLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsAnimalsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'animals',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Stack(
          children: [
            // Lush jungle framing the screen edges
            Positioned(
              top: 40.h,
              left: -20.w,
              child: _SafariLeaf(
                color: _LocalPalette.color166534,
                size: 80,
                rotation: 0.5,
              ),
            ),
            Positioned(
              top: 100.h,
              right: -10.w,
              child: _SafariLeaf(
                color: _LocalPalette.color14532d,
                size: 100,
                rotation: -0.8,
              ),
            ),
            Positioned(
              bottom: 120.h,
              left: -30.w,
              child: _SafariLeaf(
                color: _LocalPalette.color15803d,
                size: 120,
                rotation: 0.3,
              ),
            ),

            Column(
              children: [
                SizedBox(height: 120.h),

                // The Binoculars / Safari Frame
                Expanded(
                  flex: 4,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: _SafariBinocularFrame(state: state, quest: quest),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Wooden Signposts for Options
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 16.w,
                        runSpacing: 16.h,
                        children: List.generate(quest.options?.length ?? 0, (
                          index,
                        ) {
                          final option = quest.options![index];
                          return _DraggableWoodenSignpost(
                            state: state,
                            quest: quest,
                            text: option,
                            isCorrect: quest.correctAnswer == option,
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SafariLeaf extends StatelessWidget {
  final Color color;
  final double size;
  final double rotation;

  const _SafariLeaf({
    required this.color,
    required this.size,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: size.r,
        height: size.r,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size.r),
            bottomRight: Radius.circular(size.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(4, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafariBinocularFrame extends StatelessWidget {
  final KidsLoaded state;
  final dynamic quest;

  const _SafariBinocularFrame({required this.state, required this.quest});

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        di.sl<HapticService>().selection();
        final text = details.data;
        final isCorrect = (text == quest.correctAnswer);
        if (!isCorrect) {
          di.sl<KidsTTSService>().speak(text);
        } else {
          // Play the animal sound for the correct animal if it exists in JSON
          if (quest.animalSound != null &&
              quest.animalSound!.toString().isNotEmpty) {
            di.sl<KidsTTSService>().speak(quest.animalSound!);
          }
        }
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final isSuccess = state.answerStatus == AnswerStatus.correct;

        Widget binocularWidget = Semantics(
          label: 'Drop target for ${quest.question}. Tap to hear instruction.',
          button: true,
          child: InkWell(
            onTap: state.answerStatus.isAnswered
                ? null
                : () {
                    final instruction = InstructionHelper.getInstruction(quest);
                    if (instruction.isNotEmpty) {
                      di.sl<KidsTTSService>().speak(instruction);
                    }
                  },
            child: AspectRatio(
              aspectRatio: 1.5,
              child: Container(
                constraints: BoxConstraints(maxWidth: 400.w, maxHeight: 266.h),
                decoration: BoxDecoration(
                  color: isHovering
                      ? _LocalPalette.colorfef9c3
                      : _LocalPalette.colorfef3c7, // Safari Khaki
                  borderRadius: BorderRadius.circular(
                    100.r,
                  ), // Pill shape for binoculars
                  border: Border.all(
                    color: isHovering || isSuccess
                        ? _LocalPalette.color92400e
                        : AppColors.amber900,
                    width: isHovering || isSuccess ? 10.r : 8.r,
                  ), // Dark leather
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isHovering ? 0.4 : 0.2,
                      ),
                      blurRadius: isHovering ? 25 : 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Middle split of binoculars
                    Container(
                      width: 12.w,
                      height: double.infinity,
                      color: AppColors.amber900,
                    ),
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              child: KidsFittedText(
                                quest.question ?? "?",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: AppColors.slate800,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        if (isSuccess) {
          binocularWidget = binocularWidget.animate().scale(
            duration: 400.ms,
            curve: Curves.elasticOut,
          );
        }

        return binocularWidget;
      },
    );
  }
}

class _DraggableWoodenSignpost extends StatelessWidget {
  final KidsLoaded state;
  final dynamic quest;
  final String text;
  final bool isCorrect;

  const _DraggableWoodenSignpost({
    required this.state,
    required this.quest,
    required this.text,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final shadowColor = _LocalPalette.color92400e; // Dark Wood

    final signpostWidget =
        Semantics(
              label: 'Option: $text. Tap or Drag to binoculars.',
              button: true,
              child: GestureDetector(
                onTap: state.answerStatus.isAnswered
                    ? null
                    : () {
                        di.sl<HapticService>().selection();
                        if (!isCorrect) {
                          di.sl<KidsTTSService>().speak(text);
                        } else {
                          // Play the animal sound for the correct animal if it exists in JSON
                          if (quest.animalSound != null &&
                              quest.animalSound!.toString().isNotEmpty) {
                            di.sl<KidsTTSService>().speak(quest.animalSound!);
                          }
                        }
                        context.read<KidsBloc>().add(
                          SubmitKidsAnswer(isCorrect),
                        );
                      },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The wooden board
                    Container(
                      height: 60.h,
                      width: 80.w,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            _LocalPalette.woodLight,
                            _LocalPalette.woodDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: shadowColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: Offset(0, 4.h),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              text,
                              style: TextStyle(fontSize: 32.sp),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // The stick holding it up
                    Container(
                      height: 40.h,
                      width: 16.w,
                      decoration: BoxDecoration(
                        color: shadowColor,
                        border: Border.all(color: AppColors.amber900, width: 1),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .rotate(
              duration: 2.seconds,
              begin: -0.02,
              end: 0.02,
              curve: Curves.easeInOutSine,
            );

    return Draggable<String>(
      data: text,
      onDragStarted: () => di.sl<HapticService>().light(),
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(opacity: 0.9, child: signpostWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: signpostWidget),
      child: signpostWidget,
    );
  }
}
