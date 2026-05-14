import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/features/home/presentation/widgets/mastery_avatar.dart';
import 'package:vowl/features/home/presentation/widgets/vowl_mascot_card.dart';

enum CommandPodMode { headerOnly, kidsOnly, vaultOnly, full }

class CommandPod extends StatelessWidget {
  const CommandPod({
    super.key,
    required this.user,
    this.mode = CommandPodMode.full,
  });

  final UserEntity user;
  final CommandPodMode mode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (mode == CommandPodMode.full ||
            mode == CommandPodMode.headerOnly) ...[
          SizedBox(height: 12.h),
          _buildDiscoveryHero(context),
        ],
        if (mode == CommandPodMode.full || mode == CommandPodMode.kidsOnly) ...[
          _buildKidsLearningCard(context),
        ],
        if (mode == CommandPodMode.full ||
            mode == CommandPodMode.vaultOnly) ...[
          _buildBentoMasteryVault(context),
        ],
      ],
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildDiscoveryHero(BuildContext context) {
    final progress = (user.totalExp % 100) / 100.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: GlassTile(
        borderRadius: BorderRadius.circular(32.r),
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulsing ring
                    Container(
                          width: 75.r,
                          height: 75.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.15, 1.15),
                          duration: 2.seconds,
                        )
                        .fadeOut(duration: 2.seconds),

                    MasteryAvatar(user: user, progress: progress),

                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.all(5.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.bolt_rounded,
                          size: 12.r,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDynamicGreeting(context),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'RANK: VOWL OPERATIVE',
                          style: GoogleFonts.outfit(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2563EB),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            _buildFuturisticXPBar(context, progress),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticXPBar(BuildContext context, double progress) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 14.r,
                  color: const Color(0xFF2563EB),
                ),
                SizedBox(width: 6.w),
                Text(
                  'LEVEL ${user.level}',
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            Text(
              '${(progress * 100).toInt()}% COMPLETED',
              style: GoogleFonts.outfit(
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Stack(
          children: [
            Container(
              height: 12.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.05, 1.0),
              child: Container(
                height: 12.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(6.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ).animate().shimmer(duration: 2.seconds, color: Colors.white24),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKidsLearningCard(BuildContext context) {
    return ScaleButton(
      onTap: () => context.push(AppRouter.kidsZoneRoute),
      child: Container(
        constraints: BoxConstraints(minHeight: 160.h),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32.r),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA855F7).withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32.r),
          child: Stack(
            children: [
              // Decorative background circles
              Positioned(
                right: -30.w,
                bottom: -30.h,
                child: Container(
                  width: 180.r,
                  height: 180.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),

              // Playful background icons
              Positioned(
                left: 20.w,
                top: 20.h,
                child:
                    Icon(
                          Icons.auto_awesome_rounded,
                          size: 24.r,
                          color: Colors.white.withValues(alpha: 0.2),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.3, 1.3),
                          duration: 3.seconds,
                        ),
              ),

              // Content Layer
              Stack(
                children: [
                  // Text Content (Moved to left side)
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 16.h, 150.w, 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.rocket_launch_rounded,
                                size: 10.r,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                "EARLY LEARNERS",
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "JUNIOR\nADVENTURE",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24.sp, // Slightly larger
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "22 playful missions for\nyoung explorers!",
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mascot Area (Concentric & Engaging Design)
                  Positioned(
                    right: -10.w,
                    bottom: 0,
                    top: 0,
                    child: SizedBox(
                      width: 140.w,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. Outer Soft Glow
                          Container(
                                width: 140.r,
                                height: 140.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.1),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.2, 1.2),
                                duration: 4.seconds,
                              ),

                          // 2. Secondary Interactive Ring
                          Container(
                                width: 100.r,
                                height: 100.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 1.5,
                                  ),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .rotate(duration: 10.seconds),

                          // 3. Floating Sparkles/Particles
                          ...List.generate(5, (index) {
                            final random = math.Random(index + 50);
                            return Positioned(
                              left: 20.w + random.nextDouble() * 100.w,
                              top: 20.h + random.nextDouble() * 80.h,
                              child:
                                  Icon(
                                        Icons.star_rounded,
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                        size: (8 + random.nextInt(8)).r,
                                      )
                                      .animate(
                                        onPlay: (c) => c.repeat(reverse: true),
                                      )
                                      .fadeIn(
                                        duration:
                                            (1 + random.nextDouble()).seconds,
                                      )
                                      .moveY(
                                        begin: 0,
                                        end: -20,
                                        duration: 2.seconds,
                                      ),
                            );
                          }),

                          // 4. The Buddy Icon (Grounded in Center)
                          Container(
                                padding: EdgeInsets.all(18.r),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 2.r,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 25,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  "🧸",
                                  style: TextStyle(fontSize: 48.sp),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .moveY(
                                begin: -6,
                                end: 6,
                                duration: 2.seconds,
                                curve: Curves.easeInOut,
                              )
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.05, 1.05),
                                duration: 2.seconds,
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoMasteryVault(BuildContext context) {
    return Column(
      children: [
        const VowlMascotCard(),

        SizedBox(height: 8.h),

        Row(
          children: [
            Expanded(
              child: _buildMiniStatTile(
                context,
                'BADGES',
                '${user.badges.length}',
                Icons.emoji_events_rounded,
                const Color(0xFFF59E0B),
                AppRouter.trophyRoomRoute,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildMiniStatTile(
                context,
                'LEVEL',
                '${user.level}',
                Icons.star_rounded,
                const Color(0xFF3B82F6),
                AppRouter.levelRoute,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildMiniStatTile(
                context,
                'TOTAL XP',
                _formatXp(user.totalExp),
                Icons.bolt_rounded,
                const Color(0xFFA855F7),
                AppRouter.adventureXPRoute,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}k';
    }
    return xp.toString();
  }

  Widget _buildMiniStatTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    String route,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleButton(
      onTap: () => context.push(route),
      child: GlassTile(
        borderRadius: BorderRadius.circular(20.r),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20.r),
            ),
            SizedBox(height: 8.h),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 8.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white38 : Colors.black45,
                letterSpacing: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicGreeting(BuildContext context) {
    final name = user.displayName?.split(' ').first ?? 'Seeker';
    final hour = DateTime.now().hour;
    String greeting = 'Salutations';
    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17 && hour < 22) {
      greeting = 'Good Evening';
    } else {
      greeting = 'Good Night';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.7 : 0.9),
            letterSpacing: 0.5,
          ),
        ),
        Text(
          name,
          style: GoogleFonts.outfit(
            fontSize: 26.sp,
            fontWeight: FontWeight.w900,
            color: MeshGradientBackground.getContrastColor(context),
            letterSpacing: -1.0,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
