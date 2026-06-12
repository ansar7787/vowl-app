import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_state.dart';

/// Bottom-sheet feedback card shown after the user submits an answer.
///
/// Displays:
/// - Animated pass/fail icon and title
/// - Explanation / correct answer on final failure
/// - A labelled action button (Continue / Try Again / See Results)
///
/// Returns [SizedBox.shrink] for any non-[GrammarLoaded] state so the caller
/// can show it unconditionally — it self-guards.
class GrammarFeedbackCard extends StatelessWidget {
  /// The current BLoC state. Only renders for [GrammarLoaded].
  final GrammarState state;

  /// Whether the last answer was correct. Drives colour scheme and copy.
  final bool? isCorrect;

  /// Whether the question has reached its final failure (mastery re-queue).
  final bool isFinalFailure;

  /// Called when the user taps the primary action button.
  final VoidCallback onContinue;

  const GrammarFeedbackCard({
    super.key,
    required this.state,
    required this.isCorrect,
    required this.isFinalFailure,
    required this.onContinue,
  });

  // --- Theme helpers -------------------------------------------------------

  static const _successGradient = [Color(0xFF2DD4BF), Color(0xFF10B981)];
  static const _failGradient = [Color(0xFFF43F5E), Color(0xFFE11D48)];
  static const _successShadow = Color(0xFF10B981);
  static const _failShadow = Color(0xFFE11D48);

  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (state is! GrammarLoaded) return const SizedBox.shrink();
    final loaded = state as GrammarLoaded;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final success = isCorrect ?? false;
    final lives = loaded.livesRemaining;
    final gradient = success ? _successGradient : _failGradient;
    final shadowColor = success ? _successShadow : _failShadow;
    final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;
    final title = success ? 'EXCELLENT!' : 'NOT QUITE!';

    final buttonText = success
        ? 'CONTINUE'
        : (isFinalFailure
              ? (lives == 0 ? 'SEE RESULTS' : 'CONTINUE')
              : 'TRY AGAIN');

    // Build explanation string for mastery-loop failures.
    String? explanation;
    if (!success && isFinalFailure) {
      final quest = loaded.currentQuest;
      explanation =
          quest.explanation ??
          (quest.options != null && quest.correctAnswerIndex != null
              ? quest.options![quest.correctAnswerIndex!]
              : null);
    }

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildResultRow(icon, title, gradient),
                if (explanation != null) ...[
                  SizedBox(height: 16.h),
                  _buildExplanationCard(explanation, shadowColor, isDark),
                ],
                SizedBox(height: 28.h),
                _buildActionButton(buttonText, gradient, shadowColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(IconData icon, String title, List<Color> gradient) {
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
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: gradient,
                ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationCard(
    String explanation,
    Color accentColor,
    bool isDark,
  ) {
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
                    'EXPLANATION:',
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
                explanation,
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

  Widget _buildActionButton(
    String label,
    List<Color> gradient,
    Color shadowColor,
  ) {
    return Semantics(
      label: label,
      button: true,
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
