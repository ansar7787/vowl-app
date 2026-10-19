import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/vocabulary/academic_word/academic_word_constants.dart';

/// The thesis paper card displaying the fill-in-the-blank passage.
class AcademicWordThesisPaper extends StatelessWidget {
  final String passage;
  final Color color;
  final GlobalKey slotKey;
  final bool isAnswered;
  final bool? isCorrect;
  final String? correctAnswer;
  final String? userSpelledWord;
  final bool isSlotSelected;
  final VoidCallback onSlotTap;

  const AcademicWordThesisPaper({
    super.key,
    required this.passage,
    required this.color,
    required this.slotKey,
    required this.isAnswered,
    required this.isCorrect,
    required this.correctAnswer,
    this.userSpelledWord,
    required this.isSlotSelected,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxAllowedWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : (MediaQuery.of(context).size.width - 40.w);
          final cardWidth = maxAllowedWidth.clamp(0.0, 420.0);
          final slotWidth = ((cardWidth - 40.w) * 0.50).clamp(100.0, 160.w);
          final slotHeight = (38.h).clamp(32.0, 44.0);

          final paper = Container(
            key: const Key('academic_word_thesis_paper'),
            width: cardWidth,
            constraints: BoxConstraints(
              maxHeight: constraints.maxHeight.isFinite && constraints.maxHeight > 0
                  ? constraints.maxHeight * 0.75
                  : double.infinity,
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            decoration: _cardDecoration(isDark),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _ThesisPaperContent(
                passage: passage,
                color: color,
                slotKey: slotKey,
                isAnswered: isAnswered,
                isCorrect: isCorrect,
                correctAnswer: correctAnswer,
                userSpelledWord: userSpelledWord,
                isSlotSelected: isSlotSelected,
                onSlotTap: onSlotTap,
                isDark: isDark,
                slotWidth: slotWidth,
                slotHeight: slotHeight,
              ),
            ),
          );

          if (VowlMotion.lowAnimationModeOverride.value) {
            return paper;
          }

          return paper
              .animate()
              .fadeIn(duration: 800.ms)
              .slideY(begin: -0.05, end: 0, curve: Curves.easeOutCubic);
        },
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AcademicWordColors.cardDark : Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: color.withValues(alpha: isDark ? 0.08 : 0.05),
          blurRadius: 36,
        ),
      ],
      border: Border.all(
        color: isDark
            ? color.withValues(alpha: 0.25)
            : color.withValues(alpha: 0.15),
        width: 1.5,
      ),
    );
  }
}

// ── Private StatefulWidget: owns passage split cache ─────────────────────────
// passage.split() is O(n) — cached here so it only runs when passage changes,
// not on every drag-gesture rebuild (60 fps).
class _ThesisPaperContent extends StatefulWidget {
  final String passage;
  final Color color;
  final GlobalKey slotKey;
  final bool isAnswered;
  final bool? isCorrect;
  final String? correctAnswer;
  final String? userSpelledWord;
  final bool isSlotSelected;
  final VoidCallback onSlotTap;
  final bool isDark;
  final double slotWidth;
  final double slotHeight;

  const _ThesisPaperContent({
    required this.passage,
    required this.color,
    required this.slotKey,
    required this.isAnswered,
    required this.isCorrect,
    required this.correctAnswer,
    required this.userSpelledWord,
    required this.isSlotSelected,
    required this.onSlotTap,
    required this.isDark,
    required this.slotWidth,
    required this.slotHeight,
  });

  @override
  State<_ThesisPaperContent> createState() => _ThesisPaperContentState();
}

class _ThesisPaperContentState extends State<_ThesisPaperContent> {
  late List<String> _parts;

  @override
  void initState() {
    super.initState();
    _parts = _splitPassage(widget.passage);
  }

  @override
  void didUpdateWidget(covariant _ThesisPaperContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.passage != widget.passage) {
      _parts = _splitPassage(widget.passage);
    }
  }

  static List<String> _splitPassage(String passage) {
    final parts = passage.split('[TARGET]');
    assert(
      parts.length <= 2,
      'AcademicWordThesisPaper: passage has more than one [TARGET] marker.\n'
      'Passage: "$passage"',
    );
    return parts.length >= 2 ? parts : [passage, ''];
  }

  static TextStyle _passageStyle(Color textColor) => TextStyle(
    fontFamily: 'Spectral',
    fontSize: 16.5.sp,
    fontWeight: FontWeight.w500,
    height: 1.55,
    color: textColor,
  );

  static TextStyle _answerStyle(Color color) => TextStyle(
    fontFamily: 'Outfit',
    color: color,
    fontWeight: FontWeight.w700,
    fontSize: 15.sp,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    final passageTextColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.92)
        : Colors.black87;
    final pendingColor = widget.color.withValues(alpha: 0.6);
    final slotUnderlineColor = widget.isAnswered && widget.isCorrect == false
        ? AcademicWordColors.slotError
        : widget.color;

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: _passageStyle(passageTextColor),
        children: [
          TextSpan(text: _parts[0]),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _AnswerSlot(
              slotKey: widget.slotKey,
              color: widget.color,
              width: widget.slotWidth,
              height: widget.slotHeight,
              underlineColor: slotUnderlineColor,
              isAnswered: widget.isAnswered,
              isCorrect: widget.isCorrect,
              correctAnswer: widget.correctAnswer,
              userSpelledWord: widget.userSpelledWord,
              isSlotSelected: widget.isSlotSelected,
              onSlotTap: widget.onSlotTap,
              answerStyle: _answerStyle(widget.color),
              pendingColor: pendingColor,
            ),
          ),
          if (_parts[1].isNotEmpty) TextSpan(text: _parts[1]),
        ],
      ),
    );
  }
}

// ── Extracted fill-in slot widget ─────────────────────────────────────────────
class _AnswerSlot extends StatelessWidget {
  final GlobalKey slotKey;
  final Color color;
  final double width;
  final double height;
  final Color underlineColor;
  final bool isAnswered;
  final bool? isCorrect;
  final String? correctAnswer;
  final String? userSpelledWord;
  final bool isSlotSelected;
  final VoidCallback onSlotTap;
  final TextStyle answerStyle;
  final Color pendingColor;

  const _AnswerSlot({
    required this.slotKey,
    required this.color,
    required this.width,
    required this.height,
    required this.underlineColor,
    required this.isAnswered,
    required this.isCorrect,
    required this.correctAnswer,
    required this.userSpelledWord,
    required this.isSlotSelected,
    required this.onSlotTap,
    required this.answerStyle,
    required this.pendingColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isSlotSelected
        ? color.withValues(alpha: 0.16)
        : color.withValues(alpha: 0.06);
    final borderColor = isSlotSelected ? color : underlineColor;

    return Semantics(
      button: true,
      label: isAnswered
          ? (isCorrect == true
              ? 'Answer: $correctAnswer'
              : 'Incorrect: $userSpelledWord')
          : (isSlotSelected ? 'Slot selected' : 'Slot pending'),
      child: GestureDetector(
        key: const Key('academic_word_slot_detector'),
        onTap: onSlotTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          key: slotKey,
          width: width,
          height: height,
          margin: EdgeInsets.symmetric(horizontal: 6.w),
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSlotSelected ? color : borderColor.withValues(alpha: 0.6),
              width: isSlotSelected ? 2.0 : 1.5,
            ),
          ),
          child: Center(
            child:
                (isAnswered && isCorrect == true) ||
                    (isAnswered && isCorrect == false && userSpelledWord != null)
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: VowlMotion.lowAnimationModeOverride.value
                        ? Text(
                            (isCorrect == true ? correctAnswer : userSpelledWord)
                                    ?.toUpperCase() ??
                                '',
                            key: const Key('academic_word_slot_answered_text'),
                            style: isCorrect == true
                                ? answerStyle
                                : answerStyle.copyWith(
                                    color: AcademicWordColors.slotError,
                                  ),
                          )
                        : Text(
                            (isCorrect == true ? correctAnswer : userSpelledWord)
                                    ?.toUpperCase() ??
                                '',
                            key: const Key('academic_word_slot_answered_text'),
                            style: isCorrect == true
                                ? answerStyle
                                : answerStyle.copyWith(
                                    color: AcademicWordColors.slotError,
                                  ),
                          ).animate().fadeIn().scale(),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: VowlMotion.lowAnimationModeOverride.value
                        ? Text(
                            AcademicWordStrings.slotPending,
                            key: const Key('academic_word_slot_pending_text'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: isSlotSelected ? color : pendingColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          )
                        : Text(
                            AcademicWordStrings.slotPending,
                            key: const Key('academic_word_slot_pending_text'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: isSlotSelected ? color : pendingColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          )
                            .animate(
                              onPlay: (c) => c.repeat(),
                            )
                            .shimmer(duration: 2.seconds),
                  ),
          ),
        ),
      ),
    );
  }
}
