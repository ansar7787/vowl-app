import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class ReadingHighlightablePassage extends StatefulWidget {
  final String passage;
  final String correctAnswer;
  final Color primaryColor;
  final bool isDark;
  final bool isAnswered;
  final Function(bool isCorrect, String selectedSentence) onSentenceSelected;

  const ReadingHighlightablePassage({
    super.key,
    required this.passage,
    required this.correctAnswer,
    required this.primaryColor,
    required this.isDark,
    required this.isAnswered,
    required this.onSentenceSelected,
  });

  @override
  State<ReadingHighlightablePassage> createState() =>
      _ReadingHighlightablePassageState();
}

class _ReadingHighlightablePassageState
    extends State<ReadingHighlightablePassage> {
  final _hapticService = di.sl<HapticService>();
  List<String> _sentences = [];
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _splitSentences();
  }

  @override
  void didUpdateWidget(ReadingHighlightablePassage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.passage != widget.passage) {
      _splitSentences();
      _selectedIndex = null;
    }
    if (!widget.isAnswered && oldWidget.isAnswered) {
      _selectedIndex = null;
    }
  }

  void _splitSentences() {
    // Basic sentence splitting by punctuation followed by space
    final rawSentences = widget.passage.split(RegExp(r'(?<=[.!?])\s+'));
    _sentences = rawSentences.where((s) => s.trim().isNotEmpty).toList();
  }

  void _onSentenceTap(int index) {
    if (widget.isAnswered) return;

    _hapticService.selection();
    setState(() {
      _selectedIndex = index;
    });

    final selected = _sentences[index];
    // Check if the selected sentence contains the correct answer or matches it
    // Usually the correct answer in these games is the specific sentence
    final isCorrect = selected.trim().toLowerCase().contains(widget.correctAnswer.trim().toLowerCase()) ||
        widget.correctAnswer.trim().toLowerCase().contains(selected.trim().toLowerCase());

    widget.onSentenceSelected(isCorrect, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
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
                  'TAP THE SENTENCE THAT CONTAINS THE ANSWER',
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
          SizedBox(height: 16.h),
          Wrap(
            spacing: 4.w,
            runSpacing: 4.h,
            children: List.generate(_sentences.length, (index) {
              final isSelected = _selectedIndex == index;
              final sentence = _sentences[index];

              return GestureDetector(
                onTap: () => _onSentenceTap(index),
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
                    sentence,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 17.sp,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? widget.primaryColor
                          : (widget.isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B)),
                      height: 1.65,
                      letterSpacing: 0.2,
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
