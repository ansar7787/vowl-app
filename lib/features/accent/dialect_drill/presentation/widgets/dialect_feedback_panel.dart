import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class DialectFeedbackPanel extends StatelessWidget {
  final bool isCorrect;
  final String word;
  final String britishPronunciation; // "SHED-yool"
  final String americanPronunciation; // "SKED-yool"
  final String hint;
  final Function(String text, String locale) onPlayAudio;
  final bool isDark;
  final bool isMidnight;

  const DialectFeedbackPanel({
    super.key,
    required this.isCorrect,
    required this.word,
    required this.britishPronunciation,
    required this.americanPronunciation,
    required this.hint,
    required this.onPlayAudio,
    required this.isDark,
    required this.isMidnight,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? Colors.greenAccent : Colors.orangeAccent;

    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(30.r),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
                  color: color,
                  size: 32.r,
                ).animate().scale(delay: 200.ms),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCorrect ? "Correct!" : "Let's Review",
                      style: GoogleFonts.outfit(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      "Accent Comparison",
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Transcription Text Visualization
          Container(
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              children: [
                Text(
                  word,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                SizedBox(height: 16.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "British: ",
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black45,
                      ),
                    ),
                    Text(
                      britishPronunciation,
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(
                          0xFFE94335,
                        ), // Theme generic red/crimson
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "American: ",
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black45,
                      ),
                    ),
                    Text(
                      americanPronunciation,
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4285F4), // Theme generic blue
                      ),
                    ),
                  ],
                ).animate().shimmer(delay: 500.ms, duration: 1.5.seconds),

                SizedBox(height: 20.h),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Dialect Audio Playback Buttons
          Row(
            children: [
              Expanded(
                child: _buildAudioButton(
                  title: "BRITISH",
                  icon: Icons.record_voice_over_rounded,
                  textToPlay: word,
                  locale: "en-GB",
                  bgColor: const Color(0xFFE94335).withValues(alpha: 0.1),
                  textColor: isDark
                      ? Colors.redAccent.shade100
                      : const Color(0xFFE94335),
                  borderColor: const Color(0xFFE94335).withValues(alpha: 0.3),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildAudioButton(
                  title: "AMERICAN",
                  icon: Icons.record_voice_over_rounded,
                  textToPlay: word,
                  locale: "en-US",
                  bgColor: const Color(0xFF4285F4).withValues(alpha: 0.1),
                  textColor: isDark
                      ? Colors.blueAccent.shade100
                      : const Color(0xFF4285F4),
                  borderColor: const Color(0xFF4285F4).withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildAudioButton({
    required String title,
    required IconData icon,
    required String textToPlay,
    required String locale,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return ElevatedButton.icon(
      onPressed: () => onPlayAudio(textToPlay, locale),
      icon: Icon(icon, size: 20.r, color: textColor),
      label: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: textColor,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: borderColor, width: 1.5),
        ),
      ),
    );
  }
}
