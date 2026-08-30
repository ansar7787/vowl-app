import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:vowl/core/utils/gibberish_detector_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class BlindDictationWrapper extends StatefulWidget {
  final String expectedText;
  final Color primaryColor;
  final VoidCallback onConfirmed;
  final VoidCallback onSkipped;
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
        _isSubmitting.value = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) widget.onSkipped();
        });
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
        _isSubmitting.value = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) widget.onSkipped();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0C0C1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;
    final errorColor = Colors.redAccent;

    final content = Material(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                widget.primaryColor.withValues(alpha: 0.7),
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
                    child: TextField(
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
                          color: subtitleColor.withValues(alpha: 0.5),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  )
                  .animate(target: hasError ? 1 : 0)
                  .shakeX(amount: 5, duration: 400.ms),

                  // Attempt counter
                  ValueListenableBuilder<int>(
                    valueListenable: _attempts,
                    builder: (context, attempts, _) {
                      if (attempts > 0 && attempts < widget.maxAttempts) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(
                            '${widget.maxAttempts - attempts} attempts remaining',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                              color: subtitleColor.withValues(alpha: 0.6),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  SizedBox(height: 24.h),

                  // Controls
                  ValueListenableBuilder<bool>(
                    valueListenable: _isSubmitting,
                    builder: (context, isSubmitting, _) {
                      return Row(
                        children: [
                          if (widget.allowSkip) ...[
                            Expanded(
                              flex: 1,
                              child: TextButton(
                                onPressed: isSubmitting ? null : () {
                                  _isSubmitting.value = true;
                                  widget.onSkipped();
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 16.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                ),
                                child: Text(
                                  'Skip',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: subtitleColor,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                          ],
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasError
                                    ? errorColor
                                    : widget.primaryColor,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                              ),
                              child: Text(
                                'Submit',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                  ],
                ),
              ),
            ),
          );
        }
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
