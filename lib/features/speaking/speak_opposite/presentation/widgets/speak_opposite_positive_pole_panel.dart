import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

/// Display panel presenting the given word pole and contextual example sentence.
class SpeakOppositePositivePolePanel extends StatelessWidget {
  /// Word whose opposite is sought.
  final String targetWord;

  /// Example contextual sentence illustrating the word.
  final String contextText;

  /// Primary theme accent color.
  final Color primaryColor;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Callback executed to trigger word pronunciation TTS audio.
  final VoidCallback onPlayTts;

  /// Creates a [SpeakOppositePositivePolePanel].
  const SpeakOppositePositivePolePanel({
    super.key,
    required this.targetWord,
    required this.contextText,
    required this.primaryColor,
    required this.isDark,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      key: const Key('speak_opposite_positive_pole_panel'),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Semantics(
                  header: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.school_rounded,
                        color: primaryColor,
                        size: 15.r,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          "GIVEN WORD",
                          key: const Key('speak_opposite_given_word_label'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF475569),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Semantics(
                label: 'Listen to the target word',
                button: true,
                child: ScaleButton(
                  key: const Key('speak_opposite_listen_button'),
                  onTap: onPlayTts,
                  child: Container(
                    padding: EdgeInsets.all(7.r),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.25),
                        width: 1.w,
                      ),
                    ),
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: primaryColor,
                      size: 18.r,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Container(
            key: const Key('speak_opposite_target_word_container'),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.5),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Semantics(
              container: true,
              label: 'Target word to find opposite: $targetWord',
              child: Text(
                targetWord,
                key: const Key('speak_opposite_target_word_text'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          if (contextText.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text(
              contextText,
              key: const Key('speak_opposite_context_text'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.82)
                    : const Color(0xFF334155),
                height: 1.45,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          SizedBox(height: 20.h),
          Divider(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.08,
            ),
            height: 1.h,
          ),
          SizedBox(height: 14.h),
          Row(
            key: const Key('speak_opposite_mic_hint'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic_rounded,
                color: isDark ? Colors.white54 : Colors.black45,
                size: 16.r,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  "Hold mic to say the opposite",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
