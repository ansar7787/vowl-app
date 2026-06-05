import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class ClozeTestInstruction extends StatelessWidget {
  final Color primaryColor;

  const ClozeTestInstruction({
    super.key,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_input_component_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              "INJECT FUEL CELLS TO POWER THE PASSAGE", 
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 10.sp, 
                fontWeight: FontWeight.w900, 
                color: primaryColor, 
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
