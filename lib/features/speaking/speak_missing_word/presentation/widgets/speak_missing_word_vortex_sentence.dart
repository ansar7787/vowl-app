import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class SpeakMissingWordVortexSentence extends StatelessWidget {
  final String text;
  final String insertedWord;
  final Color primaryColor;
  final bool isDark;

  const SpeakMissingWordVortexSentence({
    super.key,
    required this.text,
    required this.insertedWord,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 28.h),
      borderRadius: BorderRadius.circular(32.r),
      child: Column(
        children: [
          Text(
            "VOCAL SENTENCE CONSTRUCTOR",
            style: TextStyle(fontFamily: 'RobotoMono', 
              fontSize: 10.sp,
              color: primaryColor,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Outfit', 
              fontSize: 20.sp,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.45,
            ),
          ),
          if (insertedWord.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
              ),
              child: Text(
                "LOCKED OPTION: ${insertedWord.toUpperCase()}",
                style: TextStyle(fontFamily: 'RobotoMono', 
                  fontSize: 10.sp,
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
