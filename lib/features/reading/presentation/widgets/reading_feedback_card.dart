import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';

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

  String _title(BuildContext context) =>
      _success ? context.tr('games.excellent', fallback: 'Excellent!', fallback: 'Excellent!') : context.tr('games.not_quite', fallback: 'Not Quite', fallback: 'Not Quite');

  String _buttonText(BuildContext context) {
    if (_success) return context.tr('common.continue_text', fallback: 'Continue', fallback: 'Continue').toUpperCase();
    if (isFinalFailure) {
      return lives == 0
          ? context.tr('games.see_results', fallback: 'See Results', fallback: 'See Results')
          : context.tr('common.continue_text', fallback: 'Continue', fallback: 'Continue').toUpperCase();
    }
    return context.tr('games.try_again', fallback: 'Try Again', fallback: 'Try Again').toUpperCase();
  }

  // Only show the explanation block when correctAnswer is available.
  // Guards the non-null assertion in _buildExplanationCard.
  bool get _showExplanation =>
      !_success &&
      isFinalFailure &&
      (currentQuest.correctAnswer?.isNotEmpty ?? false);

  String _semanticLabel(BuildContext context) {
    if (_success) return context.tr('games.semantic_correct_continue', fallback: 'Correct. Tap to continue.', fallback: 'Correct. Tap to continue.');
    if (_showExplanation) {
      // _showExplanation guards non-null; ?? keeps the static analyser happy.
      final answer = currentQuest.correctAnswer ?? '';
      return context.tr(
        'games.semantic_incorrect_explanation', fallback: 'Incorrect. Read explanation.',
        args: [answer, _buttonText(context)],
      );
    }
    return context.tr('games.semantic_incorrect_try_again', fallback: 'Incorrect. Tap to try again.', fallback: 'Incorrect. Tap to try again.');
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
              _buildExplanationCard(context, reduceMotion),
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

  Widget _buildExplanationCard(BuildContext context, bool reduceMotion) {
    Widget card = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: _shadowColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _shadowColor.withValues(alpha: 0.2),
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
                  color: _shadowColor,
                  size: 14.r,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                context.tr('games.explanation_caps', fallback: 'EXPLANATION', fallback: 'EXPLANATION'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: _shadowColor,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            // Safe: _showExplanation checks correctAnswer?.isNotEmpty before
            // this widget is built, so the value is guaranteed non-null here.
            currentQuest.correctAnswer!,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );

    if (!reduceMotion) {
      card = card
          .animate()
          .fadeIn(delay: 300.ms)
          .scale(duration: 400.ms, curve: Curves.easeOutBack);
    }

    return card;
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
