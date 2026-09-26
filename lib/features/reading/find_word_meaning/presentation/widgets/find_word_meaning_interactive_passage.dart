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

class FindWordMeaningInteractivePassage extends StatefulWidget {
  final String passage;
  final String targetWord;
  final Color primaryColor;
  final bool isDark;
  final bool isAnswered;
  final int? selectedIndex;
  final bool? isCorrectSelection;
  final Function(bool isCorrect, String selectedWord, int index) onWordSelected;

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
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.1)
              : widget.primaryColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.05),
            blurRadius: 10,
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
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Tap the matching word below:',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: widget.primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 8.h,
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
                fontSize: 18.sp,
                fontWeight: FontWeight.w400,
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.slate800,
                height: 1.4,
              );

              if (token.word.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
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
                    Text(token.prefix, style: baseTextStyle),
                  GestureDetector(
                    onTap: () => _onWordTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: isSelected ? activeColor : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        token.word,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18.sp,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? activeColor
                              : (widget.isDark
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : AppColors.slate800),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  if (token.suffix.isNotEmpty)
                    Text(token.suffix, style: baseTextStyle),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
