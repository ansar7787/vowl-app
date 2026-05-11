import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class ModernGameResultOverlay extends StatelessWidget {
  final bool isCorrect;
  final String title;
  final String? subtitle;
  final VoidCallback onContinue;
  final Color primaryColor;
  final String? recognizedText;
  final String? targetText;
  final bool? showHint;
  final String? explanation;

  const ModernGameResultOverlay({
    super.key,
    required this.isCorrect,
    required this.title,
    this.subtitle,
    required this.onContinue,
    required this.primaryColor,
    this.recognizedText,
    this.targetText,
    this.showHint,
    this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feedbackColor = isCorrect
        ? const Color(0xFF10B981)
        : const Color(0xFFF43F5E);

    return Stack(
      children: [
        if (isCorrect) 
          const Positioned.fill(
            child: IgnorePointer(
              child: GameConfetti(),
            ),
          ),
        Container(
          color: Colors.black.withValues(alpha: 0.4),
          alignment: Alignment.bottomCenter,
          child: GlassTile(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            padding: EdgeInsets.zero,
            glassOpacity: isDark ? 0.1 : 0.4,
            blur: 30,
            child: Container(
              padding: EdgeInsets.all(32.r),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: feedbackColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCorrect
                                ? Icons.auto_awesome_rounded
                                : Icons.info_outline_rounded,
                            color: feedbackColor,
                            size: 32.r,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.outfit(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w900,
                                  color: feedbackColor,
                                ),
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.sp,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    if (recognizedText != null) ...[
                      GlassTile(
                        borderRadius: BorderRadius.circular(16.r),
                        padding: EdgeInsets.all(16.r),
                        glassOpacity: 0.1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "YOU SAID:",
                              style: GoogleFonts.outfit(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              recognizedText!,
                              style: GoogleFonts.outfit(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: isCorrect
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF43F5E),
                              ),
                            ),
                            if (targetText != null && !isCorrect) ...[
                              SizedBox(height: 12.h),
                              Text(
                                "EXPECTED:",
                                style: GoogleFonts.outfit(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                targetText!,
                                style: GoogleFonts.outfit(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],
                    if (explanation != null) ...[
                      GlassTile(
                        borderRadius: BorderRadius.circular(16.r),
                        padding: EdgeInsets.all(16.r),
                        glassOpacity: 0.1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "GRAMMAR RULE:",
                              style: GoogleFonts.outfit(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              explanation!,
                              style: GoogleFonts.outfit(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 60.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: feedbackColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                        ),
                        onPressed: onContinue,
                        child: Text(
                          "CONTINUE",
                          style: GoogleFonts.outfit(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutBack),
        ),
      ],
    );
  }
}
