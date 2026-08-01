import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DescribeSituationWritingArea extends StatelessWidget {
  final TextEditingController textController;
  final int minWords;
  final int wordCount;
  final List<String> usedKeywords;
  final Color color;
  final bool isDark;

  const DescribeSituationWritingArea({
    super.key,
    required this.textController,
    required this.minWords,
    required this.wordCount,
    required this.usedKeywords,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black87 : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 2,
        ),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          TextField(
            controller: textController,
            maxLines: 4,
            maxLength: 400,
            buildCounter: (context,
                    {required currentLength,
                    required isFocused,
                    maxLength}) =>
                null,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14.sp,
            ),
            decoration: InputDecoration(
              hintText:
                  "Type description here... (Tap floating emoji cells to inject keyword boosters directly!)",
              hintStyle: TextStyle(
                fontFamily: 'Outfit',
                color: isDark ? Colors.white30 : Colors.black38,
                fontSize: 12.sp,
              ),
              border: InputBorder.none,
            ),
          ),
          const Divider(color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Booster words used: ${usedKeywords.length}",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Builder(
                builder: (context) {
                  final displayColor = wordCount >= minWords
                      ? (isDark ? Colors.greenAccent : const Color(0xFF16A34A))
                      : (isDark ? Colors.redAccent : const Color(0xFFDC2626));
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: displayColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      "$wordCount / $minWords words",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        color: displayColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
