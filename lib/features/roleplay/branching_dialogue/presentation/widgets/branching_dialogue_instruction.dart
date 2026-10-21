import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

class BranchingDialogueInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;
  final bool isDark;

  const BranchingDialogueInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDark =
        isDark || Theme.of(context).brightness == Brightness.dark;
    final effectiveInstruction =
        (instruction != null && instruction!.trim().isNotEmpty)
            ? instruction!
            : context.tr(
                'games.branchingDialogue_instruction',
                fallback:
                    'Choose the best response to continue the conversation.',
              );

    return Semantics(
      label: effectiveInstruction,
      header: true,
      child: Column(
        children: [
          Container(
            key: const Key('branching_dialogue_instruction_badge'),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              "BRANCHING DIALOGUE",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: primaryColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              effectiveInstruction,
              key: const Key('branching_dialogue_instruction_text'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: effectiveDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.black87,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
