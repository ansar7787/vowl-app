import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color1e1e2c = Color(0xFF1E1E2C);
}

/// Audition question card presenting the statement or query for yes/no evaluation.
class YesNoSpeakingAuditionCard extends StatelessWidget {
  /// Active speaking quest entity.
  final SpeakingQuest quest;

  /// Primary theme accent color.
  final Color primaryColor;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Callback executed to trigger question speech audio.
  final VoidCallback onPlayTts;

  /// Creates a [YesNoSpeakingAuditionCard].
  const YesNoSpeakingAuditionCard({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    final sampleAnswerText = quest.sampleAnswer ?? "";

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: isDark ? _LocalPalette.color1e1e2c : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "LISTEN & MATCH",
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    color: primaryColor,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              ScaleButton(
                key: const Key('yes_no_speaking_replay_button'),
                onTap: onPlayTts,
                child: Semantics(
                  button: true,
                  label: 'Replay audio prompt',
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.volume_up_rounded,
                          color: primaryColor,
                          size: 16.r,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          "LISTEN AGAIN",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            "WRITTEN SENTENCE",
            key: const Key('yes_no_speaking_target_card_label'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: isDark ? Colors.white54 : AppColors.slate500,
            ),
          ),
          SizedBox(height: 6.h),
          Semantics(
            container: true,
            label: 'Target sentence: $sampleAnswerText',
            child: Text(
              sampleAnswerText,
              key: const Key('yes_no_speaking_target_text'),
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.slate900,
                height: 1.4,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
