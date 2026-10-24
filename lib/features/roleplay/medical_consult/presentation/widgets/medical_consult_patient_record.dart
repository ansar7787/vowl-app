import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Patient chart card displaying medical history, chief complaint, and prompt.
class MedicalConsultPatientRecord extends StatelessWidget {
  /// Prompt text describing the patient's complaint.
  final String prompt;

  /// Primary theme accent color.
  final Color color;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Creates a [MedicalConsultPatientRecord] widget.
  const MedicalConsultPatientRecord({
    super.key,
    required this.prompt,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('medical_consult_patient_record'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
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
                : color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline_rounded,
            color: color.withValues(alpha: 0.85),
            size: 26.r,
          ),
          SizedBox(height: 8.h),
          Text(
            "PATIENT COMPLAINT",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              color: color,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            prompt,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
