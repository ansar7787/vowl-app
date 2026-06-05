import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';

class StreakMilestones extends StatelessWidget {
  final UserEntity user;

  const StreakMilestones({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic Milestone Logic: Starter set + Periodic Centuries + Yearly Bonuses
    final List<Map<String, int>> milestones = [];
    final Set<int> addedDays = {};

    void addMilestone(int d) {
      if (!addedDays.contains(d)) {
        int reward = d % 365 == 0 ? 5000 : d * 10;
        milestones.add({'days': d, 'reward': reward});
        addedDays.add(d);
      }
    }

    [10, 50, 100, 200, 300, 365].forEach(addMilestone);
    user.claimedStreakMilestones.forEach(addMilestone);

    int current = user.currentStreak;
    int lastCentury = (current ~/ 100) * 100;
    if (lastCentury > 0) addMilestone(lastCentury);

    int nextCentury = ((current ~/ 100) + 1) * 100;
    addMilestone(nextCentury);
    addMilestone(nextCentury + 100);

    int nextYear = ((current ~/ 365) + 1) * 365;
    addMilestone(nextYear);

    milestones.sort((a, b) => a['days']!.compareTo(b['days']!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STREAK MILESTONES',
          style: TextStyle(fontFamily: 'Outfit', 
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 16.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          child: Row(
            children: milestones.map((m) {
              final days = m['days'] as int;
              final reward = m['reward'] as int;
              final isReached = user.currentStreak >= days;
              final isClaimed = user.claimedStreakMilestones.contains(days);
              final isNext = !isReached &&
                  (milestones.firstWhere(
                        (element) => (element['days'] as int) > user.currentStreak,
                        orElse: () => milestones.last,
                      )['days'] == days);

              return Container(
                width: 120.w,
                margin: EdgeInsets.only(right: 12.w),
                child: Stack(
                  children: [
                    Container(
                      width: 120.w,
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: isReached
                            ? Colors.amber.withValues(alpha: 0.1)
                            : (isNext ? Colors.blue.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03)),
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(
                          color: isClaimed
                              ? Colors.amber.withValues(alpha: 0.3)
                              : (isReached
                                  ? Colors.amber
                                  : (isNext
                                      ? Colors.blue.withValues(alpha: 0.4)
                                      : Colors.white.withValues(alpha: 0.1))),
                          width: isNext ? 2 : 1,
                        ),
                        boxShadow: isNext
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.1),
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
                              color: (isReached ? Colors.amber : Colors.grey).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isClaimed ? LucideIcons.checkCircle : LucideIcons.gift,
                              color: isReached ? Colors.amber : Colors.grey,
                              size: 20.r,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            days % 365 == 0 ? '${(days / 365).toInt()} YEAR${days / 365 == 1 ? '' : 'S'}' : '$days DAYS',
                            style: TextStyle(fontFamily: 'Outfit', 
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                              color: isReached ? Colors.amber : Colors.grey,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '+$reward COINS',
                            style: TextStyle(fontFamily: 'Outfit', 
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: isReached ? Colors.amber.withValues(alpha: 0.7) : Colors.grey.withValues(alpha: 0.5),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          if (isReached && !isClaimed)
                            ElevatedButton(
                              onPressed: () => context.read<ProgressionBloc>().add(
                                ProgressionClaimStreakMilestoneRequested(days, reward),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                elevation: 0,
                              ),
                              child: Text(
                                'CLAIM',
                                style: TextStyle(fontFamily: 'Outfit', fontSize: 10.sp, fontWeight: FontWeight.w900),
                              ),
                            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds)
                          else if (isClaimed)
                            Text(
                              'CLAIMED',
                              style: TextStyle(fontFamily: 'Outfit', 
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.amber.withValues(alpha: 0.5),
                              ),
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
                              child: LinearProgressIndicator(
                                value: user.currentStreak / days,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation<Color>(isNext ? Colors.blue : Colors.grey),
                                minHeight: 4.h,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isNext)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24.r)),
                          ).animate(onPlay: (c) => c.repeat()).shimmer(
                                duration: 3.seconds,
                                color: Colors.blue.withValues(alpha: 0.1),
                              ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
