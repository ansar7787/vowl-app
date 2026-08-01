import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class PronunciationFocusPhonemeCrucible extends StatelessWidget {
  final SpeakingQuest quest;
  final Color primaryColor;
  final bool isDark;
  final double heatLevel;
  final bool showGuide;
  final VoidCallback onToggleGuide;

  const PronunciationFocusPhonemeCrucible({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
    required this.heatLevel,
    required this.showGuide,
    required this.onToggleGuide,
  });

  @override
  Widget build(BuildContext context) {
    final String targetSound = quest.targetPhoneme ?? "[r]";

    return GlassTile(
      padding: EdgeInsets.all(20.r),
      borderRadius: BorderRadius.circular(28.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TARGET PHONETIC CORE",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  color: Colors.grey.shade400,
                  letterSpacing: 1.0,
                ),
              ),
              ScaleButton(
                onTap: onToggleGuide,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        color: Colors.orangeAccent,
                        size: 12.r,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        "POSITION GUIDE",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9.sp,
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Glowing liquid metal sphere capsule
          Container(
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(
                        const Color(0xFF1F1C2C),
                        const Color(0xFFFF512F),
                        heatLevel,
                      )!,
                      Color.lerp(
                        const Color(0xFF928DAB),
                        const Color(0xFFDD2476),
                        heatLevel,
                      )!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Color.lerp(
                        Colors.blue,
                        Colors.orangeAccent,
                        heatLevel,
                      )!.withValues(alpha: 0.35 + heatLevel * 0.25),
                      blurRadius: 15.r + heatLevel * 10.r,
                    ),
                  ],
                ),
                child: Text(
                  targetSound,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .slideY(
                begin: -0.05,
                end: 0.05,
                duration: const Duration(milliseconds: 1500),
              ),

          AnimatedCrossFade(
            firstChild: const SizedBox(),
            secondChild: Padding(
              padding: EdgeInsets.only(top: 14.h),
              child: Column(
                children: [
                  const Divider(color: Colors.white12),
                  SizedBox(height: 8.h),
                  Text(
                    quest.phoneticHint ??
                        "Accentuate the critical sound matching the crucible target.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: showGuide
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
