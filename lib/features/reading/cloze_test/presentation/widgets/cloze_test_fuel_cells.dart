import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ClozeTestFuelCells extends StatelessWidget {
  final List<String> options;
  final Color color;
  final bool isDark;
  final String? dockedOption;

  const ClozeTestFuelCells({
    super.key,
    required this.options,
    required this.color,
    required this.isDark,
    required this.dockedOption,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      alignment: WrapAlignment.center,
      children: options.map((o) {
        final bool isAlreadyDocked = dockedOption == o;
        return Opacity(
          opacity: isAlreadyDocked ? 0.35 : 1.0,
          child: IgnorePointer(
            ignoring: isAlreadyDocked,
            child: Draggable<String>(
              data: o,
              feedback: Material(
                color: Colors.transparent,
                child: _buildCellWidget(o, color, isDark, true),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildCellWidget(o, color, isDark, false),
              ),
              child: _buildCellWidget(o, color, isDark, false),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCellWidget(
    String text,
    Color color,
    bool isDark,
    bool isFeedback,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.black87 : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: isFeedback ? 20 : 10,
          ),
          if (isFeedback)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.25),
              blurRadius: 40,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 16.r, color: color),
          SizedBox(width: 8.w),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
