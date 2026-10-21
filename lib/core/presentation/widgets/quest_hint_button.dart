import 'dart:async';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/utils/hint_utility.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive hint button providing TTS-enabled hints, ad-backed rewarded
/// hints, and visual status badges with UI-level debouncing and race condition guards.
class QuestHintButton extends StatefulWidget {
  final bool used;
  final Color primaryColor;
  final String? hintText;
  final VoidCallback onTap;
  final SoundService soundService;

  const QuestHintButton({
    super.key,
    required this.used,
    required this.primaryColor,
    this.hintText,
    required this.onTap,
    required this.soundService,
  });

  @override
  State<QuestHintButton> createState() => _QuestHintButtonState();
}

class _QuestHintButtonState extends State<QuestHintButton> {
  DateTime? _lastTapTime;
  bool _isProcessing = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _activateHint(BuildContext context) {
    setState(() => _isProcessing = true);
    widget.soundService.playHint();
    widget.onTap();

    if (widget.hintText != null) {
      final isDynamic = HintUtility.isGenericHint(widget.hintText);
      final displayText = isDynamic
          ? context.tr(
              'hint.pro_tip_generic',
              fallback:
                  'PRO TIP: Look for context clues! Eliminating unlikely options often reveals the truth.',
            )
          : widget.hintText!;

      try {
        di.sl<TtsService>().stop();
        di.sl<TtsService>().speak(
          isDynamic
              ? context.tr(
                  'hint.pro_tip_tts',
                  fallback: 'Pro tip: Look for context clues.',
                )
              : widget.hintText!,
        );
      } catch (_) {}

      CustomSnackBar.show(
        context: context,
        message: displayText,
        type: CustomSnackBarType.info,
        duration: const Duration(seconds: 8),
      );
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  void _handleTap(BuildContext context, int hintCount) {
    if (widget.used || _isProcessing) return;

    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 1000)) {
      return;
    }
    _lastTapTime = now;

    final canUseHint = !widget.used && hintCount > 0;
    if (canUseHint) {
      _activateHint(context);
    } else if (!widget.used) {
      GameDialogHelper.showHintAdDialog(
        context,
        onHintEarned: () {
          if (!mounted) return;
          _activateHint(context);
        },
      );
    }
  }

  @override
  void didUpdateWidget(covariant QuestHintButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.used != oldWidget.used) {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final hintCount = state.user?.hintCount ?? 0;
        final isPremium = state.user?.isPremium ?? false;
        final canUseHint = !widget.used && hintCount > 0;

        return Semantics(
          button: true,
          enabled: !widget.used,
          label: widget.used
              ? context.tr(
                  'hint.already_used_semantic',
                  fallback: 'Hint already used',
                )
              : canUseHint
              ? context.tr(
                  'hint.use_hint_semantic',
                  args: ['$hintCount'],
                  fallback: 'Use hint ($hintCount remaining)',
                )
              : isPremium
              ? context.tr(
                  'hint.get_free_hint_semantic',
                  fallback: 'Get a free hint',
                )
              : context.tr(
                  'hint.watch_ad_semantic',
                  fallback: 'Watch ad to earn a hint',
                ),
          child: ScaleButton(
            onTap: () => _handleTap(context, hintCount),
            child: RepaintBoundary(
              child: Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: canUseHint
                      ? widget.primaryColor.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: canUseHint
                        ? widget.primaryColor.withValues(alpha: 0.4)
                        : Colors.grey.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    if (canUseHint)
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Main icon
                    Icon(
                          widget.used
                              ? Icons.psychology_outlined
                              : (hintCount > 0
                                    ? Icons.lightbulb_rounded
                                    : (isPremium
                                          ? Icons.add_circle_outline_rounded
                                          : Icons.video_collection_rounded)),
                          color: widget.used
                              ? Colors.grey
                              : (hintCount > 0
                                    ? widget.primaryColor
                                    : (isPremium
                                          ? tokens.gameCorrect
                                          : Colors.amber[700])),
                          size: 26.r,
                        )
                        .animate(
                          target: VowlMotion.shouldReduceMotion(context)
                              ? 0
                              : 1,
                          onPlay: (c) =>
                              widget.used ? c.stop() : c.repeat(reverse: true),
                        )
                        .shimmer(
                          duration: 2.seconds,
                          color: widget.primaryColor.withValues(alpha: 0.3),
                        ),

                    // Hint count badge (when hints available)
                    if (!widget.used && hintCount > 0)
                      Positioned(
                        top: 2.r,
                        right: 2.r,
                        child: Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color: widget.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16.r,
                            minHeight: 16.r,
                          ),
                          child: Center(
                            child: Text(
                              '$hintCount',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Ad badge (when 0 hints)
                    if (!widget.used && hintCount == 0)
                      Positioned(
                        bottom: 4.r,
                        right: 4.r,
                        child: Container(
                          padding: EdgeInsets.all(2.r),
                          decoration: BoxDecoration(
                            color: isPremium
                                ? Colors.green
                                : AppColors.amber500,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Icon(
                            isPremium ? Icons.add : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 10.r,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
