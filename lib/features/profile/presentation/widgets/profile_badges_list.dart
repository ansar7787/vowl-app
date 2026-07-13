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
              context.tr('profile.hall_of_fame_vacant', fallback: 'Hall of Fame is Vacant'),
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
              context.tr('profile.hall_of_fame_vacant_subtitle', fallback: 'Complete quests to earn badges.'),
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
                  // ACCESSIBILITY FIX: a trophy image with no semantic
                  // label conveys nothing to TalkBack/VoiceOver users
                  // beyond "image" - the badge name and level (already
                  // shown visually below) are now announced together.
                  Semantics(
                    label: context.tr(
                      'profile.badge_semantic_label',
                      args: [context.tr(badge.nameKey), '${badge.minLevel}'],
                    ),
                    image: true,
                    child: ExcludeSemantics(
                      child: Center(
                        child:
                            Transform(
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateY(0.1),
                                  alignment: FractionalOffset.center,
                                  child: Image.asset(
                                    'assets/images/mascot/gold_trophy.webp',
                                    height: 140.h,
                                    color: badge.color.withValues(alpha: 0.9),
                                    colorBlendMode: BlendMode.screen,
                                    // PRODUCTION SAFETY: falls back to a plain
                                    // icon instead of a red error box if the
                                    // asset is ever missing/corrupted in a
                                    // build, rather than crashing this section
                                    // of the Profile screen.
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.emoji_events_rounded,
                                          size: 100.r,
                                          color: badge.color.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                  ),
                                )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .moveY(begin: -5, end: 5, duration: 2000.ms),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 20.h,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Text(
                          context.tr(badge.nameKey).toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          context.tr(
                            'profile.level_achieved',
                            args: ['${badge.minLevel}'],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
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
