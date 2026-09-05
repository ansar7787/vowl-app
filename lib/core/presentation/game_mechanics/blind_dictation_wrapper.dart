import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:vowl/core/utils/gibberish_detector_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class BlindDictationWrapper extends StatefulWidget {
  final String expectedText;
  final Color primaryColor;
  final VoidCallback onConfirmed;
  final VoidCallback onSkipped;
  final VoidCallback? onBypassed;
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
    this.bonusCoins = 5,
    this.allowSkip = true,
    this.isPositioned = true,
    this.maxAttempts = 3,
  });

  @override
  State<BlindDictationWrapper> createState() => _BlindDictationWrapperState();
}

class _BlindDictationWrapperState extends State<BlindDictationWrapper> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final ValueNotifier<bool> _hasError = ValueNotifier(false);
  final ValueNotifier<int> _attempts = ValueNotifier(0);
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);

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
      _attempts.value++;
      _hapticService.error();
      if (_attempts.value >= widget.maxAttempts) {
        _focusNode.unfocus();
      }
      return;
    }

    String cleanInput = input
        .replaceAll(RegExp(r'[.,!?]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    String cleanCorrect = widget.expectedText
        .replaceAll(RegExp(r'[.,!?]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();

    if (cleanInput == cleanCorrect) {
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
      _attempts.value++;
      if (_attempts.value >= widget.maxAttempts) {
        _focusNode.unfocus();
      }
    }
  }

  Widget _buildSkipButton(Color subtitleColor) {
    return ValueListenableBuilder<int>(
      valueListenable: _attempts,
      builder: (context, attempts, _) {
        return GestureDetector(
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
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: subtitleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attempts >= widget.maxAttempts ? 'CONTINUE' : 'SKIP',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: subtitleColor.withValues(alpha: 0.8),
                  ),
                ),
                Builder(
                  builder: (context) {
                    final isPremium =
                        context.watch<AuthBloc>().state.user?.isPremium ??
                        false;
                    if (!isPremium && attempts < widget.maxAttempts) {
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
    final bgColor = isDark ? const Color(0xFF0C0C1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;
    final errorColor = Colors.redAccent;

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
                                    child: _buildSkipButton(subtitleColor),
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
                                                  color: Colors.redAccent
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
