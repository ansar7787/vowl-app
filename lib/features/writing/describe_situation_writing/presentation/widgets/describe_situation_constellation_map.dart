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
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 1.0,
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(emojis.length, (index) {
              final isExpanded = expandedEmojiIndex == index;
              return Semantics(
                button: true,
                label: 'Emoji ${emojis[index]}',
                hint: isExpanded
                    ? 'Double tap to close keyword list'
                    : 'Double tap to open keyword list',
                child: GestureDetector(
                  key: Key('describe_situation_emoji_$index'),
                  onTap: () => onEmojiTap(index),
                  child:
                      Container(
                            width: 50.r,
                            height: 50.r,
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
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                  )
                                else if (!isDark)
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
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
                            end: const Offset(1.08, 1.08),
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
                    padding: EdgeInsets.only(top: 16.h),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black87 : Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: color.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "TAP A KEYWORD TO ADD:",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: color,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Wrap(
                            spacing: 10.w,
                            runSpacing: 10.h,
                            alignment: WrapAlignment.center,
                            children:
                                (keywords[expandedEmojiIndex.toString()] ?? [])
                                    .map(
                                      (k) => Semantics(
                                        button: true,
                                        label: 'Keyword ${k.toLowerCase()}',
                                        hint: 'Double tap to add to description',
                                        child: InkWell(
                                          key: Key('describe_situation_keyword_$k'),
                                          onTap: () => onInjectKeyword(k),
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 14.w,
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
                                                fontWeight: FontWeight.w600,
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
                    ).animate().fadeIn().slideY(begin: 0.15, end: 0),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}
