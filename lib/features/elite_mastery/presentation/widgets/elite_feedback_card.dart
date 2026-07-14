import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/elite_mastery/domain/entities/elite_mastery_quest.dart';

import '../bloc/elite_mastery_bloc.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';

/// Bottom-sheet feedback card displayed after the player answers a question.
///
/// Extracted from [EliteBaseLayout] to:
///  - Accept a concrete [EliteMasteryLoaded] type — eliminating the
///    runtime `TypeError` risk from the old `(state as EliteMasteryLoaded)` casts.
///  - Contain `RepaintBoundary` around the animated status icon so the
///    elastic-scale animation doesn't propagate repaints across the backdrop.
///  - Provide a rich `Semantics` node so screen readers announce the result
///    and the available action in a single focused pass.
///  - Isolate answer-resolution logic in `_resolveCorrectAnswer` —
///    adding a new [GameSubtype] only requires one new `if` branch there.
class EliteFeedbackCard extends StatelessWidget {
  /// The current loaded game state — guaranteed non-null at the call site.
  final EliteMasteryLoaded state;

  /// Result of the player's last submission.  `null` before any answer.
  final bool? isCorrect;

  final VoidCallback onContinue;

  final bool isDark;

  const EliteFeedbackCard({
    super.key,
    required this.state,
    required this.isCorrect,
    required this.onContinue,
    required this.isDark,
  });

  // ── Derived values ──────────────────────────────────────────────────────

  bool get _success => isCorrect ?? false;

  List<Color> get _gradient => _success
      ? const [Color(0xFF2DD4BF), Color(0xFF10B981)]
      : const [Color(0xFFF43F5E), Color(0xFFE11D48)];

  Color get _shadowColor =>
      _success ? const Color(0xFF10B981) : const Color(0xFFE11D48);

  String _title(BuildContext context) =>
      _success ? context.tr('games.excellent', fallback: 'Excellent!') : context.tr('games.not_quite', fallback: 'Not Quite');

  IconData get _icon =>
      _success ? Icons.check_circle_rounded : Icons.error_rounded;

  String _buttonLabel(BuildContext context) {
    if (_success) return context.tr('common.continue_text', fallback: 'Continue').toUpperCase();
    if (state.isFinalFailure) {
      return state.livesRemaining == 0
          ? context.tr('games.see_results', fallback: 'See Results')
          : context.tr('common.continue_text', fallback: 'Continue').toUpperCase();
    }
    return context.tr('games.try_again', fallback: 'Try Again').toUpperCase();
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ruleTip = state.currentQuest.explanation;
    final hasRuleTip =
        (_success || state.isFinalFailure) &&
        ruleTip != null &&
        ruleTip.trim().isNotEmpty;

    final showCorrectAnswer = !_success && state.isFinalFailure && !hasRuleTip;
    final correctAnswerText = showCorrectAnswer
        ? _resolveCorrectAnswer(state.currentQuest)
        : null;

    final shadowingFocus = state.currentQuest.shadowingFocus;
    final hasShadowingFocus =
        shadowingFocus != null && shadowingFocus.trim().isNotEmpty;

    final usageContext = state.currentQuest.usageContext;
    final hasUsageContext =
        usageContext != null && usageContext.trim().isNotEmpty;

    final spellingRule = state.currentQuest.spellingRule;
    final hasSpellingRule =
        spellingRule != null && spellingRule.trim().isNotEmpty;

    final sequenceLogic = state.currentQuest.sequenceLogic;
    final hasSequenceLogic =
        sequenceLogic != null && sequenceLogic.trim().isNotEmpty;

    // Curriculum "why" note (e.g. the stress/linking/intonation rule behind
    // the sentence). Shown on both success and failure — reinforcing the
    // underlying rule regardless of outcome is more valuable for retention
    // than only explaining mistakes.

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(28.r),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            // Semantics container: the screen reader announces the full
            // outcome in one pass ("Correct answer! CONTINUE") so the player
            // doesn't have to navigate through individual child nodes.
            child: Semantics(
              container: true,
              label: _buildSemanticLabel(
                context,
                correctAnswerText,
                hasRuleTip ? ruleTip : null,
              ),
              excludeSemantics: true, // children handled by the container label
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildResultRow(context),
                  if (hasRuleTip) ...[
                    SizedBox(height: 16.h),
                    _RuleTipBox(
                      text: ruleTip,
                      accentColor: _shadowColor,
                      isDark: isDark,
                    ),
                  ],
                  if (correctAnswerText != null) ...[
                    SizedBox(height: 16.h),
                    _ExplanationBox(
                      text: correctAnswerText,
                      accentColor: _shadowColor,
                      isDark: isDark,
                    ),
                  ],
                  if (hasShadowingFocus) ...[
                    SizedBox(height: 16.h),
                    _ShadowingFocusBox(
                      text: shadowingFocus,
                      accentColor: _shadowColor,
                      isDark: isDark,
                    ),
                  ],
                  if (hasUsageContext) ...[
                    SizedBox(height: 16.h),
                    _UsageContextBox(
                      text: usageContext,
                      accentColor: _shadowColor,
                      isDark: isDark,
                    ),
                  ],
                  if (hasSpellingRule) ...[
                    SizedBox(height: 16.h),
                    _SpellingRuleBox(
                      text: spellingRule,
                      accentColor: _shadowColor,
                      isDark: isDark,
                    ),
                  ],
                  if (hasSequenceLogic) ...[
                    SizedBox(height: 16.h),
                    _SequenceLogicBox(
                      text: sequenceLogic,
                      accentColor: _shadowColor,
                      isDark: isDark,
                    ),
                  ],
                  SizedBox(height: 28.h),
                  _ContinueButton(
                    label: _buttonLabel(context),
                    gradient: _gradient,
                    shadowColor: _shadowColor,
                    onTap: onContinue,
                  ),
                ],
              ),
            ),
          ),
        ),
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
        // RepaintBoundary: the elastic-scale entrance animation fires once per
        // question reveal. Isolating it avoids repainting the backdrop blur
        // and text during the animation frames.
        RepaintBoundary(
          child: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _gradient),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: Colors.white, size: 28.r),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: ShaderMask(
            // ShaderMask uses the widget's actual rendered bounds — no
            // hardcoded Rect needed, adapts to any text length or font scale.
            shaderCallback: (bounds) =>
                LinearGradient(colors: _gradient).createShader(bounds),
            child: Text(
              _title(context),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _buildSemanticLabel(
    BuildContext context,
    String? correctAnswerText,
    String? ruleTip,
  ) {
    final buffer = StringBuffer();
    if (_success) {
      buffer.write(context.tr('games.semantic_correct_continue', fallback: 'Correct. Tap to continue.'));
    } else if (correctAnswerText != null) {
      buffer.write(
        context.tr(
          'games.semantic_incorrect_explanation', fallback: 'Incorrect. Read explanation.',
          args: [correctAnswerText, _buttonLabel(context)],
        ),
      );
    } else {
      buffer.write(context.tr('games.semantic_incorrect_try_again', fallback: 'Incorrect. Tap to try again.'));
    }
    if (ruleTip != null) {
      // FIX: previously concatenated a raw label + the tip text directly
      // (`context.tr('games.pro_tip_caps', fallback: 'PRO TIP') + ruleTip`), inconsistent with
      // the properly parameterized template used a few lines above
      // (`games.semantic_incorrect_explanation`, args: [...]). Naive
      // concatenation can't be reordered for languages with different word
      // order/grammar around an inserted value. NOTE: `games.semantic_pro_tip`
      // is a new localization key needed in the ARB/localization files
      // (outside this feature slice), e.g. English: "Pro tip: {0}".
      buffer.write(context.tr('games.semantic_pro_tip', fallback: 'Pro tip available', args: [ruleTip]));
    }
    return buffer.toString();
  }

  // ── Answer resolver ─────────────────────────────────────────────────────

  /// Resolves the human-readable correct answer for [quest].
  ///
  /// Handles all currently supported [GameSubtype] variants.
  /// Adding a new subtype: insert one `if` branch here; the rendering is
  /// untouched.
  ///
  /// Bounds-safe: filters `correctOrder` indices that exceed `sentences.length`
  /// to avoid [RangeError] on malformed backend data.
  String? _resolveCorrectAnswer(EliteMasteryQuest quest) {
    // Story Builder — reconstruct sentence order
    if (quest.subtype == GameSubtype.storyBuilder &&
        quest.sentences != null &&
        quest.correctOrder != null) {
      final sentences = quest.sentences!;
      final ordered = quest.correctOrder!
          .where((i) => i >= 0 && i < sentences.length)
          .map((i) => sentences[i])
          .join(' → ');
      return ordered.isNotEmpty ? ordered : null;
    }

    // Idiom Match — answer is the meaning in the options list
    if (quest.subtype == GameSubtype.idiomMatch &&
        quest.options != null &&
        quest.correctAnswerIndex != null) {
      final idx = quest.correctAnswerIndex!;
      if (idx >= 0 && idx < quest.options!.length) {
        return quest.options![idx];
      }
    }

    // Generic fallback: word, correctAnswer field, then options
    if (quest.word != null) return quest.word;
    if (quest.correctAnswer != null) return quest.correctAnswer;
    if (quest.options != null && quest.correctAnswerIndex != null) {
      final idx = quest.correctAnswerIndex!;
      if (idx >= 0 && idx < quest.options!.length) {
        return quest.options![idx];
      }
    }
    return null;
  }
}

// ── Private sub-widgets ─────────────────────────────────────────────────────

class _ExplanationBox extends StatefulWidget {
  final String text;
  final Color accentColor;
  final bool isDark;

  const _ExplanationBox({
    required this.text,
    required this.accentColor,
    required this.isDark,
  });

  @override
  State<_ExplanationBox> createState() => _ExplanationBoxState();
}

class _ExplanationBoxState extends State<_ExplanationBox> {
  String? _translatedText;

  @override
  Widget build(BuildContext context) {
    final displayText = _translatedText ?? widget.text;

    return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: widget.accentColor,
                    size: 14.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      context.tr('games.explanation_caps', fallback: 'EXPLANATION'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: widget.accentColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (_translatedText == null)
                    TranslateButtonWidget(
                      originalText: widget.text,
                      onTranslationComplete: (translated) {
                        if (mounted) setState(() => _translatedText = translated);
                      },
                    ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                displayText,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms)
        .scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}

/// Displays the curriculum's pedagogical `explanation` (the "why" behind a
/// hint/pattern) — a previously-unused field. Uses a distinct icon and
/// caption from [_ExplanationBox] (which reveals the *correct answer*) so
/// the two boxes are never visually or semantically conflated even though
/// they share the same accent-color treatment for visual consistency.
class _RuleTipBox extends StatefulWidget {
  final String text;
  final Color accentColor;
  final bool isDark;

  const _RuleTipBox({
    required this.text,
    required this.accentColor,
    required this.isDark,
  });

  @override
  State<_RuleTipBox> createState() => _RuleTipBoxState();
}

class _RuleTipBoxState extends State<_RuleTipBox> {
  String? _translatedText;

  @override
  Widget build(BuildContext context) {
    final displayText = _translatedText ?? widget.text;

    return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: widget.accentColor, size: 14.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      context.tr('games.pro_tip_caps', fallback: 'PRO TIP'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: widget.accentColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (_translatedText == null)
                    TranslateButtonWidget(
                      originalText: widget.text,
                      onTranslationComplete: (translated) {
                        if (mounted) setState(() => _translatedText = translated);
                      },
                    ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                displayText,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 200.ms)
        .scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}

class _ShadowingFocusBox extends StatefulWidget {
  final String text;
  final Color accentColor;
  final bool isDark;

  const _ShadowingFocusBox({
    required this.text,
    required this.accentColor,
    required this.isDark,
  });

  @override
  State<_ShadowingFocusBox> createState() => _ShadowingFocusBoxState();
}

class _ShadowingFocusBoxState extends State<_ShadowingFocusBox> {
  String? _translatedText;

  @override
  Widget build(BuildContext context) {
    final displayText = _translatedText ?? widget.text;

    return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.record_voice_over_rounded,
                    color: widget.accentColor,
                    size: 14.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "SHADOWING FOCUS",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: widget.accentColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (_translatedText == null)
                    TranslateButtonWidget(
                      originalText: widget.text,
                      onTranslationComplete: (translated) {
                        if (mounted) setState(() => _translatedText = translated);
                      },
                    ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                displayText,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 250.ms)
        .scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}

class _UsageContextBox extends StatefulWidget {
  final String text;
  final Color accentColor;
  final bool isDark;

  const _UsageContextBox({
    required this.text,
    required this.accentColor,
    required this.isDark,
  });

  @override
  State<_UsageContextBox> createState() => _UsageContextBoxState();
}

class _UsageContextBoxState extends State<_UsageContextBox> {
  String? _translatedText;

  @override
  Widget build(BuildContext context) {
    final displayText = _translatedText ?? widget.text;

    return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: widget.accentColor,
                    size: 14.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "USAGE CONTEXT",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: widget.accentColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (_translatedText == null)
                    TranslateButtonWidget(
                      originalText: widget.text,
                      onTranslationComplete: (translated) {
                        if (mounted) setState(() => _translatedText = translated);
                      },
                    ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                displayText,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 250.ms)
        .scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}

class _SpellingRuleBox extends StatefulWidget {
  final String text;
  final Color accentColor;
  final bool isDark;

  const _SpellingRuleBox({
    required this.text,
    required this.accentColor,
    required this.isDark,
  });

  @override
  State<_SpellingRuleBox> createState() => _SpellingRuleBoxState();
}

class _SpellingRuleBoxState extends State<_SpellingRuleBox> {
  String? _translatedText;

  @override
  Widget build(BuildContext context) {
    final displayText = _translatedText ?? widget.text;

    return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.spellcheck_rounded,
                    color: widget.accentColor,
                    size: 14.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "SPELLING PATTERN",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: widget.accentColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (_translatedText == null)
                    TranslateButtonWidget(
                      originalText: widget.text,
                      onTranslationComplete: (translated) {
                        if (mounted) setState(() => _translatedText = translated);
                      },
                    ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                displayText,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 250.ms)
        .scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}

class _SequenceLogicBox extends StatefulWidget {
  final String text;
  final Color accentColor;
  final bool isDark;

  const _SequenceLogicBox({
    required this.text,
    required this.accentColor,
    required this.isDark,
  });

  @override
  State<_SequenceLogicBox> createState() => _SequenceLogicBoxState();
}

class _SequenceLogicBoxState extends State<_SequenceLogicBox> {
  String? _translatedText;

  @override
  Widget build(BuildContext context) {
    final displayText = _translatedText ?? widget.text;

    return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_tree_rounded,
                    color: widget.accentColor,
                    size: 14.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "LOGICAL SEQUENCE",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: widget.accentColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (_translatedText == null)
                    TranslateButtonWidget(
                      originalText: widget.text,
                      onTranslationComplete: (translated) {
                        if (mounted) setState(() => _translatedText = translated);
                      },
                    ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                displayText,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 250.ms)
        .scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}

class _ContinueButton extends StatelessWidget {
  final String label;
  final List<Color> gradient;
  final Color shadowColor;
  final VoidCallback onTap;

  const _ContinueButton({
    required this.label,
    required this.gradient,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child:
          ScaleButton(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              // 65.h gives ~48dp on a 812px reference — meets the WCAG 2.1 AA
              // minimum touch-target requirement of 44dp. FIX: on the
              // smallest realistic phone heights (~568-667 logical px),
              // ScreenUtil's proportional scaling can bring this closer to
              // ~45dp — still above the 44dp WCAG floor, but under Android
              // Material's 48dp recommendation. `math.max` guarantees the
              // full 48dp regardless of device height, while leaving the
              // value unchanged (still scaling normally) on every device
              // where 65.h already clears it.
              height: math.max(65.h, 48.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradient,
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
                child: Text(
                  label,
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
          ).animate().scale(
            delay: 500.ms,
            duration: 400.ms,
            curve: Curves.elasticOut,
          ),
    );
  }
}
