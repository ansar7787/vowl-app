import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class WordLabCore extends StatelessWidget {
  final dynamic quest;
  final ThemeResult theme;
  final bool isDark;

  const WordLabCore({
    super.key,
    required this.quest,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 130.r,
          height: 130.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [theme.primaryColor.withValues(alpha: 0.2), Colors.transparent],
            ),
          ),
        ).animate(onPlay: (c) => c.repeat())
            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2.seconds, curve: Curves.easeInOut)
            .fadeIn(duration: 1.seconds)
            .fadeOut(delay: 1.seconds),

        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "CORE ELEMENT",
              style: GoogleFonts.shareTechMono(
                fontSize: 8.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white38 : Colors.black38,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 8.h),
            GlassTile(
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
              borderRadius: BorderRadius.circular(20.r),
              borderColor: theme.primaryColor,
              color: theme.primaryColor.withValues(alpha: 0.1),
              child: Text(
                quest.word?.toUpperCase() ?? "---",
                style: GoogleFonts.outfit(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : theme.primaryColor,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: theme.primaryColor.withValues(alpha: 0.5),
                      blurRadius: 10,
                    )
                  ],
                ),
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 1.seconds),
          ],
        ),
      ],
    );
  }
}
