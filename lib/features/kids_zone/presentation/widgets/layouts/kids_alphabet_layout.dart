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

            AutoSizeText(
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
              maxLines: 2,
              minFontSize: 10,
              textAlign: TextAlign.center,
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
                        if (quest.wordExample != null) {
                          di.sl<KidsTTSService>().speak(quest.wordExample!);
                        } else if (quest.question != null) {
                          di.sl<KidsTTSService>().speak(quest.question!);
                        }
                        // Reveal the visual clues if not already revealed
                        if (!isRevealed) {
                          setState(() => isRevealed = true);
                        }
                      },
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: !isRevealed
                        ? _buildUnrevealedState(context)
                        : _buildRevealedState(context, quest),
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
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 32.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF78350F), // Etched wood color
            ),

            textAlign: TextAlign.center,
          ),
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
            fontWeight: FontWeight.w700,
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

  Widget _buildUnrevealedState(BuildContext context) {
    return Column(
      key: const ValueKey('unrevealed'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.help_outline_rounded,
          size: 64.sp,
          color: const Color(0xFFFDE68A).withValues(alpha: 0.5),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFDE68A),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: Offset(0, 4.h),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.volume_up_rounded, size: 20.sp, color: const Color(0xFF78350F)),
              SizedBox(width: 8.w),
              AutoSizeText(
                context.tr('games.kids_tap_clue', fallback: 'TAP FOR CLUE!'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF78350F),
                  letterSpacing: 1.2,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRevealedState(BuildContext context, dynamic quest) {
    return Padding(
      key: const ValueKey('revealed'),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (quest.wordExample != null)
              AutoSizeText.rich(
                TextSpan(
                  children: [
                    ..._buildHighlightedWordSpans(quest.wordExample!, quest.correctAnswer),
                    if (quest.phonetic != null)
                      TextSpan(
                        text: ' (/${quest.phonetic}/)',
                        style: const TextStyle(color: Color(0xFFFCD34D)), 
                      ),
                  ],
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 32.sp, // Made bigger since it's the main focus now
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                minFontSize: 14,
                overflow: TextOverflow.ellipsis,
              ),
            if (quest.wordExample != null) SizedBox(height: 12.h),
            if ((quest.wordEmoji ?? quest.emoji) != null)
              Text(
                (quest.wordEmoji ?? quest.emoji)!,
                style: TextStyle(fontSize: 80.sp),
              ),
          ],
        ),
      ),
    );
  }
}
