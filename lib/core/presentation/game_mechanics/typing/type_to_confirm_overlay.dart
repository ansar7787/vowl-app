import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/text_similarity_helper.dart';
import 'package:vowl/core/utils/gibberish_detector_service.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/game_skip_bypass_button.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/smart_typo_controller.dart';

/// Type-to-confirm overlay requiring user text entry to solidify understanding.
class TypeToConfirmOverlay extends StatefulWidget {
  final String expectedText;
  final String? displayText;
  final String? hintText;
  final Color primaryColor;
  final VoidCallback onConfirmed;
  final VoidCallback onSkipped;
  final VoidCallback? onBypassed;
  final double threshold;
  final int maxAttempts;
  final bool allowSkip;
  final bool isPositioned;
  final double? displayFontSize;
  final FontWeight? displayFontWeight;
  final TextAlign? displayTextAlign;
  final String? title;
  final String? subtitle;

  const TypeToConfirmOverlay({
    super.key,
    required this.expectedText,
    this.displayText,
    this.hintText,
    required this.primaryColor,
    required this.onConfirmed,
    required this.onSkipped,
    this.onBypassed,
    this.threshold = 0.85,
    this.maxAttempts = 3,
    this.allowSkip = true,
    this.isPositioned = true,
    this.displayFontSize,
    this.displayFontWeight,
    this.displayTextAlign,
    this.title,
    this.subtitle,
  });

  @override
  State<TypeToConfirmOverlay> createState() => _TypeToConfirmOverlayState();
}

class _TypeToConfirmOverlayState extends State<TypeToConfirmOverlay> {
  final _hapticService = di.sl<HapticService>();
  late final SmartTypoController _textController;
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  final ValueNotifier<int> _attempts = ValueNotifier(0);
  final ValueNotifier<_ConfirmResult?> _result = ValueNotifier(null);
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _textController = SmartTypoController(expectedText: widget.expectedText);
    _textController.addListener(() {
      if (_textController.showDiff) {
        _textController.showDiff = false;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    _textController.dispose();
    _attempts.dispose();
    _result.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }

  Future<void> _evaluate() async {
    if (_isSubmitting.value) return;

    final text = _textController.text.trim();
    if (text.isEmpty) {
      _result.value = _ConfirmResult.empty;
      _hapticService.selection();
      return;
    }

    if (!GibberishDetectorService.isNaturalSentence(context, text)) {
      _result.value = _ConfirmResult.mismatch;
      _textController.showDiff = true;
      _attempts.value++;
      _hapticService.error();
      return;
    }

    bool matched = TextSimilarityHelper.isMatch(
      text,
      widget.expectedText,
      threshold: widget.threshold,
    );

    _attempts.value++;
    _result.value = matched ? _ConfirmResult.success : _ConfirmResult.mismatch;

    if (matched) {
      _textController.showDiff = false;
      _isSubmitting.value = true;
      _hapticService.success();
      _focusNode.unfocus();

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) widget.onConfirmed();
    } else {
      _textController.showDiff = true;
      _hapticService.error();
      if (_attempts.value >= widget.maxAttempts) {
        _focusNode.unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: widget.isPositioned
              ? MediaQuery.of(context).viewInsets.bottom + 12.h
              : 0,
          top: widget.isPositioned
              ? MediaQuery.paddingOf(context).top + 12.h
              : 0,
        ),
        child:
            (MediaQuery.disableAnimationsOf(context) ||
                VowlMotion.lowAnimationModeOverride.value)
            ? _buildPanel(isDark)
            : _buildPanel(isDark)
                  .animate()
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(duration: 300.ms),
      ),
    );

    if (widget.isPositioned) {
      return Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        right: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [Flexible(child: content)],
        ),
      );
    }

    return content;
  }

  Widget _buildPanel(bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.slate900;
    final subtitleColor = isDark ? Colors.white70 : Colors.black87;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32.r),
      child: ValueListenableBuilder<_ConfirmResult?>(
        valueListenable: _result,
        builder: (context, result, child) {
          final borderColor = result == _ConfirmResult.success
              ? AppColors.gameCorrect.withValues(alpha: 0.5)
              : result == _ConfirmResult.mismatch
              ? AppColors.gameIncorrect.withValues(alpha: 0.5)
              : widget.primaryColor.withValues(alpha: 0.3);

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(32.r),
              border: Border.all(color: borderColor, width: 1.5),
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
            child: child,
          );
        },
        child: Builder(
          builder: (context) {
            final innerContent = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Builder(
                      builder: (context) {
                        final reduceMotion =
                            MediaQuery.disableAnimationsOf(context) ||
                            VowlMotion.lowAnimationModeOverride.value;
                        Widget iconContainer = Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: widget.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            Icons.keyboard_rounded,
                            color: widget.primaryColor,
                            size: 22.r,
                          ),
                        );

                        if (!reduceMotion) {
                          iconContainer = iconContainer
                              .animate(onPlay: (c) => c.repeat(reverse: true))
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
                            widget.title ?? 'Type to confirm',
                            maxLines: 1,
                            minFontSize: 8,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: widget.primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          AutoSizeText(
                            widget.subtitle ?? 'Type the answer to confirm',
                            maxLines: 1,
                            minFontSize: 8,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w500,
                              color: subtitleColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.allowSkip)
                      Padding(
                        padding: EdgeInsets.only(left: 8.w),
                        child: GameSkipBypassButton(
                          subtitleColor: subtitleColor,
                          isSubmitting: _isSubmitting,
                          attempts: _attempts,
                          maxAttempts: widget.maxAttempts,
                          onBypassed: widget.onBypassed,
                          onConfirmed: widget.onConfirmed,
                          onSkipped: widget.onSkipped,
                          onSubmittingChanged: (v) => _isSubmitting.value = v,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Expected text display
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: widget.primaryColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Builder(
                    builder: (context) {
                      final rawText = widget.displayText ?? widget.expectedText;
                      final isSingleWord = !rawText.trim().contains(' ');

                      Widget textWidget = Text(
                        rawText,
                        textAlign: widget.displayTextAlign ?? TextAlign.center,
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: widget.displayFontSize ?? 20.sp,
                          fontWeight: widget.displayFontWeight ?? FontWeight.w700,
                          color: textColor,
                          letterSpacing: 0.5,
                          height: 1.4,
                        ),
                      );

                      if (isSingleWord) {
                        textWidget = FittedBox(
                          fit: BoxFit.scaleDown,
                          child: textWidget,
                        );
                      }

                      return textWidget;
                    },
                  ),
                ),
                SizedBox(height: 20.h),

                // Input and Action Area
                ValueListenableBuilder<_ConfirmResult?>(
                  valueListenable: _result,
                  builder: (context, result, _) {
                    if (result == _ConfirmResult.success) {
                      final reduceMotion =
                          MediaQuery.disableAnimationsOf(context) ||
                          VowlMotion.lowAnimationModeOverride.value;
                      final badge = Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: AppColors.gameCorrect.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_rounded,
                          color: AppColors.gameCorrect,
                          size: 48.r,
                        ),
                      );
                      final label = AutoSizeText(
                        'CORRECT!',
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gameCorrect,
                          letterSpacing: 1.5,
                        ),
                      );

                      return Padding(
                        padding: EdgeInsets.only(top: 20.h),
                        child: Column(
                          children: [
                            reduceMotion
                                ? badge
                                : badge.animate().scale(
                                    begin: const Offset(0, 0),
                                    end: const Offset(1, 1),
                                    duration: 400.ms,
                                    curve: Curves.easeOutCubic,
                                  ),
                            SizedBox(height: 12.h),
                            reduceMotion
                                ? label
                                : label.animate().fadeIn(delay: 200.ms),
                          ],
                        ),
                      );
                    }

                    final reduceMotion =
                        MediaQuery.disableAnimationsOf(context) ||
                        VowlMotion.lowAnimationModeOverride.value;

                    final inputContainer = Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: result == _ConfirmResult.mismatch
                              ? AppColors.gameIncorrect.withValues(alpha: 0.5)
                              : widget.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Stack(
                        children: [
                          TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            minLines: 1,
                            maxLines: 4,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.done,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: widget.hintText ?? 'Type your answer',
                              hintStyle: TextStyle(
                                color: subtitleColor.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(
                                left: 16.w,
                                right: 16.w,
                                top: 16.h,
                                bottom: 32.h,
                              ),
                            ),
                            onSubmitted: (_) => _evaluate(),
                            onChanged: (_) {
                              if (_result.value == _ConfirmResult.mismatch ||
                                  _result.value == _ConfirmResult.empty) {
                                _result.value = null;
                              }
                            },
                          ),
                          Positioned(
                            bottom: 12.h,
                            left: 16.w,
                            child: ValueListenableBuilder<int>(
                              valueListenable: _attempts,
                              builder: (context, attempts, _) {
                                if (attempts > 0) {
                                  return AutoSizeText(
                                    '${widget.maxAttempts - attempts} attempts left',
                                    maxLines: 1,
                                    minFontSize: 7,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gameIncorrect.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ],
                      ),
                    );

                    return Column(
                      children: [
                        // Input field
                        reduceMotion
                            ? inputContainer
                            : inputContainer
                                  .animate(
                                    target: result == _ConfirmResult.mismatch
                                        ? 1
                                        : 0,
                                  )
                                  .shakeX(amount: 5, duration: 400.ms),

                        // Status message
                        if (result == _ConfirmResult.mismatch ||
                            result == _ConfirmResult.empty)
                          Padding(
                            padding: EdgeInsets.only(top: 12.h),
                            child: AutoSizeText(
                              result == _ConfirmResult.mismatch
                                  ? 'Not quite right. Check your spelling.'
                                  : 'Please type your answer.',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              minFontSize: 8,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: result == _ConfirmResult.mismatch
                                    ? AppColors.gameIncorrect
                                    : Colors.orangeAccent,
                              ),
                            ),
                          ),

                        // Submit / Continue button
                        Padding(
                          padding: EdgeInsets.only(top: 20.h),
                          child: ValueListenableBuilder<int>(
                            valueListenable: _attempts,
                            builder: (context, attempts, _) {
                              final outOfAttempts =
                                  attempts >= widget.maxAttempts;
                              return ValueListenableBuilder<bool>(
                                valueListenable: _isSubmitting,
                                builder: (context, isSubmitting, _) {
                                  return ScaleButton(
                                    onTap: isSubmitting
                                        ? null
                                        : () {
                                            if (outOfAttempts) {
                                              _isSubmitting.value = true;
                                              widget.onSkipped();
                                            } else {
                                              _evaluate();
                                            }
                                          },
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16.h,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: outOfAttempts
                                              ? [
                                                  Colors.grey.withValues(
                                                    alpha: 0.8,
                                                  ),
                                                  Colors.grey.withValues(
                                                    alpha: 0.6,
                                                  ),
                                                ]
                                              : [
                                                  widget.primaryColor,
                                                  widget.primaryColor
                                                      .withValues(alpha: 0.8),
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: outOfAttempts
                                                ? Colors.black26
                                                : widget.primaryColor
                                                      .withValues(alpha: 0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: AutoSizeText(
                                          outOfAttempts ? 'CONTINUE' : 'SUBMIT',
                                          maxLines: 1,
                                          minFontSize: 10,
                                          overflow: TextOverflow.visible,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );

            if (!widget.isPositioned) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 28.h),
                child: innerContent,
              );
            }

            return RawScrollbar(
              controller: _scrollController,
              thumbColor: widget.primaryColor.withValues(alpha: 0.5),
              radius: Radius.circular(8.r),
              thickness: 4.w,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(vertical: 28.h),
                physics: const BouncingScrollPhysics(),
                child: innerContent,
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _ConfirmResult { success, mismatch, empty }
