import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class CorrectionWritingVault extends StatelessWidget {
  final List<String> options;
  final String? selectedCorrection;
  final Color color;
  final bool isDark;
  final Function(String) onSelectCorrection;

  const CorrectionWritingVault({
    super.key,
    required this.options,
    required this.selectedCorrection,
    required this.color,
    required this.isDark,
    required this.onSelectCorrection,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "AVAILABLE SYNTACTIC CORRECTIONS",
          style: TextStyle(fontFamily: 'RobotoMono', 
            fontSize: 10.sp, 
            color: isDark ? Colors.white54 : Colors.black54, 
            fontWeight: FontWeight.bold
          )
        ),
        SizedBox(height: 16.h),
        Wrap(
          spacing: 12.w, 
          runSpacing: 12.h,
          alignment: WrapAlignment.center,
          children: options.map((opt) {
            final bool isSelected = selectedCorrection == opt;
            final displayColor = isSelected ? color : (isDark ? Colors.white24 : Colors.black26);

            return GestureDetector(
              onTap: () => onSelectCorrection(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : (isDark ? Colors.black45 : Colors.white),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: displayColor, width: 2),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: isSelected ? 0.35 : 0.08), blurRadius: 8)
                  ],
                ),
                child: Text(
                  opt,
                  style: TextStyle(fontFamily: 'RobotoMono', 
                    color: isSelected ? color : (isDark ? Colors.white70 : Colors.black87),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
