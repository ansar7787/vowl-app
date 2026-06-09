import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ConnectedSpeechInstruction extends StatelessWidget {
  final Color primaryColor;
  final bool isCompact;

  const ConnectedSpeechInstruction({
    super.key,
    required this.primaryColor,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: isCompact ? 6.h : 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.waves_rounded, size: isCompact ? 12.r : 14.r, color: primaryColor),
          SizedBox(width: isCompact ? 8.w : 12.w),
          Flexible(
            child: Text(
              "IDENTIFY THE CONNECTED SPEECH PHENOMENON ENUNCIATED",
              style: TextStyle(
                fontFamily: 'Outfit', 
                fontSize: isCompact ? 8.sp : 10.sp,
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
