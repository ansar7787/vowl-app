import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class JobInterviewResponseConsole extends StatelessWidget {
  final List<String> options;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final int? selectedIndex;
  final bool isAnswered;
  final bool? isCorrect;
  final Function(int, int) onOptionSelected;

  const JobInterviewResponseConsole({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.selectedIndex,
    required this.isAnswered,
    required this.isCorrect,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(
        options.length,
        (i) => _buildResponseStone(i, options[i]),
      ),
    );
  }

  Widget _buildResponseStone(int index, String text) {
    final bool isSelected = selectedIndex == index;

    Color stoneColor = color;
    if (isAnswered) {
      if (isSelected) {
        stoneColor = (isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
      } else if (index == correctIndex) {
        stoneColor = Colors.greenAccent; // Highlight correct answer if incorrect chosen
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ScaleButton(
        onTap: () => onOptionSelected(index, correctIndex),
        child: Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: isSelected
                ? stoneColor
                : (isDark ? const Color(0xFF0F0F1B) : Colors.white),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: isSelected
                  ? Colors.white
                  : (isAnswered && index == correctIndex)
                      ? Colors.greenAccent
                      : color.withValues(alpha: 0.35),
              width: (isSelected || (isAnswered && index == correctIndex)) ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? stoneColor : color).withValues(alpha: isSelected ? 0.35 : 0.06),
                blurRadius: isSelected ? 12 : 6,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected
                      ? ((isCorrect ?? false) ? Icons.verified_rounded : Icons.cancel_rounded)
                      : Icons.diamond_rounded,
                  color: isSelected ? Colors.white : color,
                  size: 16.r,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (isAnswered && index == correctIndex)
                            ? (isDark ? Colors.greenAccent : Colors.green)
                            : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(
      target: isSelected ? 1.0 : 0.0,
    ).scale(
      begin: const Offset(1, 1),
      end: const Offset(1.02, 1.02),
      duration: 150.ms,
    );
  }
}
