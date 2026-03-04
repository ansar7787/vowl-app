import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  MpFocusBadge — Shows phoneme focus (e.g. "Focus: /ɪ/")
// ═══════════════════════════════════════════════════════════════════════════

class MpFocusBadge extends StatelessWidget {
  final String phoneme;
  final bool isDark;
  final Color primaryColor;

  const MpFocusBadge({
    super.key,
    required this.phoneme,
    required this.isDark,
    required this.primaryColor,
  });

  static const _blue = Color(0xFF3B82F6);
  static const _purple = Color(0xFF8B5CF6);

  static final _labelStyle = GoogleFonts.outfit(
    fontWeight: FontWeight.w900,
    letterSpacing: 4,
  );
  static final _focusStyle = GoogleFonts.outfit(
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );

  @override
  Widget build(BuildContext context) {
    if (phoneme.isEmpty) {
      return Text(
        'MINIMAL PAIRS',
        style: _labelStyle.copyWith(fontSize: 12.sp, color: primaryColor),
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _blue.withValues(alpha: 0.15),
            _purple.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hearing_rounded, size: 16.r, color: _blue),
          SizedBox(width: 8.w),
          Text(
            'Focus: $phoneme',
            style: _focusStyle.copyWith(
              fontSize: 13.sp,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MpFeedbackPanel — Shows "Good!" / "Not quite" with hint text
// ═══════════════════════════════════════════════════════════════════════════

class MpFeedbackPanel extends StatelessWidget {
  final bool isCorrect;
  final String hint;
  final bool isDark;

  const MpFeedbackPanel({
    super.key,
    required this.isCorrect,
    required this.hint,
    required this.isDark,
  });

  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFF43F5E);

  static final _titleStyle = GoogleFonts.outfit(fontWeight: FontWeight.w800);
  static final _bodyStyle = GoogleFonts.outfit(fontWeight: FontWeight.w500);

  @override
  Widget build(BuildContext context) {
    final c = isCorrect ? _green : _red;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: c.withValues(alpha: isCorrect ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: c.withValues(alpha: isCorrect ? 0.3 : 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect
                ? Icons.sentiment_satisfied_alt_rounded
                : Icons.sentiment_dissatisfied_rounded,
            color: c,
            size: 28.r,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Good!' : 'Not quite',
                  style: _titleStyle.copyWith(fontSize: 17.sp, color: c),
                ),
                if (hint.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    isCorrect ? hint : 'Listen again. $hint',
                    style: _bodyStyle.copyWith(
                      fontSize: 13.sp,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3, duration: 300.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MpRepeatButton — Purple "REPEAT" button for TTS replay
// ═══════════════════════════════════════════════════════════════════════════

class MpRepeatButton extends StatelessWidget {
  final VoidCallback onTap;

  const MpRepeatButton({super.key, required this.onTap});

  static const _purple = Color(0xFF8B5CF6);
  static final _style = GoogleFonts.outfit(
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_purple.withValues(alpha: 0.9), _purple],
            ),
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: _purple.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.replay_rounded, color: Colors.white, size: 22.r),
              SizedBox(width: 10.w),
              Text('REPEAT', style: _style.copyWith(fontSize: 16.sp)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.4, duration: 400.ms);
  }
}
