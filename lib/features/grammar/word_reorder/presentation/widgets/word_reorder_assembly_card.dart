import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class WordReorderAssemblyCard extends StatelessWidget {
  final List<int> assembledIndices;
  final List<String> shuffledWords;
  final Color primaryColor;
  final bool isDark;
  final bool isAnswered;
  final ValueChanged<int> onWordRemove;

  const WordReorderAssemblyCard({
    super.key,
    required this.assembledIndices,
    required this.shuffledWords,
    required this.primaryColor,
    required this.isDark,
    required this.isAnswered,
    required this.onWordRemove,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    final card = Container(
      key: const ValueKey('word_assembly_card'),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 110.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Wrap(
          spacing: 8.w,
          runSpacing: 10.h,
          alignment: WrapAlignment.center,
          children: assembledIndices.isEmpty
              ? [
                  Builder(
                    builder: (context) {
                      final text = Text(
                        "Tap words below to build your sentence",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: primaryColor.withValues(alpha: 0.6),
                          letterSpacing: 0.2,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      );
                      if (reduceMotion) return text;
                      return text
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .shimmer(duration: 2.seconds);
                    },
                  ),
                ]
              : assembledIndices.map((idx) {
                  final word = shuffledWords[idx];
                  final wordButton = ScaleButton(
                    key: ValueKey('assembled_word_$idx'),
                    onTap: isAnswered ? null : () => onWordRemove(idx),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        word,
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  );
                  if (reduceMotion) return wordButton;
                  return wordButton.animate().scale(
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  );
                }).toList(),
        ),
      ),
    );

    if (reduceMotion) return card;
    return card.animate().fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0);
  }
}
