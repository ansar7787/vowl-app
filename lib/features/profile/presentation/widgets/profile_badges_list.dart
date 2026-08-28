import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/constants/badge_constants.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class ProfileBadgesList extends StatefulWidget {
  final UserEntity user;

  const ProfileBadgesList({super.key, required this.user});

  @override
  State<ProfileBadgesList> createState() => _ProfileBadgesListState();
}

class _ProfileBadgesListState extends State<ProfileBadgesList> {
  // MEMORY LEAK FIX: this widget was a StatelessWidget that created a
  // brand-new `PageController(viewportFraction: 0.7)` *inside build()*.
  // Every single rebuild allocated a new PageController and the previous one
  // was simply discarded without ever calling `.dispose()` - a textbook
  // controller leak. Converting to a StatefulWidget lets the controller be
  // created exactly once in `initState` and disposed exactly once in `dispose`.
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.55);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalBadges = BadgeConstants.badges.length;
    final earnedBadgesList = BadgeConstants.badges
        .where((b) => widget.user.claimedLevelMilestones.contains(b.minLevel))
        .toList();

    if (earnedBadgesList.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: GlassTile(
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
              SizedBox(height: 16.h),
              // Progress counter even when empty
              _buildProgressCounter(context, 0, totalBadges),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Badge progress counter
        Padding(
          padding: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 16.h),
          child: _buildProgressCounter(
            context,
            earnedBadgesList.length,
            totalBadges,
          ),
        ),
        // Badge carousel
        SizedBox(
          height: 190.h,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              di.sl<HapticService>().selection();
            },
            itemCount: earnedBadgesList.length,
            itemBuilder: (context, index) {
              final badge = earnedBadgesList[index];

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 0.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                  } else {
                    // Initialize correctly before first layout
                    value = (0.0 - index).toDouble();
                  }

                  // Card Physical 3D Tilt based on swipe position
                  final tiltY = (value * 0.4).clamp(-0.8, 0.8);
                  final scale =
                      1.0 - (value.abs() * 0.15).clamp(0.0, 0.3);

                  // Holographic foil reflection shift
                  final foilShift = value * 1.5;

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(tiltY),
                    alignment: FractionalOffset.center,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32.r),
                        ),
                        child: GlassTile(
                          borderRadius: BorderRadius.circular(32.r),
                          usePremiumStyle: true,
                          showShadow: false,
                          border: Border.all(
                            color: badge.color.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          child: Stack(
                            children: [
                              // Abstract glowing background meshes
                              Positioned(
                                top: -40.h,
                                right: -30.w,
                                child: Container(
                                  width: 130.r,
                                  height: 130.r,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: badge.color
                                            .withValues(alpha: 0.6),
                                        blurRadius: 50,
                                        spreadRadius: 15,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -20.h,
                                left: -30.w,
                                child: Container(
                                  width: 100.r,
                                  height: 100.r,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: badge.color
                                            .withValues(alpha: 0.4),
                                        blurRadius: 40,
                                        spreadRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // ACCESSIBILITY FIX: badge name and level
                              Semantics(
                                label: context.tr(
                                  'profile.badge_semantic_label',
                                  fallback: 'Badge earned',
                                  args: [
                                    context.tr(badge.nameKey),
                                    '${badge.minLevel}',
                                  ],
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
                                        shaderCallback: (bounds) =>
                                            LinearGradient(
                                          begin: Alignment(
                                            -1.0 + foilShift,
                                            -1.0,
                                          ),
                                          end: Alignment(
                                            1.0 + foilShift,
                                            1.0,
                                          ),
                                          colors: [
                                            Colors.white,
                                            badge.color,
                                            badge.color
                                                .withValues(alpha: 0.5),
                                          ],
                                        ).createShader(bounds),
                                        child: Icon(
                                          badge.icon,
                                          size: 80.r,
                                          color: Colors.white,
                                        ),
                                      )
                                          .animate(
                                            onPlay: (c) =>
                                                c.repeat(reverse: true),
                                          )
                                          .moveY(
                                            begin: -5,
                                            end: 5,
                                            duration: 3000.ms,
                                          )
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
                                bottom: 20.h,
                                left: 0,
                                right: 0,
                                child: Column(
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white,
                                          Color(0xFFE2E8F0),
                                        ],
                                      ).createShader(bounds),
                                      child: AutoSizeText(
                                        context
                                            .tr(badge.nameKey)
                                            .toUpperCase(),
                                        maxLines: 1,
                                        minFontSize: 8,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                          shadows: [
                                            Shadow(
                                              color: badge.color,
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            badge.color
                                                .withValues(alpha: 0.4),
                                            badge.color
                                                .withValues(alpha: 0.1),
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                        border: Border.all(
                                          color: badge.color
                                              .withValues(alpha: 0.6),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        context
                                            .tr(
                                              'profile.level_achieved',
                                              fallback: 'LEVEL ACHIEVED',
                                              args: ['${badge.minLevel}'],
                                            )
                                            .toUpperCase(),
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          color: Colors.white,
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCounter(
    BuildContext context,
    int earned,
    int total,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = total > 0 ? earned / total : 0.0;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6.h,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF8B5CF6),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          context.tr(
            'profile.badges_progress',
            fallback: '{0} of {1}',
            args: ['$earned', '$total'],
          ),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }
}
