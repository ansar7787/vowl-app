import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:vowl/core/utils/gibberish_detector_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/locale_service.dart';

class ContextSentenceBuilder extends StatefulWidget {
  final String targetKeyword;
  final Color primaryColor;
  final VoidCallback onConfirmed;
  final VoidCallback onSkipped;
  final VoidCallback? onBypassed;
  final int minWordCount;
  final List<String>? acceptedKeywordForms;
  final bool isPositioned;
  final int maxAttempts;
  final int? bonusCoins;
  final bool allowSkip;
  final String? exampleSentence;

  const ContextSentenceBuilder({
    super.key,
    required this.targetKeyword,
    required this.primaryColor,
    required this.onConfirmed,
    required this.onSkipped,
    this.onBypassed,
    this.minWordCount = 5,
    this.acceptedKeywordForms,
    this.isPositioned = true,
    this.maxAttempts = 3,
    this.bonusCoins = 5,
    this.allowSkip = true,
    this.exampleSentence,
  });

  @override
  State<ContextSentenceBuilder> createState() => _ContextSentenceBuilderState();
}

class _ContextSentenceBuilderState extends State<ContextSentenceBuilder> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  final ValueNotifier<int> _attempts = ValueNotifier(0);
  final ValueNotifier<_BuilderStatus> _status = ValueNotifier(
    _BuilderStatus.idle,
  );
  final ValueNotifier<String> _feedbackMessage = ValueNotifier('');
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !widget.isPositioned) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _focusNode.context != null) {
            Scrollable.ensureVisible(
              _focusNode.context!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: 0.5,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    _attempts.dispose();
    _status.dispose();
    _feedbackMessage.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }

  void _evaluate() {
    if (_isSubmitting.value) return;
    final text = _controller.text.trim();

    final acceptedForms =
        widget.acceptedKeywordForms ?? [widget.targetKeyword.toLowerCase()];

    final result = ContextSentenceValidator.validate(
      context: context,
      text: text,
      minWordCount: widget.minWordCount,
      targetKeyword: widget.targetKeyword,
      acceptedKeywordForms: acceptedForms,
      exampleSentence: widget.exampleSentence,
    );

    if (!result.isValid) {
      _status.value = _BuilderStatus.error;
      _feedbackMessage.value = result.errorMessage ?? 'Error';
      _attempts.value++;
      _hapticService.error();
      _checkAttemptLimit();
      return;
    }

    _status.value = _BuilderStatus.success;
    _feedbackMessage.value = ContextSentenceStrings.successMessage(context);
    _isSubmitting.value = true;
    _hapticService.success();
    _soundService.playCorrect();
    _focusNode.unfocus();

    if (widget.bonusCoins != null && widget.bonusCoins! > 0) {
      if (_attempts.value < widget.maxAttempts) {
        context.read<EconomyBloc>().add(
          EconomyAddCoinsRequested(widget.bonusCoins!),
        );
      }
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) widget.onConfirmed();
    });
  }

  void _checkAttemptLimit() {
    if (_attempts.value >= widget.maxAttempts) {
      _focusNode.unfocus();
    }
  }

  Widget _buildSkipButton(Color subtitleColor) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            if (_isSubmitting.value) return;
            _isSubmitting.value = true;
            final user = context.read<AuthBloc>().state.user;
            final isPremium = user?.isPremium ?? false;
            if (isPremium) {
              if (widget.onBypassed != null) {
                widget.onBypassed!();
              } else {
                widget.onConfirmed();
              }
            } else {
              di.sl<AdService>().showRewardedAd(
                context: context,
                isPremium: false,
                onUserEarnedReward: (_) {
                  if (mounted) {
                    if (widget.onBypassed != null) {
                      widget.onBypassed!();
                    } else {
                      widget.onConfirmed();
                    }
                  }
                },
                onDismissed: () {
                  if (mounted) _isSubmitting.value = false;
                },
              );
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: subtitleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSizeText(
                  ContextSentenceStrings.skipButton(context),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: subtitleColor.withValues(alpha: 0.8),
                  ),
                ),
                Builder(
                  builder: (context) {
                    final isPremium =
                        context.watch<AuthBloc>().state.user?.isPremium ??
                        false;
                    if (!isPremium) {
                      return Padding(
                        padding: EdgeInsets.only(left: 4.w),
                        child: Icon(
                          Icons.ondemand_video_rounded,
                          size: 12.r,
                          color: subtitleColor.withValues(alpha: 0.8),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final glassColor = isDark
        ? Colors.black.withValues(alpha: 0.85) // Highly opaque for dark mode
        : Colors.white.withValues(alpha: 0.95); // Nearly solid for light mode

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70 : Colors.black87;

    final innerContent = ClipRRect(
      borderRadius: BorderRadius.circular(32.r),
      child: ValueListenableBuilder<_BuilderStatus>(
        valueListenable: _status,
        builder: (context, status, child) {
          final borderColor = status == _BuilderStatus.success
              ? Colors.greenAccent.withValues(alpha: 0.5)
              : status == _BuilderStatus.error
              ? Colors.redAccent.withValues(alpha: 0.5)
              : isDark
              ? widget.primaryColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.8);

          return Container(
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(32.r),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : widget.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          );
        },
        child: widget.isPositioned
            ? RawScrollbar(
                controller: _scrollController,
                thumbColor: widget.primaryColor.withValues(alpha: 0.5),
                radius: Radius.circular(8.r),
                thickness: 4.w,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 24.h,
                    ),
                    child: _buildFormContent(isDark, subtitleColor, textColor),
                  ),
                ),
              )
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: _buildFormContent(isDark, subtitleColor, textColor),
              ),
      ),
    );

    final content =
        Material(
              type: MaterialType.transparency,
              child: widget.isPositioned
                  ? Padding(
                      padding: EdgeInsets.only(
                        left: 20.w,
                        right: 20.w,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 12.h,
                        top: MediaQuery.paddingOf(context).top + 12.h,
                      ),
                      child: innerContent,
                    )
                  : Padding(
                      padding: EdgeInsets.only(left: 20.w, right: 20.w),
                      child: innerContent,
                    ),
            )
            .animate()
            .slideY(begin: 1.0, end: 0, duration: 600.ms, curve: Curves.easeOut)
            .fadeIn(duration: 400.ms);

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

  Widget _buildFormContent(bool isDark, Color subtitleColor, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: widget.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.history_edu_rounded,
                    color: widget.primaryColor,
                    size: 22.r,
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 1.5.seconds,
                ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    ContextSentenceStrings.headerTitle(context),
                    maxLines: 1,
                    minFontSize: 8,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                      color: widget.primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  AutoSizeText(
                    ContextSentenceStrings.headerSubtitle(context),
                    maxLines: 1,
                    minFontSize: 6,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                  if (widget.exampleSentence != null &&
                      widget.exampleSentence!.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: widget.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: AutoSizeText(
                        '${ContextSentenceStrings.examplePrefix(context)}"${widget.exampleSentence!}"',
                        maxLines: 2,
                        minFontSize: 8,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.allowSkip)
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: _buildSkipButton(subtitleColor),
              ),
          ],
        ),
        SizedBox(height: 12.h),

        // Target keyword chip
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: widget.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: widget.primaryColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: widget.primaryColor,
                size: 14.r,
              ),
              SizedBox(width: 6.w),
              AutoSizeText(
                widget.targetKeyword.toUpperCase(),
                maxLines: 1,
                minFontSize: 10,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: widget.primaryColor,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Text input area
        ValueListenableBuilder<_BuilderStatus>(
          valueListenable: _status,
          builder: (context, status, _) {
            if (status == _BuilderStatus.success) {
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: status == _BuilderStatus.error
                              ? Colors.redAccent.withValues(alpha: 0.5)
                              : isDark
                              ? Colors.white10
                              : Colors.black12,
                        ),
                      ),
                      child: Stack(
                        children: [
                          TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15.sp,
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 3,
                            minLines: 1,
                            onChanged: (_) {
                              if (_status.value == _BuilderStatus.error) {
                                _status.value = _BuilderStatus.idle;
                              }
                            },
                            onSubmitted: (_) => _evaluate(),
                            decoration: InputDecoration(
                              hintText: ContextSentenceStrings.hintText(
                                context,
                              ),
                              hintStyle: TextStyle(
                                color: subtitleColor.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(
                                left: 16.w,
                                right: 16.w,
                                top: 12.h,
                                bottom: 44.h,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12.h,
                            right: 16.w,
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _controller,
                              builder: (context, value, _) {
                                final text = value.text.trim();
                                final wordCount = text.isEmpty
                                    ? 0
                                    : text.split(RegExp(r'\s+')).length;
                                return AutoSizeText(
                                  '$wordCount / ${widget.minWordCount} ${ContextSentenceStrings.wordsSuffix(context)}',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: wordCount >= widget.minWordCount
                                        ? Colors.greenAccent
                                        : subtitleColor.withValues(alpha: 0.6),
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 12.h,
                            left: 16.w,
                            child: ValueListenableBuilder<int>(
                              valueListenable: _attempts,
                              builder: (context, attempts, _) {
                                if (attempts > 0) {
                                  final remaining =
                                      widget.maxAttempts - attempts;
                                  if (remaining > 0) {
                                    return AutoSizeText(
                                      '$remaining ${ContextSentenceStrings.attemptsLeftSuffix(context)}',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.redAccent.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    );
                                  } else {
                                    return AutoSizeText(
                                      ContextSentenceStrings.practiceMode(
                                        context,
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: subtitleColor.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    );
                                  }
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate(target: status == _BuilderStatus.error ? 1 : 0)
                    .shakeX(amount: 5, duration: 400.ms),

                // Error message
                if (status == _BuilderStatus.error)
                  ValueListenableBuilder<String>(
                    valueListenable: _feedbackMessage,
                    builder: (context, feedback, _) {
                      if (feedback.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: EdgeInsets.only(top: 12.h),
                        child: AutoSizeText(
                          feedback,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent.withValues(alpha: 0.9),
                          ),
                        ),
                      );
                    },
                  ),

                SizedBox(height: 24.h),

                // Submit / Continue button
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, textValue, _) {
                    final text = textValue.text.trim();
                    final wordCount = text.isEmpty
                        ? 0
                        : text.split(RegExp(r'\s+')).length;
                    final hasEnoughWords = wordCount >= widget.minWordCount;

                    return ValueListenableBuilder<int>(
                      valueListenable: _attempts,
                      builder: (context, attempts, _) {
                        final canEarnCoins =
                            widget.bonusCoins != null &&
                            widget.bonusCoins! > 0 &&
                            attempts < widget.maxAttempts;

                        return GestureDetector(
                          onTap: () {
                            if (!hasEnoughWords) return;
                            _evaluate();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: !hasEnoughWords
                                    ? [
                                        Colors.grey.withValues(alpha: 0.8),
                                        Colors.grey.withValues(alpha: 0.6),
                                      ]
                                    : [
                                        widget.primaryColor,
                                        widget.primaryColor.withValues(
                                          alpha: 0.8,
                                        ),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AutoSizeText(
                                    ContextSentenceStrings.submitButton(
                                      context,
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  if (canEarnCoins) ...[
                                    SizedBox(width: 8.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6.w,
                                        vertical: 2.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amberAccent.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        border: Border.all(
                                          color: Colors.amberAccent.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AutoSizeText(
                                            '+${widget.bonusCoins}',
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.amberAccent,
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Icon(
                                            Icons.monetization_on_rounded,
                                            size: 14.r,
                                            color: Colors.amberAccent,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),

        // Success state
        ValueListenableBuilder<_BuilderStatus>(
          valueListenable: _status,
          builder: (context, status, _) {
            if (status != _BuilderStatus.success) {
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Colors.greenAccent,
                  size: 56.r,
                ).animate().scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                ),
                SizedBox(height: 12.h),
                AutoSizeText(
                  ContextSentenceStrings.masteryProven(context),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.greenAccent,
                    letterSpacing: 2,
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ],
            );
          },
        ),
      ],
    );
  }
}

enum _BuilderStatus { idle, error, success }

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  const ValidationResult(this.isValid, [this.errorMessage]);
}

class ContextSentenceValidator {
  static ValidationResult validate({
    required BuildContext context,
    required String text,
    required int minWordCount,
    required String targetKeyword,
    required List<String> acceptedKeywordForms,
    required String? exampleSentence,
  }) {
    if (text.isEmpty) {
      return ValidationResult(
        false,
        ContextSentenceStrings.errorEmpty(context),
      );
    }

    final wordCount = text.split(RegExp(r'\s+')).length;
    if (wordCount < minWordCount) {
      return ValidationResult(
        false,
        ContextSentenceStrings.errorTooShort(context, minWordCount),
      );
    }

    final lowerText = text.toLowerCase();
    final keywordFound = acceptedKeywordForms.any(
      (form) => lowerText.contains(form.toLowerCase()),
    );

    if (!keywordFound) {
      return ValidationResult(
        false,
        ContextSentenceStrings.errorMissingKeyword(context, targetKeyword),
      );
    }

    if (exampleSentence != null) {
      final String formattedExample = exampleSentence
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim();
      final String formattedInput = lowerText
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim();

      if (formattedInput == formattedExample) {
        return ValidationResult(
          false,
          ContextSentenceStrings.errorCopiedExample(context),
        );
      }
    }

    if (!GibberishDetectorService.isNaturalSentence(context, text)) {
      return ValidationResult(
        false,
        ContextSentenceStrings.errorGibberish(context),
      );
    }

    return const ValidationResult(true);
  }
}

class ContextSentenceStrings {
  static String errorEmpty(BuildContext context) => context.tr(
    'game.sentence_builder.error_empty',
    fallback: 'Please write a sentence.',
  );
  static String errorTooShort(BuildContext context, int count) => context
      .tr(
        'game.sentence_builder.error_too_short',
        fallback: 'Too short! Write at least {count} words.',
      )
      .replaceAll('{count}', count.toString());
  static String errorMissingKeyword(BuildContext context, String keyword) =>
      context
          .tr(
            'game.sentence_builder.error_missing_keyword',
            fallback: 'Your sentence must include "{keyword}".',
          )
          .replaceAll('{keyword}', keyword);
  static String errorCopiedExample(BuildContext context) => context.tr(
    'game.sentence_builder.error_copied_example',
    fallback:
        'Nice try! You must write your own original sentence, not copy the example.',
  );
  static String errorGibberish(BuildContext context) => context.tr(
    'game.sentence_builder.error_gibberish',
    fallback: 'Write a proper, meaningful sentence.',
  );
  static String successMessage(BuildContext context) => context.tr(
    'game.sentence_builder.success_message',
    fallback: 'Great sentence! 🎯',
  );

  static String skipButton(BuildContext context) =>
      context.tr('game.sentence_builder.skip_button', fallback: 'SKIP');
  static String headerTitle(BuildContext context) => context.tr(
    'game.sentence_builder.header_title',
    fallback: 'USE IT IN A SENTENCE',
  );
  static String headerSubtitle(BuildContext context) => context.tr(
    'game.sentence_builder.header_subtitle',
    fallback: 'Prove your mastery using the target word.',
  );
  static String examplePrefix(BuildContext context) =>
      context.tr('game.sentence_builder.example_prefix', fallback: 'Example: ');
  static String hintText(BuildContext context) => context.tr(
    'game.sentence_builder.hint_text',
    fallback: 'Type your sentence here...',
  );

  static String wordsSuffix(BuildContext context) =>
      context.tr('game.sentence_builder.words_suffix', fallback: 'words');
  static String attemptsLeftSuffix(BuildContext context) => context.tr(
    'game.sentence_builder.attempts_left_suffix',
    fallback: 'attempts left',
  );
  static String practiceMode(BuildContext context) => context.tr(
    'game.sentence_builder.practice_mode',
    fallback: 'Practice Mode',
  );

  static String submitButton(BuildContext context) => context.tr(
    'game.sentence_builder.submit_button',
    fallback: 'SUBMIT SENTENCE',
  );
  static String masteryProven(BuildContext context) => context.tr(
    'game.sentence_builder.mastery_proven',
    fallback: 'MASTERY PROVEN! 🎯',
  );
}
