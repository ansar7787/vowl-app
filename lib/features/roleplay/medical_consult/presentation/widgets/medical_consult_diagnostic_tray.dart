import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

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
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ANATOMICAL DIAGNOSTICS SLATE",
                style: TextStyle(fontFamily: 'RobotoMono', 
                  fontSize: 10.sp,
                  color: color,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.health_and_safety_rounded, color: color.withValues(alpha: 0.5), size: 16.r),
            ],
          ),
          SizedBox(height: 16.h),

          // Symptoms grid chips
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10.w,
            runSpacing: 10.h,
            children: symptoms.map((s) {
              final bool isScanned = scannedGlitches.contains(s);
              final bool isChecked = diagnosedSymptoms.contains(s);

              Color cardColor = color;
              if (isAnswered && isChecked) {
                cardColor = (isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
              }

              return ScaleButton(
                onTap: () => onSymptomTapped(s),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isChecked
                        ? cardColor
                        : (isDark ? const Color(0xFF131326) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isChecked
                          ? Colors.white
                          : isScanned
                              ? color.withValues(alpha: 0.4)
                              : color.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isChecked ? cardColor : color).withValues(alpha: isChecked ? 0.25 : 0.04),
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
                      Text(
                        s.toUpperCase(),
                        style: TextStyle(fontFamily: 'Outfit', 
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          color: isChecked
                              ? Colors.white
                              : isScanned
                                  ? (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87)
                                  : (isDark ? Colors.white24 : Colors.black26),
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
