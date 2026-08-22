import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PrefixSuffixSynthesizer extends StatelessWidget {
  final String rootWord;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final String? selectedAffix;
  final String? hintedAffix;
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
    this.hintedAffix,
    required this.isFirstStagePassed,
    required this.primaryColor,
    required this.isDark,
    required this.onAffixSelected,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    // 1. ROBUST DETECTION LOGIC
    final cleanCorrect = correctAnswer.replaceAll('-', '').trim().toLowerCase();
    
    // Find which option actually fits inside the correct answer
    final correctOption = options.firstWhere(
      (opt) => cleanCorrect.contains(opt.replaceAll('-', '').trim().toLowerCase()),
      orElse: () => options.first,
    );
    
    final cleanOpt = correctOption.replaceAll('-', '').trim().toLowerCase();
    
    // A prefix is anything that comes at the beginning of the word.
    final isPrefix = correctOption.endsWith('-') || cleanCorrect.startsWith(cleanOpt);

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
          ).animate(target: selectedAffix != null ? 0 : 1).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            duration: 300.ms,
            curve: Curves.easeOut,
          ).fade(duration: 300.ms),
        ]
      ],
    );
  }

  Widget _buildSynthesisSockets(bool isPrefix) {
    // 2. FITTEDBOX TO PREVENT RENDERFLEX OVERFLOWS
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isPrefix) _buildDynamicSocket(),
          if (isPrefix) SizedBox(width: 8.w),
          _buildRootBlock(),
          if (!isPrefix) SizedBox(width: 8.w),
          if (!isPrefix) _buildDynamicSocket(),
        ],
      ),
    );
  }

  // 3. TRUE ANIMATION (Sockets render the selected piece immediately)
  Widget _buildDynamicSocket() {
    if (selectedAffix != null) {
      // Show the selected affix snapping into the socket
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            )
          ],
        ),
        child: Text(
          selectedAffix!.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ).animate().scale(begin: const Offset(1.3, 1.3), end: const Offset(1.0, 1.0), duration: 250.ms, curve: Curves.easeOutBack);
    }

    // Default Empty Socket
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
    // 4. FIX HINT SYSTEM (Visual glow for correct piece)
    final bool isHinted = hintedAffix == affix;
    
    Widget piece = GestureDetector(
      onTap: () {
        if (selectedAffix == null) {
          onAffixSelected(affix);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isHinted ? primaryColor : primaryColor.withValues(alpha: 0.3),
            width: isHinted ? 3 : 2,
          ),
          boxShadow: isHinted
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.6),
                    blurRadius: 16,
                    spreadRadius: 4,
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
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );

    if (isHinted) {
      piece = piece.animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05), duration: 500.ms);
    }

    return piece;
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
     .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack, duration: 400.ms)
     .shimmer(color: Colors.white.withValues(alpha: 0.5), duration: 800.ms, delay: 200.ms);
  }
}
