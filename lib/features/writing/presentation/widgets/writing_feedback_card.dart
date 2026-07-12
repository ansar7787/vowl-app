import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';

// ---------------------------------------------------------------------------
// WritingFeedbackCard
//
// Extracted from _buildModernFeedbackCard in WritingBaseLayout.
// Slides up from the bottom when a question is answered.
// Self-contained: owns its own gradient, icon, explanation, and CTA button.
// ---------------------------------------------------------------------------

class WritingFeedbackCard extends StatelessWidget {
  final WritingState state;
  final bool? isCorrect;
  final VoidCallback onContinue;
  final bool isDark;
  final dynamic theme;

  const WritingFeedbackCard({
    super.key,
    required this.state,
    required this.isCorrect,
    required this.onContinue,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Guard: card is only meaningful in WritingLoaded.
    // Any other state returns empty — prevents cast crash on rapid transitions.
    if (state is! WritingLoaded) return const SizedBox.shrink();

    final s = state as WritingLoaded;
    final success = isCorrect ?? false;
    final lives = s.livesRemaining;
    final isFinalFailure = s.isFinalFailure;

    final primaryGradient = success
        ? const [Color(0xFF2DD4BF), Color(0xFF10B981)]
        : const [Color(0xFFF43F5E), Color(0xFFE11D48)];
    final shadowColor = success
        ? const Color(0xFF10B981)
        : const Color(0xFFE11D48);
    final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;
    final title = success
        ? context.tr('games.excellent')
        : context.tr('games.not_quite');

    final showCorrectAnswer = !success && isFinalFailure;
    final buttonText = success
        ? context.tr('common.continue_text').toUpperCase()
        : (isFinalFailure
              ? (lives == 0
                    ? context.tr('common.see_results').toUpperCase()
                    : context.tr('common.continue_text').toUpperCase())
              : context.tr('games.try_again').toUpperCase());

    final String? explanation = showCorrectAnswer
        ? s.currentQuest.explanation
        : null;

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
          _Header(icon: icon, title: title, gradient: primaryGradient),
          if (explanation != null) ...[
            SizedBox(height: 16.h),
            _ExplanationCard(
              explanation: explanation,
              color: shadowColor,
              isDark: isDark,
            ),
          ],
          SizedBox(height: 28.h),
          _ContinueButton(
            label: buttonText,
            gradient: primaryGradient,
            shadowColor: shadowColor,
            onTap: onContinue,
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

// ---------------------------------------------------------------------------
// Private sub-widgets — not exposed outside this file
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Color> gradient;

  const _Header({
    required this.icon,
    required this.title,
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
          // ACCESSIBILITY: mark icon as decorative; the title text conveys meaning.
          child: ExcludeSemantics(
            child: Icon(icon, color: Colors.white, size: 28.r),
          ),
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
}

class _ExplanationCard extends StatelessWidget {
  final String explanation;
  final Color color;
  final bool isDark;

  const _ExplanationCard({
    required this.explanation,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
          label: 'Explanation: $explanation',
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // ACCESSIBILITY: purely decorative icon beside the label
                    ExcludeSemantics(
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: color,
                        size: 14.r,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // ACCESSIBILITY: wrap in MediaQuery clamp so small label
                    // doesn't overflow at 2× text scale on accessibility settings.
                    Flexible(
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: TextScaler.linear(
                            MediaQuery.of(
                              context,
                            ).textScaler.scale(1).clamp(0.8, 1.3),
                          ),
                        ),
                        child: Text(
                          context.tr('games.explanation_caps'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: color,
                            letterSpacing: 1,
                          ),
                        ),
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
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms)
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
