import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/daily_challenges/word_mixer/domain/models/word_mixer_puzzle.dart';

/// Collapsible clue card featuring anti-leak masked definitions and TTS auditory reading.
class WordMixerHintCard extends StatefulWidget {
  final WordMixerPuzzle puzzle;
  final ValueNotifier<bool> isExpanded;
  final Color primaryColor;
  final HapticService? hapticService;
  final TtsService? ttsService;

  const WordMixerHintCard({
    super.key,
    required this.puzzle,
    required this.isExpanded,
    this.primaryColor = IllustrationColors.richPurple,
    this.hapticService,
    this.ttsService,
  });

  @override
  State<WordMixerHintCard> createState() => _WordMixerHintCardState();
}

class _WordMixerHintCardState extends State<WordMixerHintCard> {
  late final HapticService _hapticService =
      widget.hapticService ?? di.sl<HapticService>();
  late final TtsService _ttsService =
      widget.ttsService ?? di.sl<TtsService>();
  bool _isSpeaking = false;

  @override
  void dispose() {
    if (_isSpeaking) {
      _ttsService.stop();
    }
    super.dispose();
  }

  Future<void> _speakDefinition() async {
    _hapticService.light();
    if (_isSpeaking) {
      await _ttsService.stop();
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }

    setState(() => _isSpeaking = true);
    try {
      // Strip out the blank masks for natural TTS pronunciation
      final cleanText = widget.puzzle.maskedHint.replaceAll('______', 'the word');
      await _ttsService.speak(cleanText);
    } finally {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<bool>(
      valueListenable: widget.isExpanded,
      builder: (context, expanded, _) {
        return GestureDetector(
          onTap: () {
            _hapticService.light();
            widget.isExpanded.value = !widget.isExpanded.value;
          },
          child: AnimatedContainer(
            duration: 300.ms,
            curve: Curves.easeInOut,
            width: double.infinity,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: widget.primaryColor.withValues(
                  alpha: expanded ? 0.4 : 0.15,
                ),
                width: expanded ? 1.5 : 1,
              ),
              boxShadow: expanded
                  ? [
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: AppColors.amber500.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text('💡', style: TextStyle(fontSize: 14.sp)),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        expanded
                            ? context.tr('home.hint', fallback: 'Hint & Definition')
                            : context.tr(
                                'home.tap_for_hint',
                                fallback: 'Tap to reveal definition clue',
                              ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: expanded
                              ? widget.primaryColor
                              : (isDark ? Colors.white60 : Colors.black45),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: 300.ms,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? Colors.white38 : Colors.black38,
                        size: 20.r,
                      ),
                    ),
                  ],
                ),

                // Expanded clue content
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: EdgeInsets.only(top: 14.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Definition text with anti-leak protection
                        Text(
                          widget.puzzle.maskedHint,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.85)
                                : Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Action pill row: First letter clue + TTS speaker button
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 8.h,
                          children: [
                            // First letter pill
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: widget.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                '${context.tr('home.starts_with', fallback: 'Starts with')}: ${widget.puzzle.firstLetter}',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: widget.primaryColor,
                                ),
                              ),
                            ),

                            // TTS Auditory button
                            Semantics(
                              button: true,
                              label: context.tr('common.listen', fallback: 'Listen to clue'),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _speakDefinition,
                                  borderRadius: BorderRadius.circular(16.r),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 5.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isSpeaking
                                              ? Icons.volume_up_rounded
                                              : Icons.volume_down_rounded,
                                          size: 16.r,
                                          color: widget.primaryColor,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          _isSpeaking
                                              ? context.tr('common.stop', fallback: 'Stop')
                                              : context.tr('common.listen', fallback: 'Listen'),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: widget.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  crossFadeState:
                      expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: 300.ms,
                  sizeCurve: Curves.easeInOut,
                ),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05, duration: 400.ms);
  }
}
