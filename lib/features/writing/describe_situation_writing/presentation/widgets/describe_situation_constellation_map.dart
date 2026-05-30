import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DescribeSituationConstellationMap extends StatelessWidget {
  final List<String> emojis;
  final Map<String, List<String>> keywords;
  final Color color;
  final bool isDark;
  final int? expandedEmojiIndex;
  final Function(int) onEmojiTap;
  final Function(String) onInjectKeyword;

  const DescribeSituationConstellationMap({
    super.key,
    required this.emojis,
    required this.keywords,
    required this.color,
    required this.isDark,
    required this.expandedEmojiIndex,
    required this.onEmojiTap,
    required this.onInjectKeyword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180.h,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.03 : 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Stack(
        children: List.generate(emojis.length, (index) {
          final isExpanded = expandedEmojiIndex == index;
          
          final double leftPos = 20.w + (index * 70.w);
          final double topPos = (index % 2 == 0) ? 25.h : 95.h;

          return Positioned(
            left: leftPos,
            top: topPos,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => onEmojiTap(index),
                  child: Container(
                    width: 50.r, height: 50.r,
                    decoration: BoxDecoration(
                      color: isExpanded ? color : (isDark ? Colors.white10 : Colors.black12),
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (isExpanded) 
                          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 15)
                      ],
                    ),
                    child: Center(
                      child: Text(emojis[index], style: TextStyle(fontSize: 22.sp))
                    ),
                  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                ),
                if (isExpanded) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black87 : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: color),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (keywords[index.toString()] ?? []).map((k) => TextButton(
                        onPressed: () => onInjectKeyword(k),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        ),
                        child: Text(
                          k, 
                          style: GoogleFonts.shareTechMono(
                            color: isDark ? Colors.white : Colors.black87, 
                            fontSize: 11.sp, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      )).toList(),
                    ),
                  ).animate().scale(alignment: Alignment.centerLeft).fadeIn(),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}
