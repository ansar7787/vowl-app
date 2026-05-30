import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class AccentShadowingTargetPanel extends StatelessWidget {
  final String text;
  final Set<int> matchedIndices;
  final bool isDark;
  final Color primaryColor;
  final bool isAnswered;
  final bool? isCorrect;
  final int attempts;

  const AccentShadowingTargetPanel({
    super.key,
    required this.text,
    required this.matchedIndices,
    required this.isDark,
    required this.primaryColor,
    required this.isAnswered,
    this.isCorrect,
    required this.attempts,
  });

  @override
  Widget build(BuildContext context) {
    final isErrorState = isCorrect == false && attempts > 0;

    return GlassTile(
      borderRadius: BorderRadius.circular(32.r),
      padding: EdgeInsets.all(32.r),
      border: (isAnswered || isErrorState)
          ? Border.all(
              color: isCorrect == true ? Colors.greenAccent : Colors.redAccent,
              width: 2,
            )
          : null,
      child: Column(
        children: [
          Icon(
            Icons.record_voice_over_rounded,
            color: isDark ? primaryColor : const Color(0xFF0F172A),
            size: 32.r,
          ),
          SizedBox(height: 20.h),
          _buildTargetWords(),
        ],
      ),
    );
  }

  Widget _buildTargetWords() {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8.w,
      runSpacing: 8.h,
      children: List.generate(words.length, (index) {
        final isMatched = matchedIndices.contains(index);
        return Text(
          words[index],
          style: GoogleFonts.outfit(
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            color: isMatched
                ? Colors.greenAccent
                : (isDark ? Colors.white : const Color(0xFF1E293B)),
            height: 1.4,
          ),
        )
            .animate(target: isMatched ? 1 : 0)
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 200.ms,
            );
      }),
    );
  }
}
