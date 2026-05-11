import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class VoiceTransformationCard extends StatelessWidget {
  final String originalSentence;
  final String? transformedSentence;
  final bool showResult;
  final bool isCorrect;
  final Color primaryColor;
  final bool isDark;
  final bool isMidnight;

  const VoiceTransformationCard({
    super.key,
    required this.originalSentence,
    this.transformedSentence,
    required this.showResult,
    required this.isCorrect,
    required this.primaryColor,
    required this.isDark,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.all(32.r),
      borderRadius: BorderRadius.circular(32.r),
      borderColor: primaryColor.withValues(alpha: isMidnight ? 0.1 : 0.3),
      color: isMidnight
          ? Colors.black.withValues(alpha: 0.2)
          : (isDark
              ? const Color(0xFF101827).withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.98)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Original Sentence (Visible initially, fades out if correct)
          AnimatedOpacity(
            duration: 500.ms,
            opacity: showResult && isCorrect ? 0 : 1,
            child: Text(
              originalSentence,
              style: GoogleFonts.outfit(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: isMidnight
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Transformed Sentence (Visible only if correct result)
          if (showResult && isCorrect && transformedSentence != null)
            Text(
                  transformedSentence!,
                  style: GoogleFonts.outfit(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                ),

          // If WRONG, we don't transform, just keep original but maybe shake/shimmer
          if (showResult && !isCorrect)
            const SizedBox.shrink().animate().shake(duration: 500.ms),
        ],
      ),
    );
  }
}
