import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_context_blitz_hero.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_option_tile.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_phrase_duel_hero.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_sentence_strike_hero.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_word_clash_hero.dart';

/// MCQ Classic mechanic widget for 1v1 Arena.
/// Reuses the 4 discipline-specific hero widgets and option tile styles.
class ArenaMcqMechanic extends StatelessWidget {
  final ArenaChallenge challenge;
  final ArenaDuelState state;
  final bool isDark;
  final bool isMidnight;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<int> onSelectOption;

  const ArenaMcqMechanic({
    super.key,
    required this.challenge,
    required this.state,
    required this.isDark,
    required this.isMidnight,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onSelectOption,
  });

  void _handleOptionTap(int idx, ArenaQuestion q) {
    if (state.isAnswered) return;
    final isCorrect = idx == q.correctIndex;
    if (isCorrect) {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().success();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playCorrect(
          comboStep: state.currentQuestionIndex + 1,
        );
      }
    } else {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().error();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playWrong();
      }
    }
    onSelectOption(idx);
  }

  Widget _buildDisciplineHero(ArenaQuestion q) {
    switch (q.discipline) {
      case 'word_clash':
        return ArenaWordClashHero(
          q: q,
          state: state,
          isDark: isDark,
          isMidnight: isMidnight,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      case 'phrase_duel':
        return ArenaPhraseDuelHero(
          q: q,
          state: state,
          isDark: isDark,
          isMidnight: isMidnight,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      case 'sentence_strike':
        return ArenaSentenceStrikeHero(
          q: q,
          state: state,
          isDark: isDark,
          isMidnight: isMidnight,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      case 'context_blitz':
      default:
        return ArenaContextBlitzHero(
          q: q,
          state: state,
          isDark: isDark,
          isMidnight: isMidnight,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeQ = challenge.toLegacyQuestion();
    final isWordClash = activeQ.discipline == 'word_clash';
    final isShortOptions = activeQ.options.every(
      (opt) => opt.trim().length <= 14 && !opt.trim().contains(' '),
    );
    final shouldUseGrid = isWordClash && isShortOptions;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RepaintBoundary(
            child: AnimatedSwitcher(
              duration: VowlMotion.fast,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.08, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<String>(challenge.id),
                child: _buildDisciplineHero(activeQ),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          RepaintBoundary(
            child: shouldUseGrid
                ? GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeQ.options.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10.h,
                      crossAxisSpacing: 10.w,
                      childAspectRatio: 2.2,
                    ),
                    itemBuilder: (context, idx) {
                      return ArenaGridOptionTile(
                        index: idx,
                        text: activeQ.options[idx],
                        isAnswered: state.isAnswered,
                        selectedOption: state.selectedOption,
                        correctIndex: activeQ.correctIndex,
                        isDark: isDark,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        onTap: () => _handleOptionTap(idx, activeQ),
                      );
                    },
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeQ.options.length,
                    separatorBuilder: (_, _) => SizedBox(height: 10.h),
                    itemBuilder: (context, idx) {
                      return ArenaListOptionTile(
                        index: idx,
                        text: activeQ.options[idx],
                        isAnswered: state.isAnswered,
                        selectedOption: state.selectedOption,
                        correctIndex: activeQ.correctIndex,
                        isDark: isDark,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        onTap: () => _handleOptionTap(idx, activeQ),
                      );
                    },
                  ),
          ),
          if (state.isAnswered && activeQ.explanation.isNotEmpty) ...[
            SizedBox(height: 8.h),
            RepaintBoundary(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : AppColors.slate100,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.lightbulb,
                      size: 15.sp,
                      color: AppColors.amber500,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        activeQ.explanation,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
