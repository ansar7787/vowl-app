import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SpeakOppositePositivePolePanel extends StatelessWidget {
  final String targetWord;
  final String contextText;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onPlayTts;

  const SpeakOppositePositivePolePanel({
    super.key,
    required this.targetWord,
    required this.contextText,
    required this.primaryColor,
    required this.isDark,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.all(22.r),
      borderRadius: BorderRadius.circular(26.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.school_rounded, color: primaryColor, size: 14.r),
                  SizedBox(width: 6.w),
                  Text(
                    "GIVEN WORD",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      color: Colors.grey.shade400,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Semantics(
                label: 'Listen to the target word',
                button: true,
                child: ScaleButton(
                  onTap: onPlayTts,
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: primaryColor,
                    size: 18.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.6),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Text(
              targetWord,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (contextText.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text(
              contextText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          SizedBox(height: 24.h),
          Divider(color: Colors.grey.withValues(alpha: 0.2)),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic_rounded, color: Colors.grey, size: 16.r),
              SizedBox(width: 8.w),
              Text(
                "Hold mic to say the opposite",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
