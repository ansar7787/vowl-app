import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

class FlashcardView extends StatelessWidget {
  final bool isFlipped;
  final bool showHint;
  final VocabularyQuest quest;
  final String definition;
  final ThemeResult theme;
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
                    builder: (context, animatedChild) {
                      final matrix = Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateY(rotate.value);

                      return Transform(
                        transform: matrix,
                        alignment: Alignment.center,
                        child: animatedChild,
                      );
                    },
                  );
                },
                child: isFlipped
                    ? _FlashcardCardSide(
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
                    : _FlashcardCardSide(
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

class _FlashcardCardSide extends StatelessWidget {
  final String title;
  final String content;
  final String? secondaryContent;
  final Color color;
  final Color textColor;
  final bool isBackSide;
  final ThemeResult theme;
  final VocabularyQuest quest;
  final bool showHint;
  final int hintCount;
  final VoidCallback onHintToggle;

  const _FlashcardCardSide({
    super.key,
    required this.title,
    required this.content,
    this.secondaryContent,
    required this.color,
    required this.textColor,
    required this.isBackSide,
    required this.theme,
    required this.quest,
    required this.showHint,
    required this.hintCount,
    required this.onHintToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      key: key,
      color: color,
      borderRadius: BorderRadius.circular(32.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.r),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxHeight < 320 || constraints.maxWidth < 280;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        color: textColor.withValues(alpha: 0.5),
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: compact ? 16.h : 24.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        content,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: isBackSide
                              ? (compact ? 20.sp : 24.sp)
                              : (compact ? 34.sp : 42.sp),
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          height: 1.1,
                        ),
                      ),
                    ),
                    if (isBackSide && secondaryContent?.isNotEmpty == true) ...[
                      SizedBox(height: 20.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: textColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'EXAMPLE',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                color: textColor.withValues(alpha: 0.4),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              secondaryContent!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: textColor.withValues(alpha: 0.8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: compact ? 16.h : 24.h),
                    _FlashcardControlBar(
                      isBackSide: isBackSide,
                      quest: quest,
                      showHint: showHint,
                      hintCount: hintCount,
                      theme: theme,
                      onHintToggle: onHintToggle,
                    ),
                    if (showHint &&
                        !isBackSide &&
                        (quest.hint?.isNotEmpty ?? false))
                      _FlashcardHintPanel(hint: quest.hint!),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FlashcardControlBar extends StatelessWidget {
  final bool isBackSide;
  final VocabularyQuest quest;
  final bool showHint;
  final int hintCount;
  final ThemeResult theme;
  final VoidCallback onHintToggle;

  const _FlashcardControlBar({
    required this.isBackSide,
    required this.quest,
    required this.showHint,
    required this.hintCount,
    required this.theme,
    required this.onHintToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16.w,
      runSpacing: 12.h,
      children: [
        if (!isBackSide && (quest.hint?.isNotEmpty ?? false))
          ScaleButton(
            onTap: onHintToggle,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999.r),
                border: Border.all(color: Colors.white30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    showHint
                        ? Icons.lightbulb_rounded
                        : Icons.lightbulb_outline_rounded,
                    color: Colors.white,
                    size: 20.r,
                  ),
                  if (!showHint) ...[
                    SizedBox(width: 4.w),
                    Text(
                      '$hintCount',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ScaleButton(
          onTap: () {
            di.sl<TtsService>().speak(quest.word ?? 'Vocabulary');
          },
          child: Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: !isBackSide
                  ? Colors.white24
                  : theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: !isBackSide
                    ? Colors.white30
                    : theme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              Icons.volume_up_rounded,
              color: !isBackSide ? Colors.white : theme.primaryColor,
              size: 24.r,
            ),
          ),
        ),
      ],
    );
  }
}

class _FlashcardHintPanel extends StatelessWidget {
  final String hint;

  const _FlashcardHintPanel({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        hint,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13.sp,
        ),
      ),
    );
  }
}
