import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

/// Panel displaying contextual sentences with visually highlighted target synonym words.
class SpeakSynonymSentencePanel extends StatelessWidget {
  /// Active speaking quest entity.
  final SpeakingQuest quest;

  /// Primary theme accent color.
  final Color primaryColor;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Callback executed to play pronunciation audio.
  final VoidCallback onPlayTts;

  /// Creates a [SpeakSynonymSentencePanel].
  const SpeakSynonymSentencePanel({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    final String fullText = quest.textToSpeak ?? "";
    final List<String> segments = fullText.split('*');
    final String cleanText = fullText.replaceAll('*', '');

    final tokens = Theme.of(context).extension<AppColorTokens>();
    final Color sentenceTextColor = tokens?.textPrimary ??
        (isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF1E293B));

    return Semantics(
      container: true,
      label: 'Sentence: $cleanText',
      child: GlassTile(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
        borderRadius: BorderRadius.circular(24.r),
        child: Column(
          children: [
            Semantics(
              container: true,
              child: SizedBox(
                width: double.infinity,
                child: RichText(
                  key: const Key('speak_synonym_rich_text'),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      color: sentenceTextColor,
                      height: 1.5,
                    ),
                    children: segments.asMap().entries.map((e) {
                      final bool isTarget = e.key % 2 != 0;
                      if (isTarget) {
                        return WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            key: Key('speak_synonym_target_chip_${e.key}'),
                            margin: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 2.h,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.5),
                                width: 1.5.w,
                              ),
                            ),
                            child: Text(
                              e.value,
                              key: Key('speak_synonym_target_text_${e.key}'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return TextSpan(text: e.value);
                      }
                    }).toList(),
                  ),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            ScaleButton(
              key: const Key('speak_synonym_listen_button'),
              onTap: onPlayTts,
              child: Semantics(
                button: true,
                label: 'Listen to sentence',
                child: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: primaryColor,
                    size: 22.r,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
