import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class TopicContainmentBin extends StatelessWidget {
  final int index;
  final String label;
  final Color color;
  final bool isDark;
  final String correctAnswer;
  final String currentWord;
  final List<String> words;
  final bool isHintActive;

  const TopicContainmentBin({
    super.key,
    required this.index,
    required this.label,
    required this.color,
    required this.isDark,
    required this.correctAnswer,
    required this.currentWord,
    required this.words,
    required this.isHintActive,
  });

  @override
  Widget build(BuildContext context) {
    bool isHinted = isHintActive && correctAnswer.contains("$label:$currentWord");

    // Contextual Icons for Categories
    IconData bucketIcon = Icons.settings_input_component_rounded;
    final lLabel = label.toLowerCase();
    
    if (lLabel.contains("positive")) {
      bucketIcon = Icons.sentiment_very_satisfied_rounded;
    } else if (lLabel.contains("negative")) {
      bucketIcon = Icons.sentiment_very_dissatisfied_rounded;
    } else if (lLabel.contains("fruit")) {
      bucketIcon = Icons.apple_rounded;
    } else if (lLabel.contains("vegetable")) {
      bucketIcon = Icons.eco_rounded;
    } else if (lLabel.contains("indoor")) {
      bucketIcon = Icons.home_rounded;
    } else if (lLabel.contains("outdoor")) {
      bucketIcon = Icons.landscape_rounded;
    } else if (lLabel.contains("animal")) {
      bucketIcon = Icons.pets_rounded;
    } else if (lLabel.contains("plant")) {
      bucketIcon = Icons.local_florist_rounded;
    } else if (lLabel.contains("modern")) {
      bucketIcon = Icons.smartphone_rounded;
    } else if (lLabel.contains("ancient")) {
      bucketIcon = Icons.history_rounded;
    } else if (lLabel.contains("loud")) {
      bucketIcon = Icons.volume_up_rounded;
    } else if (lLabel.contains("quiet")) {
      bucketIcon = Icons.volume_off_rounded;
    } else if (lLabel.contains("large")) {
      bucketIcon = Icons.aspect_ratio_rounded;
    } else if (lLabel.contains("small")) {
      bucketIcon = Icons.photo_size_select_small_rounded;
    } else if (lLabel.contains("water")) {
      bucketIcon = Icons.water_drop_rounded;
    } else if (lLabel.contains("land")) {
      bucketIcon = Icons.terrain_rounded;
    } else if (lLabel.contains("summer")) {
      bucketIcon = Icons.wb_sunny_rounded;
    } else if (lLabel.contains("winter")) {
      bucketIcon = Icons.ac_unit_rounded;
    } else if (lLabel.contains("work")) {
      bucketIcon = Icons.work_rounded;
    } else if (lLabel.contains("hobby")) {
      bucketIcon = Icons.sports_esports_rounded;
    } else if (lLabel.contains("correct")) {
      bucketIcon = Icons.check_circle_outline_rounded;
    } else if (lLabel.contains("wrong")) {
      bucketIcon = Icons.cancel_outlined;
    }

    return Column(
      children: [
        SizedBox(
          width: 140.w,
          height: 180.h,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 130.w, height: 160.h,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(10.r),
                    bottom: Radius.circular(30.r),
                  ),
                  border: Border.all(
                    color: isHinted ? Colors.white : color.withValues(alpha: 0.4),
                    width: isHinted ? 3.5 : 2,
                  ),
                  boxShadow: [
                    if (isHinted)
                      const BoxShadow(color: Colors.white, blurRadius: 25, spreadRadius: 2),
                    BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: -5)
                  ],
                ),
              ).animate(target: isHinted ? 1 : 0).shimmer(duration: 1.seconds, color: Colors.white.withValues(alpha: 0.3)),

              Positioned(
                bottom: 10.h,
                child: Container(
                  width: 110.w, height: 130.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: Stack(
                      children: [
                        _buildPlasmaFill(color),
                        Padding(
                          padding: EdgeInsets.all(12.r),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: words.reversed.take(4).map((w) => Padding(
                              padding: EdgeInsets.only(bottom: 4.h),
                              child: Text(
                                w.toUpperCase(),
                                style: GoogleFonts.shareTechMono(
                                  fontSize: 9.sp,
                                  color: color.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(bucketIcon, color: Colors.white, size: 10.r),
                      SizedBox(width: 4.w),
                      Text(
                        label.toUpperCase(),
                        style: GoogleFonts.shareTechMono(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlasmaFill(Color color) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .shimmer(duration: 3.seconds, color: Colors.white.withValues(alpha: 0.1)),
    );
  }
}
