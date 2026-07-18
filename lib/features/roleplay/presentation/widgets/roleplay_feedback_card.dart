import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';

/// Bottom-sheet card shown when [isAnswered] is true.
///
/// Tapping the action button calls [onContinue]; the button label and content
/// adapt automatically based on [state] and [isCorrect].
///
/// Wrapped in [RepaintBoundary] internally so the slide-up animation does not
/// trigger repaints in parent layers.
class RoleplayFeedbackCard extends StatelessWidget {
  const RoleplayFeedbackCard({
    super.key,
    required this.state,
    required this.lives,
    required this.isCorrect,
    required this.isDark,
    required this.onContinue,
    this.onTutorPass,
  });

  final RoleplayState state;
  final int lives;
  final bool? isCorrect;
  final bool isDark;
  final VoidCallback onContinue;
  final VoidCallback? onTutorPass;

  @override
  Widget build(BuildContext context) {
    // Type-safe access — never force-cast the abstract RoleplayState.
    final loadedState = state is RoleplayLoaded
        ? state as RoleplayLoaded
        : null;

    final success = isCorrect ?? false;
    final isFinal = loadedState?.isFinalFailure ?? false;

    final gradient = success
        ? const [Color(0xFF2DD4BF), Color(0xFF10B981)]
        : const [Color(0xFFF43F5E), Color(0xFFE11D48)];
    final shadowColor = success
        ? const Color(0xFF10B981)
        : const Color(0xFFE11D48);
    final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;
    final title = success
        ? context.tr('games.excellent', fallback: 'Excellent!')
        : context.tr('games.not_quite', fallback: 'Not Quite');
    final buttonText = success
        ? context.tr('common.continue_text', fallback: 'Continue').toUpperCase()
        : (isFinal
              ? (lives == 0
                    ? context.tr('games.see_results', fallback: 'See Results')
                    : context
                          .tr('common.continue_text', fallback: 'Continue')
                          .toUpperCase())
              : context
                    .tr('games.try_again', fallback: 'Try Again')
                    .toUpperCase());
    final explanation = (success || isFinal)
        ? loadedState?.currentQuest.explanation
        : null;

    return RepaintBoundary(
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
                Semantics(
                  label: success
                      ? context.tr('games.correct', fallback: 'Correct')
                      : (isFinal
                            ? '${context.tr('games.incorrect', fallback: 'Incorrect')} ${explanation != null ? context.tr('games.explanation', fallback: 'Explanation') : ''}'
                            : context.tr(
                                'games.semantic_incorrect_try_again',
                                fallback: 'Incorrect. Tap to try again.',
                              )),
                  child: _ResultHeader(
                    icon: icon,
                    title: title,
                    gradient: gradient,
                  ),
                ),
                if (explanation != null) ...[
                  SizedBox(height: 16.h),
                  _ExplanationCard(
                    explanation: explanation,
                    shadowColor: shadowColor,
                    isDark: isDark,
                  ),
                ],
                SizedBox(height: 28.h),
                Semantics(
                  button: true,
                  label: buttonText,
                  hint: 'Double tap to $buttonText',
                  child: _ActionButton(
                    text: buttonText,
                    gradient: gradient,
                    shadowColor: shadowColor,
                    onTap: onContinue,
                  ),
                ),
                if (!success && onTutorPass != null) ...[
                  SizedBox(height: 12.h),
                  _TutorPassButton(
                    onTap: onTutorPass!,
                    accentColor: shadowColor,
                  ),
                ],
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

// ── Private sub-widgets ────────────────────────────────────────────────────

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({
    required this.icon,
    required this.title,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final List<Color> gradient;

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
        SizedBox(width: 16.r),
        Expanded(
          child: ShaderMask(
            shaderCallback: (bounds) =>
                LinearGradient(colors: gradient).createShader(bounds),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white, // masked by shader
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── ─────────────────────────────────────────────────────────────────────────

class _ExplanationCard extends StatefulWidget {
  const _ExplanationCard({
    required this.explanation,
    required this.shadowColor,
    required this.isDark,
  });

  final String explanation;
  final Color shadowColor;
  final bool isDark;

  @override
  State<_ExplanationCard> createState() => _ExplanationCardState();
}

class _ExplanationCardState extends State<_ExplanationCard> {
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
                Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: widget.shadowColor,
                        size: 14.r,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ExcludeSemantics(
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
        )
        .animate()
        .fadeIn(delay: 300.ms)
        .scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}

// ── ─────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.text,
    required this.gradient,
    required this.shadowColor,
    required this.onTap,
  });

  final String text;
  final List<Color> gradient;
  final Color shadowColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        // minHeight instead of fixed height supports accessibility text scaling.
        constraints: BoxConstraints(minHeight: 65.h),
        padding: EdgeInsets.symmetric(vertical: 16.h),
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
            text,
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
    );
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

