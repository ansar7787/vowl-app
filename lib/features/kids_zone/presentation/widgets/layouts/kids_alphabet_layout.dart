import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';

class KidsAlphabetLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsAlphabetLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'alphabet',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h), // Mascot space
            // The Chalkboard for the Question
            Expanded(
              flex: 5,
              child: Center(child: _buildChalkboard(context, state, quest)),
            ),

            Text(
              context.tr(
                'games.kids_alphabet_drag',
                fallback: 'Drag the block to the chalkboard! 👆',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 12.h),

            // The Wooden Blocks for Options
            Flexible(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(quest.options?.length ?? 0, (index) {
                    final option = quest.options![index];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: _buildWoodenBlock(
                          context,
                          state,
                          option,
                          quest.correctAnswer == option,
                        ),
                      ),
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

  Widget _buildChalkboard(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
  ) {
    bool isRevealed = false; // Local state for progressive disclosure

    return StatefulBuilder(
      key: ValueKey(quest), // CRITICAL: Reset state when the question changes
      builder: (context, setState) {
        return DragTarget<String>(
          onAcceptWithDetails: (details) {
            if (state.lastAnswerCorrect != null) return;
            final text = details.data;
            final isCorrect = (text == quest.correctAnswer);
            context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
          },
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 320.w,
              height: 220.h,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isHovering
                    ? const Color(0xFF2D6A4F)
                    : const Color(0xFF1B4332), // Highlight green when hovering
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isHovering
                      ? const Color(0xFFB07D45)
                      : const Color(0xFF8B5A2B),
                  width: 12.r,
                ), // Wooden frame
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: InkWell(
                onTap: state.lastAnswerCorrect != null
                    ? null
                    : () {
                        // Play the instruction sound
                        if (quest.instruction != null) {
                          di.sl<KidsTTSService>().speak(quest.instruction!);
                        }
                        // Reveal the visual clues if not already revealed
                        if (!isRevealed) {
                          setState(() => isRevealed = true);
                        }
                      },
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The instruction is now handled entirely by the Kidz Buddy mascot bubble!

                      // The interactive mystery button / letter
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                        child: isRevealed
                            ? ((quest.wordEmoji ?? quest.emoji) != null
                                  ? Text(
                                      (quest.wordEmoji ?? quest.emoji)!,
                                      key: const ValueKey('emoji'),
                                      style: TextStyle(fontSize: 64.sp),
                                    )
                                  : const SizedBox.shrink())
                            : Column(
                                key: const ValueKey('mystery'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(16.r),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFDE68A,
                                      ).withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFFDE68A),
                                        width: 3.w,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.volume_up_rounded,
                                      size: 40.sp,
                                      color: const Color(0xFFFDE68A),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 8.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFDE68A),
                                      borderRadius: BorderRadius.circular(20.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          offset: Offset(0, 4.h),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      context.tr(
                                        'games.kids_tap_me',
                                        fallback: 'TAP ME!',
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(
                                          0xFF78350F,
                                        ), // Etched wood color
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      // The visual word clue (fade in without jumping layout)
                      AnimatedOpacity(
                        opacity: isRevealed ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: quest.wordExample != null
                            ? Padding(
                                padding: EdgeInsets.only(
                                  top: 8.h,
                                  left: 8.w,
                                  right: 8.w,
                                ),
                                child: AutoSizeText.rich(
                                  TextSpan(
                                    children: [
                                      ..._buildHighlightedWordSpans(
                                        quest.wordExample!,
                                        quest.correctAnswer,
                                      ),
                                      if (quest.phonetic != null)
                                        TextSpan(
                                          text: ' (/${quest.phonetic}/)',
                                          style: const TextStyle(
                                            color: Color(0xFFFCD34D),
                                          ), // Bright yellow to highlight phonetic sound
                                        ),
                                    ],
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  minFontSize: 12,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWoodenBlock(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    final baseColor = const Color(0xFFFDE68A); // Light wood
    final shadowColor = const Color(0xFFD97706); // Dark wood

    final blockWidget = Container(
      height: 100.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: shadowColor, width: 2),
        boxShadow: [BoxShadow(color: shadowColor, offset: Offset(0, 8.h))],
      ),
      child: Center(
        child: AutoSizeText(
          text,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 32.sp,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF78350F), // Etched wood color
          ),
          maxLines: 1,
          minFontSize: 12,
          textAlign: TextAlign.center,
        ),
      ),
    );

    if (state.lastAnswerCorrect != null) {
      return blockWidget;
    }

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.15, // Make it pop more when picked up
          child: Transform.rotate(
            angle:
                0.08, // Playful slight tilt while dragging (AAA micro-interaction)
            child: Opacity(opacity: 0.95, child: blockWidget),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: blockWidget),
      child: blockWidget,
    );
  }

  /// Helper to highlight the target letter in the word to teach phonetic connection
  List<TextSpan> _buildHighlightedWordSpans(
    String word,
    String? correctAnswer,
  ) {
    if (correctAnswer == null || correctAnswer.isEmpty) {
      return [
        TextSpan(
          text: word,
          style: const TextStyle(color: Color(0xFFA7F3D0)),
        ),
      ];
    }

    if (word.toLowerCase().startsWith(correctAnswer.toLowerCase())) {
      final firstPart = word.substring(0, correctAnswer.length);
      final restPart = word.substring(correctAnswer.length);
      return [
        TextSpan(
          text: firstPart,
          style: const TextStyle(
            color: Color(0xFFFCD34D),
            fontWeight: FontWeight.w900,
          ), // Highlight Yellow
        ),
        TextSpan(
          text: restPart,
          style: const TextStyle(color: Color(0xFFA7F3D0)), // Chalk mint
        ),
      ];
    }
    return [
      TextSpan(
        text: word,
        style: const TextStyle(color: Color(0xFFA7F3D0)),
      ),
    ];
  }
}
