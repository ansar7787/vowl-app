import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class GuessTitleOptions extends StatefulWidget {
  final List<String> options;
  final String correctAnswer;
  final Color primaryColor;
  final bool isDark;
  final bool isAnswered;
  final Function(bool isCorrect, String selectedOption) onOptionSelected;

  const GuessTitleOptions({
    super.key,
    required this.options,
    required this.correctAnswer,
    required this.primaryColor,
    required this.isDark,
    required this.isAnswered,
    required this.onOptionSelected,
  });

  @override
  State<GuessTitleOptions> createState() => _GuessTitleOptionsState();
}

class _GuessTitleOptionsState extends State<GuessTitleOptions> {
  final _hapticService = di.sl<HapticService>();
  int? _selectedIndex;

  @override
  void didUpdateWidget(GuessTitleOptions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isAnswered && oldWidget.isAnswered) {
      _selectedIndex = null;
    }
  }

  void _onOptionTap(int index) {
    if (widget.isAnswered) return;

    _hapticService.selection();
    setState(() {
      _selectedIndex = index;
    });

    final selected = widget.options[index];
    final isCorrect = selected.trim().toLowerCase() == widget.correctAnswer.trim().toLowerCase();

    widget.onOptionSelected(isCorrect, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.options.length, (index) {
        final isSelected = _selectedIndex == index;
        final option = widget.options[index];

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: GestureDetector(
            onTap: () => _onOptionTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? widget.primaryColor.withValues(alpha: 0.2)
                    : (widget.isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03)),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isSelected
                      ? widget.primaryColor
                      : (widget.isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05)),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? widget.primaryColor
                            : (widget.isDark
                                ? Colors.white30
                                : Colors.black26),
                        width: 2,
                      ),
                      color: isSelected ? widget.primaryColor : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, size: 16.sp, color: Colors.white)
                        : null,
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? widget.primaryColor
                            : (widget.isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
