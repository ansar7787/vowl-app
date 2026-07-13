import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_state.dart';
import 'package:vowl/core/utils/locale_service.dart';

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

  const AccentFeedbackCard({
    super.key,
    required this.state,
    required this.isDark,
    required this.isCorrect,
    required this.onContinue,
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
    final explanation = showExplanation ? state.currentQuest.explanation : null;

    final buttonText = success
        ? context.tr('common.continue_text', fallback: 'Continue').toUpperCase()
        : (state.isFinalFailure
              ? (lives == 0
                    ? context.tr('games.see_results', fallback: 'See Results')
                    : context.tr('common.continue_text', fallback: 'Continue').toUpperCase())
              : context.tr('games.try_again', fallback: 'Try Again').toUpperCase());

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
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
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
            Container(
                  width: 342.w,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: shadowColor.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: shadowColor.withValues(alpha: 0.3),
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
                              color: shadowColor,
                              size: 16.r,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            context.tr('games.explanation_caps', fallback: 'EXPLANATION'),
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
                      SizedBox(height: 6.h),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 120.h),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Semantics(
                            label:
                                '${context.tr('games.explanation', fallback: 'Explanation')}: $explanation',
                            child: Text(
                              explanation ??
                                  (success
                                      ? "Excellent listening! You correctly identified the precise sound."
                                      : "Keep practicing! Pay close attention to the subtle differences in these sounds."),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark
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
                .fadeIn(delay: 300.ms)
                .slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
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
            delay: 500.ms,
            duration: 400.ms,
            curve: Curves.elasticOut,
          ),
        ],
      ),
    ).animate().slideY(
      begin: 1,
      end: 0,
      curve: Curves.easeOutCubic,
      duration: 500.ms,
    );
  }
}
