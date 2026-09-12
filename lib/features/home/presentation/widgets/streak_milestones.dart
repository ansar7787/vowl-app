import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// A single streak milestone: the day count it unlocks at, and its reward.
class StreakMilestone {
  final int days;
  final int reward;
  const StreakMilestone({required this.days, required this.reward});
}

/// Pure, side-effect-free milestone calculation — extracted out of
/// StreakMilestones.build() so it's unit-testable on its own and isn't
/// silently re-derived as a side effect of an unrelated widget rebuild.
class StreakMilestoneCalculator {
  StreakMilestoneCalculator._();

  static List<StreakMilestone> compute(UserEntity user) {
    // Single Source of Truth: UI now precisely matches the backend rewards.
    // This prevents the bug where UI displayed "350 coins" but backend awarded 100.
    final milestones =
        UserGameConstants.kStreakMilestoneRewards.entries
            .map((e) => StreakMilestone(days: e.key, reward: e.value))
            .toList()
          ..sort((a, b) => a.days.compareTo(b.days));

    return milestones;
  }
}

class StreakMilestones extends StatefulWidget {
  final UserEntity user;

  const StreakMilestones({super.key, required this.user});

  @override
  State<StreakMilestones> createState() => _StreakMilestonesState();
}

class _StreakMilestonesState extends State<StreakMilestones> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToNext();
    });
  }

  void _scrollToNext() {
    final milestones = StreakMilestoneCalculator.compute(widget.user);
    final nextIndex = milestones.indexWhere(
      (m) => m.days > widget.user.currentStreak,
    );
    if (nextIndex > 0 && _scrollController.hasClients) {
      final offset = (nextIndex - 1).clamp(0, milestones.length - 1) * 132.0;
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final milestones = StreakMilestoneCalculator.compute(widget.user);

    return BlocListener<ProgressionBloc, ProgressionState>(
      listenWhen: (prev, curr) => prev.message != curr.message,
      listener: (context, state) {
        if (state.message == 'progression.milestone_claimed') {
          CustomSnackBar.show(
            context: context,
            message: context.tr(
              'streak.milestone_claimed_success',
              fallback: 'Milestone Claimed!',
            ),
            type: CustomSnackBarType.success,
          );
          context.read<ProgressionBloc>().add(
            const ProgressionClearMessageRequested(),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            context.tr(
              'streak.milestones_title',
              fallback: 'STREAK MILESTONES',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            minFontSize: 12,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              context.tr(
                'streak.milestones_subtitle',
                fallback: 'Reach streak day goals to earn bonus coins.',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${widget.user.claimedStreakMilestones.length}/${milestones.length}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  context.tr(
                    'streak.milestones_claimed_label',
                    fallback: 'milestones claimed',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
            child: Row(
              children: milestones.map((m) {
                final days = m.days;
                final reward = m.reward;
                final isReached = widget.user.currentStreak >= days;
                final isClaimed = widget.user.claimedStreakMilestones.contains(
                  days,
                );
                final isNext =
                    !isReached &&
                    (milestones
                            .firstWhere(
                              (element) =>
                                  element.days > widget.user.currentStreak,
                              orElse: () => milestones.last,
                            )
                            .days ==
                        days);

                final daysLabel = (days % 365 == 0)
                    ? ((days ~/ 365) == 1
                          ? context.tr(
                              'streak.milestone_year_singular',
                              fallback: '1 YEAR',
                            )
                          : context.tr(
                              'streak.milestone_years_plural',
                              args: [(days ~/ 365).toString()],
                              fallback: '${days ~/ 365} YEARS',
                            ))
                    : context.tr(
                        'streak.milestone_days',
                        args: [days.toString()],
                        fallback: '$days DAYS',
                      );

                final statusLabel = isClaimed
                    ? context.tr(
                        'streak.milestone_claimed',
                        fallback: 'CLAIMED',
                      )
                    : (isReached
                          ? context.tr(
                              'streak.milestone_claim_cta',
                              fallback: 'CLAIM',
                            )
                          : context.tr(
                              'streak.milestone_progress_label',
                              args: [
                                widget.user.currentStreak.toString(),
                                days.toString(),
                              ],
                              fallback:
                                  '${widget.user.currentStreak}/$days days',
                            ));

                return Container(
                  width: 120.w,
                  margin: EdgeInsets.only(right: 12.w),
                  child: Semantics(
                    label:
                        '$daysLabel, +$reward ${context.tr('common.coins_label', fallback: 'coins')}, $statusLabel',
                    button: isReached && !isClaimed,
                    child: Stack(
                      children: [
                        ExcludeSemantics(
                          excluding: !(isReached && !isClaimed),
                          child: Container(
                            width: 120.w,
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: isReached
                                  ? Colors.amber.withValues(alpha: 0.1)
                                  : (isNext
                                        ? Colors.blue.withValues(alpha: 0.08)
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.03,
                                                )
                                              : const Color(0xFFF8FAFC))),
                              borderRadius: BorderRadius.circular(24.r),
                              border: Border.all(
                                color: isClaimed
                                    ? Colors.amber.withValues(alpha: 0.3)
                                    : (isReached
                                          ? Colors.amber
                                          : (isNext
                                                ? Colors.blue.withValues(
                                                    alpha: 0.4,
                                                  )
                                                : (isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.1,
                                                        )
                                                      : Colors.black.withValues(
                                                          alpha: 0.08,
                                                        )))),
                                width: isNext ? 2 : 1,
                              ),
                              boxShadow: isNext
                                  ? [
                                      BoxShadow(
                                        color: Colors.blue.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10.r),
                                  decoration: BoxDecoration(
                                    color:
                                        (isReached ? Colors.amber : Colors.grey)
                                            .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isClaimed
                                        ? LucideIcons.checkCircle
                                        : LucideIcons.gift,
                                    color: isReached
                                        ? Colors.amber
                                        : Colors.grey,
                                    size: 20.r,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                AutoSizeText(
                                  daysLabel,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w900,
                                    color: isReached
                                        ? Colors.amber
                                        : Colors.grey,
                                  ),
                                  maxLines: 1,
                                  minFontSize: 8,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.circleDollarSign,
                                      size: 12.sp,
                                      color: isReached
                                          ? Colors.amber.withValues(alpha: 0.7)
                                          : Colors.grey.withValues(alpha: 0.5),
                                    ),
                                    SizedBox(width: 4.w),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '+$reward',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w800,
                                            color: isReached
                                                ? Colors.amber.withValues(
                                                    alpha: 0.7,
                                                  )
                                                : Colors.grey.withValues(
                                                    alpha: 0.5,
                                                  ),
                                          ),
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                if (isReached && !isClaimed)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ConstrainedBox(
                                      // Guarantees the 48dp accessible touch
                                      // target for this real-money-adjacent
                                      // reward-claim action, even though the
                                      // visual button is intentionally compact.
                                      constraints: BoxConstraints(
                                        minHeight: 48.r,
                                      ),
                                      child:
                                          ElevatedButton(
                                            onPressed: () => context
                                                .read<ProgressionBloc>()
                                                .add(
                                                  ProgressionClaimStreakMilestoneRequested(
                                                    days,
                                                  ),
                                                ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.amber,
                                              foregroundColor: Colors.black,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12.w,
                                                vertical: 8.h,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: AutoSizeText(
                                              statusLabel,
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w900,
                                              ),
                                              maxLines: 1,
                                              minFontSize: 6,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ).animate().shimmer(
                                            duration: 2.seconds,
                                            delay: 400.ms,
                                          ),
                                    ),
                                  )
                                else if (isClaimed)
                                  AutoSizeText(
                                    statusLabel,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.amber.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    maxLines: 1,
                                    minFontSize: 6,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                else
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4.r),
                                    child: LinearProgressIndicator(
                                      value: widget.user.currentStreak / days,
                                      backgroundColor: Colors.white10,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isNext ? Colors.blue : Colors.grey,
                                      ),
                                      minHeight: 4.h,
                                      semanticsLabel: statusLabel,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (isNext)
                          Positioned.fill(
                            child: IgnorePointer(
                              child:
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24.r),
                                    ),
                                  ).animate().shimmer(
                                    duration: 3.seconds,
                                    color: Colors.blue.withValues(alpha: 0.1),
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.05);
  }
}
