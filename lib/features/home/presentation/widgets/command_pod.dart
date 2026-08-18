import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/home/presentation/widgets/mastery_avatar.dart';
import 'package:auto_size_text/auto_size_text.dart';

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

  /// Returns a dynamic rank label and accent color based on the user's level.
  static ({String label, Color color, IconData icon}) _rankForLevel(int level) {
    if (level >= 50) {
      return (
        label: 'LEGEND',
        color: const Color(0xFFFFD700),
        icon: Icons.workspace_premium_rounded,
      );
    }
    if (level >= 30) {
      return (
        label: 'ELITE',
        color: const Color(0xFFA855F7),
        icon: Icons.diamond_rounded,
      );
    }
    if (level >= 15) {
      return (
        label: 'COMMANDER',
        color: const Color(0xFF3B82F6),
        icon: Icons.shield_rounded,
      );
    }
    if (level >= 5) {
      return (
        label: 'OPERATIVE',
        color: const Color(0xFF6366F1),
        icon: Icons.bolt_rounded,
      );
    }
    return (
      label: 'ROOKIE',
      color: const Color(0xFF10B981),
      icon: Icons.explore_rounded,
    );
  }

  Widget _buildDiscoveryHero(BuildContext context) {
    // XP-to-next-level progress; guarded against a zero/undefined modulus.
    final progress = (user.totalExp % 100) / 100.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rank = _rankForLevel(user.level);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.15),
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
            // ── Identity Area ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                                0xFF6366F1,
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

                    // Level badge on avatar
                    PositionedDirectional(
                      end: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: rank.color,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: rank.color.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          '${user.level}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                          ),
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
                      SizedBox(height: 8.h),
                      // Dynamic Rank Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: rank.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: rank.color.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(rank.icon, size: 11.r, color: rank.color),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                context.tr(
                                  'home.rank_operative',
                                  fallback: rank.label,
                                ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w900,
                                  color: rank.color,
                                  letterSpacing: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Divider ───────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(vertical: 18.h),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── XP Progress Bar ───────────────────────────────
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
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14.r,
                    color: const Color(0xFF6366F1),
                  ),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      context.tr(
                        'home.level',
                        fallback: 'Level',
                        args: [user.level.toString()],
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF0F172A),
                        letterSpacing: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              context.tr(
                'home.completed_percent',
                fallback: 'Completed',
                args: [(progress * 100).toInt().toString()],
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF6366F1),
              ),
              maxLines: 1,
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
    return Semantics(
      button: true,
      label:
          '${context.tr('home.junior_adventure', fallback: 'Junior Adventure')}. ${context.tr('home.junior_adventure_subtitle', fallback: 'For younger explorers')}',
      child: ScaleButton(
        onTap: () => context.push(AppRouter.kidsZoneRoute),
        child: ExcludeSemantics(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                constraints: BoxConstraints(minHeight: 160.h),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32.r),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFFA855F7),
                      Color(0xFFEC4899),
                    ],
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
                      PositionedDirectional(
                        end: -30.w,
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
                      PositionedDirectional(
                        start: 20.w,
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

                      // Text Content (Moved to left side)
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          24.w,
                          16.h,
                          130.w,
                          16.h,
                        ),
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
                                  Flexible(
                                    child: AutoSizeText(
                                      context.tr(
                                        'home.early_learners',
                                        fallback: 'Early Learners',
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: Colors.white,
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                      maxLines: 1,
                                      minFontSize: 6,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8.h),
                            AutoSizeText(
                              context.tr(
                                'home.junior_adventure',
                                fallback: 'Junior Adventure',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white,
                                fontSize: 24.sp, // Slightly larger
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                height: 1.0,
                              ),
                              maxLines: 1,
                              minFontSize: 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            AutoSizeText(
                              context.tr(
                                'home.junior_adventure_subtitle',
                                fallback:
                                    '25 playful missions for young explorers',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              minFontSize: 8,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Mascot Area (Concentric & Engaging Design) OUTSIDE ClipRRect
              PositionedDirectional(
                end: 0,
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
                                    color: Colors.white.withValues(alpha: 0.3),
                                    size: (8 + random.nextInt(8)).r,
                                  )
                                  .animate(
                                    onPlay: (c) => c.repeat(reverse: true),
                                  )
                                  .fadeIn(
                                    duration: (1 + random.nextDouble()).seconds,
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
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 25,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Text(
                              "🧸",
                              style: TextStyle(fontSize: 48.sp, height: 1.0),
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
        ),
      ),
    );
  }

  Widget _buildBentoMasteryVault(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMiniStatTile(
                context,
                context.tr('home.badges', fallback: 'Badges'),
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
                context.tr('home.level_label', fallback: 'Lvl'),
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
                context.tr('home.total_xp', fallback: 'Total XP'),
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
    return Semantics(
      button: true,
      label: '$label: $value',
      child: ScaleButton(
        onTap: () => context.push(route),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 48.r),
          child: GlassTile(
            borderRadius: BorderRadius.circular(20.r),
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
            child: ExcludeSemantics(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                      style: TextStyle(
                        fontFamily: 'Outfit',
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
                      style: TextStyle(
                        fontFamily: 'Outfit',
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicGreeting(BuildContext context) {
    final name =
        user.displayName?.split(' ').first ??
        context.tr('home.default_seeker_name', fallback: 'Seeker');
    final hour = DateTime.now().hour;
    String greeting = context.tr('home.greeting_default', fallback: 'Hello');
    if (hour >= 5 && hour < 12) {
      greeting = context.tr('home.greeting_morning', fallback: 'Good Morning');
    } else if (hour >= 12 && hour < 17) {
      greeting = context.tr(
        'home.greeting_afternoon',
        fallback: 'Good Afternoon',
      );
    } else if (hour >= 17 && hour < 22) {
      greeting = context.tr('home.greeting_evening', fallback: 'Good Evening');
    } else {
      greeting = context.tr('home.greeting_night', fallback: 'Good Night');
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AutoSizeText(
          '$greeting,',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(
              0xFF6366F1,
            ).withValues(alpha: isDark ? 0.8 : 0.9),
            letterSpacing: 0.5,
            height: 1.2,
          ),
          maxLines: 1,
          minFontSize: 10,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 3.h),
        AutoSizeText(
          name,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            color: MeshGradientBackground.getContrastColor(context),
            letterSpacing: -0.8,
            height: 1.15,
          ),
          maxLines: 1,
          minFontSize: 16,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
