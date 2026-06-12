import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

class FlashcardSwipeFront extends StatelessWidget {
  // FIX: was dynamic — now VocabularyQuest for full compile-time safety.
  final VocabularyQuest quest;
  final Color color;
  final bool isDark;
  final double width;
  final double height;

  const FlashcardSwipeFront({
    super.key,
    required this.quest,
    required this.color,
    required this.isDark,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Word: ${quest.word ?? ""}. Tap to reveal definition.',
      child: Container(
        width: width,
        height: height,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isDark ? Colors.white10 : color.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 25,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactHeight = constraints.maxHeight < 260;
            final compactWidth = constraints.maxWidth < 290;

            return Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  padding: EdgeInsets.all(compactHeight ? 16.r : 20.r),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    quest.topicEmoji ?? '🏷️',
                    style: TextStyle(fontSize: compactHeight ? 44.sp : 58.sp),
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                SizedBox(height: compactHeight ? 16.h : 24.h),
                Flexible(
                  flex: 4,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        quest.word?.toUpperCase() ?? '',
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: compactWidth ? 28.sp : 34.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: compactWidth ? 2.5 : 3.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 1),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8.w,
                  runSpacing: 4.h,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 14.r,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.72)
                          : color.withValues(alpha: 0.72),
                    ),
                    Text(
                      'TAP TO FLIP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.72)
                            : color.withValues(alpha: 0.72),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
              ],
            );
          },
        ),
      ),
    );
  }
}
