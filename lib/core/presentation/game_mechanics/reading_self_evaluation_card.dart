import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

/// Self-evaluation card for reading comprehension games.
///
/// Two-phase flow:
/// 1. **Hidden** — user sees "TAP TO REVEAL" button (forces mental recall first)
/// 2. **Revealed** — shows correct answer + optional explanation + "Nailed It / Missed It"
///
/// Previously lived in `features/reading/presentation/widgets/` but is a
/// reusable game mechanic used across 4+ reading game screens.
///
/// Usage:
/// ```dart
/// ReadingSelfEvaluationCard(
///   correctAnswer: quest.correctAnswer ?? '',
///   explanation: quest.explanation,
///   primaryColor: theme.primaryColor,
///   onEvaluated: (nailedIt) => _submitAnswer(nailedIt),
/// )
/// ```
class ReadingSelfEvaluationCard extends StatefulWidget {
  final String correctAnswer;
  final String? explanation;
  final Color primaryColor;
  final Function(bool isCorrect) onEvaluated;

  /// Whether to wrap in a Positioned widget (for Stack layouts).
  final bool isPositioned;

  /// Bonus coins awarded on "Nailed It". Null hides badge.
  final int? bonusCoins;

  const ReadingSelfEvaluationCard({
    super.key,
    required this.correctAnswer,
    this.explanation,
    required this.primaryColor,
    required this.onEvaluated,
    this.isPositioned = false,
    this.bonusCoins = 5,
  });

  @override
  State<ReadingSelfEvaluationCard> createState() =>
      _ReadingSelfEvaluationCardState();
}

class _ReadingSelfEvaluationCardState extends State<ReadingSelfEvaluationCard> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  final ValueNotifier<bool> _isRevealed = ValueNotifier(false);
  final ValueNotifier<bool> _isEvaluated = ValueNotifier(false);

  @override
  void didUpdateWidget(ReadingSelfEvaluationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset state when question changes (new correctAnswer = new question)
    if (oldWidget.correctAnswer != widget.correctAnswer) {
      _isRevealed.value = false;
      _isEvaluated.value = false;
    }
  }

  @override
  void dispose() {
    _isRevealed.dispose();
    _isEvaluated.dispose();
    super.dispose();
  }

  void _reveal() {
    _hapticService.selection();
    _isRevealed.value = true;
  }

  void _evaluate(bool isCorrect) {
    if (_isEvaluated.value) return;
    _isEvaluated.value = true;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      // Award bonus coins
      if (widget.bonusCoins != null && widget.bonusCoins! > 0) {
        context.read<EconomyBloc>().add(
          EconomyAddCoinsRequested(widget.bonusCoins!),
        );
      }
    } else {
      _hapticService.error();
      _soundService.playWrong();
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) widget.onEvaluated(isCorrect);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    return ValueListenableBuilder<bool>(
      valueListenable: _isRevealed,
      builder: (context, isRevealed, _) {
        final content = !isRevealed 
            ? _buildRevealButton(context) 
            : _buildAnswerCard(
                context,
                isDark: isDark,
                textColor: textColor,
                subtitleColor: subtitleColor,
              );

        if (widget.isPositioned) {
          return Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: content,
          );
        }

        return content;
      }
    );
  }

  Widget _buildRevealButton(BuildContext context) {
    return GestureDetector(
      onTap: _reveal,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 24.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.primaryColor.withValues(alpha: 0.8),
              widget.primaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.visibility_rounded, color: Colors.white, size: 32.sp),
            SizedBox(height: 12.h),
            AutoSizeText(
              context.tr(
                'reading.tap_reveal_answer',
                fallback: 'TAP TO REVEAL ANSWER',
              ),
              maxLines: 1,
              minFontSize: 10,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 8.h),
            AutoSizeText(
              context.tr(
                'reading.think_answer_first',
                fallback: 'Think of the answer first!',
              ),
              maxLines: 1,
              minFontSize: 8,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ).animate().scale(
            delay: 200.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }

  Widget _buildAnswerCard(
    BuildContext context, {
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: widget.primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AutoSizeText(
                context.tr(
                  'reading.the_answer_is',
                  fallback: 'THE ANSWER IS',
                ),
                maxLines: 1,
                minFontSize: 8,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: widget.primaryColor,
                  letterSpacing: 2,
                ),
              ),
              if (widget.bonusCoins != null) ...[
                SizedBox(width: 10.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.primaryColor,
                        widget.primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: AutoSizeText(
                    '+${widget.bonusCoins} Coins',
                    maxLines: 1,
                    minFontSize: 6,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 12.h),

          // Correct answer text
          AutoSizeText(
            widget.correctAnswer,
            textAlign: TextAlign.center,
            maxLines: 5,
            minFontSize: 10,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),

          // Explanation
          if (widget.explanation != null &&
              widget.explanation!.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: AutoSizeText(
                widget.explanation!,
                textAlign: TextAlign.center,
                maxLines: 6,
                minFontSize: 8,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                  height: 1.5,
                ),
              ),
            ),
          ],
          SizedBox(height: 24.h),
          Divider(color: widget.primaryColor.withValues(alpha: 0.2)),
          SizedBox(height: 16.h),

          // Prompt
          AutoSizeText(
            context.tr(
              'reading.did_you_get_it_right',
              fallback: 'DID YOU GET IT RIGHT?',
            ),
            maxLines: 1,
            minFontSize: 8,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: subtitleColor,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 16.h),

          // Eval buttons — scoped ValueListenableBuilder
          ValueListenableBuilder<bool>(
            valueListenable: _isEvaluated,
            builder: (context, isEvaluated, _) {
              if (isEvaluated) return const SizedBox.shrink();
              return Row(
                children: [
                  Expanded(
                    child: _buildEvalButton(
                      icon: Icons.close_rounded,
                      label: context.tr(
                        'reading.missed_it',
                        fallback: 'MISSED IT',
                      ),
                      color: Colors.redAccent,
                      onTap: () => _evaluate(false),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildEvalButton(
                      icon: Icons.check_rounded,
                      label: context.tr(
                        'reading.nailed_it',
                        fallback: 'NAILED IT',
                      ),
                      color: Colors.greenAccent,
                      onTap: () => _evaluate(true),
                    ),
                  ),
                ],
              );
            }
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildEvalButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28.sp),
            SizedBox(height: 6.h),
            AutoSizeText(
              label,
              maxLines: 1,
              minFontSize: 8,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
