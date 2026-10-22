import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/game_skip_bypass_button.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speaking_self_evaluation_controls.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// A self-evaluation overlay for speaking tasks.
///
/// Uses [SpeakingSelfEvaluationControls] inside a floating bottom-sheet design.
class SpeakToConfirmOverlay extends StatefulWidget {
  final String expectedText;
  final String? ttsText;
  final List<String> acceptedSynonyms;
  final String? displayText;
  final double? displayFontSize;
  final FontWeight? displayFontWeight;
  final TextAlign? displayTextAlign;
  final bool hideExpectedText;
  final String title;
  final String subtitle;
  final Color primaryColor;
  final VoidCallback onConfirmed;
  final VoidCallback onSkipped;
  final VoidCallback? onBypassed;
  final double threshold;
  final int maxAttempts;
  final bool allowSkip;
  final bool isPositioned;

  const SpeakToConfirmOverlay({
    super.key,
    required this.expectedText,
    this.ttsText,
    this.acceptedSynonyms = const [],
    this.displayText,
    this.displayFontSize,
    this.displayFontWeight,
    this.displayTextAlign = TextAlign.center,
    this.hideExpectedText = false,
    this.title = 'NOW SAY IT',
    this.subtitle = 'Speak the answer to confirm',
    required this.primaryColor,
    required this.onConfirmed,
    required this.onSkipped,
    this.onBypassed,
    this.threshold = 0.65,
    this.maxAttempts = 3,
    this.allowSkip = true,
    this.isPositioned = true,
  });

  @override
  State<SpeakToConfirmOverlay> createState() => _SpeakToConfirmOverlayState();
}

class _SpeakToConfirmOverlayState extends State<SpeakToConfirmOverlay> {
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);

  @override
  void dispose() {
    _isSubmitting.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.slate900;
    final subtitleColor = isDark ? Colors.white70 : Colors.black87;

    final content =
        Material(
              type: MaterialType.transparency,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: widget.isPositioned
                      ? MediaQuery.of(context).viewInsets.bottom + 24.h
                      : 0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: widget.primaryColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.2)
                              : widget.primaryColor.withValues(alpha: 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Header ──
                          Row(
                            children: [
                              Builder(
                                builder: (context) {
                                  final reduceMotion =
                                      VowlMotion.shouldReduceMotion(context);
                                  Widget iconContainer = Container(
                                    padding: EdgeInsets.all(10.r),
                                    decoration: BoxDecoration(
                                      color: widget.primaryColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(14.r),
                                      border: Border.all(
                                        color: widget.primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.mic_rounded,
                                      color: widget.primaryColor,
                                      size: 22.r,
                                    ),
                                  );

                                  if (!reduceMotion) {
                                    iconContainer = iconContainer
                                        .animate(
                                          onPlay: (c) =>
                                              c.repeat(reverse: true),
                                        )
                                        .scale(
                                          begin: const Offset(1, 1),
                                          end: const Offset(1.05, 1.05),
                                          duration: 1.5.seconds,
                                        );
                                  }

                                  return iconContainer;
                                },
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AutoSizeText(
                                      widget.title,
                                      textAlign: TextAlign.start,
                                      maxLines: 2,
                                      minFontSize: 10,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: widget.primaryColor,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    AutoSizeText(
                                      widget.subtitle,
                                      textAlign: TextAlign.start,
                                      maxLines: 2,
                                      minFontSize: 9,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w500,
                                        color: subtitleColor,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),

                          if (!widget.hideExpectedText) ...[
                            // ── Expected text display ──
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 14.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: widget.primaryColor.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ),
                              child: Text(
                                widget.displayText ?? widget.expectedText,
                                textAlign: widget.displayTextAlign,
                                softWrap: true,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: widget.displayFontSize ?? 18.sp,
                                  fontWeight:
                                      widget.displayFontWeight ??
                                      FontWeight.w700,
                                  color: textColor,
                                  letterSpacing: 0.3,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            SizedBox(height: 24.h),
                          ],

                          SpeakingSelfEvaluationControls(
                            expectedText: widget.expectedText,
                            ttsText: widget.ttsText,
                            acceptedSynonyms: widget.acceptedSynonyms,
                            primaryColor: widget.primaryColor,
                            onConfirmed: () {
                              if (_isSubmitting.value) return;
                              _isSubmitting.value = true;
                              widget.onConfirmed();
                            },
                            onSkipped: () {
                              if (_isSubmitting.value) return;
                              _isSubmitting.value = true;
                              widget.onSkipped();
                            },
                          ),

                          // Skip button
                          if (widget.allowSkip)
                            Padding(
                              padding: EdgeInsets.only(top: 16.h),
                              child: GameSkipBypassButton(
                                subtitleColor: subtitleColor,
                                isSubmitting: _isSubmitting,
                                onBypassed: widget.onBypassed,
                                onConfirmed: widget.onConfirmed,
                                onSkipped: widget.onSkipped,
                                onSubmittingChanged: (v) =>
                                    _isSubmitting.value = v,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .animate()
            .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut)
            .fadeIn(duration: 300.ms);

    if (!widget.isPositioned) {
      return content;
    }

    return Positioned(bottom: 0, left: 0, right: 0, child: content);
  }
}
