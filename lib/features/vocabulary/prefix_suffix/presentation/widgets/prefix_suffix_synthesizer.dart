import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

class PrefixSuffixSynthesizer extends StatelessWidget {
  final String rootWord;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final String? selectedAffix;
  final bool isFirstStagePassed;
  final Color primaryColor;
  final bool isDark;
  final Function(String) onAffixSelected;
  final VoidCallback onContinue;

  const PrefixSuffixSynthesizer({
    super.key,
    required this.rootWord,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.selectedAffix,
    required this.isFirstStagePassed,
    required this.primaryColor,
    required this.isDark,
    required this.onAffixSelected,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if the correct answer uses a prefix or suffix based on the options.
    // If the correct option ends with '-', it's a prefix (goes on the left).
    final correctOption = options.firstWhere(
      (opt) => correctAnswer.toLowerCase().contains(opt.replaceAll('-', '').toLowerCase()),
      orElse: () => options.first,
    );
    final isPrefix = correctOption.endsWith('-');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 40.h),
        // ── SYNTHESIS ZONE ──
        Container(
          height: 120.h,
          width: double.infinity,
          alignment: Alignment.center,
          child: isFirstStagePassed
              ? _buildFusedWord()
              : _buildSynthesisSockets(isPrefix),
        ),

        SizedBox(height: 60.h),

        // ── EXPLANATION OR AFFIX DOCK ──
        if (isFirstStagePassed) ...[
          if (explanation != null && explanation!.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                explanation!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.4,
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),
          
          SizedBox(height: 30.h),
          
          ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            child: Text(
              'CONTINUE',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms).scale(curve: Curves.easeOutBack),
        ] else ...[
          // Affix Dock
          Wrap(
            spacing: 16.w,
            runSpacing: 16.h,
            alignment: WrapAlignment.center,
            children: options.map((option) {
              return _buildAffixPiece(option);
            }).toList(),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),
        ]
      ],
    );
  }

  Widget _buildSynthesisSockets(bool isPrefix) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isPrefix) _buildEmptySocket(),
        if (isPrefix) SizedBox(width: 8.w),
        _buildRootBlock(),
        if (!isPrefix) SizedBox(width: 8.w),
        if (!isPrefix) _buildEmptySocket(),
      ],
    );
  }

  Widget _buildEmptySocket() {
    return Container(
      width: 80.w,
      height: 70.h,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.5),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.add,
        color: primaryColor.withValues(alpha: 0.5),
        size: 32.r,
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
     .fade(begin: 0.5, end: 1.0, duration: 1000.ms);
  }

  Widget _buildRootBlock() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        rootWord.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 24.sp,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : Colors.black87,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildAffixPiece(String affix) {
    final bool isSelected = selectedAffix == affix;
    return GestureDetector(
      onTap: () => onAffixSelected(affix),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? primaryColor : primaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Text(
          affix.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildFusedWord() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        correctAnswer.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 32.sp,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 3,
        ),
      ),
    ).animate()
     .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack, duration: 600.ms)
     .shimmer(color: Colors.white.withValues(alpha: 0.5), duration: 1000.ms, delay: 600.ms);
  }
}
