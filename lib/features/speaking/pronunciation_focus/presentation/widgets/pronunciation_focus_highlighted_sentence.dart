import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/audio_recording_service.dart';

/// Sentence card highlighting target phonemes with interactive word-level pronunciation.
class PronunciationFocusHighlightedSentence extends StatelessWidget {
  /// Active speaking quest entity.
  final SpeakingQuest quest;

  /// Primary theme accent color.
  final Color primaryColor;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Creates a [PronunciationFocusHighlightedSentence].
  const PronunciationFocusHighlightedSentence({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
  });

  List<Widget> _buildHighlightedSentence(
    String text,
    String targetPhoneme,
    bool isDark,
  ) {
    final soundService = di.sl<SoundService>();
    final words = text.split(' ');
    final String phonemeChar = targetPhoneme
        .replaceAll('[', '')
        .replaceAll(']', '')
        .toLowerCase();

    return words.asMap().entries.map((entry) {
      final index = entry.key;
      final word = entry.value;
      final String cleanWord = word
          .replaceAll(RegExp(r'[^\w]'), '')
          .toLowerCase();
      final bool hasPhoneme =
          cleanWord.contains(phonemeChar) && phonemeChar.isNotEmpty;

      return Semantics(
        button: true,
        label: "Word: $word. Tap to listen to pronunciation.",
        child: GestureDetector(
          key: Key('pronunciation_focus_word_$index'),
          onTap: () {
            if (di.sl<AudioRecordingService>().isRecording) return;
            soundService.playTts(word);
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: hasPhoneme
                  ? (isDark
                      ? Colors.orange[900]!.withValues(alpha: 0.3)
                      : Colors.orange[100]!)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: hasPhoneme
                    ? Colors.orangeAccent.withValues(alpha: 0.7)
                    : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: hasPhoneme
                  ? [
                      BoxShadow(
                        color: Colors.orangeAccent.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              word,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: hasPhoneme ? FontWeight.w700 : FontWeight.w500,
                color: hasPhoneme
                    ? (isDark ? Colors.orangeAccent : const Color(0xFFC2410C))
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : const Color(0xFF1E293B)),
              ),
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
      padding: EdgeInsets.all(20.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PRACTICE SENTENCE",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "Tap any word to hear pronunciation",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              ScaleButton(
                key: const Key('pronunciation_focus_sentence_tts_button'),
                onTap: () {
                  if (di.sl<AudioRecordingService>().isRecording) return;
                  soundService.playTts(quest.textToSpeak ?? "");
                },
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: primaryColor,
                    size: 18.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6.w,
            runSpacing: 6.h,
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
