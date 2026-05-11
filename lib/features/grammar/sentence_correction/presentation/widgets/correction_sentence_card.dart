import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class CorrectionSentenceCard extends StatelessWidget {
  final String sentence;
  final String incorrectPart;
  final String correctedPart;
  final bool isCorrected;
  final Color primaryColor;
  final bool isDark;
  final bool isMidnight;

  const CorrectionSentenceCard({
    super.key,
    required this.sentence,
    required this.incorrectPart,
    required this.correctedPart,
    required this.isCorrected,
    required this.primaryColor,
    required this.isDark,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    // Split the sentence by the incorrect part
    final parts = sentence.split(incorrectPart);

    return GlassTile(
      padding: EdgeInsets.all(32.r),
      borderRadius: BorderRadius.circular(32.r),
      borderColor:
          (isCorrected ? const Color(0xFF10B981) : const Color(0xFFF43F5E))
              .withValues(alpha: 0.3),
      color: isMidnight
          ? Colors.black.withValues(alpha: 0.2)
          : (isDark
              ? (isCorrected ? const Color(0xFF10B981) : const Color(0xFFF43F5E))
                    .withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.5)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCorrected
                    ? Icons.check_circle_rounded
                    : Icons.report_gmailerrorred_rounded,
                color: isCorrected
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF43F5E),
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              Text(
                isCorrected ? "FIXED" : "FAULT DETECTED",
                style: GoogleFonts.shareTechMono(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: isCorrected
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF43F5E),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (parts.isNotEmpty) _buildTextPart(parts[0]),

              _buildInteractivePart(),

              if (parts.length > 1) _buildTextPart(parts[1]),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildTextPart(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: isMidnight
            ? Colors.white70
            : (isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B)),
        height: 1.5,
      ),
    );
  }

  Widget _buildInteractivePart() {
    return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: isCorrected
                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                : const Color(0xFFF43F5E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color:
                  (isCorrected
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF43F5E))
                      .withValues(alpha: 0.3),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The text that changes
              Text(
                    isCorrected ? correctedPart : incorrectPart,
                    style: GoogleFonts.outfit(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: isCorrected
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF43F5E),
                      decoration: isCorrected
                          ? TextDecoration.none
                          : TextDecoration.underline,
                      decorationColor: const Color(
                        0xFFF43F5E,
                      ).withValues(alpha: 0.5),
                    ),
                  )
                  .animate(key: ValueKey(isCorrected))
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
            ],
          ),
        )
        .animate(
          onPlay: (controller) => !isCorrected
              ? controller.repeat(reverse: true)
              : controller.stop(),
        )
        .shimmer(
          duration: 2.seconds,
          color:
              (isCorrected ? const Color(0xFF10B981) : const Color(0xFFF43F5E))
                  .withValues(alpha: 0.2),
        );
  }
}
