import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class OpinionWritingOptionCard extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isAnswered;
  final bool isCorrectOption;
  final bool isMultiSelect;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const OpinionWritingOptionCard({
    super.key,
    required this.text,
    required this.isSelected,
    required this.isAnswered,
    required this.isCorrectOption,
    required this.isMultiSelect,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    Color borderColor = isDark ? Colors.white24 : Colors.black12;
    Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    IconData iconData = isMultiSelect
        ? Icons.check_box_outline_blank
        : Icons.radio_button_unchecked;
    Color iconColor = isDark ? Colors.white38 : Colors.black38;

    if (isAnswered) {
      if (isCorrectOption) {
        bgColor = Colors.green.withValues(alpha: 0.1);
        borderColor = Colors.green;
        iconData = isMultiSelect ? Icons.check_box : Icons.check_circle;
        iconColor = Colors.green;
      } else if (isSelected && !isCorrectOption) {
        bgColor = Colors.red.withValues(alpha: 0.1);
        borderColor = Colors.red;
        iconData = Icons.cancel;
        iconColor = Colors.red;
      }
    } else if (isSelected) {
      bgColor = primaryColor.withValues(alpha: 0.05);
      borderColor = primaryColor;
      iconData = isMultiSelect ? Icons.check_box : Icons.check_circle;
      iconColor = primaryColor;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ScaleButton(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: borderColor,
              width: isSelected || (isAnswered && isCorrectOption) ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    iconData,
                    key: ValueKey(iconData),
                    color: iconColor,
                    size: 24.w,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
