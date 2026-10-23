import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color131326 = Color(0xFF131326);
}

/// Tray displaying potential clinical symptoms and diagnostic choices.
class MedicalConsultDiagnosticTray extends StatelessWidget {
  /// Available clinical symptoms.
  final List<String> symptoms;

  /// Primary theme accent color.
  final Color color;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Symptoms detected by the scanner.
  final List<String> scannedGlitches;

  /// Currently selected or diagnosed symptoms.
  final List<String> diagnosedSymptoms;

  /// Whether an answer has been submitted for this stage.
  final bool isAnswered;

  /// Whether the submitted diagnosis was correct.
  final bool? isCorrect;

  /// Callback fired when a symptom tile is tapped.
  final Function(String) onSymptomTapped;

  /// Creates a [MedicalConsultDiagnosticTray] widget.
  const MedicalConsultDiagnosticTray({
    super.key,
    required this.symptoms,
    required this.color,
    required this.isDark,
    required this.scannedGlitches,
    required this.diagnosedSymptoms,
    required this.isAnswered,
    required this.isCorrect,
    required this.onSymptomTapped,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Container(
      key: const Key('medical_consult_diagnostic_tray'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : color.withValues(alpha: 0.16),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : color.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.health_and_safety_rounded,
                color: color.withValues(alpha: 0.8),
                size: 16.r,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  "DIAGNOSTIC OPTIONS",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    color: color,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Symptoms grid chips
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.w,
            runSpacing: 10.h,
            children: symptoms.map((s) {
              final bool isScanned = scannedGlitches.contains(s);
              final bool isChecked = diagnosedSymptoms.contains(s);

              Color cardColor = color;
              if (isAnswered && isChecked) {
                cardColor = (isCorrect ?? false)
                    ? tokens.gameCorrect
                    : tokens.gameIncorrect;
              }

              return ScaleButton(
                onTap: () => onSymptomTapped(s),
                child: Container(
                  key: Key('medical_consult_symptom_chip_${s.replaceAll(' ', '_')}'),
                  constraints: BoxConstraints(maxWidth: 1.sw - 68.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 9.h,
                  ),
                  decoration: BoxDecoration(
                    color: isChecked
                        ? cardColor
                        : (isDark
                              ? _LocalPalette.color131326
                              : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isChecked
                          ? Colors.white
                          : isScanned
                          ? color.withValues(alpha: 0.4)
                          : color.withValues(alpha: 0.08),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isChecked ? cardColor : color).withValues(
                          alpha: isChecked ? 0.25 : 0.04,
                        ),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isChecked
                            ? Icons.check_circle_rounded
                            : isScanned
                            ? Icons.biotech_rounded
                            : Icons.lock_outline_rounded,
                        color: isChecked
                            ? Colors.white
                            : isScanned
                            ? color
                            : (isDark ? Colors.white24 : Colors.black26),
                        size: 14.r,
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          s.toUpperCase(),
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: isChecked
                                ? Colors.white
                                : isScanned
                                ? (isDark
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : Colors.black87)
                                : (isDark ? Colors.white24 : Colors.black26),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
