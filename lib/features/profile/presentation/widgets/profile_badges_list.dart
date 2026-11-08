import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/constants/badge_constants.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class _LocalPalette {
  _LocalPalette._();
  static const Color colorc084fc = Color(0xFFC084FC);
}

/// Horizontal badge carousel showcasing curriculum milestones and unlock criteria.
///
/// Features:
/// - Full 8-milestone carousel displaying both unlocked trophies and locked previews.
/// - Unlocked badges render with vibrant holographic foil and reactive 3D tilt.
/// - Locked badges render with frosted glass silhouette and minimum level requirement.
/// - Dedicated collection progress counter decoupled from navigation.
/// - Distinct CTA to explore the full 3D Trophy Room.
class ProfileBadgesList extends StatefulWidget {
  /// Current authenticated [user] entity.
  final UserEntity user;

  /// Creates a [ProfileBadgesList] for [user].
  const ProfileBadgesList({super.key, required this.user});

  @override
  State<ProfileBadgesList> createState() => _ProfileBadgesListState();
}

class _ProfileBadgesListState extends State<ProfileBadgesList> {
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

  bool _isBadgeUnlocked(BadgeData badge) {
    return widget.user.badges.contains(badge.id) ||
        widget.user.claimedLevelMilestones.contains(badge.minLevel) ||
        (badge.minLevel != null && widget.user.level >= badge.minLevel!);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final allBadges = BadgeConstants.badges;
    final totalBadges = allBadges.length;
    final earnedCount = allBadges.where(_isBadgeUnlocked).length;

    return Column(
      children: [
        // ── 1. Decoupled Collection Progress Counter (Informational, No Navigation) ──
        Padding(
          padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 16.h),
          child: _buildProgressCounter(context, earnedCount, totalBadges),
        ),

        // ── 2. Full 8-Milestone Holographic Badge Carousel ──
        SizedBox(
          height: 195.h,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              di.sl<HapticService>().selection();
            },
            itemCount: allBadges.length,
            itemBuilder: (context, index) {
              final badge = allBadges[index];
              final isEarned = _isBadgeUnlocked(badge);

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 0.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                  } else {
                    value = (0.0 - index).toDouble();
                  }

                  // Card Physical 3D Tilt based on swipe position
                  final tiltY = (value * 0.4).clamp(-0.8, 0.8);
                  final scale = 1.0 - (value.abs() * 0.15).clamp(0.0, 0.3);

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
                          borderRadius: BorderRadius.circular(24.r),
                          usePremiumStyle: isEarned,
                          showShadow: false,
                          blur: 0,
                          glassOpacity: 1.0,
                          borderColor: isMidnight
                              ? Colors.white.withValues(alpha: 0.12)
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : AppColors.slate100),
                          borderWidth: 1.0,
                          child: Stack(
                            children: [
                              // Abstract glowing background meshes (Only for earned badges)
                              if (isEarned) ...[
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
                                          color: badge.color.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 16,
                                          spreadRadius: 2,
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
                                          color: badge.color.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              // Badge Icon (Holographic Foil if earned; Frosted Silhouette if locked)
                              Semantics(
                                label: isEarned
                                    ? context.tr(
                                        'profile.badge_semantic_label',
                                        fallback: 'Badge earned',
                                        args: [
                                          context.tr(badge.nameKey),
                                          '${badge.minLevel}',
                                        ],
                                      )
                                    : 'Locked badge, Level ${badge.minLevel} required',
                                image: true,
                                child: ExcludeSemantics(
                                  child: Center(
                                    child: Transform(
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.001)
                                        ..rotateY(0.1),
                                      alignment: FractionalOffset.center,
                                      child: isEarned
                                          ? ShaderMask(
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
                                                      badge.color.withValues(
                                                        alpha: 0.5,
                                                      ),
                                                    ],
                                                  ).createShader(bounds),
                                              child: Icon(
                                                badge.icon,
                                                size: 76.r,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  badge.icon,
                                                  size: 76.r,
                                                  color: isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.12,
                                                        )
                                                      : Colors.black.withValues(
                                                          alpha: 0.08,
                                                        ),
                                                ),
                                                Icon(
                                                  Icons.lock_rounded,
                                                  size: 26.r,
                                                  color: isDark
                                                      ? Colors.white38
                                                      : AppColors.slate400,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),

                              // Bottom Typography UI
                              Positioned(
                                bottom: 18.h,
                                left: 8.w,
                                right: 8.w,
                                child: Column(
                                  children: [
                                    AutoSizeText(
                                      context.tr(badge.nameKey).toUpperCase(),
                                      maxLines: 1,
                                      minFontSize: 8,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: isEarned
                                            ? Colors.white
                                            : (isDark
                                                  ? Colors.white54
                                                  : AppColors.slate600),
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                        shadows: isEarned
                                            ? [
                                                Shadow(
                                                  color: badge.color,
                                                  blurRadius: 8,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isEarned
                                            ? badge.color.withValues(alpha: 0.2)
                                            : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.06,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.04,
                                                    )),
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        border: Border.all(
                                          color: isEarned
                                              ? badge.color.withValues(
                                                  alpha: 0.6,
                                                )
                                              : (isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.12,
                                                      )
                                                    : AppColors.slate200),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        isEarned
                                            ? context
                                                  .tr(
                                                    'profile.level_achieved',
                                                    fallback: 'LEVEL ACHIEVED',
                                                    args: ['${badge.minLevel}'],
                                                  )
                                                  .toUpperCase()
                                            : 'UNLOCKS AT LVL ${badge.minLevel ?? 0}',
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          color: isEarned
                                              ? Colors.white
                                              : (isDark
                                                    ? Colors.white60
                                                    : AppColors.slate600),
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
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
        SizedBox(height: 14.h),

        // ── 3. Dedicated Trophy Room CTA Button (Exclusive Gateway to /trophy-room) ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: _buildExploreTrophyRoomButton(context),
        ),
      ],
    );
  }

  /// Exclusive gateway CTA to navigate to the 3D Trophy Room.
  Widget _buildExploreTrophyRoomButton(BuildContext context) {
    return ScaleButton(
      onTap: () {
        di.sl<HapticService>().selection();
        context.push(AppRouter.trophyRoomRoute);
      },
      child: GlassTile(
        borderRadius: BorderRadius.circular(20.r),
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        blur: 0,
        borderColor: AppColors.violet500.withValues(alpha: 0.35),
        borderWidth: 1.2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: AppColors.violet500.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                color: AppColors.violet500,
                size: 18.r,
              ),
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                context.tr(
                  'profile.explore_trophy_room',
                  fallback: 'Explore Full Trophy Room',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.violet500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.violet500,
              size: 13.r,
            ),
          ],
        ),
      ),
    );
  }

  /// Informational progress counter displaying unlocked badges out of total available.
  /// Does NOT navigate to trophy room on tap.
  Widget _buildProgressCounter(BuildContext context, int earned, int total) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate100);
    final progress = total > 0 ? (earned / total).clamp(0.0, 1.0) : 0.0;

    return GlassTile(
      borderRadius: BorderRadius.circular(20.r),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      borderColor: borderColor,
      borderWidth: 1.0,
      blur: 0,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.violet500.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.military_tech_rounded,
              color: AppColors.violet500,
              size: 22.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        context.tr(
                          'profile.hall_of_fame_progress',
                          fallback: 'Collection Progress',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white70 : AppColors.slate700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '$earned of $total',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.violet500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 7.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: progress),
                          duration: 600.ms,
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Container(
                              height: 7.h,
                              width: constraints.maxWidth * value,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.violet500,
                                    _LocalPalette.colorc084fc,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                                boxShadow: [
                                  if (value > 0)
                                    BoxShadow(
                                      color: AppColors.violet500.withValues(
                                        alpha: (0.4 * value).clamp(0.0, 1.0),
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
