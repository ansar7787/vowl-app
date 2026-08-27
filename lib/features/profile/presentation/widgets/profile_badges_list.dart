import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/constants/badge_constants.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class ProfileBadgesList extends StatefulWidget {
  final UserEntity user;

  const ProfileBadgesList({super.key, required this.user});

  @override
  State<ProfileBadgesList> createState() => _ProfileBadgesListState();
}

class _ProfileBadgesListState extends State<ProfileBadgesList> {
  // MEMORY LEAK FIX: this widget was a StatelessWidget that created a
  // brand-new `PageController(viewportFraction: 0.7)` *inside build()*.
  // Every single rebuild (e.g. caused by a parent BlocBuilder rebuilding
  // for any reason) allocated a new PageController and the previous one
  // was simply discarded without ever calling `.dispose()` - a textbook
  // controller leak that compounds over the lifetime of the Profile
  // screen. Converting to a StatefulWidget lets the controller be created
  // exactly once in `initState` and disposed exactly once in `dispose`.
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.7);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final earnedBadgesList = BadgeConstants.badges
        .where((b) => widget.user.claimedLevelMilestones.contains(b.minLevel))
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
              context.tr(
                'profile.hall_of_fame_vacant',
                fallback: 'Hall of Fame is Vacant',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 16.sp,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              context.tr(
                'profile.hall_of_fame_vacant_subtitle',
                fallback: 'Complete quests to earn badges.',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
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
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: earnedBadgesList.length,
        itemBuilder: (context, index) {
          final badge = earnedBadgesList[index];
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32.r),
              boxShadow: [
                BoxShadow(
                  color: badge.color.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: -10,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: GlassTile(
              borderRadius: BorderRadius.circular(32.r),
              usePremiumStyle: true,
              border: Border.all(
                color: badge.color.withValues(alpha: 0.5),
                width: 1.5,
              ),
              child: Stack(
                children: [
                  // Abstract glowing background meshes (holographic feel)
                  Positioned(
                    top: -60.h,
                    right: -40.w,
                    child: Container(
                      width: 180.r,
                      height: 180.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: badge.color.withValues(alpha: 0.6),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30.h,
                    left: -40.w,
                    child: Container(
                      width: 140.r,
                      height: 140.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: badge.color.withValues(alpha: 0.4),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ACCESSIBILITY FIX: badge name and level announced
                  Semantics(
                    label: context.tr(
                      'profile.badge_semantic_label',
                      fallback: 'Badge earned',
                      args: [context.tr(badge.nameKey), '${badge.minLevel}'],
                    ),
                    image: true,
                    child: ExcludeSemantics(
                      child: Center(
                        child: Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(0.1),
                          alignment: FractionalOffset.center,
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                badge.color,
                                badge.color.withValues(alpha: 0.5),
                              ],
                            ).createShader(bounds),
                            child: Icon(
                              badge.icon,
                              size: 100.r,
                              color: Colors.white,
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .moveY(begin: -8, end: 8, duration: 3000.ms)
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1.05, 1.05),
                                duration: 2500.ms,
                              ),
                        ),
                      ),
                    ),
                  ),

                  // Modern Typography UI
                  Positioned(
                    bottom: 24.h,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Color(0xFFE2E8F0)],
                          ).createShader(bounds),
                          child: Text(
                            context.tr(badge.nameKey).toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              shadows: [
                                Shadow(
                                  color: badge.color,
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                badge.color.withValues(alpha: 0.4),
                                badge.color.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: badge.color.withValues(alpha: 0.6),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            context.tr(
                              'profile.level_achieved',
                              fallback: 'LEVEL ACHIEVED',
                              args: ['${badge.minLevel}'],
                            ).toUpperCase(),
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
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
