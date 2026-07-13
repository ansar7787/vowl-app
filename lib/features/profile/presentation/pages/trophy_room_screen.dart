import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_background_renderer.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/locale_service.dart';

class TrophyRoomScreen extends StatelessWidget {
  const TrophyRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;

    return Scaffold(
      backgroundColor: isMidnight
          ? const Color(0xFF020617)
          : (isDark ? const Color(0xFF0F172A) : Colors.white),
      body: Stack(
        children: [
          // Dynamic Living Background
          KidsBackgroundRenderer(
            painterName: 'UnicornMist',
            shaderName: 'magic_twinkle',
            primaryColor: isDark
                ? const Color(0xFFF59E0B)
                : const Color(0xFFFFD700),
            gameType: 'trophy',
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildPremiumAppBar(context, isDark, isMidnight),
                ),

                // Mascot Stage Section
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(height: 16.h),
                        _buildMascotStage(context, isDark, isMidnight),
                        SizedBox(height: 48.h),
                        _buildSectionTitle(
                          context.tr('profile.trophies_badges', fallback: 'Trophies & Badges'),
                          isDark,
                          isMidnight,
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),

                // Badges Grid / Empty Section
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  sliver: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final badges = state.user?.badges ?? [];
                      if (badges.isEmpty) {
                        return SliverToBoxAdapter(
                          child: _buildEmptySection(
                            context.tr('profile.no_trophies', fallback: 'No trophies yet'),
                            isDark,
                            isMidnight,
                            icon: Icons.military_tech_rounded,
                          ),
                        );
                      }

                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16.r,
                          crossAxisSpacing: 16.r,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _buildBadgeCard(
                            badges[index],
                            isDark,
                            isMidnight,
                            index,
                          );
                        }, childCount: badges.length),
                      );
                    },
                  ),
                ),

                // Collectibles Section
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(height: 48.h),
                        _buildSectionTitle(
                          context.tr('profile.collectibles_vault', fallback: 'Collectibles Vault'),
                          isDark,
                          isMidnight,
                        ),
                        SizedBox(height: 20.h),
                        _buildFurnitureSection(context, isDark, isMidnight),
                        SizedBox(height: 100.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAppBar(
    BuildContext context,
    bool isDark,
    bool isMidnight,
  ) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final coins = state.user?.coins ?? 0;

        return Container(
              margin: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: isMidnight
                    ? Colors.white.withValues(alpha: 0.05)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(40.r),
                boxShadow: isMidnight
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ScaleButton(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: const Color(0xFFD97706),
                            size: 20.r,
                          ),
                        ),
                      ),
                      Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              ),
                              borderRadius: BorderRadius.circular(30.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.monetization_on_rounded,
                                  color: Colors.white,
                                  size: 20.r,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  "$coins",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.05, 1.05),
                            duration: 2.seconds,
                            curve: Curves.easeInOutSine,
                          ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('profile.trophy_room', fallback: 'Trophy Room'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w900,
                                color: (isDark || isMidnight)
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              context.tr('profile.trophy_subtitle', fallback: 'Your achievements'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                color: (isDark || isMidnight)
                                    ? Colors.white54
                                    : const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Text(
                              "🏆",
                              style: TextStyle(fontSize: 32.sp),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .shake(duration: 2.seconds, hz: 2),
                    ],
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.1, end: 0, curve: Curves.easeOutBack);
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isDark, bool isMidnight) {
    return Row(
      children: [
        Container(
          width: 6.w,
          height: 24.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B),
            borderRadius: BorderRadius.circular(3.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: (isDark || isMidnight)
                ? Colors.white.withValues(alpha: 0.9)
                : const Color(0xFF1E293B),
            letterSpacing: 1.5,
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildMascotStage(BuildContext context, bool isDark, bool isMidnight) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        final level = user?.level ?? 1;
        final mascotId = user?.vowlMascot;
        final accessoryId = user?.vowlEquippedAccessory;

        return GlassTile(
          borderRadius: BorderRadius.circular(40.r),
          padding: EdgeInsets.all(2.r),
          borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.4),
          child: Container(
            height: 180.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(38.r),
              gradient: RadialGradient(
                center: const Alignment(0, 0.2),
                radius: 1.2,
                colors: [
                  const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated Holographic Rings
                ...List.generate(3, (index) {
                  return Container(
                        width: (110 + (index * 25)).r,
                        height: (110 + (index * 25)).r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.15 - (index * 0.03)),
                            width: 2,
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .rotate(duration: Duration(seconds: 10 + (index * 5)))
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.1, 1.1),
                        duration: Duration(seconds: 4 + index),
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .scale(
                        begin: const Offset(1.1, 1.1),
                        end: const Offset(0.9, 0.9),
                        duration: Duration(seconds: 4 + index),
                        curve: Curves.easeInOut,
                      );
                }),

                // Core Glow
                Container(
                      width: 90.r,
                      height: 90.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFFD700,
                            ).withValues(alpha: 0.4),
                            blurRadius: 80,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(duration: 3.seconds, color: Colors.white24),

                // Mascot & Accessory
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            VowlMascot(
                              size: 75.r,
                              state: VowlMascotState.happy,
                              useFloatingAnimation: true,
                              level: level,
                              mascotId: mascotId,
                              accessoryId: accessoryId,
                            ),
                          ],
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(
                          begin: -10,
                          end: 10,
                          duration: 2.5.seconds,
                          curve: Curves.easeInOutSine,
                        ),
                    SizedBox(height: 20.h),

                    // Premium Level Badge
                    Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.5),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                                size: 14.r,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                context.tr(
                                  'profile.level',
                                  args: [level.toString()],
                                ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.sp,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.2, curve: Curves.easeOutBack),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgeCard(
    String badgeId,
    bool isDark,
    bool isMidnight,
    int index,
  ) {
    // Badges represent real achievements!
    final isLegendary =
        badgeId.contains('master') ||
        badgeId.contains('legend') ||
        badgeId.contains('100');
    final colorPair = isLegendary
        ? [const Color(0xFFFFD700), const Color(0xFFF59E0B)] // Gold
        : [const Color(0xFFC0C0C0), const Color(0xFF94A3B8)]; // Silver

    return ScaleButton(
          onTap: () => Haptics.vibrate(HapticsType.light),
          child: GlassTile(
            borderRadius: BorderRadius.circular(24.r),
            padding: EdgeInsets.all(2.r),
            borderColor: colorPair[0].withValues(alpha: 0.4),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorPair[0].withValues(alpha: 0.2),
                    colorPair[1].withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                        width: 64.r,
                        height: 64.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: colorPair,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorPair[0].withValues(alpha: 0.5),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isLegendary ? "👑" : "🏆",
                            style: TextStyle(
                              fontSize: 32.sp,
                              shadows: const [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(
                        begin: -4,
                        end: 4,
                        duration: 2.seconds,
                        curve: Curves.easeInOutSine,
                      ),

                  SizedBox(height: 12.h),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Text(
                      badgeId.replaceAll('_', ' ').toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: (isDark || isMidnight)
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .scale(
          delay: (100 * index).ms,
          duration: 400.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(delay: (100 * index).ms);
  }

  Widget _buildFurnitureSection(
    BuildContext context,
    bool isDark,
    bool isMidnight,
  ) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        if (user == null) return const SizedBox.shrink();

        final owned = user.kidsOwnedFurniture;
        final equipped = user.kidsEquippedFurniture;

        if (owned.isEmpty) {
          return _buildEmptySection(
            context.tr('profile.empty_vault', fallback: 'Your vault is empty.'),
            isDark,
            isMidnight,
            icon: Icons.inventory_2_rounded,
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16.r,
            crossAxisSpacing: 16.r,
            childAspectRatio: 0.85,
          ),
          itemCount: owned.length,
          itemBuilder: (context, index) {
            final fId = owned[index];
            final category = fId.contains('bed')
                ? 'bed'
                : (fId.contains('window') ? 'window' : 'prop');
            final isEquipped = equipped[category] == fId;
            final emoji = _getFurnitureEmoji(fId);
            final name = _getFurnitureName(fId);

            return ScaleButton(
                  onTap: () {
                    Haptics.vibrate(HapticsType.medium);
                    context.read<ProfileBloc>().add(
                      ProfileUpdateFurnitureRequested(category, fId),
                    );
                  },
                  child: GlassTile(
                    borderRadius: BorderRadius.circular(24.r),
                    padding: EdgeInsets.all(2.r),
                    borderColor: isEquipped
                        ? const Color(0xFF10B981)
                        : ((isDark || isMidnight)
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22.r),
                        color: isEquipped
                            ? const Color(0xFF10B981)
                            : ((isDark || isMidnight)
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : Colors.white),
                        boxShadow: isEquipped
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : [
                                if (!isDark && !isMidnight)
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(emoji, style: TextStyle(fontSize: 54.sp))
                                  .animate(
                                    onPlay: (c) => c.repeat(reverse: true),
                                  )
                                  .moveY(
                                    begin: -3,
                                    end: 3,
                                    duration: 2.seconds,
                                  ),
                              SizedBox(height: 16.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
                                child: Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w900,
                                    color: isEquipped
                                        ? Colors.white
                                        : ((isDark || isMidnight)
                                              ? Colors.white
                                              : const Color(0xFF0F172A)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isEquipped)
                            Positioned(
                              top: 10.r,
                              right: 10.r,
                              child: Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: const Color(0xFF10B981),
                                  size: 14.r,
                                ),
                              ),
                            ).animate().scale(
                              duration: 400.ms,
                              curve: Curves.elasticOut,
                            ),
                        ],
                      ),
                    ),
                  ),
                )
                .animate()
                .scale(
                  delay: (index * 50).ms,
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn();
          },
        );
      },
    );
  }

  String _getFurnitureEmoji(String id) {
    if (id.contains('bed')) return '🛏️';
    if (id.contains('window')) return '🪟';
    if (id.contains('rug')) return '🫓';
    if (id.contains('lamp')) return '🛋️';
    return '📦';
  }

  String _getFurnitureName(String id) {
    return id.replaceAll('_', ' ').toUpperCase();
  }

  Widget _buildEmptySection(
    String text,
    bool isDark,
    bool isMidnight, {
    IconData icon = Icons.emoji_events_outlined,
  }) {
    return GlassTile(
      borderRadius: BorderRadius.circular(24.r),
      padding: EdgeInsets.all(2.r),
      borderColor: Colors.white.withValues(alpha: 0.1),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          color: (isDark || isMidnight)
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.02),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 56.r,
              color: (isDark || isMidnight) ? Colors.white24 : Colors.black26,
            ),
            SizedBox(height: 16.h),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: (isDark || isMidnight)
                    ? Colors.white54
                    : const Color(0xFF64748B),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
