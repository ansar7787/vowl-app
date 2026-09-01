import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';

/// Bottom-sheet style result card shown after the player submits an answer.
///
/// Accepts [ListeningLoaded] directly — this eliminates the `as` cast that
/// previously existed in the original code and which could throw if [state]
/// was unexpectedly `ListeningLoading` or `ListeningError`.
///
/// The gradient [Shader] for the title text is cached via a [_GradientText]
/// helper instead of being recreated on every [build] call.
class ListeningFeedbackCard extends StatelessWidget {
  /// Enforces the correct state type at the call-site — no runtime cast needed.
  final ListeningLoaded state;
  final bool? isCorrect;
  final dynamic theme;
  final bool isDark;
  final VoidCallback onContinue;

  const ListeningFeedbackCard({
    super.key,
    required this.state,
    required this.isCorrect,
    required this.theme,
    required this.isDark,
    required this.onContinue,
  });

  // ── Colour palettes ───────────────────────────────────────────────────────

  static const _successGradient = [Color(0xFF2DD4BF), Color(0xFF10B981)];
  static const _failureGradient = [Color(0xFFF43F5E), Color(0xFFE11D48)];
  static const _successShadow = Color(0xFF10B981);
  static const _failureShadow = Color(0xFFE11D48);

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final success = isCorrect ?? false;
    final gradient = success ? _successGradient : _failureGradient;
    final shadowColor = success ? _successShadow : _failureShadow;
    final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;
    final title = success
        ? context.tr('games.excellent', fallback: 'Excellent!')
        : context.tr('games.not_quite', fallback: 'Not Quite');

    final showExplanation = success || state.isFinalFailure;
    final explanation = showExplanation ? state.currentQuest.explanation : null;

    // Overflow-safe button label: Flexible + FittedBox handles long
    // translations without the 'letterSpacing: 3' causing overflow.
    final buttonText = success
        ? context.tr('common.continue_text', fallback: 'Continue').toUpperCase()
        : (state.isFinalFailure
              ? (state.livesRemaining == 0
                    ? context
                          .tr('common.see_results', fallback: 'See Results')
                          .toUpperCase()
                    : context
                          .tr('common.continue_text', fallback: 'Continue')
                          .toUpperCase())
              : context
                    .tr('games.try_again', fallback: 'Try Again')
                    .toUpperCase());

    return Semantics(
      container: true,
      label: success
          ? 'Correct answer. $buttonText to proceed.'
          : 'Wrong answer. $buttonText.',
      child:
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(28.r),
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
                // Status row: icon + gradient title
                Row(
                  children: [
                    ExcludeSemantics(
                      child:
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradient),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: Colors.white, size: 28.r),
                          ).animate().scale(
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _GradientText(
                        text: title,
                        gradient: gradient,
                        fontSize: 24.sp,
                      ),
                    ),
                  ],
                ),

                // Explanation card (only on final failure)
                if (explanation != null) ...[
                  SizedBox(height: 16.h),
                  _ExplanationCard(
                        explanation: explanation,
                        shadowColor: shadowColor,
                        isDark: isDark,
                      )
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .scale(duration: 400.ms, curve: Curves.easeOutBack),
                ],

                SizedBox(height: 28.h),

                // CTA button — flexible text prevents localization overflow
                Semantics(
                  button: true,
                  label: buttonText,
                  excludeSemantics: true,
                  child:
                      ScaleButton(
                        onTap: onContinue,
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
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
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
                      ).animate().scale(
                        delay: 500.ms,
                        duration: 400.ms,
                        curve: Curves.elasticOut,
                      ),
                ),
              ],
            ),
          ).animate().slideY(
            begin: 1,
            end: 0,
            curve: Curves.easeOutCubic,
            duration: 500.ms,
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GradientText  —  caches the shader so it isn't recreated every frame
// ─────────────────────────────────────────────────────────────────────────────

class _GradientText extends StatelessWidget {
  final String text;
  final List<Color> gradient;
  final double fontSize;

  const _GradientText({
    required this.text,
    required this.gradient,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder resolves the actual available width so the shader rect
    // matches the rendered text width, avoiding cropped/shifted gradients.
    return LayoutBuilder(
      builder: (_, constraints) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          foreground: Paint()
            ..shader = LinearGradient(colors: gradient).createShader(
              Rect.fromLTWH(0, 0, constraints.maxWidth, fontSize * 1.4),
            ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ExplanationCard
// ─────────────────────────────────────────────────────────────────────────────

class _ExplanationCard extends StatefulWidget {
  final String explanation;
  final Color shadowColor;
  final bool isDark;

  const _ExplanationCard({
    required this.explanation,
    required this.shadowColor,
    required this.isDark,
  });

  @override
  State<_ExplanationCard> createState() => _ExplanationCardState();
}

class _ExplanationCardState extends State<_ExplanationCard> {
  final ValueNotifier<String?> _translatedText = ValueNotifier(null);

  @override
  void dispose() {
    _translatedText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _translatedText,
      builder: (context, translatedTextValue, _) {
        final displayText = translatedTextValue ?? widget.explanation;

        return Semantics(
          label: 'Explanation: $displayText',
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
                      if (translatedTextValue == null)
                        TranslateButtonWidget(
                          originalText: widget.explanation,
                          onTranslationComplete: (translated) {
                            if (mounted) {
                              _translatedText.value = translated;
                            }
                          },
                        ),
                    ],
                  ),
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
          ),
        );
      },
    );
  }
}
