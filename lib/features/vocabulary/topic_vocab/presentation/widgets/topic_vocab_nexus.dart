import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';

class TopicVocabNexus extends StatelessWidget {
  final dynamic quest;
  final ThemeResult theme;
  final bool isDark;
  final VowlMascotState mascotState;
  final String fact;

  const TopicVocabNexus({
    super.key,
    required this.quest,
    required this.theme,
    required this.isDark,
    required this.mascotState,
    required this.fact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: VowlMascot(state: mascotState, size: 50.r),
              ).animate().fadeIn().scale(curve: Curves.easeOutBack),

              // Rotating orbit
              Container(
                width: 100.r,
                height: 100.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 10.seconds),
            ],
          ),
          SizedBox(height: 12.h),
          GlassTile(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            borderRadius: BorderRadius.circular(20.r),
            borderColor: theme.primaryColor.withValues(alpha: 0.2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      quest.topicEmoji ?? '📚',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      (quest.word ?? "TOPIC").toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  fact,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.2),
        ],
      ),
    );
  }
}
