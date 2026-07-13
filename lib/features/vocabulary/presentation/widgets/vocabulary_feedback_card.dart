import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';

class VocabularyFeedbackCard extends StatelessWidget {
  final VocabularyState state;
  final bool isDark;
  final bool? isCorrect;
  final bool isFinalFailure;
  final VoidCallback onContinue;

  const VocabularyFeedbackCard({
    super.key,
    required this.state,
    required this.isDark,
    required this.isCorrect,
    required this.isFinalFailure,
    required this.onContinue,
  });

  String? _resolveCorrectAnswer(VocabularyLoaded s) {
    final q = s.currentQuestOrNull;
    if (q == null) return null;
    if (q.interactionType == InteractionType.flip) return q.meaning;
    if (q.correctAnswerIndex != null &&
        q.options != null &&
        q.correctAnswerIndex! < q.options!.length) {
      return q.options![q.correctAnswerIndex!];
    }
    return q.correctAnswer ?? q.word;
  }

  @override
  Widget build(BuildContext context) {
    if (state is! VocabularyLoaded) return const SizedBox.shrink();
    final s = state as VocabularyLoaded;

    final success = isCorrect ?? false;
    final lives = s.livesRemaining;

    const successGradient = [Color(0xFF2DD4BF), Color(0xFF10B981)];
    const failureGradient = [Color(0xFFF43F5E), Color(0xFFE11D48)];
    const successShadow = Color(0xFF10B981);
    const failureShadow = Color(0xFFE11D48);

    final List<Color> gradient = success ? successGradient : failureGradient;
    final Color shadowColor = success ? successShadow : failureShadow;
    final IconData icon = success
        ? Icons.check_circle_rounded
        : Icons.error_rounded;
    final String title = success
        ? context.tr('games.excellent', fallback: 'Excellent!')
        : context.tr('games.not_quite', fallback: 'Not Quite');
    final bool showCorrectAnswer = !success && s.isFinalFailure;
    final String buttonText = success
        ? context.tr('common.continue_text', fallback: 'Continue').toUpperCase()
        : (s.isFinalFailure
              ? (lives == 0
                    ? context.tr('common.see_results', fallback: 'See Results').toUpperCase()
                    : context.tr('common.continue_text', fallback: 'Continue').toUpperCase())
              : context.tr('games.try_again', fallback: 'Try Again').toUpperCase());

    final correctAnswerText = showCorrectAnswer
        ? _resolveCorrectAnswer(s)
        : null;

    // RepaintBoundary prevents the BackdropFilter compositing layer from
    // being invalidated by ancestor/sibling widget repaints (e.g. mascot
    // animations, BLoC state changes).
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
        child:
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(28.r),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(40.r),
                  ),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Header row ──────────────────────────────────────
                      _FeedbackHeader(
                        title: title,
                        icon: icon,
                        gradient: gradient,
                      ),

                      // ── Correct answer box ──────────────────────────────
                      if (correctAnswerText != null) ...[
                        SizedBox(height: 16.h),
                        _CorrectAnswerBox(
                          text: correctAnswerText,
                          color: shadowColor,
                          isDark: isDark,
                        ),
                      ],

                      // ── Explanation box ─────────────────────────────────
                      if (s.currentQuestOrNull?.explanation != null &&
                          (success || s.isFinalFailure)) ...[
                        SizedBox(height: 16.h),
                        _ExplanationBox(
                          explanation: s.currentQuestOrNull!.explanation!,
                          accentColor: shadowColor,
                          isDark: isDark,
                        ),
                      ],

                      SizedBox(height: 28.h),

                      // ── Continue / Try Again button ─────────────────────
                      _ContinueButton(
                        label: buttonText,
                        gradient: gradient,
                        shadowColor: shadowColor,
                        onTap: onContinue,
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().slideY(
              begin: 1,
              end: 0,
              curve: Curves.easeOutCubic,
              duration: 500.ms,
            ),
      ),
    );
  }
}

// ─── Private sub-widgets ──────────────────────────────────────────────────────

class _FeedbackHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradient;

  const _FeedbackHeader({
    required this.title,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 28.r),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        SizedBox(width: 16.w),
        // LayoutBuilder measures the available width so the gradient shader
        // matches the exact text bounds instead of a hardcoded value.
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final shader = LinearGradient(
                colors: gradient,
              ).createShader(Rect.fromLTWH(0, 0, constraints.maxWidth, 70));
              return Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  foreground: Paint()..shader = shader,
                  letterSpacing: 1.5,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CorrectAnswerBox extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;

  const _CorrectAnswerBox({
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CORRECT ANSWER:',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                text,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20.sp,
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

class _ExplanationBox extends StatefulWidget {
  final String explanation;
  final Color accentColor;
  final bool isDark;

  const _ExplanationBox({
    required this.explanation,
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
    final displayText = _translatedText ?? widget.explanation;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: widget.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18.r,
            color: widget.accentColor.withValues(alpha: 0.7),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              displayText,
              maxLines: 15,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: widget.isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
            ),
          ),
          if (_translatedText == null) ...[
            SizedBox(width: 8.w),
            TranslateButtonWidget(
              originalText: widget.explanation,
              onTranslationComplete: (translated) {
                if (mounted) setState(() => _translatedText = translated);
              },
            ),
          ]
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
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
      button: true,
      label: label,
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          width: double.infinity,
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
      ),
    ).animate().scale(
      delay: 500.ms,
      duration: 400.ms,
      curve: Curves.elasticOut,
    );
  }
}
