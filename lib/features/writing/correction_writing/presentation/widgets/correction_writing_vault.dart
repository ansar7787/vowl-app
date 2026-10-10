import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

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
          context.tr(
            'games.correctionWriting.select_word',
            fallback: "Select the correct word",
          ),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.sp,
            color: isDark ? Colors.white54 : Colors.black54,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 16.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          alignment: WrapAlignment.center,
          children: options.map((opt) {
            final bool isSelected = selectedCorrection == opt;
            final displayColor = isSelected
                ? color
                : (isDark ? Colors.white24 : Colors.black26);

            return Semantics(
              button: true,
              selected: isSelected,
              label: 'Option: $opt',
              child: GestureDetector(
                onTap: () => onSelectCorrection(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : (isDark ? Colors.black45 : Colors.white),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: displayColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(
                          alpha: isSelected ? 0.35 : 0.08,
                        ),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isSelected
                          ? color
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
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
