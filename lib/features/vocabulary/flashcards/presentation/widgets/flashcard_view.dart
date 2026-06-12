import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_card_side.dart';
import 'package:vowl/features/vocabulary/presentation/themes/vocab_level_theme.dart';

/// Alternative flip-card widget for the non-swipe flashcard variant.
///
/// Uses [AnimatedSwitcher] with a perspective-correct Y-rotation transition.
/// All card-face content has been extracted to [FlashcardCardSide] so that
/// each face can be developed, tested, and golden-tested independently.
class FlashcardView extends StatelessWidget {
  final bool isFlipped;
  final bool showHint;
  final VocabularyQuest quest;
  final String definition;
  final VocabLevelTheme theme;
  final bool isDark;
  final int hintCount;
  final VoidCallback onFlip;
  final VoidCallback onHintToggle;

  const FlashcardView({
    super.key,
    required this.isFlipped,
    required this.showHint,
    required this.quest,
    required this.definition,
    required this.theme,
    required this.isDark,
    required this.hintCount,
    required this.onFlip,
    required this.onHintToggle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth * 0.88).clamp(220.0, 520.0);
        final cardHeight = (constraints.maxHeight * 0.58).clamp(240.0, 560.0);

        return Center(
          child: GestureDetector(
            onTap: onFlip,
            child: Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32.r),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: -10,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [...previousChildren, ?currentChild],
                  );
                },
                transitionBuilder: (child, animation) {
                  final rotate = Tween<double>(begin: math.pi, end: 0.0)
                      .animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOutCubic,
                        ),
                      );
                  return AnimatedBuilder(
                    animation: rotate,
                    child: child,
                    builder: (_, animatedChild) => Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateY(rotate.value),
                      alignment: Alignment.center,
                      child: animatedChild,
                    ),
                  );
                },
                child: isFlipped
                    ? FlashcardCardSide(
                        key: const ValueKey(true),
                        title: 'MEANING',
                        content: definition,
                        secondaryContent:
                            (quest.contextSentence != null &&
                                quest.contextSentence != quest.word)
                            ? quest.contextSentence
                            : null,
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        textColor: isDark ? Colors.white : Colors.black87,
                        isBackSide: true,
                        theme: theme,
                        quest: quest,
                        showHint: showHint,
                        hintCount: hintCount,
                        onHintToggle: onHintToggle,
                      )
                    : FlashcardCardSide(
                        key: const ValueKey(false),
                        title: 'VOCABULARY',
                        content: quest.word ?? 'Unknown',
                        color: theme.primaryColor,
                        textColor: Colors.white,
                        isBackSide: false,
                        theme: theme,
                        quest: quest,
                        showHint: showHint,
                        hintCount: hintCount,
                        onHintToggle: onHintToggle,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
