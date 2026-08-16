import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  const AcademicWordThesisPaper({
    super.key,
    required this.passage,
    required this.color,
    required this.slotKey,
    required this.isAnswered,
    required this.isCorrect,
    required this.correctAnswer,
    this.userSpelledWord,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cardWidth = constraints.maxWidth > 0
              ? (330.w).clamp(0.0, constraints.maxWidth - 32.w)
              : 330.w;
          final cardPadding = (cardWidth * 0.082).clamp(12.0, 28.0);
          final slotWidth = ((cardWidth - cardPadding * 2) * 0.55).clamp(
            90.0,
            150.w,
          );
          final slotHeight = (40.h).clamp(32.0, 44.0);

          return Container(
                width: cardWidth,
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight > 0
                      ? constraints.maxHeight * 0.65
                      : double.infinity,
                ),
                padding: EdgeInsets.all(cardPadding),
                decoration: _cardDecoration(isDark),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: _ThesisPaperContent(
                    passage: passage,
                    color: color,
                    slotKey: slotKey,
                    isAnswered: isAnswered,
                    isCorrect: isCorrect,
                    correctAnswer: correctAnswer,
                    userSpelledWord: userSpelledWord,
                    isDark: isDark,
                    slotWidth: slotWidth,
                    slotHeight: slotHeight,
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 1.seconds)
              .slideY(begin: -0.05, end: 0, curve: Curves.easeOutCubic);
        },
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AcademicWordColors.cardDark : Colors.white,
      borderRadius: BorderRadius.circular(4.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
          blurRadius: 30,
          offset: const Offset(0, 15),
        ),
        BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 50),
      ],
      border: Border.all(
        color: isDark
            ? color.withValues(alpha: 0.3)
            : color.withValues(alpha: 0.1),
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
    fontSize: 19,
    height: 1.6,
    color: textColor,
  );

  static TextStyle _answerStyle(Color color) => TextStyle(
    fontFamily: 'Outfit',
    color: color,
    fontWeight: FontWeight.bold,
    fontSize: 15,
  );

  @override
  Widget build(BuildContext context) {
    final passageTextColor = widget.isDark ? Colors.white70 : Colors.black87;
    final pendingColor = widget.color.withValues(alpha: 0.3);
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
    required this.answerStyle,
    required this.pendingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: slotKey,
      width: width,
      height: height,
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: underlineColor, width: 2.5)),
      ),
      child: Center(
        child: (isAnswered && isCorrect == true) || (isAnswered && isCorrect == false && userSpelledWord != null)
            ? Text(
                (isCorrect == true ? correctAnswer : userSpelledWord)?.toUpperCase() ?? '',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: isCorrect == true ? answerStyle : answerStyle.copyWith(color: AcademicWordColors.slotError),
              ).animate().fadeIn().scale()
            : Text(
                AcademicWordStrings.slotPending,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: pendingColor,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(),
      ),
    );
  }
}
