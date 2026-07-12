import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AudioTrueFalsePolarizedFilters extends StatelessWidget {
  final double tuningValue;
  final bool isAnswered;
  final bool? isCorrectState;
  final Color color;
  final Function(double) onChanged;
  final Function(double) onChangeEnd;

  const AudioTrueFalsePolarizedFilters({
    super.key,
    required this.tuningValue,
    required this.isAnswered,
    required this.isCorrectState,
    required this.color,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFilterZone(
              "FALSE",
              Colors.redAccent,
              tuningValue < 0.2,
              false,
            ),
            _buildFilterZone(
              "TRUE",
              Colors.greenAccent,
              tuningValue > 0.8,
              true,
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Slider(
          value: tuningValue,
          onChanged: isAnswered ? null : onChanged,
          onChangeEnd: onChangeEnd,
          activeColor: color,
          inactiveColor: color.withValues(alpha: 0.2),
        ),
      ],
    );
  }

  Widget _buildFilterZone(
    String label,
    Color filterColor,
    bool isActive,
    bool isTrueZone,
  ) {
    bool isSelected =
        isAnswered &&
        ((isTrueZone && tuningValue > 0.8) ||
            (!isTrueZone && tuningValue < 0.2));
    bool isCorrect = isAnswered && isSelected && isCorrectState == true;
    bool isWrong = isAnswered && isSelected && isCorrectState == false;

    Color zoneColor = isCorrect
        ? Colors.greenAccent
        : (isWrong
              ? Colors.redAccent
              : (isActive ? filterColor : filterColor.withValues(alpha: 0.2)));

    return Container(
      width: 120.w,
      height: 60.h,
      decoration: BoxDecoration(
        color: zoneColor.withValues(alpha: isActive || isAnswered ? 0.3 : 0.05),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: zoneColor, width: 2),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
            color: zoneColor,
          ),
        ),
      ),
    );
  }
}
