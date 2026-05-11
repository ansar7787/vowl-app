import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class AgreementSentenceCard extends StatelessWidget {
  final String sentence;
  final String? selectedVerb;
  final bool showResult;
  final bool isCorrect;
  final Color primaryColor;
  final bool isDark;
  final bool isMidnight;

  const AgreementSentenceCard({
    super.key,
    required this.sentence,
    this.selectedVerb,
    required this.showResult,
    required this.isCorrect,
    required this.primaryColor,
    required this.isDark,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    // Regex to find "___" or similar blank patterns
    final blankRegex = RegExp(r'___+');
    final hasBlank = sentence.contains(blankRegex);

    List<String> parts;
    if (hasBlank) {
      parts = sentence.split(blankRegex);
    } else {
      parts = [sentence, ""];
    }

    return GlassTile(
      padding: EdgeInsets.all(32.r),
      borderRadius: BorderRadius.circular(32.r),
      borderColor: primaryColor.withValues(alpha: 0.3),
      color: isDark
          ? primaryColor.withValues(alpha: 0.05)
          : Colors.white.withValues(alpha: 0.5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome_mosaic_rounded,
                color: primaryColor,
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              Text(
                "SENTENCE PUZZLE",
                style: GoogleFonts.shareTechMono(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.w,
            runSpacing: 12.h,
            children: [
              if (parts.isNotEmpty)
                ..._buildTextParts(parts[0], isSubject: true),

              _buildVerbSlot(),

              if (parts.length > 1 && parts[1].trim().isNotEmpty)
                ..._buildTextParts(parts[1], isSubject: false),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  List<Widget> _buildTextParts(String text, {required bool isSubject}) {
    final words = text.trim().split(' ');
    return words.map((word) {
      return Text(
        word,
        style: GoogleFonts.outfit(
          fontSize: 22.sp,
          fontWeight: isSubject ? FontWeight.w900 : FontWeight.w600,
          color: isSubject
              ? (isDark ? Colors.white : const Color(0xFF1E293B))
              : (isDark ? Colors.white70 : Colors.black87),
          decoration: isSubject
              ? TextDecoration.underline
              : TextDecoration.none,
          decorationColor: isSubject
              ? primaryColor.withValues(alpha: 0.3)
              : null,
          decorationThickness: 2,
        ),
      );
    }).toList();
  }

  Widget _buildVerbSlot() {
    final displayVerb = selectedVerb ?? "?";
    final isFilled = selectedVerb != null;

    Color slotColor = primaryColor;
    if (showResult) {
      slotColor = isCorrect ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      constraints: BoxConstraints(minWidth: 60.w),
      decoration: BoxDecoration(
        color: isFilled ? slotColor.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: slotColor.withValues(alpha: isFilled ? 0.6 : 0.3),
          width: 2,
          style: isFilled ? BorderStyle.solid : BorderStyle.none,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!isFilled)
            Container(
                  width: 40.w,
                  height: 2.h,
                  color: primaryColor.withValues(alpha: 0.3),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 800.ms)
                .fadeOut(duration: 800.ms),

          Text(
                displayVerb,
                style: GoogleFonts.outfit(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: slotColor,
                ),
              )
              .animate(key: ValueKey(displayVerb))
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.8, 0.8)),
        ],
      ),
    );
  }
}
