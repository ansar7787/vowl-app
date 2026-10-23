import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class _LocalPalette {
  _LocalPalette._();
  static const Color color34d399 = Color(0xFF34D399);
  static const Color colorf87171 = Color(0xFFF87171);
}

class _PassageToken {
  final String raw;
  final String prefix;
  final String word;
  final String suffix;

  _PassageToken({
    required this.raw,
    required this.prefix,
    required this.word,
    required this.suffix,
  });
}

/// Interactive passage splitting text into selectable word tokens with highlight feedback.
class FindWordMeaningInteractivePassage extends StatefulWidget {
  /// The full text of the reading passage.
  final String passage;

  /// The authoritative target word representing the definition.
  final String targetWord;

  /// Theme accent color applied to selections and borders.
  final Color primaryColor;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Whether the answer has been evaluated.
  final bool isAnswered;

  /// Index of the currently selected word token, or null if none is selected.
  final int? selectedIndex;

  /// Whether the current selection is correct, or null if unverified.
  final bool? isCorrectSelection;

  /// Callback invoked when a word token is tapped.
  final Function(bool isCorrect, String selectedWord, int index) onWordSelected;

  /// Creates a [FindWordMeaningInteractivePassage] widget.
  const FindWordMeaningInteractivePassage({
    super.key,
    required this.passage,
    required this.targetWord,
    required this.primaryColor,
    required this.isDark,
    required this.isAnswered,
    required this.selectedIndex,
    required this.isCorrectSelection,
    required this.onWordSelected,
  });

  @override
  State<FindWordMeaningInteractivePassage> createState() =>
      _FindWordMeaningInteractivePassageState();
}

class _FindWordMeaningInteractivePassageState
    extends State<FindWordMeaningInteractivePassage> {
  final _hapticService = di.sl<HapticService>();
  List<_PassageToken> _tokens = [];

  static final _prefixRegex = RegExp(r'^([^\p{L}\p{N}]+)', unicode: true);
  static final _suffixRegex = RegExp(r'([^\p{L}\p{N}]+)$', unicode: true);
  static final _cleanRegex = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);

  @override
  void initState() {
    super.initState();
    _splitWords();
  }

  @override
  void didUpdateWidget(FindWordMeaningInteractivePassage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.passage != widget.passage) {
      _splitWords();
    }
  }

  void _splitWords() {
    final rawWords = widget.passage
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();

    _tokens = rawWords.map((rawWord) {
      String prefix = '';
      String suffix = '';
      String word = rawWord;

      final prefixMatch = _prefixRegex.firstMatch(word);
      if (prefixMatch != null) {
        prefix = prefixMatch.group(1)!;
        word = word.substring(prefix.length);
      }

      final suffixMatch = _suffixRegex.firstMatch(word);
      if (suffixMatch != null) {
        suffix = suffixMatch.group(1)!;
        word = word.substring(0, word.length - suffix.length);
      }

      return _PassageToken(
        raw: rawWord,
        prefix: prefix,
        word: word,
        suffix: suffix,
      );
    }).toList();
  }

  void _onWordTap(int index) {
    if (widget.isAnswered) return;

    _hapticService.selection();

    final token = _tokens[index];

    // Clean punctuation for comparison using unicode-aware regex
    final cleanSelected = token.word
        .replaceAll(_cleanRegex, '')
        .trim()
        .toLowerCase();
    final cleanTarget = widget.targetWord
        .replaceAll(_cleanRegex, '')
        .trim()
        .toLowerCase();

    final isCorrect = cleanSelected == cleanTarget;

    widget.onWordSelected(isCorrect, cleanSelected, index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : widget.primaryColor.withValues(alpha: 0.16),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isDark
                ? Colors.black.withValues(alpha: 0.2)
                : widget.primaryColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.touch_app_rounded,
                color: widget.primaryColor,
                size: 18.r,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Tap the word that matches the definition:',
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: widget.primaryColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 5.w,
            runSpacing: 8.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: List.generate(_tokens.length, (index) {
              final token = _tokens[index];
              final isSelected = widget.selectedIndex == index;

              Color activeColor = widget.primaryColor;
              if (isSelected && widget.isCorrectSelection != null) {
                activeColor = widget.isCorrectSelection!
                    ? (widget.isDark
                          ? _LocalPalette.color34d399
                          : AppColors.emerald500)
                    : (widget.isDark
                          ? _LocalPalette.colorf87171
                          : AppColors.red500);
              }

              final baseTextStyle = TextStyle(
                fontFamily: 'Outfit',
                fontSize: 17.5.sp,
                fontWeight: FontWeight.w500,
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.92)
                    : AppColors.slate800,
                height: 1.45,
              );

              if (token.word.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 3.5.h),
                  child: Text(
                    token.prefix + token.suffix,
                    style: baseTextStyle,
                  ),
                );
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (token.prefix.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 3.5.h),
                      child: Text(token.prefix, style: baseTextStyle),
                    ),
                  GestureDetector(
                    onTap: () => _onWordTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 3.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor.withValues(alpha: 0.18)
                            : (widget.isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : widget.primaryColor.withValues(alpha: 0.04)),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isSelected ? activeColor : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        token.word,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 17.5.sp,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? activeColor
                              : (widget.isDark
                                    ? Colors.white.withValues(alpha: 0.92)
                                    : AppColors.slate800),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                  if (token.suffix.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 3.5.h),
                      child: Text(token.suffix, style: baseTextStyle),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
