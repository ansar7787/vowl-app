import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmergencyHubInstruction extends StatelessWidget {
  final String? instruction;

  const EmergencyHubInstruction({super.key, this.instruction});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: tokens.gameIncorrect.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: tokens.gameIncorrect.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            "SECTOR DISPATCH STATION",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: tokens.gameIncorrect,
              letterSpacing: 2.5,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          instruction ??
              "Authenticate terminal code and spin safety valve to route unit!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}
