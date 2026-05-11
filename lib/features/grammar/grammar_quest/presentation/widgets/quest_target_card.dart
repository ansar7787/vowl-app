import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuestTargetCard extends StatelessWidget {
  final String? question;
  final String? instruction;
  final bool isScanning;
  final bool isDark;
  final bool isMidnight;
  final Color primaryColor;

  const QuestTargetCard({
    super.key,
    this.question,
    this.instruction,
    this.isScanning = false,
    required this.isDark,
    this.isMidnight = false,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      borderRadius: BorderRadius.circular(32.r),
      borderColor: primaryColor.withValues(alpha: isMidnight ? 0.1 : 0.3),
      color: isMidnight
          ? Colors.black.withValues(alpha: 0.2)
          : (isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.02)),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: 120.h),
        child: isScanning ? _buildScannerUI() : _buildRevealedUI(),
      ).animate(key: ValueKey(isScanning)).fadeIn(duration: 400.ms),
    );
  }

  Widget _buildScannerUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
              Icons.document_scanner_rounded,
              color: primaryColor.withValues(alpha: 0.5),
              size: 40.r,
            )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 2.seconds)
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.05, 1.05),
              curve: Curves.easeInOut,
            ),
        SizedBox(height: 16.h),
        Text(
              "ANALYZING SYNTAX...",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: primaryColor.withValues(alpha: 0.7),
                letterSpacing: 2,
              ),
            )
            .animate(onPlay: (c) => c.repeat())
            .fadeIn(duration: 800.ms)
            .fadeOut(delay: 800.ms, duration: 800.ms),
      ],
    );
  }

  Widget _buildRevealedUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            "MASTER SENTENCE",
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF10B981),
              letterSpacing: 1.5,
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.2),
        SizedBox(height: 16.h),
        Text(
              question ?? "",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: isMidnight
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
                height: 1.3,
              ),
            )
            .animate()
            .fadeIn(delay: 200.ms)
            .scale(begin: const Offset(0.98, 0.98)),
      ],
    );
  }
}
