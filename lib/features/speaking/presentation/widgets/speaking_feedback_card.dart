import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';

/// Bottom-sheet style feedback card shown after each answer.
///
/// Handles three outcomes:
///   • Correct answer → green card, context.tr('common.continue_text', fallback: 'Continue').toUpperCase() button.
///   • First wrong answer → red card, context.tr('games.try_again', fallback: 'Try Again').toUpperCase() button.
///   • Final failure (2nd wrong or 0 lives) → red card, explanation,
///     context.tr('common.continue_text', fallback: 'Continue').toUpperCase() or context.tr('common.see_results', fallback: 'See Results').toUpperCase() depending on lives remaining.
///
/// All interactive and informational elements carry [Semantics] labels
/// for full screen-reader compatibility.
class SpeakingFeedbackCard extends StatelessWidget {
  final bool success;
  final int livesRemaining;
  final bool isFinalFailure;

  /// The correct answer explanation shown on final failure. May be null.
  final String? explanation;

  final VoidCallback onContinue;
  final bool isDark;

  const SpeakingFeedbackCard({
    super.key,
    required this.success,
    required this.livesRemaining,
    required this.isFinalFailure,
    required this.onContinue,
    required this.isDark,
    this.explanation,
  });

  // ---------------------------------------------------------------------------
  // Derived values
  // ---------------------------------------------------------------------------

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
    if (isFinalFailure) {
      return livesRemaining == 0
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
    if (isFinalFailure) {
      return livesRemaining == 0
          ? context.tr(
              'games.semantic_incorrect_explanation',
              args: [
                '',
                context.tr('games.see_results', fallback: 'See Results'),
              ],
            )
          : context.tr(
              'games.semantic_incorrect_explanation',
              args: [
                '',
                context.tr('common.continue_text', fallback: 'Continue'),
              ],
            );
    }
    return context.tr(
      'games.semantic_incorrect_try_again',
      fallback: 'Incorrect. Tap to try again.',
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
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
              explanation: explanation!,
              shadowColor: _shadowColor,
              isDark: isDark,
            ),
          ],
          SizedBox(height: 28.h),
          _buildContinueButton(context),
        ],
      ),
    ).animate().slideY(
      begin: 1,
      end: 0,
      curve: Curves.easeOutCubic,
      duration: 500.ms,
    );
  }

  // ---------------------------------------------------------------------------
  // Result row: icon + title
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Explanation box (shown on final failure only)
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Continue / Try-again button
  // ---------------------------------------------------------------------------

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
              color: widget.shadowColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: widget.shadowColor.withValues(alpha: 0.2),
                width: 1.5,
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
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: widget.shadowColor,
                            letterSpacing: 1,
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
                SizedBox(height: 4.h),
                ExcludeSemantics(
                  child: Text(
                    displayText,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms)
        .scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}
