import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Instruction banner guiding users to identify pronoun referents.
class PronounResolutionInstruction extends StatelessWidget {
  /// The primary theme accent color.
  final Color primaryColor;

  /// The instruction text describing the objective.
  final String? instruction;

  /// Creates a [PronounResolutionInstruction] widget.
  const PronounResolutionInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final rawInstruction = instruction?.trim() ?? '';
    final isSciFiBuzzword =
        rawInstruction.toUpperCase() == 'ALIGN THE GRAVITY WELL' ||
        rawInstruction.toUpperCase() == 'ALIGN THE GRAVITY';
    final cleanInstruction = (rawInstruction.isEmpty || isSciFiBuzzword)
        ? 'Find what the pronoun refers to'
        : rawInstruction;

    return Container(
      key: const ValueKey('pronoun_resolution_instruction'),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 16.r, color: primaryColor),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              cleanInstruction,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                letterSpacing: 0.3,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
