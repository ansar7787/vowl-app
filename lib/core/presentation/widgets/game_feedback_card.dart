import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/core/presentation/widgets/pedagogical_rule_box.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// Descriptor for a single pedagogical rule item (e.g. grammar rule, phonetic rule,
/// mouth position, spelling rule, sequence logic, fun fact).
class PedagogicalRuleItem {
  final IconData icon;
  final String title;
  final String rule;

  const PedagogicalRuleItem({
    required this.icon,
    required this.title,
    required this.rule,
  });
}

/// A universal, production-grade feedback card used across all 100 main games
/// and 25 kids games.
///
/// Features:
/// - Deterministic on-demand TTS audio speaker button (stops on re-tap, stops on continue,
///   never auto-shouts without user consent).
/// - Instant translation support with monetization check and download sheet.
/// - Support for single or multiple pedagogical rule boxes with rich iconography.
/// - Correct answer reveal and explanation display on final failures.
/// - 60/120 FPS hardware-accelerated animations isolated via [RepaintBoundary].
class GameFeedbackCard extends StatelessWidget {
  /// Whether the last answer was correct. Drives color scheme and copy.
  final bool? isCorrect;

  /// Whether the question has reached its final failure (mastery re-queue).
  final bool isFinalFailure;

  /// How many lives the user has remaining.
  final int livesRemaining;

  /// Called when the user taps the primary action button.
  final VoidCallback onContinue;

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

  /// Optional: multiple pedagogical rules to display (used in Accent, Elite Mastery, etc.).
  final List<PedagogicalRuleItem>? pedagogicalRules;

  /// Optional: the verified correct answer to reveal on failure.
  final String? correctAnswer;

  /// Optional: a sample answer (used in writing games).
  final String? sampleAnswer;

  /// Optional: required points for an answer (used in writing games).
  final List<String>? requiredPoints;

  /// Optional: a completely custom widget to render inside the feedback card.
  final Widget? customContent;

  /// Whether this is a 2-stage game. If true, pedagogical fields are hidden to avoid redundancy.
  final bool isTwoStageGame;

  /// Whether this game belongs to the Kids Zone (routes TTS to warm teacher cadence).
  final bool isKids;

  const GameFeedbackCard({
    super.key,
    required this.isCorrect,
    required this.isFinalFailure,
    required this.livesRemaining,
    required this.onContinue,
    required this.isDark,
    required this.primaryColor,
    this.explanation,
    this.ruleTitle,
    this.ruleContent,
    this.pedagogicalRules,
    this.correctAnswer,
    this.sampleAnswer,
    this.requiredPoints,
    this.customContent,
    this.isTwoStageGame = false,
    this.isKids = false,
  });

  static const _successGradient = [AppColors.teal400, AppColors.emerald500];
  static const _failGradient = [AppColors.rose500, AppColors.rose700];
  static const _successShadow = AppColors.emerald500;
  static const _failShadow = AppColors.rose700;

  @override
  Widget build(BuildContext context) {
    if (isCorrect == null && !isFinalFailure) return const SizedBox.shrink();

    final success = isCorrect ?? false;
    final gradient = success ? _successGradient : _failGradient;
    final shadowColor = success ? _successShadow : _failShadow;
    final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;

    final title = success
        ? context.tr('games.excellent', fallback: 'EXCELLENT!')
        : context.tr('games.not_quite', fallback: 'NOT QUITE!');

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
    final bool showPedagogicalFields = showEducationalInfo && !isTwoStageGame;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(28.r),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.95),
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
              _buildResultRow(context, icon, title, gradient),

              if (showEducationalInfo && customContent != null) ...[
                SizedBox(height: 16.h),
                customContent!,
              ],

              // Correct answer card (when available on final failure)
              if (showEducationalInfo &&
                  correctAnswer != null &&
                  correctAnswer!.trim().isNotEmpty) ...[
                SizedBox(height: 16.h),
                PedagogicalRuleBox(
                  icon: Icons.check_circle_outline_rounded,
                  capsKey: 'games.correct_answer_caps',
                  capsFallback: 'CORRECT ANSWER',
                  titleKey: 'games.correct_answer',
                  titleFallback: 'Correct Answer',
                  rule: correctAnswer!,
                  shadowColor: shadowColor,
                  isDark: isDark,
                  isKids: isKids,
                ),
              ],

              // Single pedagogical rule (Grammar, Kids Fun Fact, etc.)
              if (showPedagogicalFields &&
                  ruleContent != null &&
                  ruleContent!.trim().isNotEmpty) ...[
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
                  isKids: isKids,
                ),
              ],

              // Multiple pedagogical rules (Accent prosody, Elite Mastery patterns)
              if (showPedagogicalFields && pedagogicalRules != null) ...[
                for (final item in pedagogicalRules!) ...[
                  SizedBox(height: 16.h),
                  PedagogicalRuleBox(
                    icon: item.icon,
                    capsKey: '',
                    capsFallback: item.title.toUpperCase(),
                    titleKey: '',
                    titleFallback: item.title,
                    rule: item.rule,
                    shadowColor: shadowColor,
                    isDark: isDark,
                    isKids: isKids,
                  ),
                ],
              ],

              // Explanation card with interactive Translate & TTS Speaker buttons
              if (showEducationalInfo &&
                  explanation != null &&
                  explanation!.trim().isNotEmpty) ...[
                SizedBox(height: 16.h),
                _ExplanationCard(
                  originalExplanation: explanation!,
                  accentColor: shadowColor,
                  isDark: isDark,
                  isKids: isKids,
                ),
              ],

              if (showPedagogicalFields &&
                  sampleAnswer != null &&
                  sampleAnswer!.trim().isNotEmpty) ...[
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
                  isKids: isKids,
                ),
              ],

              if (showPedagogicalFields &&
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
                  isKids: isKids,
                ),
              ],

              SizedBox(height: 28.h),
              _buildActionButton(context, buttonText, gradient, shadowColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(
    BuildContext context,
    IconData icon,
    String title,
    List<Color> gradient,
  ) {
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;
    final iconWidget = Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 28.r),
    );

    return Row(
      children: [
        RepaintBoundary(
          child: reduceMotion
              ? iconWidget
              : iconWidget.animate().scale(
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: AutoSizeText(
            title,
            minFontSize: 14,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: gradient,
                ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    List<Color> gradient,
    Color shadowColor,
  ) {
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;

    final button = ScaleButton(
      onTap: () {
        TtsSpeakerButtonWidget.stopAll();
        onContinue();
      },
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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: AutoSizeText(
              label,
              minFontSize: 10,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );

    return RepaintBoundary(
      child: Semantics(
        label: label,
        button: true,
        child: reduceMotion
            ? button
            : button.animate().scale(
                delay: 150.ms,
                duration: 300.ms,
                curve: Curves.elasticOut,
              ),
      ),
    );
  }
}

class _ExplanationCard extends StatefulWidget {
  final String originalExplanation;
  final Color accentColor;
  final bool isDark;
  final bool isKids;

  const _ExplanationCard({
    required this.originalExplanation,
    required this.accentColor,
    required this.isDark,
    this.isKids = false,
  });

  @override
  State<_ExplanationCard> createState() => _ExplanationCardState();
}

class _ExplanationCardState extends State<_ExplanationCard> {
  late final ValueNotifier<String?> _translatedTextNotifier;
  String? _translatedLocale;

  @override
  void initState() {
    super.initState();
    _translatedTextNotifier = ValueNotifier<String?>(null);
  }

  @override
  void didUpdateWidget(covariant _ExplanationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalExplanation != widget.originalExplanation) {
      _translatedTextNotifier.value = null;
      _translatedLocale = null;
    }
  }

  @override
  void dispose() {
    _translatedTextNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;

    return ValueListenableBuilder<String?>(
      valueListenable: _translatedTextNotifier,
      builder: (context, translatedText, child) {
        final displayText = translatedText ?? widget.originalExplanation;
        final card = Container(
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
                      fallback: 'EXPLANATION:',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: widget.accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TtsSpeakerButtonWidget(
                        text: displayText,
                        color: widget.accentColor,
                        isKids: widget.isKids,
                        locale: translatedText != null
                            ? _translatedLocale
                            : null,
                      ),
                      if (translatedText == null) ...[
                        SizedBox(width: 8.w),
                        TranslateButtonWidget(
                          originalText: widget.originalExplanation,
                          isKidsZone: widget.isKids,
                          onTranslationComplete: (translated) {
                            TtsSpeakerButtonWidget.stopAll();
                            if (mounted) {
                              _translatedTextNotifier.value = translated;
                            }
                          },
                          onTranslationWithLanguage: (translated, langCode) {
                            TtsSpeakerButtonWidget.stopAll();
                            if (mounted) {
                              _translatedLocale = langCode;
                              _translatedTextNotifier.value = translated;
                            }
                          },
                        ),
                      ] else ...[
                        SizedBox(width: 8.w),
                        ScaleButton(
                          onTap: () {
                            TtsSpeakerButtonWidget.stopAll();
                            if (mounted) {
                              setState(() {
                                _translatedLocale = null;
                                _translatedTextNotifier.value = null;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: widget.accentColor.withValues(
                                alpha: widget.isDark ? 0.2 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: widget.accentColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.undo_rounded,
                                  size: 12.r,
                                  color: widget.accentColor,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'EN',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: widget.accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                displayText,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        );

        if (reduceMotion) {
          return card;
        }

        return RepaintBoundary(
          child: card
              .animate()
              .fadeIn(delay: 100.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                duration: 300.ms,
                curve: Curves.easeOutCubic,
              ),
        );
      },
    );
  }
}
