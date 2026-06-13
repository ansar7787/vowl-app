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
    final title = success ? context.tr('games.excellent') : context.tr('games.not_quite');

    // Explanation is only shown on the second wrong attempt (Mastery Loop).
    final showExplanation = !success && state.isFinalFailure;
    final explanation = showExplanation ? state.currentQuest.explanation : null;

    final buttonText = success
        ? context.tr('common.continue_text').toUpperCase()
        : (state.isFinalFailure
              ? (lives == 0 ? context.tr('games.see_results') : context.tr('common.continue_text').toUpperCase())
              : context.tr('games.try_again').toUpperCase());

    return Container(
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
                      ? context.tr('games.correct')
                      : context.tr('games.incorrect'),
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
          if (explanation != null) ...[
            SizedBox(height: 16.h),
            Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: shadowColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: shadowColor.withValues(alpha: 0.2),
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
                              Icons.info_outline_rounded,
                              color: shadowColor,
                              size: 14.r,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            context.tr('games.explanation_caps'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: shadowColor,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      // maxLines guards against long explanations overflowing on
                      // small phones or at large accessibility text scale factors.
                      Semantics(
                        label: '${context.tr('games.explanation')}: $explanation',
                        child: Text(
                          explanation,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 300.ms)
                .scale(duration: 400.ms, curve: Curves.easeOutBack),
          ],

          SizedBox(height: 28.h),

          // ── CTA button ─────────────────────────────────────────────────
          Semantics(
            label: buttonText,
            button: true,
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
