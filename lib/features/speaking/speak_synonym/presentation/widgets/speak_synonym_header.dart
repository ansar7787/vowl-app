import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class SpeakSynonymHeader extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const SpeakSynonymHeader({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco_rounded, size: 14.r, color: Colors.greenAccent),
              SizedBox(width: 8.w),
              Text(
                "LEXICAL SYNONYM SEED",
                style: TextStyle(fontFamily: 'RobotoMono', 
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (instruction != null) ...[
          SizedBox(height: 10.h),
          Text(
            instruction!,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Outfit', 
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ],
    );
  }
}
