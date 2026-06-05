import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/constants/badge_constants.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class ProfileBadgesList extends StatelessWidget {
  final UserEntity user;

  const ProfileBadgesList({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final earnedBadgesList = BadgeConstants.badges
        .where((b) => user.claimedLevelMilestones.contains(b.minLevel))
        .toList();

    if (earnedBadgesList.isEmpty) {
      return GlassTile(
        width: double.infinity,
        padding: EdgeInsets.all(32.w),
        borderRadius: BorderRadius.circular(32.r),
        child: Column(
          children: [
            VowlMascot(state: VowlMascotState.thinking, size: 60.r),
            SizedBox(height: 16.h),
            Text(
              'HALL OF FAME VACANT',
              style: TextStyle(fontFamily: 'Outfit', 
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 16.sp,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Claim milestones to display your legendary trophies here.',
              style: TextStyle(fontFamily: 'Outfit', 
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 220.h,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.7),
        physics: const BouncingScrollPhysics(),
        itemCount: earnedBadgesList.length,
        itemBuilder: (context, index) {
          final badge = earnedBadgesList[index];
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  badge.color.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: badge.color.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: GlassTile(
              borderRadius: BorderRadius.circular(32.r),
              usePremiumStyle: true,
              child: Stack(
                children: [
                  Center(
                        child: Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(0.1),
                          alignment: FractionalOffset.center,
                          child: Image.asset(
                            'assets/images/mascot/gold_trophy.webp',
                            height: 140.h,
                            color: badge.color.withValues(alpha: 0.9),
                            colorBlendMode: BlendMode.screen,
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: -5, end: 5, duration: 2000.ms),

                  Positioned(
                    bottom: 20.h,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Text(
                          badge.name.toUpperCase(),
                          style: TextStyle(fontFamily: 'Outfit', 
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'LEVEL ${badge.minLevel} ACHIEVED',
                          style: TextStyle(fontFamily: 'Outfit', 
                            color: Colors.white70,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }
}
