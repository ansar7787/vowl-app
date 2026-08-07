import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vowl/core/utils/gibberish_detector_service.dart';

class BlindDictationWrapper extends StatefulWidget {
  final String expectedText;
  final Color primaryColor;
  final VoidCallback onConfirmed;
  final VoidCallback onSkipped;
  final int? bonusCoins;
  final bool allowSkip;

  const BlindDictationWrapper({
    super.key,
    required this.expectedText,
    required this.primaryColor,
    required this.onConfirmed,
    required this.onSkipped,
    this.bonusCoins = 5,
    this.allowSkip = true,
  });

  @override
  State<BlindDictationWrapper> createState() => _BlindDictationWrapperState();
}

class _BlindDictationWrapperState extends State<BlindDictationWrapper> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasError = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    if (!GibberishDetectorService.isNaturalSentence(context, input)) {
      setState(() => _hasError = true);
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
      widget.onConfirmed();
    } else {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0C0C1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;
    final errorColor = Colors.redAccent;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child:
          Material(
                type: MaterialType.transparency,
                child: Container(
                  padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32.r),
                    ),
                    border: Border.all(
                      color: _hasError
                          ? errorColor.withValues(alpha: 0.5)
                          : widget.primaryColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _hasError
                            ? errorColor.withValues(alpha: 0.15)
                            : widget.primaryColor.withValues(alpha: 0.15),
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
                                color: widget.primaryColor.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Icon(
                                Icons.keyboard_rounded,
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
                                  color: _hasError
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
                                  if (_hasError) {
                                    setState(() => _hasError = false);
                                  }
                                },
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
                            .animate(target: _hasError ? 1 : 0)
                            .shakeX(amount: 5, duration: 400.ms),

                        SizedBox(height: 24.h),

                        // Controls
                        Row(
                          children: [
                            if (widget.allowSkip) ...[
                              Expanded(
                                flex: 1,
                                child: TextButton(
                                  onPressed: widget.onSkipped,
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
                                onPressed: _onSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _hasError
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
              .fadeIn(duration: 300.ms),
    );
  }
}
