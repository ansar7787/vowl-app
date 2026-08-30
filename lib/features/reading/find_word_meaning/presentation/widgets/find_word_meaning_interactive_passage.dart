import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class FindWordMeaningInteractivePassage extends StatefulWidget {
  final String passage;
  final String targetWord;
  final Color primaryColor;
  final bool isDark;
  final bool isAnswered;
  final int? selectedIndex;
  final Function(bool isCorrect, String selectedWord, int index) onWordSelected;

  const FindWordMeaningInteractivePassage({
    super.key,
    required this.passage,
    required this.targetWord,
    required this.primaryColor,
    required this.isDark,
    required this.isAnswered,
    required this.selectedIndex,
    required this.onWordSelected,
  });

  @override
  State<FindWordMeaningInteractivePassage> createState() =>
      _FindWordMeaningInteractivePassageState();
}

class _FindWordMeaningInteractivePassageState
    extends State<FindWordMeaningInteractivePassage> {
  final _hapticService = di.sl<HapticService>();
  List<String> _words = [];

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
    // Split by space, keeping punctuation with the words, or we can just split by space
    // Using RegExp to split by whitespace
    _words = widget.passage.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  }

  void _onWordTap(int index) {
    if (widget.isAnswered) return;

    _hapticService.selection();

    final selected = _words[index];
    // Clean punctuation for comparison
    final cleanSelected = selected.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
    final cleanTarget = widget.targetWord.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();

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
              Icon(Icons.touch_app_rounded, color: widget.primaryColor, size: 24.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'TAP THE WORD THAT MATCHES THE MEANING',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: widget.primaryColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 10.h,
            children: List.generate(_words.length, (index) {
              final isSelected = widget.selectedIndex == index;
              final word = _words[index];

              return GestureDetector(
                onTap: () => _onWordTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.primaryColor.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: isSelected
                          ? widget.primaryColor
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    word,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? widget.primaryColor
                          : (widget.isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B)),
                      height: 1.4,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
