import 'package:vowl/features/photo_vocabulary/utils/photo_vocabulary_dictionary.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_painters.dart';

class AntonymNebulaCore extends StatelessWidget {
  final String word;
  final Color color;
  final bool isDark;

  const AntonymNebulaCore({
    super.key,
    required this.word,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "MATCH TO OPPOSITE",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1,
          ),
        ).animate().fadeIn(),
        SizedBox(height: 15.h),
        Container(
              width: 140.r,
              height: 140.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.black : Colors.white,
                border: Border.all(
                  color: color.withValues(alpha: 0.8),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                        child: CustomPaint(painter: CorePainter(color)),
                      )
                      .animate(onPlay: reduceMotion ? null : (c) => c.repeat())
                      .rotate(duration: 12.seconds),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Builder(
                        builder: (context) {
                          final cleanWord = word.trim().toLowerCase();
                          final entry = PhotoVocabularyDictionary.dictionary[cleanWord];
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  child: Text(
                                    word.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (entry?.ipa != null) ...[
                                  SizedBox(height: 2.h),
                                  Text(
                                    entry!.ipa!,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10.sp,
                                      color: color.withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            )
            .animate(
              onPlay: reduceMotion ? null : (c) => c.repeat(reverse: true),
            )
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.04, 1.04),
              duration: 2.seconds,
            ),
        SizedBox(height: 8.h),
        ScaleButton(
          onTap: () {
            if (di.sl.isRegistered<SoundService>()) {
              di.sl<SoundService>().playTts(word);
            }
          },
          child: Padding(
            padding: EdgeInsets.all(4.r),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.volume_up_rounded,
                  size: 14.r,
                  color: color,
                ),
                SizedBox(width: 4.w),
                Text(
                  "LISTEN",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
