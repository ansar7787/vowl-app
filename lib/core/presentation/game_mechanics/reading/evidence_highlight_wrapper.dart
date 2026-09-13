import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// A text passage with tappable words for evidence-based highlighting.
///
/// Renders a passage as individually tappable word spans. User must tap
/// the word/phrase that serves as "evidence" for their answer. Correct
/// highlights pulse green; wrong taps shake red.
///
/// Usage:
/// ```dart
/// EvidenceHighlightWrapper(
///   passage: 'The cat sat on the mat near the window.',
///   evidenceWords: ['mat', 'window'],
///   primaryColor: theme.primaryColor,
///   onCorrectHighlight: () => _handleEvidence(),
///   onWrongHighlight: () => _handleWrongTap(),
/// )
/// ```
class EvidenceHighlightWrapper extends StatefulWidget {
  /// The full text passage to display.
  final String passage;

  /// Words or phrases that count as correct evidence. Case-insensitive match.
  final List<String> evidenceWords;

  /// Theme accent colour.
  final Color primaryColor;

  /// Fires when the user correctly highlights all required evidence.
  final VoidCallback onCorrectHighlight;

  /// Fires on an incorrect tap (for error journal tracking).
  final VoidCallback? onWrongHighlight;

  /// How many evidence words the user needs to find. Defaults to all.
  final int? requiredHighlights;

  /// Whether to wrap in a Positioned widget (for Stack layouts).
  final bool isPositioned;

  /// Optional instruction text override.
  final String? instruction;

  /// Bonus coins label. Null hides badge.
  final int? bonusCoins;

  const EvidenceHighlightWrapper({
    super.key,
    required this.passage,
    required this.evidenceWords,
    required this.primaryColor,
    required this.onCorrectHighlight,
    this.onWrongHighlight,
    this.requiredHighlights,
    this.isPositioned = true,
    this.instruction,
    this.bonusCoins = 5,
  });

  @override
  State<EvidenceHighlightWrapper> createState() =>
      _EvidenceHighlightWrapperState();
}

class _EvidenceHighlightWrapperState extends State<EvidenceHighlightWrapper> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  late List<_HighlightWord> _words;
  final ValueNotifier<Set<int>> _highlightedIndices = ValueNotifier({});
  final ValueNotifier<int> _wrongTapIndex = ValueNotifier(-1);
  final ValueNotifier<bool> _isComplete = ValueNotifier(false);
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(
    false,
  ); // Double tap lock

  late int _targetCount;

  @override
  void initState() {
    super.initState();
    _targetCount = widget.requiredHighlights ?? widget.evidenceWords.length;
    _parsePassage();
  }

  @override
  void dispose() {
    _highlightedIndices.dispose();
    _wrongTapIndex.dispose();
    _isComplete.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }

  void _parsePassage() {
    // Split passage into words preserving original order
    final rawWords = widget.passage.split(RegExp(r'\s+'));
    _words = [];

    // Normalise evidence words for case-insensitive matching
    final normalised = widget.evidenceWords
        .map((w) => w.toLowerCase().replaceAll(RegExp('[.,!?;:"\']+'), ''))
        .toSet();

    for (int i = 0; i < rawWords.length; i++) {
      final word = rawWords[i];
      final cleanWord = word.toLowerCase().replaceAll(
        RegExp('[.,!?;:"\']+'),
        '',
      );
      final isEvidence = normalised.contains(cleanWord);
      _words.add(
        _HighlightWord(
          index: i,
          display: word,
          cleaned: cleanWord,
          isEvidence: isEvidence,
        ),
      );
    }
  }

  void _onWordTapped(int index) {
    if (_isComplete.value || _isSubmitting.value) return;
    final word = _words[index];

    if (_highlightedIndices.value.contains(index)) {
      // Already highlighted — remove
      final newSet = Set<int>.from(_highlightedIndices.value);
      newSet.remove(index);
      _highlightedIndices.value = newSet;
      return;
    }

    if (word.isEvidence) {
      // Correct evidence word
      _hapticService.success();
      _soundService.playCorrect();

      final newSet = Set<int>.from(_highlightedIndices.value);
      newSet.add(index);
      _highlightedIndices.value = newSet;
      _wrongTapIndex.value = -1;

      // Check completion
      final evidenceFound = _highlightedIndices.value
          .where((i) => _words[i].isEvidence)
          .length;
      if (evidenceFound >= _targetCount) {
        _isComplete.value = true;
        _isSubmitting.value = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) widget.onCorrectHighlight();
        });
      }
    } else {
      // Wrong tap
      _hapticService.error();
      _wrongTapIndex.value = index;

      widget.onWrongHighlight?.call();

      // Clear wrong indicator after animation
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _wrongTapIndex.value == index) {
          _wrongTapIndex.value = -1;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0C0C1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    final content =
        Material(
              type: MaterialType.transparency,
              child: ValueListenableBuilder<bool>(
                valueListenable: _isComplete,
                builder: (context, isComplete, _) {
                  return Container(
                    padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 20.h),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32.r),
                      ),
                      border: Border.all(
                        color: isComplete
                            ? Colors.greenAccent.withValues(alpha: 0.5)
                            : widget.primaryColor.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle bar
                          Container(
                            width: 48.w,
                            height: 4.h,
                            decoration: BoxDecoration(
                              color: subtitleColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // Header
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.r),
                                decoration: BoxDecoration(
                                  color: widget.primaryColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                child: Icon(
                                  Icons.highlight_alt_rounded,
                                  color: widget.primaryColor,
                                  size: 22.r,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AutoSizeText(
                                      'FIND THE EVIDENCE',
                                      maxLines: 1,
                                      minFontSize: 8,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w900,
                                        color: widget.primaryColor,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    AutoSizeText(
                                      widget.instruction ??
                                          'Tap the word(s) that prove the answer',
                                      maxLines: 2,
                                      minFontSize: 6,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w500,
                                        color: subtitleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Progress indicator
                              ValueListenableBuilder<Set<int>>(
                                valueListenable: _highlightedIndices,
                                builder: (context, highlighted, _) {
                                  final evidenceFound = highlighted
                                      .where((i) => _words[i].isEvidence)
                                      .length;

                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: evidenceFound >= _targetCount
                                          ? Colors.greenAccent.withValues(
                                              alpha: 0.15,
                                            )
                                          : widget.primaryColor.withValues(
                                              alpha: 0.1,
                                            ),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: AutoSizeText(
                                      '$evidenceFound / $_targetCount',
                                      maxLines: 1,
                                      minFontSize: 6,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w800,
                                        color: evidenceFound >= _targetCount
                                            ? Colors.greenAccent
                                            : widget.primaryColor,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),

                          // Passage with tappable words
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: widget.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            ),
                            child: ListenableBuilder(
                              listenable: Listenable.merge([
                                _highlightedIndices,
                                _wrongTapIndex,
                              ]),
                              builder: (context, _) {
                                return Wrap(
                                  spacing: 4.w,
                                  runSpacing: 6.h,
                                  children: _words.map((word) {
                                    final isHighlighted = _highlightedIndices
                                        .value
                                        .contains(word.index);
                                    final isWrongTap =
                                        _wrongTapIndex.value == word.index;
                                    final isCorrectEvidence =
                                        isHighlighted && word.isEvidence;

                                    Widget wordWidget = AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6.w,
                                        vertical: 3.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isWrongTap
                                            ? Colors.redAccent.withValues(
                                                alpha: 0.2,
                                              )
                                            : isCorrectEvidence
                                            ? Colors.greenAccent.withValues(
                                                alpha: 0.2,
                                              )
                                            : isHighlighted
                                            ? widget.primaryColor.withValues(
                                                alpha: 0.15,
                                              )
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                        border: isCorrectEvidence
                                            ? Border.all(
                                                color: Colors.greenAccent
                                                    .withValues(alpha: 0.5),
                                                width: 1.5,
                                              )
                                            : isWrongTap
                                            ? Border.all(
                                                color: Colors.redAccent
                                                    .withValues(alpha: 0.5),
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                      child: Text(
                                        word.display,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 16.sp,
                                          fontWeight: isCorrectEvidence
                                              ? FontWeight.w800
                                              : FontWeight.w500,
                                          color: isWrongTap
                                              ? Colors.redAccent
                                              : isCorrectEvidence
                                              ? Colors.greenAccent
                                              : textColor,
                                          height: 1.5,
                                        ),
                                      ),
                                    );

                                    if (isWrongTap) {
                                      wordWidget = wordWidget
                                          .animate(
                                            key: ValueKey(
                                              'shake_${word.index}',
                                            ),
                                          )
                                          .shakeX(amount: 3, duration: 300.ms);
                                    }

                                    return GestureDetector(
                                      onTap: () => _onWordTapped(word.index),
                                      child: wordWidget,
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),

                          // Completion state
                          if (isComplete)
                            Padding(
                              padding: EdgeInsets.only(top: 16.h),
                              child:
                                  Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.verified_rounded,
                                            color: Colors.greenAccent,
                                            size: 24.r,
                                          ),
                                          SizedBox(width: 8.w),
                                          AutoSizeText(
                                            'EVIDENCE FOUND! 🎯',
                                            maxLines: 1,
                                            minFontSize: 8,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.greenAccent,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      )
                                      .animate()
                                      .fadeIn(duration: 300.ms)
                                      .scale(
                                        begin: const Offset(0.8, 0.8),
                                        end: const Offset(1, 1),
                                        duration: 400.ms,
                                        curve: Curves.easeOutBack,
                                      ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
            .animate()
            .slideY(begin: 1.0, end: 0, duration: 400.ms, curve: Curves.easeOut)
            .fadeIn(duration: 300.ms);

    if (widget.isPositioned) {
      return Positioned(bottom: 0, left: 0, right: 0, child: content);
    }

    return content;
  }
}

class _HighlightWord {
  final int index;
  final String display;
  final String cleaned;
  final bool isEvidence;

  const _HighlightWord({
    required this.index,
    required this.display,
    required this.cleaned,
    required this.isEvidence,
  });
}
