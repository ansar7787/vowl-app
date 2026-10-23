import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Word vault grid displaying available grammatical replacements for sentence correction.
class CorrectionWritingVault extends StatelessWidget {
  /// Available correction choice strings.
  final List<String> options;

  /// Currently selected correction option, if any.
  final String? selectedCorrection;

  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Callback when a correction chip is tapped.
  final Function(String) onSelectCorrection;

  /// Creates a [CorrectionWritingVault] options layout.
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
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            color: isDark
                ? Colors.white.withValues(alpha: 0.75)
                : Colors.black87.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 16.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          alignment: WrapAlignment.center,
          children: options.map((opt) {
            final bool isSelected = selectedCorrection == opt;

            return Semantics(
              button: true,
              selected: isSelected,
              label: 'Option: $opt',
              child: GestureDetector(
                key: Key('correction_vault_chip_$opt'),
                onTap: () => onSelectCorrection(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: 22.w,
                    vertical: 13.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.12)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.14)
                              : Colors.black.withValues(alpha: 0.12)),
                      width: isSelected ? 2.0 : 1.2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: color.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      else if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Text(
                    opt,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isSelected
                          ? color
                          : (isDark ? Colors.white : Colors.black87),
                      fontSize: 16.sp,
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

