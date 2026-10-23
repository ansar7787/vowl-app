import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Objective instruction card for the Medical Consult minigame.
class MedicalConsultInstruction extends StatelessWidget {
  /// Primary theme accent color.
  final Color primaryColor;

  /// Custom instruction text or fallback.
  final String? instruction;

  /// Creates a [MedicalConsultInstruction] widget.
  const MedicalConsultInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: const Key('medical_consult_instruction'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.18),
          width: 1,
        ),
      ),
      child: Text(
        instruction ?? "Examine the patient and identify the matching symptoms.",
        textAlign: TextAlign.center,
        softWrap: true,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
          height: 1.45,
        ),
      ),
    );
  }
}
