import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

class DailyJournalInstruction extends StatelessWidget {
  final Color primaryColor;
  final String instruction;

  const DailyJournalInstruction({
    super.key,
    required this.primaryColor,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        context.tr('games.dailyJournal_instruction', fallback: instruction),
        textAlign: TextAlign.center,
        maxLines: null,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: primaryColor,
        ),
      ),
    );
  }
}
