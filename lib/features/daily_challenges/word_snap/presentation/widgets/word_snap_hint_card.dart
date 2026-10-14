import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/daily_challenges/word_snap/domain/models/word_snap_puzzle.dart';

/// Progressive hint card for Word Snap.
///
/// Features:
/// - Premium users get instant free hint access.
/// - Free users unlock hints via rewarded ads (matching other games in Vowl).
/// - Tiered anchor clue with starting word, word count, TTS audio, and sanitized definition.
class WordSnapHintCard extends StatelessWidget {
  final WordSnapPuzzle puzzle;
  final ValueNotifier<bool> isExpandedNotifier;
  final Color primaryColor;
  final SoundService soundService;
  final HapticService hapticService;

  const WordSnapHintCard({
    super.key,
    required this.puzzle,
    required this.isExpandedNotifier,
    required this.primaryColor,
    required this.soundService,
    required this.hapticService,
  });

  void _onTapHeader(BuildContext context) {
    hapticService.light();

    if (isExpandedNotifier.value) {
      isExpandedNotifier.value = false;
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
      soundService.playHint();
      isExpandedNotifier.value = true;
    } else {
      // Free user: prompt hint ad dialog
      GameDialogHelper.showHintAdDialog(
        context,
        onHintEarned: () {
          soundService.playHint();
          isExpandedNotifier.value = true;
        },
      );
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
      valueListenable: isExpandedNotifier,
      builder: (context, isExpanded, _) {
        return Semantics(
          label: isExpanded ? 'Collapse hint' : 'Expand hint',
          button: true,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: isExpanded
                    ? primaryColor.withValues(alpha: 0.45)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.slate200),
                width: isExpanded ? 1.5.w : 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: isExpanded
                      ? primaryColor.withValues(alpha: isDark ? 0.15 : 0.06)
                      : Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                  blurRadius: isExpanded ? 16 : 8,
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
                  borderRadius: BorderRadius.circular(18.r),
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
                                isExpanded
                                    ? context.tr('games.hint', fallback: 'Hint & Clue')
                                    : context.tr(
                                        'games.tap_for_hint',
                                        fallback: 'Need help? Tap for a hint',
                                      ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isExpanded
                                      ? primaryColor
                                      : (isDark ? Colors.white : AppColors.slate800),
                                  letterSpacing: 0.2,
                                ),
                              ),
                                if (!isExpanded) ...[
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
                        if (!isExpanded)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: isPremium
                                  ? AppColors.amber500.withValues(alpha: 0.14)
                                  : primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: isPremium
                                    ? AppColors.amber500.withValues(alpha: 0.3)
                                    : primaryColor.withValues(alpha: 0.2),
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
                                  color: isPremium ? AppColors.amber500 : primaryColor,
                                ),
                                SizedBox(width: 3.w),
                                Text(
                                  isPremium ? 'FREE' : 'AD',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isPremium ? AppColors.amber500 : primaryColor,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(width: 8.w),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: 250.ms,
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
                if (isExpanded)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        SizedBox(height: 12.h),

                        // Starting Anchor Clue Container
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 9.h,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: isDark ? 0.14 : 0.08),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.2),
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tips_and_updates_rounded,
                                color: primaryColor,
                                size: 16.r,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  puzzle.hintClue,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              // Audio button to listen to playable sentence
                              Semantics(
                                label: 'Listen to sentence hint',
                                button: true,
                                child: ScaleButton(
                                  onTap: () {
                                    hapticService.selection();
                                    soundService.playTts(puzzle.playableSentence);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(6.r),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Icon(
                                      Icons.volume_up_rounded,
                                      color: primaryColor,
                                      size: 16.r,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // Definition Section
                        Text(
                          context.tr('vocabulary.full_definition', fallback: 'Definition').toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: isDark ? Colors.white54 : AppColors.slate500,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          puzzle.cleanDefinition,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.9)
                                : AppColors.slate800,
                            height: 1.45,
                          ),
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
