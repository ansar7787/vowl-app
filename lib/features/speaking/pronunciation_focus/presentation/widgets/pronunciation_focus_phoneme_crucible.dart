import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/audio_recording_service.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color1f1c2c = Color(0xFF1F1C2C);
  static const Color colorff512f = Color(0xFFFF512F);
  static const Color color928dab = Color(0xFF928DAB);
  static const Color colordd2476 = Color(0xFFDD2476);
}

/// Phoneme crucible card isolating specific phonemes with articulatory guide toggles.
class PronunciationFocusPhonemeCrucible extends StatelessWidget {
  /// Active speaking quest entity.
  final SpeakingQuest quest;

  /// Primary theme accent color.
  final Color primaryColor;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Acoustic heat intensity level (0.0 to 1.0).
  final double heatLevel;

  /// Whether the articulatory mouth/tongue guide is expanded.
  final bool showGuide;

  /// Callback executed when toggling the phoneme pronunciation guide.
  final VoidCallback onToggleGuide;

  /// Creates a [PronunciationFocusPhonemeCrucible].
  const PronunciationFocusPhonemeCrucible({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
    required this.heatLevel,
    required this.showGuide,
    required this.onToggleGuide,
  });

  @override
  Widget build(BuildContext context) {
    final String targetSound = quest.targetPhoneme ?? "[r]";
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return GlassTile(
      padding: EdgeInsets.all(20.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "TARGET SOUND",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              ScaleButton(
                key: const Key('pronunciation_focus_position_guide_button'),
                onTap: onToggleGuide,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.orangeAccent.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        color: Colors.orangeAccent,
                        size: 14.r,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        "Sound Guide",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Core phoneme badge with comparison pronunciation
          ScaleButton(
            key: const Key('pronunciation_focus_target_phoneme_badge_btn'),
            onTap: () {
              if (di.sl<AudioRecordingService>().isRecording) return;
              final word = quest.targetWord ?? quest.textToSpeak ?? targetSound;
              di.sl<SoundService>().playTtsComparison(word);
            },
            child: Semantics(
              label: "Target phonetic sound: $targetSound. Tap to compare pronunciation.",
              button: true,
              child: Container(
                key: const Key('pronunciation_focus_target_phoneme_badge'),
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(
                        _LocalPalette.color1f1c2c,
                        _LocalPalette.colorff512f,
                        heatLevel,
                      )!,
                      Color.lerp(
                        _LocalPalette.color928dab,
                        _LocalPalette.colordd2476,
                        heatLevel,
                      )!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Color.lerp(
                        primaryColor,
                        Colors.orangeAccent,
                        heatLevel,
                      )!.withValues(alpha: 0.3 + heatLevel * 0.2),
                      blurRadius: 12.r + heatLevel * 8.r,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  targetSound,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              )
                  .animate(
                    target: reduceMotion ? 0 : 1,
                    onPlay: (c) =>
                        reduceMotion ? c.stop() : c.repeat(reverse: true),
                  )
                  .slideY(
                    begin: -0.04,
                    end: 0.04,
                    duration: const Duration(milliseconds: 1500),
                  ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Tap sound to hear normal & slow speeds",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox(),
            secondChild: Padding(
              padding: EdgeInsets.only(top: 14.h),
              child: Column(
                children: [
                  Divider(
                    color: isDark ? Colors.white12 : Colors.black12,
                    height: 20.h,
                  ),
                  InkWell(
                    onTap: () {
                      if (di.sl<AudioRecordingService>().isRecording) return;
                      final word = quest.targetWord ?? quest.textToSpeak ?? targetSound;
                      di.sl<SoundService>().playTts(word, speed: 0.28);
                    },
                    borderRadius: BorderRadius.circular(10.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.volume_up_rounded,
                            color: Colors.orangeAccent,
                            size: 16.r,
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              quest.phoneticHint ??
                                  "Listen closely and focus on how this sound is pronounced.",
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : const Color(0xFF1E293B),
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (quest.pronunciationTips != null &&
                      quest.pronunciationTips!.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Colors.amberAccent,
                          size: 15.r,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            quest.pronunciationTips!,
                            softWrap: true,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.5.sp,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF334155),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (quest.commonMistakes != null &&
                      quest.commonMistakes!.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orangeAccent,
                          size: 15.r,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            "Watch out: ${quest.commonMistakes!.join(', ')}",
                            softWrap: true,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.orangeAccent
                                  : const Color(0xFFD97706),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: showGuide
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
