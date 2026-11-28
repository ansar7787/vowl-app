import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';

/// Mechanic 3: Rapid Fire Judge ✅❌
/// Displays 6 grammar sentences one-by-one. Unanswered items count wrong on timeout.
class ArenaRapidJudgeMechanic extends StatelessWidget {
  final ArenaChallenge challenge;
  final ArenaDuelState state;
  final bool isDark;
  final bool isMidnight;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final void Function(int itemIndex, bool judgedCorrect) onJudgeItem;

  const ArenaRapidJudgeMechanic({
    super.key,
    required this.challenge,
    required this.state,
    required this.isDark,
    required this.isMidnight,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onJudgeItem,
  });

  void _tapJudge(int itemIndex, bool judgedCorrect, RapidJudgeItem item) {
    if (state.isAnswered) return;
    final itemRight = judgedCorrect == item.isCorrect;
    if (itemRight) {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().success();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playCorrect(comboStep: itemIndex + 1);
      }
    } else {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().error();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playWrong();
      }
    }
    onJudgeItem(itemIndex, judgedCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final items = challenge.rapidItems ?? const <RapidJudgeItem>[];
    final judgments = state.rapidMyJudgments ?? const <bool?>[];
    final currentIdx = (state.rapidCurrentItemIndex ?? 0).clamp(
      0,
      items.isEmpty ? 0 : items.length - 1,
    );
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.slate800 : Colors.white);

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No sentences available.',
          style: TextStyle(color: textSecondary),
        ),
      );
    }

    final isAnswered = state.isAnswered;
    final currentItem = items[currentIdx];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 6-Item Progress Pills
        Row(
          children: List.generate(items.length, (i) {
            final judged = i < judgments.length ? judgments[i] : null;
            final Color dotColor;
            if (judged != null) {
              dotColor = (judged == items[i].isCorrect)
                  ? AppColors.emerald500
                  : AppColors.rose500;
            } else if (!isAnswered && i == currentIdx) {
              dotColor = AppColors.indigo500;
            } else {
              dotColor = isDark ? AppColors.slate700 : AppColors.slate200;
            }

            return Expanded(
              child: Container(
                height: 7.h,
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  color: dotColor,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            );
          }),
        ),

        SizedBox(height: 12.h),

        if (!isAnswered) ...[
          // Active Sentence Card
          Container(
            padding: EdgeInsets.all(AppSpacing.cardSpacious),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: AppColors.indigo500.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'SENTENCE ${currentIdx + 1} OF ${items.length}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.5.sp,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.indigo500,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  currentItem.sentence,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Is this grammatically correct?',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 18.h),

          // Side-by-side WRONG / CORRECT buttons
          Row(
            children: [
              Expanded(
                child: ScaleButton(
                  debounceDuration: Duration.zero,
                  onTap: () => _tapJudge(currentIdx, false, currentItem),
                  child: Container(
                    height: 64.h,
                    decoration: BoxDecoration(
                      color: AppColors.rose500.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.rose500, width: 1.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.xCircle,
                          size: 22.sp,
                          color: AppColors.rose500,
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'WRONG',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.rose500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ScaleButton(
                  debounceDuration: Duration.zero,
                  onTap: () => _tapJudge(currentIdx, true, currentItem),
                  child: Container(
                    height: 64.h,
                    decoration: BoxDecoration(
                      color: AppColors.emerald500.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.emerald500,
                        width: 1.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.checkCircle2,
                          size: 22.sp,
                          color: AppColors.emerald500,
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'CORRECT',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.emerald500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Post-round Rapid Fire Review Card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rapid Judge Complete: ${state.rapidMyCorrectItems ?? 0}/${items.length} Correct',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: (state.isCorrect == true)
                          ? AppColors.emerald500
                          : AppColors.amber500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => SizedBox(height: 6.h),
                      itemBuilder: (_, i) {
                        final it = items[i];
                        final uJudged = i < judgments.length
                            ? judgments[i]
                            : null;
                        final right =
                            uJudged != null && uJudged == it.isCorrect;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              right ? LucideIcons.check : LucideIcons.x,
                              size: 14.sp,
                              color: right
                                  ? AppColors.emerald500
                                  : AppColors.rose500,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                '${it.sentence} — ${it.rule}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
