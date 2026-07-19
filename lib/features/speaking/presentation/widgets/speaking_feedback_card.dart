import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/core/presentation/widgets/pedagogical_rule_box.dart';

class SpeakingFeedbackCard extends StatelessWidget {
  final SpeakingLoaded state;
  final bool success;
  final VoidCallback onContinue;
  final VoidCallback? onTutorPass;
  final bool isDark;

  const SpeakingFeedbackCard({
    super.key,
    required this.state,
    required this.success,
    required this.onContinue,
    this.onTutorPass,
    required this.isDark,
  });

  List<Color> get _gradient => success
      ? [const Color(0xFF2DD4BF), const Color(0xFF10B981)]
      : [const Color(0xFFF43F5E), const Color(0xFFE11D48)];

  Color get _shadowColor =>
      success ? const Color(0xFF10B981) : const Color(0xFFE11D48);

  IconData get _icon =>
      success ? Icons.check_circle_rounded : Icons.error_rounded;

  String _title(BuildContext context) => success
      ? context.tr('games.excellent', fallback: 'Excellent!')
      : context.tr('games.not_quite', fallback: 'Not Quite');

  String _buttonText(BuildContext context) {
    if (success) {
      return context
          .tr('common.continue_text', fallback: 'Continue')
          .toUpperCase();
    }
    if (state.isFinalFailure) {
      return state.livesRemaining == 0
          ? context.tr('games.see_results', fallback: 'See Results')
          : context
                .tr('common.continue_text', fallback: 'Continue')
                .toUpperCase();
    }
    return context.tr('games.try_again', fallback: 'Try Again').toUpperCase();
  }

  String _buttonSemanticLabel(BuildContext context) {
    if (success) {
      return context.tr(
        'games.semantic_correct_continue',
        fallback: 'Correct. Tap to continue.',
      );
    }
    if (state.isFinalFailure) {
      return state.livesRemaining == 0
          ? context.tr(
              'games.semantic_incorrect_explanation',
              args: ['', context.tr('games.see_results', fallback: 'See Results')],
            )
          : context.tr(
              'games.semantic_incorrect_explanation',
              args: ['', context.tr('common.continue_text', fallback: 'Continue')],
            );
    }
    return context.tr(
      'games.semantic_incorrect_try_again',
      fallback: 'Incorrect. Tap to try again.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final showExplanation = success || (!success && state.isFinalFailure);
    final explanation = showExplanation ? state.currentQuest.explanation : null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(28.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
        boxShadow: [
          BoxShadow(
            color: _shadowColor.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildResultRow(context),
          
          if (explanation != null) ...[
            SizedBox(height: 16.h),
            _ExplanationBox(
              explanation: explanation,
              shadowColor: _shadowColor,
              isDark: isDark,
            ),
          ],

          if (showExplanation) ...[
            if (state.currentQuest.phoneticHint != null)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: PedagogicalRuleBox(
                  icon: Icons.psychology_rounded,
                  capsKey: 'games.phonetic_hint_caps',
                  capsFallback: 'PHONETIC HINT',
                  titleKey: 'games.phonetic_hint',
                  titleFallback: 'Phonetic Hint',
                  rule: state.currentQuest.phoneticHint!,
                  shadowColor: _shadowColor,
                  isDark: isDark,
                ),
              ),
            if (state.currentQuest.meaning != null)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: PedagogicalRuleBox(
                  icon: Icons.menu_book_rounded,
                  capsKey: 'games.meaning_caps',
                  capsFallback: 'MEANING',
                  titleKey: 'games.meaning',
                  titleFallback: 'Meaning',
                  rule: state.currentQuest.meaning!,
                  shadowColor: _shadowColor,
                  isDark: isDark,
                ),
              ),
            if (state.currentQuest.sampleUsage != null)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: PedagogicalRuleBox(
                  icon: Icons.chat_bubble_outline_rounded,
                  capsKey: 'games.sample_usage_caps',
                  capsFallback: 'SAMPLE USAGE',
                  titleKey: 'games.sample_usage',
                  titleFallback: 'Sample Usage',
                  rule: state.currentQuest.sampleUsage!,
                  shadowColor: _shadowColor,
                  isDark: isDark,
                ),
              ),
            if (state.currentQuest.partnerDialogue != null)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: PedagogicalRuleBox(
                  icon: Icons.people_outline_rounded,
                  capsKey: 'games.partner_dialogue_caps',
                  capsFallback: 'PARTNER DIALOGUE',
                  titleKey: 'games.partner_dialogue',
                  titleFallback: 'Partner Dialogue',
                  rule: state.currentQuest.partnerDialogue!,
                  shadowColor: _shadowColor,
                  isDark: isDark,
                ),
              ),
            if (state.currentQuest.acceptedSynonyms != null && state.currentQuest.acceptedSynonyms!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: _AcceptedSynonymsBox(
                  synonyms: state.currentQuest.acceptedSynonyms!,
                  shadowColor: _shadowColor,
                  isDark: isDark,
                ),
              ),
          ],

          SizedBox(height: 28.h),
          _buildContinueButton(context),
          if (!success && onTutorPass != null) ...[
            SizedBox(height: 12.h),
            _TutorPassButton(onTap: onTutorPass!, accentColor: _shadowColor),
          ],
        ],
      ),
    ).animate().slideY(
      begin: 1,
      end: 0,
      curve: Curves.easeOutCubic,
      duration: 500.ms,
    );
  }

  Widget _buildResultRow(BuildContext context) {
    return Row(
      children: [
        Semantics(
          label: success
              ? context.tr('games.correct', fallback: 'Correct')
              : context.tr('games.incorrect', fallback: 'Incorrect'),
          child: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _gradient),
              shape: BoxShape.circle,
            ),
            child: ExcludeSemantics(
              child: Icon(_icon, color: Colors.white, size: 28.r),
            ),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        SizedBox(width: 16.w),
        Expanded(
          child: Semantics(
            header: true,
            label: _title(context),
            child: ExcludeSemantics(
              child: Text(
                _title(context),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: _gradient,
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return Semantics(
      button: true,
      label: _buttonSemanticLabel(context),
      child: ScaleButton(
        onTap: onContinue,
        child: Container(
          width: double.infinity,
          height: 65.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: _shadowColor.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: ExcludeSemantics(
              child: Text(
                _buttonText(context),
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
      delay: 500.ms,
      duration: 400.ms,
      curve: Curves.elasticOut,
    );
  }
}

class _AcceptedSynonymsBox extends StatelessWidget {
  final List<String> synonyms;
  final Color shadowColor;
  final bool isDark;

  const _AcceptedSynonymsBox({
    required this.synonyms,
    required this.shadowColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342.w,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: shadowColor.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: shadowColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: shadowColor, size: 16.r),
              SizedBox(width: 8.w),
              Text(
                context.tr('games.accepted_synonyms_caps', fallback: 'ACCEPTED SYNONYMS'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: shadowColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: synonyms.map((s) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: shadowColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: shadowColor.withValues(alpha: 0.25)),
              ),
              child: Text(
                s,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
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

class _ExplanationBoxState extends State<_ExplanationBox> {
  String? _translatedText;

  @override
  Widget build(BuildContext context) {
    final displayText = _translatedText ?? widget.explanation;

    return Semantics(
          label:
              '${context.tr('games.explanation', fallback: 'Explanation')}: $displayText',
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: widget.shadowColor.withValues(alpha: widget.isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: widget.shadowColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: widget.shadowColor,
                        size: 14.r,
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
                ),
                SizedBox(height: 6.h),
                ExcludeSemantics(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutBack);
  }
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
            Icon(
              Icons.auto_awesome_rounded,
              color: accentColor,
              size: 14.r,
            ),
            SizedBox(width: 8.w),
            Text(
              context
                  .tr(
                    'games.i_spoke_correctly',
                    fallback: 'I spoke correctly',
                  )
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
