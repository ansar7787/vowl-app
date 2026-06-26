import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/elite_mastery/domain/entities/elite_mastery_quest.dart';

import '../bloc/elite_mastery_bloc.dart';
import 'package:vowl/core/utils/locale_service.dart';

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
      _success ? context.tr('games.excellent') : context.tr('games.not_quite');

  IconData get _icon =>
      _success ? Icons.check_circle_rounded : Icons.error_rounded;

  String _buttonLabel(BuildContext context) {
    if (_success) return context.tr('common.continue_text').toUpperCase();
    if (state.isFinalFailure) {
      return state.livesRemaining == 0
          ? context.tr('games.see_results')
          : context.tr('common.continue_text').toUpperCase();
    }
    return context.tr('games.try_again').toUpperCase();
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final showCorrectAnswer = !_success && state.isFinalFailure;
    final correctAnswerText = showCorrectAnswer
        ? _resolveCorrectAnswer(state.currentQuest)
        : null;

    // Curriculum "why" note (e.g. the stress/linking/intonation rule behind
    // the sentence). Shown on both success and failure — reinforcing the
    // underlying rule regardless of outcome is more valuable for retention
    // than only explaining mistakes.
    final ruleTip = state.currentQuest.explanation;
    final hasRuleTip = ruleTip != null && ruleTip.trim().isNotEmpty;

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
                      text: ruleTip!,
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
      buffer.write(context.tr('games.semantic_correct_continue'));
    } else if (correctAnswerText != null) {
      buffer.write(
        context.tr(
          'games.semantic_incorrect_explanation',
          args: [correctAnswerText, _buttonLabel(context)],
        ),
      );
    } else {
      buffer.write(context.tr('games.semantic_incorrect_try_again'));
    }
    if (ruleTip != null) {
      buffer
        ..write(' ')
        ..write(context.tr('games.the_rule_caps'))
        ..write(': ')
        ..write(ruleTip);
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

class _ExplanationBox extends StatelessWidget {
  final String text;
  final Color accentColor;
  final bool isDark;

  const _ExplanationBox({
    required this.text,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.2),
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
                    color: accentColor,
                    size: 14.r,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    context.tr('games.explanation_caps'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
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
class _RuleTipBox extends StatelessWidget {
  final String text;
  final Color accentColor;
  final bool isDark;

  const _RuleTipBox({
    required this.text,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: accentColor, size: 14.r),
                  SizedBox(width: 8.w),
                  Text(
                    context.tr('games.the_rule_caps'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
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
              // minimum touch-target requirement of 44dp.
              height: 65.h,
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
