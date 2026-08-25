import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';

class InstructionPanel extends StatelessWidget {
  final Color color;
  final GameQuest? quest;

  const InstructionPanel({super.key, required this.color, this.quest});

  @override
  Widget build(BuildContext context) {
    final text =
        quest?.hint ??
        quest?.instruction ??
        "Analyze the meaning and select the correct ending.";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        softWrap: true,
        overflow: TextOverflow.visible,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
          height: 1.3,
        ),
      ),
    );
  }
}
