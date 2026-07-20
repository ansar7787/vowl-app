import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/core/utils/widgets/entity_highlighted_text.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/ml_services/entity_extraction_service.dart';
import 'package:vowl/core/utils/ml_monetization_controller.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bottom-sheet style feedback card shown after the player answers.
///
/// Accessibility:
/// - The card root is a [liveRegion] — screen readers announce the result
///   the moment the card appears, without the player needing to swipe to it.
/// - The action button has a full semantic label combining result + action.
/// - Decorative icons and gradients are excluded from the semantic tree.
///
/// Responsiveness:
/// - Gradient text uses [ShaderMask] with `bounds` instead of a hardcoded
///   [Rect] — adapts to any text size, locale, or font-scaling setting.
///
/// Reduced motion:
/// - All animations are skipped when the system "reduce motion" flag is set.
class ReadingFeedbackCard extends StatelessWidget {
  final bool? isCorrect;
  final int lives;
  final bool isFinalFailure;
  final ReadingQuest currentQuest;
  final VoidCallback onContinue;
  final Color primaryColor;
  final bool isDark;

  const ReadingFeedbackCard({
    super.key,
    required this.isCorrect,
    required this.lives,
    required this.isFinalFailure,
    required this.currentQuest,
    required this.onContinue,
    required this.primaryColor,
    required this.isDark,
  });

  // ---------------------------------------------------------------------------
  // Derived values
  // ---------------------------------------------------------------------------

  bool get _success => isCorrect ?? false;

  List<Color> get _gradient => _success
      ? const [Color(0xFF2DD4BF), Color(0xFF10B981)]
      : const [Color(0xFFF43F5E), Color(0xFFE11D48)];

  Color get _shadowColor =>
      _success ? const Color(0xFF10B981) : const Color(0xFFE11D48);

  IconData get _icon =>
      _success ? Icons.check_circle_rounded : Icons.error_rounded;

  String _title(BuildContext context) => _success
      ? context.tr('games.excellent', fallback: 'Excellent!')
      : context.tr('games.not_quite', fallback: 'Not Quite');

  String _buttonText(BuildContext context) {
    if (_success) {
      return context
          .tr('common.continue_text', fallback: 'Continue')
          .toUpperCase();
    }
    if (isFinalFailure) {
      return lives == 0
          ? context.tr('games.see_results', fallback: 'See Results')
          : context
                .tr('common.continue_text', fallback: 'Continue')
                .toUpperCase();
    }
    return context.tr('games.try_again', fallback: 'Try Again').toUpperCase();
  }

  // Only show the explanation block when correctAnswer is available.
  // Guards the non-null assertion in _buildExplanationCard.
  bool get _showExplanation {
    final bool showEducationalInfo = _success || isFinalFailure;
    if (!showEducationalInfo) return false;

    if (_success) {
      return currentQuest.explanation?.isNotEmpty ?? false;
    } else {
      return (currentQuest.explanation?.isNotEmpty ?? false) ||
          (currentQuest.correctAnswer?.isNotEmpty ?? false);
    }
  }

  String get _explanationText {
    if (_success) return currentQuest.explanation!;
    return currentQuest.explanation ?? currentQuest.correctAnswer ?? '';
  }

  String _semanticLabel(BuildContext context) {
    if (_success) {
      return context.tr(
        'games.semantic_correct_continue',
        fallback: 'Correct. Tap to continue.',
      );
    }
    if (_showExplanation) {
      final answer = _explanationText;
      return context.tr(
        'games.semantic_incorrect_explanation',
        fallback: 'Incorrect. Read explanation.',
        args: [answer, _buttonText(context)],
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      // Announce the full result as soon as the card appears.
      liveRegion: true,
      label: _semanticLabel(context),
      // Prevent the child tree from producing redundant announcements.
      excludeSemantics: true,
      child: Container(
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
            _buildResultRow(context, reduceMotion),
            if (_showExplanation) ...[
              SizedBox(height: 16.h),
              _ExplanationBox(
                explanation: _explanationText,
                shadowColor: _shadowColor,
                isDark: isDark,
                reduceMotion: reduceMotion,
                passage: _success ? currentQuest.passage : null,
              ),
            ],
            SizedBox(height: 28.h),
            _buildContinueButton(context, reduceMotion),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-widgets
  // ---------------------------------------------------------------------------

  Widget _buildResultRow(BuildContext context, bool reduceMotion) {
    Widget iconWidget = Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _gradient),
        shape: BoxShape.circle,
      ),
      // ExcludeSemantics: the icon is decorative; the card Semantics label
      // already conveys success/failure to the screen reader.
      child: ExcludeSemantics(
        child: Icon(_icon, color: Colors.white, size: 28.r),
      ),
    );

    if (!reduceMotion) {
      iconWidget = iconWidget.animate().scale(
        duration: 600.ms,
        curve: Curves.elasticOut,
      );
    }

    return Row(
      children: [
        iconWidget,
        SizedBox(width: 16.w),
        Expanded(
          child: ExcludeSemantics(
            // Gradient title is decorative; the card Semantics label covers it.
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              // bounds is the actual render box of the Text — fully responsive
              // to any text size, locale, or font-scaling factor.
              shaderCallback: (bounds) =>
                  LinearGradient(colors: _gradient).createShader(bounds),
              child: Text(
                _title(context),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  // ShaderMask replaces this colour with the gradient.
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context, bool reduceMotion) {
    Widget button = Semantics(
      label: _buttonText(context),
      button: true,
      // excludeSemantics: false — let the button be focusable independently
      // (though the card-level liveRegion already announced the result).
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
    );

    if (!reduceMotion) {
      button = button.animate().scale(
        delay: 500.ms,
        duration: 400.ms,
        curve: Curves.elasticOut,
      );
    }

    return button;
  }
}

class _ExplanationBox extends StatefulWidget {
  final String explanation;
  final Color shadowColor;
  final bool isDark;
  final bool reduceMotion;
  final String? passage;

  const _ExplanationBox({
    required this.explanation,
    required this.shadowColor,
    required this.isDark,
    required this.reduceMotion,
    this.passage,
  });

  @override
  State<_ExplanationBox> createState() => _ExplanationBoxState();
}

class _ExplanationBoxState extends State<_ExplanationBox> {
  String? _translatedText;
  List<EntityAnnotation>? _entities;
  bool _isExtracting = false;
  bool _entitiesRevealed = false;

  @override
  void initState() {
    super.initState();
    _checkAutoReveal();
  }

  void _checkAutoReveal() {
    if (widget.passage != null && widget.passage!.isNotEmpty) {
      final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
      if (isPremium) {
        _extractEntities();
      }
    }
  }

  Future<void> _extractEntities() async {
    if (widget.passage == null || widget.passage!.isEmpty) return;
    setState(() => _isExtracting = true);
    
    final service = di.sl<EntityExtractionService>();
    await service.downloadModel();
    final entities = await service.extractEntities(widget.passage!);
    
    if (mounted) {
      setState(() {
        _entities = entities;
        _isExtracting = false;
        _entitiesRevealed = true;
      });
    }
  }

  void _onRevealEntitiesTap() {
    MlMonetizationController.attemptFeature(
      context,
      featureIcon: Icons.search_rounded,
      featureTitle: context.tr('reading.reveal_entities_title', fallback: 'Entity Highlighter'),
      featureSubtitle: context.tr('reading.reveal_entities_desc', fallback: 'Discover dates, places, and more!'),
      adButtonLabel: context.tr('reading.reveal_entities_ad', fallback: 'Watch Ad to Reveal'),
      onSuccess: () => _extractEntities(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _translatedText ?? widget.explanation;

    Widget card = Column(
      children: [
        if (widget.passage != null && widget.passage!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: widget.shadowColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('reading.passage_review', fallback: 'PASSAGE REVIEW'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: widget.shadowColor,
                        letterSpacing: 1,
                      ),
                    ),
                    if (!_entitiesRevealed && !_isExtracting)
                      ScaleButton(
                        onTap: _onRevealEntitiesTap,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded, color: Colors.amber.shade700, size: 14.sp),
                              SizedBox(width: 4.w),
                              Text(
                                context.tr('reading.reveal', fallback: 'Reveal Entities'),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                if (_isExtracting)
                  const Center(child: CircularProgressIndicator())
                else if (_entitiesRevealed && _entities != null)
                  EntityHighlightedText(
                    text: widget.passage!,
                    annotations: _entities!,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: widget.isDark ? Colors.white70 : Colors.black87,
                      height: 1.5,
                    ),
                    isDark: widget.isDark,
                  )
                else
                  Text(
                    widget.passage!,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: widget.isDark ? Colors.white70 : Colors.black87,
                      height: 1.5,
                    ),
                  ),
                if (_entitiesRevealed && _entities != null && _entities!.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: widget.shadowColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_rounded, color: widget.shadowColor, size: 16.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            context.tr(
                              'reading.entities_found', 
                              fallback: 'Tap the highlighted words to see their types!',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: widget.shadowColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
          SizedBox(height: 16.h),
        ],
        Container(
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
                child: Text(
                  context.tr('games.explanation_caps', fallback: 'EXPLANATION'),
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
                    if (mounted) setState(() => _translatedText = translated);
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
  ],
);

    if (!widget.reduceMotion) {
      card = card
          .animate()
          .fadeIn(delay: 300.ms)
          .scale(duration: 400.ms, curve: Curves.easeOutBack);
    }

    return card;
  }
}
