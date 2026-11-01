import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Primary hero identity and status header on the Vowl home dashboard.
///
/// Implements **Concept 4: The Apex Daily Driver** (Master Hybrid):
/// - **Borderless & Open**: Completely eliminates the enclosing card box,
///   reclaiming ~70dp of vertical screen space so core learning rises above the fold.
/// - **XP Halo Avatar**: 54dp avatar surrounded by a hairline XP progress ring
///   filling toward the next level, with a docked achievement level tag.
/// - **Contextual Habit Urgency**: Real-time habit feedback ("Goal pending"
///   vs. "Goal smashed! ⭐").
/// - **Linear-Style Dual-Metric HUD**: Single unified glass capsule with
///   live streak activity pip (amber pulse / emerald check) and coin balance.
class HomeHeroHeader extends StatelessWidget {
  /// Current authenticated [user] entity.
  final UserEntity user;

  /// Creates a [HomeHeroHeader] for [user].
  const HomeHeroHeader({super.key, required this.user});

  /// Dynamic rank descriptor based on the user's level.
  static ({String label, Color color, IconData icon}) rankForLevel(int level) {
    if (level >= 50) {
      return (
        label: 'LEGEND',
        color: AppColors.gold,
        icon: Icons.workspace_premium_rounded,
      );
    }
    if (level >= 30) {
      return (
        label: 'ELITE',
        color: IllustrationColors.richPurple,
        icon: Icons.diamond_rounded,
      );
    }
    if (level >= 15) {
      return (
        label: 'COMMANDER',
        color: AppColors.blue500,
        icon: Icons.shield_rounded,
      );
    }
    if (level >= 5) {
      return (
        label: 'OPERATIVE',
        color: AppColors.indigo500,
        icon: Icons.bolt_rounded,
      );
    }
    return (
      label: 'ROOKIE',
      color: AppColors.emerald500,
      icon: Icons.explore_rounded,
    );
  }

  /// Evaluates whether the user has already completed learning activity today.
  static bool isTodayActive(UserEntity user) {
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if ((user.dailyXpHistory[todayKey] ?? 0) > 0) {
      return true;
    }
    if (user.lastLoginDate != null &&
        user.lastLoginDate!.year == now.year &&
        user.lastLoginDate!.month == now.month &&
        user.lastLoginDate!.day == now.day &&
        user.currentStreak > 0) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final contrastColor = MeshGradientBackground.getContrastColor(context);

    // XP-to-next-level progress (0.02 to 1.0) with defensive negative check
    final safeExp = user.totalExp > 0 ? user.totalExp : 0;
    final progress = ((safeExp % 100) / 100.0).clamp(0.02, 1.0);
    final rank = rankForLevel(user.level);
    final todayActive = isTodayActive(user);

    final displayName = _resolveDisplayName(context);
    final greeting = _resolveGreeting(context);

    Widget header = Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── 1. AVATAR WITH XP HALO RING & BUDDY PIN ───────────────
          _buildAvatarWithHalo(
            context,
            isDark: isDark,
            progress: progress,
            rankColor: rank.color,
            reduceMotion: reduceMotion,
          ),
          SizedBox(width: 14.w),

          // ── 2. IDENTITY (EYEBROW STACK) & HABIT FOCUS (OPTION B) ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Line: Greeting Eyebrow
                Text(
                  '$greeting,',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6366F1).withValues(
                      alpha: isDark ? 0.85 : 0.95,
                    ),
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),

                // Middle Line: User Display Name (Scales down smoothly, zero ellipses)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: contrastColor,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                    maxLines: 1,
                  ),
                ),
                SizedBox(height: 4.h),

                // Bottom Line: Option B — Contextual Habit Focus
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Live Status Dot Indicator
                      Container(
                        width: 7.r,
                        height: 7.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: todayActive
                              ? AppColors.emerald500
                              : IllustrationColors.warmOrange,
                          boxShadow: [
                            BoxShadow(
                              color: (todayActive
                                      ? AppColors.emerald500
                                      : IllustrationColors.warmOrange)
                                  .withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ).animateIf(
                        context,
                        (w) => !todayActive && !reduceMotion
                            ? w
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1.3, 1.3),
                                  duration: 1000.ms,
                                )
                            : w,
                      ),
                      SizedBox(width: 6.w),

                      // Clean Habit text (no truncation, high utility)
                      Text(
                        todayActive
                            ? context.tr(
                                'home.habit_goal_completed',
                                fallback: 'Daily goal completed ⭐',
                              )
                            : context.tr(
                                'home.habit_goal_pending',
                                fallback: '1 lesson to reach daily goal',
                              ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.75)
                              : AppColors.slate600,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),

          // ── 3. LINEAR-STYLE DUAL METRIC HUD (STREAK + COINS) ──────
          _buildDualMetricHud(
            context,
            isDark: isDark,
            todayActive: todayActive,
          ),
        ],
      ),
    );

    if (reduceMotion) return header;
    return header.animate().fadeIn(duration: 400.ms).slideY(begin: -0.04, end: 0);
  }

  /// Avatar wrapped in a concentric XP progress halo ring with docked level badge.
  Widget _buildAvatarWithHalo(
    BuildContext context, {
    required bool isDark,
    required double progress,
    required Color rankColor,
    required bool reduceMotion,
  }) {
    return Semantics(
      button: true,
      label: context.tr(
        'home.avatar_semantics_label',
        fallback: 'Profile avatar, Level {0}',
        args: [user.level.toString()],
      ),
      child: ScaleButton(
        onTap: () {
          _triggerHaptic();
          context.push(AppRouter.profileRoute);
        },
        child: SizedBox(
          width: 56.r,
          height: 56.r,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // XP Progress Halo
              SizedBox(
                width: 56.r,
                height: 56.r,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.5.r,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.indigo500.withValues(alpha: 0.12),
                  color: AppColors.indigo500,
                  strokeCap: StrokeCap.round,
                ),
              ),

              // Inner Avatar Circle
              Container(
                width: 46.r,
                height: 46.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.slate900 : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo500.withValues(
                        alpha: isDark ? 0.2 : 0.08,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: UserAvatar(
                  photoUrl: user.photoUrl,
                  size: 46.r,
                  fallbackIcon: Icons.person_rounded,
                  iconColor: AppColors.indigo500,
                  iconSize: 24.r,
                ),
              ),

              // Docked Companion / Buddy Pin (Top-Left)
              PositionedDirectional(
                start: -2.w,
                top: -2.h,
                child: Container(
                  width: 18.r,
                  height: 18.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: isDark ? AppColors.slate950 : Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 9.r,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Docked Level Badge (Bottom-Right)
              PositionedDirectional(
                end: -2.w,
                bottom: -2.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                  decoration: BoxDecoration(
                    color: rankColor,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isDark ? AppColors.slate950 : Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: rankColor.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${user.level}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: rankColor.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Linear-style dual-metric HUD capsule displaying Streak and Coins.
  Widget _buildDualMetricHud(
    BuildContext context, {
    required bool isDark,
    required bool todayActive,
  }) {
    final capsuleBg = isDark
        ? AppColors.slate900.withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.95);
    final borderColor = isDark
        ? AppColors.slate700.withValues(alpha: 0.6)
        : AppColors.slate200;

    return Semantics(
      container: true,
      child: Container(
        height: 38.h,
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        decoration: BoxDecoration(
          color: capsuleBg,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Streak Segment ───────────────────────────────────────
            Semantics(
              button: true,
              label: context.tr(
                'home.streak_label',
                fallback: 'Current Streak: {0} days',
                args: [user.currentStreak.toString()],
              ),
              child: ScaleButton(
                onTap: () {
                  _triggerHaptic();
                  context.push(AppRouter.streakRoute);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 6.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 16.r,
                        color: IllustrationColors.warmOrange,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${user.currentStreak}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          color: IllustrationColors.warmOrange,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Hairline Divider
            Container(
              width: 1,
              height: 16.h,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.1),
            ),

            // ── Coins Segment ────────────────────────────────────────
            Semantics(
              button: true,
              label: context.tr(
                'home.coins_label',
                fallback: 'Available Coins: {0}',
                args: [user.coins.toString()],
              ),
              child: ScaleButton(
                onTap: () {
                  _triggerHaptic();
                  context.push(AppRouter.questCoinsRoute);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 6.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.paid_rounded,
                        size: 15.r,
                        color: isDark ? AppColors.gold : AppColors.amber600,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _formatNumber(user.coins),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.gold : AppColors.amber600,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerHaptic() {
    try {
      di.sl<HapticService>().selection();
    } catch (e) {
      if (kDebugMode) debugPrint('HomeHeroHeader: haptics unavailable: $e');
    }
  }

  String _resolveDisplayName(BuildContext context) {
    final rawName =
        (user.displayName != null && user.displayName!.trim().isNotEmpty)
            ? user.displayName!.trim()
            : user.getSafeDisplayName(
                fallback: context.tr('home.default_seeker_name', fallback: 'Seeker'),
              );
    final cleanName = rawName.replaceAll(RegExp(r'\s+'), ' ');
    // Protect against absurd string spam (>30 chars) without penalizing legitimate names
    if (cleanName.length > 30) {
      return '${cleanName.substring(0, 28)}...';
    }
    return cleanName;
  }

  String _resolveGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return context.tr('home.greeting_morning', fallback: 'Good Morning');
    } else if (hour >= 12 && hour < 17) {
      return context.tr('home.greeting_afternoon', fallback: 'Good Afternoon');
    } else if (hour >= 17 && hour < 22) {
      return context.tr('home.greeting_evening', fallback: 'Good Evening');
    } else {
      return context.tr('home.greeting_night', fallback: 'Good Night');
    }
  }

  String _formatNumber(int n) {
    if (n < 0) return '0';
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(0)}k';
    if (n >= 1000) {
      final formatted = (n / 1000).toStringAsFixed(1);
      return formatted.endsWith('.0')
          ? '${(n / 1000).toStringAsFixed(0)}k'
          : '${formatted}k';
    }
    return n.toString();
  }
}
