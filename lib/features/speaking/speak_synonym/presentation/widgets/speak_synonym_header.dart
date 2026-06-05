import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class SpeakSynonymHeader extends StatelessWidget {
  final Color primaryColor;

  const SpeakSynonymHeader({
    super.key,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
