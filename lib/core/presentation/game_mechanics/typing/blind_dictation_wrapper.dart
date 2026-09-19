import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:vowl/core/utils/gibberish_detector_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/game_skip_bypass_button.dart';

import 'package:vowl/core/presentation/game_mechanics/typing/smart_typo_controller.dart';

class BlindDictationWrapper extends StatefulWidget {
  final String expectedText;
  final Color primaryColor;
  final VoidCallback onConfirmed;
  final VoidCallback onSkipped;
  final VoidCallback? onBypassed;
  final VoidCallback? onReplayAudio;
  final int? bonusCoins;
  final bool allowSkip;

  /// Whether to wrap in a Positioned widget (for Stack layouts).
  /// Set to false for Sliver/scroll layouts.
  final bool isPositioned;

  /// Maximum number of attempts before auto-skip. Default 3.
  final int maxAttempts;

  const BlindDictationWrapper({
    super.key,
    required this.expectedText,
    required this.primaryColor,
    required this.onConfirmed,
    required this.onSkipped,
    this.onBypassed,
    this.onReplayAudio,
    this.bonusCoins = 5,
    this.allowSkip = true,
    this.isPositioned = true,
    this.maxAttempts = 3,
  });

  @override
  State<BlindDictationWrapper> createState() => _BlindDictationWrapperState();
}

class _BlindDictationWrapperState extends State<BlindDictationWrapper> {
  /// Strips all non-word, non-space characters (punctuation, quotes, etc.)
  /// Matches behavior of TextSimilarityHelper.normalizeText.
  static final _punctuationPattern = RegExp(r'[^\w\s]');
  static final _whitespacePattern = RegExp(r'\s+');

  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  late final SmartTypoController _controller;
  final FocusNode _focusNode = FocusNode();

  final ValueNotifier<bool> _hasError = ValueNotifier(false);
  final ValueNotifier<int> _attempts = ValueNotifier(0);
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _controller = SmartTypoController(expectedText: widget.expectedText);
    _controller.addListener(() {
      if (_controller.showDiff) {
        _controller.showDiff = false;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _hasError.dispose();
    _attempts.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_isSubmitting.value) return;
    final input = _controller.text.trim();
    if (input.isEmpty) {
      _hasError.value = true;
      _hapticService.error();
      return;
    }

    if (!GibberishDetectorService.isNaturalSentence(context, input)) {
      _hasError.value = true;
      _controller.showDiff = true;
      _attempts.value++;
      _hapticService.error();
      if (_attempts.value >= widget.maxAttempts) {
        _focusNode.unfocus();
      }
      return;
    }

    String cleanInput = input
        .replaceAll(_punctuationPattern, '')
        .replaceAll(_whitespacePattern, ' ')
        .trim()
        .toLowerCase();
    String cleanCorrect = widget.expectedText
        .replaceAll(_punctuationPattern, '')
        .replaceAll(_whitespacePattern, ' ')
        .trim()
        .toLowerCase();

    if (cleanInput == cleanCorrect) {
      _controller.showDiff = false;
      _isSubmitting.value = true;
      _hasError.value = false;
      _hapticService.success();
      _soundService.playCorrect();
      _focusNode.unfocus();

      // Award bonus coins
      if (widget.bonusCoins != null && widget.bonusCoins! > 0) {
        context.read<EconomyBloc>().add(
          EconomyAddCoinsRequested(widget.bonusCoins!),
        );
      }
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) widget.onConfirmed();
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _hasError.value = true;
      _controller.showDiff = true;
      _attempts.value++;
      if (_attempts.value >= widget.maxAttempts) {
        _focusNode.unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final bgColor = isDark ? const Color(0xFF0C0C1A) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.slate900;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;
    final errorColor = tokens.gameIncorrect;

    final content =
        Material(
              type: MaterialType.transparency,
              child: ValueListenableBuilder<bool>(
                valueListenable: _hasError,
                builder: (context, hasError, _) {
                  return Container(
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
                        color: hasError
                            ? errorColor.withValues(alpha: 0.5)
                            : widget.primaryColor.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: hasError
                              ? errorColor.withValues(alpha: 0.15)
                              : widget.primaryColor.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
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
                                    color: widget.primaryColor.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Icon(
                                    Icons.hearing_rounded,
                                    color: widget.primaryColor,
                                    size: 22.r,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'BLIND DICTATION',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w900,
                                          color: widget.primaryColor,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        'Type exactly what you heard',
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
                                if (widget.onReplayAudio != null) ...[
                                  SizedBox(width: 8.w),
                                  Semantics(
                                    button: true,
                                    label: 'Replay audio',
                                    child: GestureDetector(
                                      onTap: () {
                                        _hapticService.selection();
                                        widget.onReplayAudio!();
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(8.r),
                                        decoration: BoxDecoration(
                                          color: widget.primaryColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.replay_rounded,
                                          color: widget.primaryColor,
                                          size: 20.r,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (widget.bonusCoins != null)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          widget.primaryColor,
                                          widget.primaryColor.withValues(
                                            alpha: 0.7,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Text(
                                      '+${widget.bonusCoins} Coins',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
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
                                      onSubmittingChanged: (v) =>
                                          _isSubmitting.value = v,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 24.h),

                            // Text Input
                            Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: hasError
                                          ? errorColor.withValues(alpha: 0.5)
                                          : widget.primaryColor.withValues(
                                              alpha: 0.3,
                                            ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      TextField(
                                        controller: _controller,
                                        focusNode: _focusNode,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                        maxLines: 3,
                                        minLines: 1,
                                        onChanged: (_) {
                                          if (_hasError.value) {
                                            _hasError.value = false;
                                          }
                                        },
                                        onSubmitted: (_) => _onSubmit(),
                                        decoration: InputDecoration(
                                          hintText: 'Type here...',
                                          hintStyle: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w500,
                                            color: subtitleColor.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                          contentPadding: EdgeInsets.only(
                                            left: 16.w,
                                            right: 16.w,
                                            top: 16.h,
                                            bottom: 32.h,
                                          ),
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 12.h,
                                        left: 16.w,
                                        child: ValueListenableBuilder<int>(
                                          valueListenable: _attempts,
                                          builder: (context, attempts, _) {
                                            if (attempts > 0) {
                                              return Text(
                                                '${widget.maxAttempts - attempts} attempts left',
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 10.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: tokens.gameIncorrect
                                                      .withValues(alpha: 0.8),
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .animate(target: hasError ? 1 : 0)
                                .shakeX(amount: 5, duration: 400.ms),

                            SizedBox(height: 24.h),

                            // Controls
                            ValueListenableBuilder<bool>(
                              valueListenable: _isSubmitting,
                              builder: (context, isSubmitting, _) {
                                return ValueListenableBuilder<int>(
                                  valueListenable: _attempts,
                                  builder: (context, attempts, _) {
                                    final outOfAttempts =
                                        attempts >= widget.maxAttempts;
                                    return SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: isSubmitting
                                            ? null
                                            : () {
                                                if (outOfAttempts) {
                                                  _isSubmitting.value = true;
                                                  widget.onSkipped();
                                                } else {
                                                  _onSubmit();
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: outOfAttempts
                                              ? Colors.grey.withValues(
                                                  alpha: 0.8,
                                                )
                                              : hasError
                                              ? errorColor
                                              : widget.primaryColor,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 16.h,
                                          ),
                                          elevation: outOfAttempts ? 0 : 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          outOfAttempts ? 'CONTINUE' : 'SUBMIT',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: outOfAttempts
                                                ? 2
                                                : 1,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
            .animate()
            .slideY(begin: 1.0, end: 0, duration: 400.ms, curve: Curves.easeOut)
            .fadeIn(duration: 300.ms);

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
}
