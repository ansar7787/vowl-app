import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/utils/sound_service.dart';

class TopicVocabHeader extends StatelessWidget {
  final bool isDark;
  final double progress;
  final ThemeResult theme;
  final int lives;
  final bool hintUsed;
  final String? hintText;
  final VoidCallback onExit;
  final VoidCallback onUseHint;
  final SoundService soundService;

  const TopicVocabHeader({
    super.key,
    required this.isDark,
    required this.progress,
    required this.theme,
    required this.lives,
    required this.hintUsed,
    this.hintText,
    required this.onExit,
    required this.onUseHint,
    required this.soundService,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          ScaleButton(
            onTap: onExit,
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(Icons.close_rounded, size: 20.r, color: Colors.white),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8.h,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          QuestHintButton(
            used: hintUsed,
            primaryColor: theme.primaryColor,
            hintText: hintText,
            onTap: onUseHint,
            soundService: soundService,
          ),
          SizedBox(width: 8.w),
          _buildHeartCount(),
        ],
      ),
    );
  }


  Widget _buildHeartCount() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(color: Colors.pink.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 14.r),
          SizedBox(width: 4.w),
          Text("$lives", style: GoogleFonts.shareTechMono(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
        ],
      ),
    );
  }
}
