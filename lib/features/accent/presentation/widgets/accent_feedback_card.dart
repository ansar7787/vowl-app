import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_state.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/pedagogical_rule_box.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';

/// Slide-up feedback card shown after a player submits an answer.
///
/// Accepts a typed [AccentLoaded] state — the call site must guard with
/// `state is AccentLoaded` before creating this widget, which eliminates
/// all unsafe `state as AccentLoaded` casts.
class AccentFeedbackCard extends StatelessWidget {
  /// The current game state at the moment the answer was submitted.
  final AccentLoaded state;

  final bool isDark;

  /// Whether the last submitted answer was correct.
  final bool? isCorrect;

  /// Called when the player taps CONTINUE / TRY AGAIN / SEE RESULTS.
  final VoidCallback onContinue;
  final VoidCallback? onTutorPass;

  const AccentFeedbackCard({
    super.key,
    required this.state,
    required this.isDark,
    required this.isCorrect,
    required this.onContinue,
    this.onTutorPass,
  });

  @override
  Widget build(BuildContext context) {
    final success = isCorrect ?? false;
    final lives = state.livesRemaining;

    final primaryGradient = success
        ? const [Color(0xFF2DD4BF), Color(0xFF10B981)]
        : const [Color(0xFFF43F5E), Color(0xFFE11D48)];
    final shadowColor = success
        ? const Color(0xFF10B981)
        : const Color(0xFFE11D48);

    final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;
    final title = success
        ? context.tr('games.excellent', fallback: 'Excellent!')
        : context.tr('games.not_quite', fallback: 'Not Quite');

    // Explanation is shown on correct answers and on the final failure attempt.
    final showExplanation = success || (!success && state.isFinalFailure);
    final explanationText =
        state.currentQuest.explanation ??
        (success
            ? "Excellent listening! You correctly identified the precise sound."
            : "Keep practicing! Pay close attention to the subtle differences in these sounds.");

    final buttonText = success
        ? context.tr('common.continue_text', fallback: 'Continue').toUpperCase()
        : (state.isFinalFailure
              ? (lives == 0
                    ? context.tr('games.see_results', fallback: 'See Results')
                    : context
                          .tr('common.continue_text', fallback: 'Continue')
                          .toUpperCase())
              : context
                    .tr('games.try_again', fallback: 'Try Again')
                    .toUpperCase());

    return Container(
      width: 342.w,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Result row ─────────────────────────────────────────────────
          Row(
            children: [
              ExcludeSemantics(
                // Decorative icon — label is on the title text below.
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: primaryGradient),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28.r),
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Semantics(
                  header: true,
                  label: success
                      ? context.tr('games.correct', fallback: 'Correct')
                      : context.tr('games.incorrect', fallback: 'Incorrect'),
                  child: ExcludeSemantics(
                    // Gradient-painted text is not readable by TalkBack/VoiceOver;
                    // the parent Semantics node carries the accessible label.
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        foreground: Paint()
                          ..shader = LinearGradient(
                            colors: primaryGradient,
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Explanation (Mastery Loop only) ────────────────────────────
          if (showExplanation) ...[
            SizedBox(height: 16.h),
            _ExplanationBox(
              explanation: explanationText,
              shadowColor: shadowColor,
              isDark: isDark,
            ),

            // Dynamic generation of all possible pedagogical rules.
            // When new games add new fields, simply add them to this list.
            ...[
              if (state.currentQuest.phoneticRule != null)
                (
                  icon: Icons.psychology_rounded,
                  capsKey: 'games.phonetic_rule_caps',
                  capsFallback: 'PHONETIC RULE',
                  titleKey: 'games.phonetic_rule',
                  titleFallback: 'Phonetic Rule',
                  rule: state.currentQuest.phoneticRule!,
                ),
              if (state.currentQuest.mouthPosition != null)
                (
                  icon: Icons.face_retouching_natural_rounded,
                  capsKey: 'games.mouth_position_caps',
                  capsFallback: 'MOUTH POSITION',
                  titleKey: 'games.mouth_position',
                  titleFallback: 'Mouth Position',
                  rule: state.currentQuest.mouthPosition!,
                ),
              if (state.currentQuest.dialectNote != null)
                (
                  icon: Icons.public,
                  capsKey: 'games.dialect_note_caps',
                  capsFallback: 'DIALECT NOTE',
                  titleKey: 'games.dialect_note',
                  titleFallback: 'Dialect Note',
                  rule: state.currentQuest.dialectNote!,
                ),
              if (state.currentQuest.pitchRule != null)
                (
                  icon: Icons.show_chart,
                  capsKey: 'games.pitch_rule_caps',
                  capsFallback: 'PITCH RULE',
                  titleKey: 'games.pitch_rule',
                  titleFallback: 'Pitch Rule',
                  rule: state.currentQuest.pitchRule!,
                ),
              if (state.currentQuest.vowelTensionRule != null)
                (
                  icon: Icons.waves_rounded,
                  capsKey: 'games.vowel_tension_caps',
                  capsFallback: 'VOWEL TENSION',
                  titleKey: 'games.vowel_tension',
                  titleFallback: 'Vowel Tension',
                  rule: state.currentQuest.vowelTensionRule!,
                ),
              if (state.currentQuest.modulationPattern != null)
                (
                  icon: Icons.graphic_eq_rounded,
                  capsKey: 'games.modulation_pattern_caps',
                  capsFallback: 'MODULATION PATTERN',
                  titleKey: 'games.modulation_pattern',
                  titleFallback: 'Modulation Pattern',
                  rule: state.currentQuest.modulationPattern!,
                ),
              if (state.currentQuest.emphasisRule != null)
                (
                  icon: Icons.priority_high_rounded,
                  capsKey: 'games.emphasis_rule_caps',
                  capsFallback: 'EMPHASIS RULE',
                  titleKey: 'games.emphasis_rule',
                  titleFallback: 'Emphasis Rule',
                  rule: state.currentQuest.emphasisRule!,
                ),
              if (state.currentQuest.flowRule != null)
                (
                  icon: Icons.water_drop_rounded,
                  capsKey: 'games.flow_rule_caps',
                  capsFallback: 'FLOW RULE',
                  titleKey: 'games.flow_rule',
                  titleFallback: 'Flow Rule',
                  rule: state.currentQuest.flowRule!,
                ),
              if (state.currentQuest.pacingRule != null)
                (
                  icon: Icons.speed_rounded,
                  capsKey: 'games.pacing_rule_caps',
                  capsFallback: 'PACING RULE',
                  titleKey: 'games.pacing_rule',
                  titleFallback: 'Pacing Rule',
                  rule: state.currentQuest.pacingRule!,
                ),
              if (state.currentQuest.stressRule != null)
                (
                  icon: Icons.compress_rounded,
                  capsKey: 'games.stress_rule_caps',
                  capsFallback: 'STRESS RULE',
                  titleKey: 'games.stress_rule',
                  titleFallback: 'Stress Rule',
                  rule: state.currentQuest.stressRule!,
                ),
            ].map(
              (ruleData) => Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: PedagogicalRuleBox(
                  icon: ruleData.icon,
                  capsKey: ruleData.capsKey,
                  capsFallback: ruleData.capsFallback,
                  titleKey: ruleData.titleKey,
                  titleFallback: ruleData.titleFallback,
                  rule: ruleData.rule,
                  shadowColor: shadowColor,
                  isDark: isDark,
                ),
              ),
            ),
          ],

          SizedBox(height: 28.h),

          // ── CTA button ─────────────────────────────────────────────────
          Semantics(
            label: buttonText,
            button: true,
            child: ScaleButton(
              onTap: onContinue,
              child: Container(
                width: 342.w,
                height: 65.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: primaryGradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: ExcludeSemantics(
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ).animate().scale(
            delay: 150.ms,
            duration: 300.ms,
            curve: Curves.elasticOut,
          ),
          if (!success && onTutorPass != null) ...[
            SizedBox(height: 12.h),
            _TutorPassButton(onTap: onTutorPass!, accentColor: shadowColor),
          ],
        ],
      ),
    ).animate().slideY(
      begin: 1,
      end: 0,
      curve: Curves.easeOutCubic,
      duration: 350.ms,
    );
  }
}

class _ExplanationBox extends StatefulWidget {
  final String explanation;
  final Color shadowColor;
  final bool isDark;

  const _ExplanationBox({
    required this.explanation,
    required this.shadowColor,
    required this.isDark,
  });

  @override
  State<_ExplanationBox> createState() => _ExplanationBoxState();
}

class _TutorPassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color accentColor;

  const _TutorPassButton({required this.onTap, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: accentColor, size: 14.r),
            SizedBox(width: 8.w),
            Text(
              context
                  .tr('games.i_spoke_correctly', fallback: 'I spoke correctly')
                  .toUpperCase(),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: accentColor,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationBoxState extends State<_ExplanationBox> {
  String? _translatedText;

  @override
  Widget build(BuildContext context) {
    final displayText = _translatedText ?? widget.explanation;

    return Container(
          width: 342.w,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: widget.shadowColor.withValues(
              alpha: widget.isDark ? 0.12 : 0.08,
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: widget.shadowColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      color: widget.shadowColor,
                      size: 16.r,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      context.tr(
                        'games.explanation_caps',
                        fallback: 'EXPLANATION',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        color: widget.shadowColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  if (_translatedText == null)
                    TranslateButtonWidget(
                      originalText: widget.explanation,
                      onTranslationComplete: (translated) {
                        if (mounted) {
                          setState(() => _translatedText = translated);
                        }
                      },
                    ),
                ],
              ),
              SizedBox(height: 6.h),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 120.h),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Semantics(
                    label:
                        '${context.tr('games.explanation', fallback: 'Explanation')}: $displayText',
                    child: Text(
                      displayText,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 100.ms)
        .slideY(
          begin: 0.2,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutBack,
        );
  }
}
