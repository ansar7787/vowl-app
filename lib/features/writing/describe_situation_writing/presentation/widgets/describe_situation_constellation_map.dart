import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.03 : 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(emojis.length, (index) {
              final isExpanded = expandedEmojiIndex == index;
              return Semantics(
                button: true,
                label: 'Category emoji ${emojis[index]}',
                hint: isExpanded
                    ? 'Double tap to close keyword list'
                    : 'Double tap to open keywords for this category',
                child: GestureDetector(
                  onTap: () => onEmojiTap(index),
                  child:
                      Container(
                            width: 48.r,
                            height: 48.r,
                            decoration: BoxDecoration(
                              color: isExpanded
                                  ? color
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.white),
                              shape: BoxShape.circle,
                              boxShadow: [
                                if (isExpanded)
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 15,
                                  )
                                else if (!isDark)
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                emojis[index],
                                style: TextStyle(fontSize: 24.sp),
                              ),
                            ),
                          )
                          .animate(target: isExpanded ? 1 : 0)
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.1, 1.1),
                          ),
                ),
              );
            }),
          ),

          AnimatedSize(
            duration: 300.ms,
            curve: Curves.easeOutCubic,
            child: expandedEmojiIndex != null
                ? Padding(
                    padding: EdgeInsets.only(top: 20.h),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black87 : Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "TAP TO INJECT:",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: color.withValues(alpha: 0.8),
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Wrap(
                            spacing: 12.w,
                            runSpacing: 12.h,
                            alignment: WrapAlignment.center,
                            children:
                                (keywords[expandedEmojiIndex.toString()] ?? [])
                                    .map(
                                      (k) => Semantics(
                                        button: true,
                                        label:
                                            'Keyword booster ${k.toLowerCase()}',
                                        hint:
                                            'Double tap to inject into your text',
                                        child: InkWell(
                                          onTap: () => onInjectKeyword(k),
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12.w,
                                              vertical: 8.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              border: Border.all(
                                                color: color.withValues(
                                                  alpha: 0.3,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              k,
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}
