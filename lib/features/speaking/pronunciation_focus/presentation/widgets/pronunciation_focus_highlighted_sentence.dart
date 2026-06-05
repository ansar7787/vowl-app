import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class PronunciationFocusHighlightedSentence extends StatelessWidget {
  final SpeakingQuest quest;
  final Color primaryColor;
  final bool isDark;

  const PronunciationFocusHighlightedSentence({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
  });

  List<Widget> _buildHighlightedSentence(String text, String targetPhoneme, bool isDark) {
    final soundService = di.sl<SoundService>();
    final words = text.split(' ');
    final String phonemeChar = targetPhoneme.replaceAll('[', '').replaceAll(']', '').toLowerCase();

    return words.map((word) {
      final String cleanWord = word.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
      final bool hasPhoneme = cleanWord.contains(phonemeChar) && phonemeChar.isNotEmpty;

      return GestureDetector(
        onTap: () => soundService.playTts(word),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: hasPhoneme
                ? (isDark ? Colors.orange[900]!.withValues(alpha: 0.25) : Colors.orange[100]!)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: hasPhoneme
                  ? Colors.orangeAccent.withValues(alpha: 0.6)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: hasPhoneme
                ? [
                    BoxShadow(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                      blurRadius: 6,
                    )
                  ]
                : [],
          ),
          child: Text(
            word,
            style: TextStyle(fontFamily: 'Outfit', 
              fontSize: 18.sp,
              fontWeight: hasPhoneme ? FontWeight.bold : FontWeight.w500,
              color: hasPhoneme
                  ? Colors.orangeAccent
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final soundService = di.sl<SoundService>();

    return GlassTile(
      padding: EdgeInsets.all(22.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "HEATMAP SENTENCE (TAP TO LISTEN)",
                style: TextStyle(fontFamily: 'RobotoMono', 
                  fontSize: 10.sp,
                  color: Colors.grey,
                ),
              ),
              ScaleButton(
                onTap: () => soundService.playTts(quest.textToSpeak ?? ""),
                child: Icon(Icons.volume_up_rounded, color: primaryColor, size: 18.r),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4.w,
            runSpacing: 4.h,
            children: _buildHighlightedSentence(
              quest.textToSpeak ?? "",
              quest.targetPhoneme ?? "",
              isDark,
            ),
          ),
        ],
      ),
    );
  }
}
