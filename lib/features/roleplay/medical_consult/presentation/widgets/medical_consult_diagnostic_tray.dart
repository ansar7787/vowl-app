import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color131326 = Color(0xFF131326);
}

class MedicalConsultDiagnosticTray extends StatelessWidget {
  final List<String> symptoms;
  final Color color;
  final bool isDark;
  final List<String> scannedGlitches;
  final List<String> diagnosedSymptoms;
  final bool isAnswered;
  final bool? isCorrect;
  final Function(String) onSymptomTapped;

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
      width: 1.sw,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.health_and_safety_rounded,
                color: color.withValues(alpha: 0.6),
                size: 16.r,
              ),
              SizedBox(width: 6.w),
              Text(
                "DIAGNOSTIC OPTIONS",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  color: color,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
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
                  constraints: BoxConstraints(maxWidth: 1.sw - 60.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: isChecked
                        ? cardColor
                        : (isDark
                              ? _LocalPalette.color131326
                              : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(14.r),
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
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          s.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
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
