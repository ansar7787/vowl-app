import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/daily_challenges/word_snap/domain/models/word_snap_puzzle.dart';

/// Collapsible progressive hint card providing starting word clues, audio, and definition.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<bool>(
      valueListenable: isExpandedNotifier,
      builder: (context, isExpanded, _) {
        return Semantics(
          label: isExpanded ? 'Collapse hint' : 'Expand hint',
          button: true,
          child: GestureDetector(
            onTap: () {
              hapticService.light();
              if (!isExpandedNotifier.value) {
                soundService.playHint();
              }
              isExpandedNotifier.value = !isExpandedNotifier.value;
            },
            child: AnimatedContainer(
              duration: 300.ms,
              curve: Curves.easeInOut,
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: primaryColor.withValues(
                    alpha: isExpanded ? 0.4 : 0.15,
                  ),
                  width: isExpanded ? 1.5 : 1,
                ),
                boxShadow: isExpanded
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.amber500.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Text('💡', style: TextStyle(fontSize: 14.sp)),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          isExpanded
                              ? context.tr('games.hint', fallback: 'Hint & Clue')
                              : context.tr(
                                  'games.tap_for_hint',
                                  fallback: 'Need help? Tap for a hint',
                                ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: isExpanded
                                ? primaryColor
                                : (isDark ? Colors.white60 : Colors.black45),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: 300.ms,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark ? Colors.white38 : Colors.black38,
                          size: 20.r,
                        ),
                      ),
                    ],
                  ),

                  // Progressive Hint content (expanded state)
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: EdgeInsets.only(top: 14.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Starting anchor clue
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline_rounded,
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
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                                // Audio button to listen to playable sentence
                                Semantics(
                                  label: 'Listen to sentence hint',
                                  button: true,
                                  child: InkWell(
                                    onTap: () {
                                      hapticService.selection();
                                      soundService.playTts(puzzle.playableSentence);
                                    },
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: Padding(
                                      padding: EdgeInsets.all(4.r),
                                      child: Icon(
                                        Icons.volume_up_rounded,
                                        color: primaryColor,
                                        size: 18.r,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12.h),

                          // Meaning explanation
                          Text(
                            context.tr('vocabulary.full_definition', fallback: 'Definition'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : Colors.black45,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            puzzle.cleanDefinition,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.88)
                                  : Colors.black87,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: 300.ms,
                    sizeCurve: Curves.easeInOut,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05, duration: 400.ms);
  }
}
