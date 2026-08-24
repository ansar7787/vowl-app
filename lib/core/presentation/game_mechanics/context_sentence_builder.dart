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

/// A mechanic where the user writes their own sentence using a target keyword.
///
/// Validates that:
/// 1. The target keyword is present in the sentence.
/// 2. The sentence meets minimum word count.
/// 3. The sentence is not gibberish (via GibberishDetectorService).
///
/// Usage:
/// ```dart
/// ContextSentenceBuilder(
///   targetKeyword: 'ambitious',
///   primaryColor: theme.primaryColor,
///   onConfirmed: () => _handleSuccess(),
///   onSkipped: () => _handleSkip(),
/// )
/// ```
class ContextSentenceBuilder extends StatefulWidget {
  /// The word/phrase the user must use in their sentence.
  final String targetKeyword;

  /// Theme accent colour.
  final Color primaryColor;

  /// Fires when the user successfully writes a valid sentence.
  final VoidCallback onConfirmed;

  /// Fires when the user skips or exhausts attempts.
  final VoidCallback onSkipped;

  /// Fires when the user watches an ad or uses premium to bypass the typing test.
  final VoidCallback? onBypassed;

  /// Minimum number of words required. Default 5.
  final int minWordCount;

  /// Accepted keyword forms for flexible matching
  /// (e.g. ["run", "running", "ran"]).
  /// If null, only exact match of targetKeyword is accepted.
  final List<String>? acceptedKeywordForms;

  /// Whether to wrap in a Positioned widget (for Stack layouts).
  final bool isPositioned;

  /// Max retry attempts before auto-skip.
  final int maxAttempts;

  /// Bonus coins on success.
  final int? bonusCoins;

  /// Whether to show skip button.
  final bool allowSkip;

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
  });

  @override
  State<ContextSentenceBuilder> createState() =>
      _ContextSentenceBuilderState();
}

class _ContextSentenceBuilderState extends State<ContextSentenceBuilder> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  int _attempts = 0;
  _BuilderStatus _status = _BuilderStatus.idle;
  String _feedbackMessage = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int get _currentWordCount {
    final text = _controller.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  void _evaluate() {
    if (_isSubmitting) return;
    final text = _controller.text.trim();

    // Check empty
    if (text.isEmpty) {
      setState(() {
        _status = _BuilderStatus.error;
        _feedbackMessage = 'Please write a sentence.';
      });
      _hapticService.error();
      return;
    }

    // Check word count
    final wordCount = text.split(RegExp(r'\s+')).length;
    if (wordCount < widget.minWordCount) {
      setState(() {
        _status = _BuilderStatus.error;
        _feedbackMessage =
            'Too short! Write at least ${widget.minWordCount} words.';
        _attempts++;
      });
      _hapticService.error();
      _checkAttemptLimit();
      return;
    }

    // Check keyword presence
    final lowerText = text.toLowerCase();
    final acceptedForms = widget.acceptedKeywordForms ??
        [widget.targetKeyword.toLowerCase()];
    final keywordFound = acceptedForms.any(
      (form) => lowerText.contains(form.toLowerCase()),
    );

    if (!keywordFound) {
      setState(() {
        _status = _BuilderStatus.error;
        _feedbackMessage =
            'Your sentence must include "${widget.targetKeyword}".';
        _attempts++;
      });
      _hapticService.error();
      _checkAttemptLimit();
      return;
    }

    // Check gibberish
    if (!GibberishDetectorService.isNaturalSentence(context, text)) {
      setState(() {
        _status = _BuilderStatus.error;
        _feedbackMessage = 'Write a proper, meaningful sentence.';
        _attempts++;
      });
      _hapticService.error();
      _checkAttemptLimit();
      return;
    }

    // SUCCESS
    setState(() {
      _status = _BuilderStatus.success;
      _feedbackMessage = 'Great sentence! 🎯';
      _isSubmitting = true;
    });
    _hapticService.success();
    _soundService.playCorrect();
    _focusNode.unfocus();

    // Award coins
    if (widget.bonusCoins != null && widget.bonusCoins! > 0) {
      context.read<EconomyBloc>().add(
        EconomyAddCoinsRequested(widget.bonusCoins!),
      );
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) widget.onConfirmed();
    });
  }

  void _checkAttemptLimit() {
    if (_attempts >= widget.maxAttempts) {
      _focusNode.unfocus();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onSkipped();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0C0C1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    final content = Material(
      type: MaterialType.transparency,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24.w,
          20.h,
          24.w,
          MediaQuery.of(context).viewInsets.bottom + 32.h,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(32.r),
          ),
          border: Border.all(
            color: _status == _BuilderStatus.success
                ? Colors.greenAccent.withValues(alpha: 0.5)
                : _status == _BuilderStatus.error
                    ? Colors.redAccent.withValues(alpha: 0.5)
                    : widget.primaryColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 48.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: subtitleColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),

              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      color: widget.primaryColor,
                      size: 22.r,
                    ),
                  ),
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
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: widget.primaryColor,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        AutoSizeText(
                          'Write your own sentence using the keyword',
                          maxLines: 2,
                          minFontSize: 6,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Target keyword chip
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 10.h,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.primaryColor.withValues(alpha: 0.15),
                      widget.primaryColor.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: widget.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.key_rounded,
                      color: widget.primaryColor,
                      size: 16.r,
                    ),
                    SizedBox(width: 8.w),
                    AutoSizeText(
                      widget.targetKeyword,
                      maxLines: 1,
                      minFontSize: 10,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: widget.primaryColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Text input + word counter
              if (_status != _BuilderStatus.success)
                Column(
                  children: [
                    Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: _status == _BuilderStatus.error
                                  ? Colors.redAccent.withValues(alpha: 0.5)
                                  : widget.primaryColor
                                      .withValues(alpha: 0.2),
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 3,
                            minLines: 2,
                            onChanged: (_) {
                              if (_status == _BuilderStatus.error) {
                                setState(
                                    () => _status = _BuilderStatus.idle);
                              }
                              setState(() {}); // Update word counter
                            },
                            onSubmitted: (_) => _evaluate(),
                            decoration: InputDecoration(
                              hintText:
                                  'Write a sentence with "${widget.targetKeyword}"...',
                              hintStyle: TextStyle(
                                color:
                                    subtitleColor.withValues(alpha: 0.6),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 16.h,
                              ),
                            ),
                          ),
                        )
                        .animate(
                            target:
                                _status == _BuilderStatus.error ? 1 : 0)
                        .shakeX(amount: 5, duration: 400.ms),

                    SizedBox(height: 8.h),

                    // Word counter + feedback
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Word count
                        AutoSizeText(
                          '$_currentWordCount / ${widget.minWordCount} words',
                          maxLines: 1,
                          minFontSize: 6,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: _currentWordCount >= widget.minWordCount
                                ? Colors.greenAccent
                                : subtitleColor,
                          ),
                        ),
                        // Attempt counter
                        if (_attempts > 0)
                          AutoSizeText(
                            '${widget.maxAttempts - _attempts} attempts left',
                            maxLines: 1,
                            minFontSize: 6,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                              color: subtitleColor.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),

                    // Error message
                    if (_status == _BuilderStatus.error &&
                        _feedbackMessage.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: AutoSizeText(
                          _feedbackMessage,
                          maxLines: 2,
                          minFontSize: 6,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent.withValues(alpha: 0.8),
                          ),
                        ),
                      ),

                    SizedBox(height: 16.h),

                    // Submit button
                    GestureDetector(
                      onTap: _evaluate,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          color: widget.primaryColor,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Center(
                          child: AutoSizeText(
                            'SUBMIT',
                            maxLines: 1,
                            minFontSize: 8,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Skip button
                    if (widget.allowSkip && _status != _BuilderStatus.success)
                      Padding(
                        padding: EdgeInsets.only(top: 12.h),
                        child: ScaleButton(
                          onTap: () {
                            if (_attempts >= widget.maxAttempts) {
                              widget.onSkipped();
                              return;
                            }
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
                                onDismissed: () {},
                              );
                            }
                          },
                          child: Builder(
                            builder: (context) {
                              final isPremium =
                                  context.watch<AuthBloc>().state.user?.isPremium ??
                                  false;
                              return AutoSizeText(
                                _attempts >= widget.maxAttempts
                                    ? 'CONTINUE'
                                    : (isPremium ? 'SKIP' : 'WATCH AD TO BYPASS'),
                                maxLines: 1,
                                minFontSize: 8,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: subtitleColor,
                                  letterSpacing: 1.5,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),

              // Success state
              if (_status == _BuilderStatus.success)
                Column(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: Colors.greenAccent,
                      size: 48.r,
                    ).animate().scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          duration: 400.ms,
                          curve: Curves.easeOutBack,
                        ),
                    SizedBox(height: 8.h),
                    AutoSizeText(
                      'PERFECT! 🎯',
                      maxLines: 1,
                      minFontSize: 8,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.greenAccent,
                        letterSpacing: 2,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
            ],
          ),
        ),
      ),
    )
    .animate()
    .slideY(
      begin: 1.0,
      end: 0,
      duration: 400.ms,
      curve: Curves.easeOut,
    )
    .fadeIn(duration: 300.ms);

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
