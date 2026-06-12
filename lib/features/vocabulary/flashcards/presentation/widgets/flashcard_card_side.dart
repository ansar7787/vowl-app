import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/themes/vocab_level_theme.dart';

/// One face of the flip-card in [FlashcardView].
///
/// Extracted from [FlashcardView] so that it can be instantiated, tested, and
/// golden-tested in isolation.  [FlashcardView] now imports this file and
/// constructs the two [FlashcardCardSide] instances it needs.
class FlashcardCardSide extends StatelessWidget {
  final String title;
  final String content;
  final String? secondaryContent;
  final Color color;
  final Color textColor;
  final bool isBackSide;
  final VocabLevelTheme theme;
  final VocabularyQuest quest;
  final bool showHint;
  final int hintCount;
  final VoidCallback onHintToggle;

  const FlashcardCardSide({
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
                    // ── Section label ────────────────────────────────────
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

                    // ── Primary content ──────────────────────────────────
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

                    // ── Example sentence (back side only) ────────────────
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

                    // ── Control bar ──────────────────────────────────────
                    _FlashcardControlBar(
                      isBackSide: isBackSide,
                      quest: quest,
                      showHint: showHint,
                      hintCount: hintCount,
                      theme: theme,
                      onHintToggle: onHintToggle,
                    ),

                    // ── Hint panel (front side only) ─────────────────────
                    if (showHint &&
                        !isBackSide &&
                        (quest.hint?.isNotEmpty ?? false))
                      _FlashcardHintPanel(
                        hint: quest.hint!,
                        textColor: textColor,
                      ),
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

// ─── Control bar ──────────────────────────────────────────────────────────────

class _FlashcardControlBar extends StatelessWidget {
  final bool isBackSide;
  final VocabularyQuest quest;
  final bool showHint;
  final int hintCount;
  final VocabLevelTheme theme;
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
        // TTS: di.sl<TtsService>() is an O(1) singleton lookup in onTap —
        // not in build — so the cost is negligible.
        ScaleButton(
          onTap: () => di.sl<TtsService>().speak(quest.word ?? 'Vocabulary'),
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

// ─── Hint panel ───────────────────────────────────────────────────────────────

class _FlashcardHintPanel extends StatelessWidget {
  final String hint;
  final Color textColor;

  const _FlashcardHintPanel({required this.hint, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        hint,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 13.sp,
        ),
      ),
    );
  }
}
