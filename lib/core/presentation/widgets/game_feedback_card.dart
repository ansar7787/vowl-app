import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/core/presentation/widgets/pedagogical_rule_box.dart';

/// A universal feedback card to be used across all game categories.
/// Consolidates duplicate feedback card patterns.
class GameFeedbackCard extends StatelessWidget {
  /// Whether the last answer was correct. Drives color scheme and copy.
  final bool? isCorrect;

  /// Whether the question has reached its final failure (mastery re-queue).
  final bool isFinalFailure;

  /// How many lives the user has remaining.
  final int livesRemaining;

  /// Called when the user taps the primary action button.
  final VoidCallback onContinue;

  /// Called when the user taps "Pass to Tutor" (optional, used in some games).
  final VoidCallback? onTutorPass;

  /// Whether the app is currently in dark mode.
  final bool isDark;

  /// The primary color of the game theme (used for accents if needed).
  final Color primaryColor;

  /// The explanation for the answer (usually shown on success or final failure).
  final String? explanation;

  /// Optional: a specific pedagogical rule title (e.g. "GRAMMAR RULE").
  final String? ruleTitle;

  /// Optional: the content of the pedagogical rule.
  final String? ruleContent;

  /// Optional: a sample answer (used in writing games).
  final String? sampleAnswer;

  /// Optional: required points for an answer (used in writing games).
  final List<String>? requiredPoints;

  const GameFeedbackCard({
    super.key,
    required this.isCorrect,
    required this.isFinalFailure,
    required this.livesRemaining,
    required this.onContinue,
    this.onTutorPass,
    required this.isDark,
    required this.primaryColor,
    this.explanation,
    this.ruleTitle,
    this.ruleContent,
    this.sampleAnswer,
    this.requiredPoints,
  });

  static const _successGradient = [Color(0xFF2DD4BF), Color(0xFF10B981)];
  static const _failGradient = [Color(0xFFF43F5E), Color(0xFFE11D48)];
  static const _successShadow = Color(0xFF10B981);
  static const _failShadow = Color(0xFFE11D48);

  @override
  Widget build(BuildContext context) {
    if (isCorrect == null && !isFinalFailure) return const SizedBox.shrink();

    final success = isCorrect ?? false;
    final gradient = success ? _successGradient : _failGradient;
    final shadowColor = success ? _successShadow : _failShadow;
    final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;

    final title = success
        ? context.tr('games.excellent', fallback: 'Excellent!')
        : context.tr('games.not_quite', fallback: 'Not Quite');

    final buttonText = success
        ? context.tr('common.continue_text', fallback: 'Continue').toUpperCase()
        : (livesRemaining <= 0
              ? context
                    .tr('common.see_results', fallback: 'See Results')
                    .toUpperCase()
              : (isFinalFailure
                    ? context
                          .tr('common.continue_text', fallback: 'Continue')
                          .toUpperCase()
                    : context
                          .tr('games.try_again', fallback: 'Try Again')
                          .toUpperCase()));

    final bool showEducationalInfo = success || isFinalFailure;

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

                if (showEducationalInfo &&
                    ruleContent != null &&
                    ruleContent!.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  PedagogicalRuleBox(
                    icon: Icons.menu_book_rounded,
                    capsKey: '',
                    capsFallback: ruleTitle ?? 'RULE',
                    titleKey: '',
                    titleFallback: ruleTitle ?? 'Rule',
                    rule: ruleContent!,
                    shadowColor: shadowColor,
                    isDark: isDark,
                  ),
                ],

                if (showEducationalInfo &&
                    explanation != null &&
                    explanation!.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  _ExplanationCard(
                    originalExplanation: explanation!,
                    accentColor: shadowColor,
                    isDark: isDark,
                  ),
                ],

                if (showEducationalInfo &&
                    sampleAnswer != null &&
                    sampleAnswer!.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  PedagogicalRuleBox(
                    icon: Icons.lightbulb_outline_rounded,
                    capsKey: 'games.sample_answer_caps',
                    capsFallback: 'SAMPLE ANSWER',
                    titleKey: 'games.sample_answer',
                    titleFallback: 'Sample Answer',
                    rule: sampleAnswer!,
                    shadowColor: shadowColor,
                    isDark: isDark,
                  ),
                ],

                if (showEducationalInfo &&
                    requiredPoints != null &&
                    requiredPoints!.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  PedagogicalRuleBox(
                    icon: Icons.checklist_rounded,
                    capsKey: 'games.required_points_caps',
                    capsFallback: 'REQUIRED POINTS',
                    titleKey: 'games.required_points',
                    titleFallback: 'Required Points',
                    rule: requiredPoints!.join("\n• "),
                    shadowColor: shadowColor,
                    isDark: isDark,
                  ),
                ],

                SizedBox(height: 28.h),
                _buildActionButton(buttonText, gradient, shadowColor),

                if (onTutorPass != null && isFinalFailure) ...[
                  SizedBox(height: 16.h),
                  ScaleButton(
                    onTap: onTutorPass,
                    child: Text(
                      context.tr(
                        'games.pass_to_tutor',
                        fallback: 'Pass to Tutor',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: shadowColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
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
        ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
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
            delay: 150.ms,
            duration: 300.ms,
            curve: Curves.elasticOut,
          ),
    );
  }
}

class _ExplanationCard extends StatefulWidget {
  final String originalExplanation;
  final Color accentColor;
  final bool isDark;

  const _ExplanationCard({
    required this.originalExplanation,
    required this.accentColor,
    required this.isDark,
  });

  @override
  State<_ExplanationCard> createState() => _ExplanationCardState();
}

class _ExplanationCardState extends State<_ExplanationCard> {
  String? _translatedText;

  @override
  Widget build(BuildContext context) {
    final displayText = _translatedText ?? widget.originalExplanation;
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
                  Text(
                    context.tr(
                      'games.explanation_caps',
                      fallback: 'EXPLANATION',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: widget.accentColor,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  if (_translatedText == null)
                    TranslateButtonWidget(
                      originalText: widget.originalExplanation,
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
        )
        .animate()
        .fadeIn(delay: 100.ms)
        .slideY(
          begin: 0.2,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutBack,
        );
  }
}
