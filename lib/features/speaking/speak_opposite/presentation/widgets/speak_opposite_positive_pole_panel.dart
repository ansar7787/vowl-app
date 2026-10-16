import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SpeakOppositePositivePolePanel extends StatelessWidget {
  final String targetWord;
  final String contextText;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onPlayTts;

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
      padding: EdgeInsets.all(22.r),
      borderRadius: BorderRadius.circular(26.r),
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
                      Icon(Icons.school_rounded, color: primaryColor, size: 14.r),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          "GIVEN WORD",
                          key: const Key('speak_opposite_given_word_label'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            color: Colors.grey.shade400,
                            letterSpacing: 1.0,
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
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: primaryColor,
                    size: 18.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Container(
            key: const Key('speak_opposite_target_word_container'),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.6),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Semantics(
              label: 'Target word to find opposite: $targetWord',
              child: Text(
                targetWord,
                key: const Key('speak_opposite_target_word_text'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 1.2,
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
                fontSize: 14.sp,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          SizedBox(height: 24.h),
          Divider(color: Colors.grey.withValues(alpha: 0.2)),
          SizedBox(height: 16.h),
          Row(
            key: const Key('speak_opposite_mic_hint'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic_rounded, color: Colors.grey, size: 16.r),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  "Hold mic to say the opposite",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    color: Colors.grey,
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
