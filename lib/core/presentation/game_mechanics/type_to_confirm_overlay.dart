import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/text_similarity_helper.dart';
import 'package:vowl/core/utils/gibberish_detector_service.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

/// click/drag answer, requiring the user to type the answer before
/// proceeding.
class TypeToConfirmOverlay extends StatefulWidget {
  /// The expected text to match against input.
  final String expectedText;

  /// Optional display text shown to the user (if different from expectedText).
  /// Falls back to [expectedText] if null.
  final String? displayText;

  /// Theme accent colour for the overlay chrome.
  final Color primaryColor;

  /// Fires when the user successfully types the answer.
  final VoidCallback onConfirmed;

  /// Fires when the user exhausts retries or taps "Skip" (and isn't bypassing).
  final VoidCallback onSkipped;

  /// Fires when the user watches an ad or uses premium to bypass the typing test.
  final VoidCallback? onBypassed;

  /// Similarity threshold for text match (0.0–1.0). Default 0.85
  final double threshold;

  /// Maximum number of recording attempts before auto-skip. Default 3.
  final int maxAttempts;

  /// Bonus Coins label shown on success. Null hides the badge entirely.
  final int? bonusCoins;

  /// Whether to show a "Skip" button. Defaults to true for accessibility.
  final bool allowSkip;

  /// Whether to wrap the overlay in a Positioned widget (for Stack layouts).
  /// Defaults to true for legacy support. Set to false for Sliver layouts.
  final bool isPositioned;

  const TypeToConfirmOverlay({
    super.key,
    required this.expectedText,
    this.displayText,
    required this.primaryColor,
    required this.onConfirmed,
    required this.onSkipped,
    this.onBypassed,
    this.threshold = 0.85,
    this.maxAttempts = 3,
    this.bonusCoins,
    this.allowSkip = true,
    this.isPositioned = true,
  });

  @override
  State<TypeToConfirmOverlay> createState() => _TypeToConfirmOverlayState();
}

class _TypeToConfirmOverlayState extends State<TypeToConfirmOverlay> {
  final _hapticService = di.sl<HapticService>();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  int _attempts = 0;
  _ConfirmResult? _result;



  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _evaluate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _result = _ConfirmResult.empty);
      return;
    }

    if (!GibberishDetectorService.isNaturalSentence(context, text)) {
      setState(() => _result = _ConfirmResult.mismatch);
      _attempts++;
      return;
    }

    bool matched = TextSimilarityHelper.isMatch(
      text,
      widget.expectedText,
      threshold: widget.threshold,
    );

    setState(() {
      _attempts++;
      _result = matched ? _ConfirmResult.success : _ConfirmResult.mismatch;
    });

    if (matched) {
      _hapticService.success();
      _focusNode.unfocus();
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) widget.onConfirmed();
    } else {
      _hapticService.error();
      if (_attempts >= widget.maxAttempts) {
        _focusNode.unfocus();
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) widget.onSkipped();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = _buildPanel(isDark)
        .animate()
        .slideY(begin: 1.0, end: 0, duration: 400.ms, curve: Curves.easeOut)
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

  Widget _buildPanel(bool isDark) {
    final bgColor = isDark ? const Color(0xFF0C0C1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24.w,
        20.h,
        24.w,
        MediaQuery.of(context).viewInsets.bottom + 32.h,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        border: Border.all(
          color: widget.primaryColor.withValues(alpha: 0.2),
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
                        'NOW TYPE IT!',
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
                        'Type the answer to confirm',
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
                      '+${widget.bonusCoins} COIN',
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
            SizedBox(height: 20.h),

            // Expected text display
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: widget.primaryColor.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                widget.displayText ?? widget.expectedText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Input field
            if (_result != _ConfirmResult.success)
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: _result == _ConfirmResult.mismatch
                        ? Colors.redAccent.withValues(alpha: 0.5)
                        : Colors.transparent,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type exactly...',
                    hintStyle: TextStyle(
                      color: subtitleColor.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                  ),
                  onSubmitted: (_) => _evaluate(),
                ),
              ),

            // Status message
            if (_result != null && _result != _ConfirmResult.success)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: _resultColor.withValues(alpha: 0.8),
                  ),
                ),
              ),

            // Submit button
            if (_result != _ConfirmResult.success)
              Padding(
                padding: EdgeInsets.only(top: 16.h),
                child: ScaleButton(
                  onTap: _evaluate,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      color: widget.primaryColor,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Center(
                      child: Text(
                        'SUBMIT',
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
              ),

            // Skip button
            if (widget.allowSkip && _result != _ConfirmResult.success)
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
                        widget.onSkipped();
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
                              widget.onSkipped();
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
                      return Text(
                        _attempts >= widget.maxAttempts
                            ? 'CONTINUE'
                            : (isPremium ? 'SKIP' : 'WATCH AD TO BYPASS'),
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

            // Attempt counter
            if (_attempts > 0 && _result != _ConfirmResult.success)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  '${widget.maxAttempts - _attempts} attempts remaining',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor.withValues(alpha: 0.6),
                  ),
                ),
              ),

            // Success state
            if (_result == _ConfirmResult.success)
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
                  Text(
                    'PERFECT! 🎯',
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
    );
  }

  Color get _resultColor {
    switch (_result) {
      case _ConfirmResult.success:
        return Colors.greenAccent;
      case _ConfirmResult.mismatch:
        return Colors.redAccent;
      case _ConfirmResult.empty:
        return Colors.orangeAccent;
      case null:
        return widget.primaryColor;
    }
  }

  String get _statusMessage {
    switch (_result) {
      case _ConfirmResult.mismatch:
        return "Hmm, that didn't match. Try checking your spelling!";
      case _ConfirmResult.empty:
        return 'Please type your answer.';
      default:
        return '';
    }
  }
}

enum _ConfirmResult { success, mismatch, empty }
