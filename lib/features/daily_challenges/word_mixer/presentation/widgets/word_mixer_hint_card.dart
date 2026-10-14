import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/daily_challenges/word_mixer/domain/models/word_mixer_puzzle.dart';

/// Progressive clue card featuring anti-leak masked definitions,
/// starting letter anchor, rewarded ad / premium hint unlocks, and TTS auditory reading.
class WordMixerHintCard extends StatefulWidget {
  final WordMixerPuzzle puzzle;
  final ValueNotifier<bool> isExpanded;
  final Color primaryColor;
  final HapticService? hapticService;
  final TtsService? ttsService;

  const WordMixerHintCard({
    super.key,
    required this.puzzle,
    required this.isExpanded,
    this.primaryColor = IllustrationColors.richPurple,
    this.hapticService,
    this.ttsService,
  });

  @override
  State<WordMixerHintCard> createState() => _WordMixerHintCardState();
}

class _WordMixerHintCardState extends State<WordMixerHintCard> {
  late final HapticService _hapticService =
      widget.hapticService ?? (di.sl.isRegistered<HapticService>() ? di.sl<HapticService>() : HapticService());
  late final TtsService? _ttsService =
      widget.ttsService ?? (di.sl.isRegistered<TtsService>() ? di.sl<TtsService>() : null);
  bool _isSpeaking = false;

  @override
  void dispose() {
    if (_isSpeaking) {
      _ttsService?.stop();
    }
    super.dispose();
  }

  void _onTapHeader(BuildContext context) {
    _hapticService.light();

    if (widget.isExpanded.value) {
      widget.isExpanded.value = false;
      return;
    }

    // Check if user is premium or if AuthBloc is available
    bool isPremium = false;
    try {
      final authState = context.read<AuthBloc>().state;
      isPremium = authState.user?.isPremium ?? false;
    } catch (_) {
      // In standalone tests where AuthBloc is not provided, default to allowing direct expand
      isPremium = true;
    }

    if (isPremium) {
      widget.isExpanded.value = true;
    } else {
      // Free user: prompt hint ad dialog
      GameDialogHelper.showHintAdDialog(
        context,
        onHintEarned: () {
          widget.isExpanded.value = true;
        },
      );
    }
  }

  Future<void> _speakDefinition() async {
    _hapticService.light();
    final tts = _ttsService;
    if (tts == null) return;
    if (_isSpeaking) {
      await tts.stop();
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }

    setState(() => _isSpeaking = true);
    try {
      // Strip out blank masks for natural TTS pronunciation
      final cleanText = widget.puzzle.maskedHint.replaceAll('______', 'the word');
      await tts.speak(cleanText);
    } finally {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    bool isPremium = false;
    try {
      final authState = context.watch<AuthBloc>().state;
      isPremium = authState.user?.isPremium ?? false;
    } catch (_) {
      isPremium = false;
    }

    return ValueListenableBuilder<bool>(
      valueListenable: widget.isExpanded,
      builder: (context, expanded, _) {
        return Semantics(
          label: expanded ? 'Collapse hint' : 'Expand hint',
          button: true,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: expanded
                    ? widget.primaryColor.withValues(alpha: 0.45)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.slate200),
                width: expanded ? 1.5.w : 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: expanded
                      ? widget.primaryColor.withValues(alpha: isDark ? 0.15 : 0.06)
                      : Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                  blurRadius: expanded ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Row (Tap target) ─────────────────────────────────
                InkWell(
                  onTap: () => _onTapHeader(context),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(7.r),
                          decoration: BoxDecoration(
                            color: AppColors.amber500.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lightbulb_rounded,
                            size: 16.r,
                            color: AppColors.amber500,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expanded
                                    ? context.tr('home.hint', fallback: 'HINT')
                                    : context.tr(
                                        'home.tap_for_hint',
                                        fallback: 'Tap for hint',
                                      ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: expanded
                                      ? widget.primaryColor
                                      : (isDark ? Colors.white : AppColors.slate800),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              if (!expanded) ...[
                                SizedBox(height: 1.h),
                                Text(
                                  isPremium
                                      ? 'Included with your Premium plan'
                                      : 'Watch a short ad to see hint',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white54 : AppColors.slate500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),

                        // Reward / Free badge pill
                        if (!expanded)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: isPremium
                                  ? AppColors.amber500.withValues(alpha: 0.14)
                                  : widget.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: isPremium
                                    ? AppColors.amber500.withValues(alpha: 0.3)
                                    : widget.primaryColor.withValues(alpha: 0.2),
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPremium
                                      ? Icons.star_rounded
                                      : Icons.play_circle_outline_rounded,
                                  size: 11.r,
                                  color: isPremium ? AppColors.amber500 : widget.primaryColor,
                                ),
                                SizedBox(width: 3.w),
                                Text(
                                  isPremium ? 'FREE' : 'AD',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isPremium ? AppColors.amber500 : widget.primaryColor,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(width: 8.w),
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: isDark ? Colors.white38 : AppColors.slate400,
                            size: 20.r,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Expanded Content (Clue + Audio + Definition) ───────────
                if (expanded)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        SizedBox(height: 12.h),

                        // Definition Text with anti-leak protection
                        Text(
                          widget.puzzle.maskedHint,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.9)
                                : AppColors.slate800,
                            height: 1.45,
                            letterSpacing: 0.15,
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // Action row: Anchor clue + Listen button
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            // Starts with anchor pill
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: widget.primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: widget.primaryColor.withValues(alpha: 0.2),
                                  width: 1.w,
                                ),
                              ),
                              child: Text(
                                'Starts with: ${widget.puzzle.firstLetter}',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: widget.primaryColor,
                                ),
                              ),
                            ),

                            // Listen button
                            ScaleButton(
                              onTap: _speakDefinition,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.primaryColor.withValues(alpha: isDark ? 0.18 : 0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: widget.primaryColor.withValues(alpha: 0.25),
                                    width: 1.w,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isSpeaking
                                          ? Icons.volume_up_rounded
                                          : Icons.volume_down_rounded,
                                      size: 15.r,
                                      color: widget.primaryColor,
                                    ),
                                    SizedBox(width: 5.w),
                                    Text(
                                      _isSpeaking
                                          ? context.tr('common.stop', fallback: 'Stop')
                                          : context.tr('common.listen', fallback: 'Listen'),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: widget.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
