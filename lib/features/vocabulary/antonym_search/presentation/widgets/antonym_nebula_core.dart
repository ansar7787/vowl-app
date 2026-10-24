import 'package:vowl/features/photo_vocabulary/utils/photo_vocabulary_dictionary.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_painters.dart';

/// Central circular core displaying the target vocabulary word with animated orbit rings and phonetic details.
class AntonymNebulaCore extends StatelessWidget {
  /// The target vocabulary word to find antonyms for.
  final String word;

  /// Theme accent color for concentric rings, shadows, and labels.
  final Color color;

  /// Whether the app is currently rendered in dark theme mode.
  final bool isDark;

  /// Creates an [AntonymNebulaCore] widget.
  const AntonymNebulaCore({
    super.key,
    required this.word,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "MATCH TO OPPOSITE",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.2,
          ),
        ).animate().fadeIn(),
        SizedBox(height: 14.h),
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
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    word.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                if (entry?.ipa != null) ...[
                                  SizedBox(height: 3.h),
                                  Text(
                                    entry!.ipa!,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11.5.sp,
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
        SizedBox(height: 10.h),
        ScaleButton(
          onTap: () {
            if (di.sl.isRegistered<SoundService>()) {
              di.sl<SoundService>().playTts(word);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
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
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
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
