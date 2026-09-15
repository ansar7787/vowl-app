import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/utils/locale_service.dart';

import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/analytics_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

/// A reusable skip/bypass button for game mechanics.
///
/// For premium users, skips immediately. For free users, shows a rewarded ad
/// before allowing bypass. After [maxAttempts] are exhausted, shows a plain
/// "CONTINUE" button that fires [onSkipped] directly.
///
/// Usage:
/// ```dart
/// GameSkipBypassButton(
///   subtitleColor: Colors.black54,
///   isSubmitting: _isSubmitting,
///   attempts: _attempts,
///   maxAttempts: widget.maxAttempts,
///   onBypassed: widget.onBypassed,
///   onConfirmed: widget.onConfirmed,
///   onSkipped: widget.onSkipped,
///   onSubmittingChanged: (v) => _isSubmitting.value = v,
/// )
/// ```
class GameSkipBypassButton extends StatefulWidget {
  /// Text/icon color.
  final Color subtitleColor;

  /// ValueNotifier for the submitting state (to prevent double-taps).
  final ValueListenable<bool> isSubmitting;

  /// Current attempts ValueNotifier.
  final ValueListenable<int>? attempts;

  /// Max attempts before auto-continuing. Pass null to never auto-continue.
  final int? maxAttempts;

  /// Fires when bypassed via ad or premium skip.
  final VoidCallback? onBypassed;

  /// Fires on successful confirmation (fallback if [onBypassed] is null).
  final VoidCallback onConfirmed;

  /// Fires when max attempts reached and user taps continue.
  final VoidCallback onSkipped;

  /// Called to update the submitting state.
  final ValueChanged<bool> onSubmittingChanged;

  /// Optional override for the skip label text.
  final String? skipLabel;

  const GameSkipBypassButton({
    super.key,
    required this.subtitleColor,
    required this.isSubmitting,
    this.attempts,
    this.maxAttempts,
    this.onBypassed,
    required this.onConfirmed,
    required this.onSkipped,
    required this.onSubmittingChanged,
    this.skipLabel,
  });

  @override
  State<GameSkipBypassButton> createState() => _GameSkipBypassButtonState();
}

class _GameSkipBypassButtonState extends State<GameSkipBypassButton> {
  bool _isPressed = false;

  void _handleTap(BuildContext context, int currentAttempts) {
    // Guard: prevent double-taps while submitting
    if (widget.isSubmitting.value) return;

    if (widget.maxAttempts != null && currentAttempts >= widget.maxAttempts!) {
      widget.onSubmittingChanged(true);
      di.sl<AnalyticsService>().logGameSkipped(false);
      widget.onSkipped();
      return;
    }

    widget.onSubmittingChanged(true);
    final user = context.read<AuthBloc>().state.user;
    final isPremium = user?.isPremium ?? false;

    if (isPremium) {
      di.sl<AnalyticsService>().logGameSkipped(false);
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
          di.sl<AnalyticsService>().logGameSkipped(true);
          if (widget.onBypassed != null) {
            widget.onBypassed!();
          } else {
            widget.onConfirmed();
          }
        },
        onDismissed: () {
          widget.onSubmittingChanged(false);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buildButton(int currentAttempts) {
      final outOfAttempts =
          widget.maxAttempts != null && currentAttempts >= widget.maxAttempts!;

      return Semantics(
        button: true,
        label: outOfAttempts
            ? context.tr('game.continue_button', fallback: 'Continue')
            : context.tr(
                'game.skip_and_watch_ad',
                fallback: 'Skip and watch an ad',
              ),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () {
            setState(() => _isPressed = false);
            _handleTap(context, currentAttempts);
          },
          child: AnimatedScale(
            scale: _isPressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: widget.subtitleColor.withValues(
                  alpha: _isPressed ? 0.2 : 0.1,
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    outOfAttempts
                        ? context.tr(
                            'game.continue_button',
                            fallback: 'CONTINUE',
                          )
                        : (widget.skipLabel ??
                              context.tr('game.skip_button', fallback: 'SKIP')),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: widget.subtitleColor.withValues(alpha: 0.8),
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final isPremium =
                          context.watch<AuthBloc>().state.user?.isPremium ??
                          false;
                      if (!isPremium && !outOfAttempts) {
                        return Padding(
                          padding: EdgeInsets.only(left: 4.w),
                          child: Icon(
                            Icons.ondemand_video_rounded,
                            size: 12.r,
                            color: widget.subtitleColor.withValues(alpha: 0.8),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (widget.attempts != null) {
      return ValueListenableBuilder<int>(
        valueListenable: widget.attempts!,
        builder: (context, currentAttempts, _) {
          return buildButton(currentAttempts);
        },
      );
    }

    return buildButton(0);
  }
}
