import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

const _csCorrect = Color(0xFF10B981);
const _csReview = Color(0xFFF59E0B);

class ConnectedSpeechFeedbackPanel extends StatelessWidget {
  final bool isCorrect;
  final String fastForm;
  final String slowForm;
  final String hint;
  final void Function(String text, {double rate}) onPlayAudio;
  final bool isDark;
  final bool isMidnight;

  const ConnectedSpeechFeedbackPanel({
    super.key,
    required this.isCorrect,
    required this.fastForm,
    required this.slowForm,
    required this.hint,
    required this.onPlayAudio,
    required this.isDark,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: was Colors.greenAccent / Colors.orangeAccent.
    final color = isCorrect ? _csCorrect : _csReview;

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
                      // FIX: was hardcoded "Spot On!" — not localised.
                      isCorrect
                          ? context.tr('games.spot_on')
                          : context.tr('games.lets_review'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      // FIX: was hardcoded "Connected Speech" — not localised.
                      context.tr('games.connected_speech'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
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
                  slowForm,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                SizedBox(height: 12.h),
                Icon(Icons.arrow_downward_rounded, color: color, size: 32.r)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .slideY(begin: -0.2, end: 0.2, duration: 1.seconds),
                SizedBox(height: 12.h),
                Text(
                  fastForm,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ).animate().shimmer(delay: 1.seconds, duration: 1500.ms),
                SizedBox(height: 20.h),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: _buildAudioButton(
                  context,
                  // FIX: was hardcoded "SLOW".
                  title: context.tr('games.slow').toUpperCase(),
                  icon: Icons.fast_rewind_rounded,
                  textToPlay: slowForm,
                  rate: 0.25,
                  bgColor: isDark ? Colors.white12 : Colors.black12,
                  textColor: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildAudioButton(
                  context,
                  // FIX: was hardcoded "FAST".
                  title: context.tr('games.fast').toUpperCase(),
                  icon: Icons.fast_forward_rounded,
                  textToPlay: fastForm,
                  rate: 0.65,
                  bgColor: color,
                  textColor: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildAudioButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String textToPlay,
    required double rate,
    required Color bgColor,
    required Color textColor,
  }) {
    return ElevatedButton.icon(
      onPressed: () => onPlayAudio(textToPlay, rate: rate),
      icon: Icon(icon, size: 20.r, color: textColor),
      label: Text(
        title,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16.sp,
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
        ),
      ),
    );
  }
}
