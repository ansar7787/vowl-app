import 'dart:ui';
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
import 'package:vowl/core/presentation/widgets/scale_button.dart';

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

  final ValueNotifier<int> _attempts = ValueNotifier(0);
  final ValueNotifier<_BuilderStatus> _status = ValueNotifier(_BuilderStatus.idle);
  final ValueNotifier<String> _feedbackMessage = ValueNotifier('');
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);

  @override
  void dispose() {
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

    if (text.isEmpty) {
      _status.value = _BuilderStatus.error;
      _feedbackMessage.value = 'Please write a sentence.';
      _hapticService.error();
      return;
    }

    final wordCount = text.split(RegExp(r'\s+')).length;
    if (wordCount < widget.minWordCount) {
      _status.value = _BuilderStatus.error;
      _feedbackMessage.value = 'Too short! Write at least ${widget.minWordCount} words.';
      _attempts.value++;
      _hapticService.error();
      _checkAttemptLimit();
      return;
    }

    final lowerText = text.toLowerCase();
    final acceptedForms = widget.acceptedKeywordForms ?? [widget.targetKeyword.toLowerCase()];
    final keywordFound = acceptedForms.any(
      (form) => lowerText.contains(form.toLowerCase()),
    );

    if (!keywordFound) {
      _status.value = _BuilderStatus.error;
      _feedbackMessage.value = 'Your sentence must include "${widget.targetKeyword}".';
      _attempts.value++;
      _hapticService.error();
      _checkAttemptLimit();
      return;
    }

    if (widget.exampleSentence != null) {
      final String formattedExample = widget.exampleSentence!.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
      final String formattedInput = lowerText.replaceAll(RegExp(r'[^\w\s]'), '').trim();

      if (formattedInput == formattedExample) {
        _status.value = _BuilderStatus.error;
        _feedbackMessage.value = 'Nice try! You must write your own original sentence, not copy the example.';
        _attempts.value++;
        _hapticService.error();
        _checkAttemptLimit();
        return;
      }
    }

    if (!GibberishDetectorService.isNaturalSentence(context, text)) {
      _status.value = _BuilderStatus.error;
      _feedbackMessage.value = 'Write a proper, meaningful sentence.';
      _attempts.value++;
      _hapticService.error();
      _checkAttemptLimit();
      return;
    }

    _status.value = _BuilderStatus.success;
    _feedbackMessage.value = 'Great sentence! 🎯';
    _isSubmitting.value = true;
    _hapticService.success();
    _soundService.playCorrect();
    _focusNode.unfocus();

    if (widget.bonusCoins != null && widget.bonusCoins! > 0) {
      context.read<EconomyBloc>().add(EconomyAddCoinsRequested(widget.bonusCoins!));
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) widget.onConfirmed();
    });
  }

  void _checkAttemptLimit() {
    if (_attempts.value >= widget.maxAttempts) {
      _focusNode.unfocus();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onSkipped();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final glassColor = isDark 
        ? widget.primaryColor.withValues(alpha: 0.1) 
        : Colors.white.withValues(alpha: 0.6);
        
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70 : Colors.black87;

    final content = Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          bottom: widget.isPositioned ? MediaQuery.of(context).viewInsets.bottom + 24.h : 0,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: ValueListenableBuilder<_BuilderStatus>(
              valueListenable: _status,
              builder: (context, status, child) {
                final borderColor = status == _BuilderStatus.success
                    ? Colors.greenAccent.withValues(alpha: 0.5)
                    : status == _BuilderStatus.error
                        ? Colors.redAccent.withValues(alpha: 0.5)
                        : isDark ? widget.primaryColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.8);

                return Container(
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    color: glassColor,
                    borderRadius: BorderRadius.circular(32.r),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.2) : widget.primaryColor.withValues(alpha: 0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: widget.primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Icon(
                          Icons.history_edu_rounded,
                          color: widget.primaryColor,
                          size: 22.r,
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05), duration: 1.5.seconds),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              'USE IT IN A SENTENCE',
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
                              'Prove your mastery using the target word.',
                              maxLines: 1,
                              minFontSize: 6,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                color: subtitleColor,
                              ),
                            ),
                            if (widget.exampleSentence != null && widget.exampleSentence!.isNotEmpty) ...[
                              SizedBox(height: 6.h),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: widget.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(color: widget.primaryColor.withValues(alpha: 0.2)),
                                ),
                                child: AutoSizeText(
                                  'Example: "${widget.exampleSentence!}"',
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
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Target keyword chip
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: widget.primaryColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.key_rounded, color: widget.primaryColor, size: 16.r),
                        SizedBox(width: 8.w),
                        AutoSizeText(
                          widget.targetKeyword.toUpperCase(),
                          maxLines: 1,
                          minFontSize: 10,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                            color: widget.primaryColor,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Text input area
                  ValueListenableBuilder<_BuilderStatus>(
                    valueListenable: _status,
                    builder: (context, status, _) {
                      if (status == _BuilderStatus.success) return const SizedBox.shrink();
                      
                      return Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: status == _BuilderStatus.error
                                    ? Colors.redAccent.withValues(alpha: 0.5)
                                    : isDark ? Colors.white10 : Colors.black12,
                              ),
                            ),
                            child: TextField(
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
                                hintText: 'Type your sentence here...',
                                hintStyle: TextStyle(
                                  color: subtitleColor.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                              ),
                            ),
                          ).animate(target: status == _BuilderStatus.error ? 1 : 0).shakeX(amount: 5, duration: 400.ms),

                          SizedBox(height: 12.h),

                          // Word counter + feedback
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _controller,
                                builder: (context, value, _) {
                                  final text = value.text.trim();
                                  final wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
                                  return AutoSizeText(
                                    '$wordCount / ${widget.minWordCount} words',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: wordCount >= widget.minWordCount
                                          ? Colors.greenAccent
                                          : subtitleColor.withValues(alpha: 0.7),
                                    ),
                                  );
                                },
                              ),
                              ValueListenableBuilder<int>(
                                valueListenable: _attempts,
                                builder: (context, attempts, _) {
                                  if (attempts > 0) {
                                    return AutoSizeText(
                                      '${widget.maxAttempts - attempts} attempts left',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: subtitleColor.withValues(alpha: 0.5),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),

                          // Error message
                          if (status == _BuilderStatus.error)
                            ValueListenableBuilder<String>(
                              valueListenable: _feedbackMessage,
                              builder: (context, feedback, _) {
                                if (feedback.isEmpty) return const SizedBox.shrink();
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

                          // Submit button
                          GestureDetector(
                            onTap: _evaluate,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [widget.primaryColor, widget.primaryColor.withValues(alpha: 0.8)],
                                ),
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Center(
                                child: AutoSizeText(
                                  'SUBMIT SENTENCE',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Skip button
                          if (widget.allowSkip)
                            ValueListenableBuilder<int>(
                              valueListenable: _attempts,
                              builder: (context, attempts, _) {
                                return Padding(
                                  padding: EdgeInsets.only(top: 16.h),
                                  child: ScaleButton(
                                    onTap: () {
                                      if (_isSubmitting.value) return;
                                      
                                      if (attempts >= widget.maxAttempts) {
                                        _isSubmitting.value = true;
                                        widget.onSkipped();
                                        return;
                                      }
                                      
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
                                    child: Builder(
                                      builder: (context) {
                                        final isPremium = context.watch<AuthBloc>().state.user?.isPremium ?? false;
                                        return AutoSizeText(
                                          attempts >= widget.maxAttempts
                                              ? 'CONTINUE'
                                              : (isPremium ? 'SKIP' : 'WATCH AD TO BYPASS'),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w800,
                                            color: subtitleColor.withValues(alpha: 0.6),
                                            letterSpacing: 1.5,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }
                            ),
                        ],
                      );
                    }
                  ),

                  // Success state
                  ValueListenableBuilder<_BuilderStatus>(
                    valueListenable: _status,
                    builder: (context, status, _) {
                      if (status != _BuilderStatus.success) return const SizedBox.shrink();
                      
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
                            'MASTERY PROVEN! 🎯',
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
                    }
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().slideY(
          begin: 1.0,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOut,
        ).fadeIn(duration: 400.ms);

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
}

enum _BuilderStatus { idle, error, success }
