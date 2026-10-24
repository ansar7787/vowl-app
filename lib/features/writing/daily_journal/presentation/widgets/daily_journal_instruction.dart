import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Instruction banner presenting the writing objective for the daily journal exercise.
class DailyJournalInstruction extends StatelessWidget {
  /// The primary theme accent color for borders and highlights.
  final Color primaryColor;

  /// The fallback prompt text explaining what the user should write.
  final String instruction;

  /// Creates a [DailyJournalInstruction] widget.
  const DailyJournalInstruction({
    super.key,
    required this.primaryColor,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('daily_journal_instruction'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Center(
        child: Text(
          context.tr('games.dailyJournal_instruction', fallback: instruction),
          textAlign: TextAlign.center,
          softWrap: true,
          maxLines: null,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: primaryColor,
            height: 1.45,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
