import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

// =============================================================================
// SLIDE 1 HERO: Speech & 100+ Games
// =============================================================================

/// Dynamic illustration for the Speech & Games slide.
///
/// Features the official Vowl mascot as the central hero, with animated sound
/// wave rings, an ambient glowing microphone badge, and floating pronunciation cards.
///
/// **Custom SVG Hook:**
/// When you are ready to supply a custom SVG for this slide, you can slot it
/// into the designated area inside this widget without changing page layout.
class OnboardingSpeechHero extends StatelessWidget {
  const OnboardingSpeechHero({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    Widget leftBadge = _FloatingHeroBadge(
      icon: LucideIcons.volume2,
      iconColor: AppColors.indigo500,
      title: 'Hello!',
      subtitle: '/həˈloʊ/',
      isDark: isDark,
    );
    if (!reduceMotion) {
      leftBadge = leftBadge
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(begin: 0, end: -6.h, duration: 2200.ms, curve: Curves.easeInOut);
    }

    Widget rightBadge = _FloatingHeroBadge(
      icon: LucideIcons.sparkles,
      iconColor: AppColors.amber400,
      title: 'Speech Score',
      subtitle: '98% Accuracy',
      isDark: isDark,
    );
    if (!reduceMotion) {
      rightBadge = rightBadge
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(begin: 0, end: 6.h, duration: 2500.ms, curve: Curves.easeInOut);
    }

    Widget micPill = Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.indigo500.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo500.withValues(alpha: 0.25),
            blurRadius: 16.r,
            spreadRadius: 2.r,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.mic, size: 14.r, color: AppColors.indigo500),
          SizedBox(width: 6.w),
          Text(
            'Real-Time AI Voice Pitch',
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.indigo950,
            ),
          ),
        ],
      ),
    );
    if (!reduceMotion) {
      micPill = micPill
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(begin: const Offset(1, 1), end: const Offset(1.04, 1.04), duration: 1800.ms);
    }

    Widget mascot = const VowlMascot(
      mascotId: 'vowly',
      state: VowlMascotState.studying,
      size: 138,
      useFloatingAnimation: true,
    );
    if (!reduceMotion) {
      mascot = mascot.animate().scale(
        begin: const Offset(0.8, 0.8),
        end: const Offset(1.0, 1.0),
        duration: 600.ms,
        curve: Curves.easeOutBack,
      );
    }

    return SizedBox(
      height: 250.h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Ambient Soundwave Rings ────────────────────────────────────────
          _SoundWaveRing(radius: 170.r, delay: 0.ms, color: AppColors.indigo500, reduceMotion: reduceMotion),
          _SoundWaveRing(radius: 220.r, delay: 400.ms, color: AppColors.indigo400, reduceMotion: reduceMotion),
          _SoundWaveRing(radius: 260.r, delay: 800.ms, color: AppColors.violet500, reduceMotion: reduceMotion),

          // ── Central Hero Mascot (Vowly) ───────────────────────────────────
          Positioned(child: mascot),

          // ── Left Floating Card: Speech Word Chip ───────────────────────────
          Positioned(left: 20.w, top: 40.h, child: leftBadge),

          // ── Right Floating Card: Pronunciation Accuracy ───────────────────
          Positioned(right: 20.w, top: 70.h, child: rightBadge),

          // ── Microphone Glowing Badge ─────────────────────────────────────
          Positioned(bottom: 12.h, child: micPill),
        ],
      ),
    );
  }
}

// =============================================================================
// SLIDE 2 HERO: AI Camera & Offline Tools
// =============================================================================

/// Dynamic illustration for the AI Camera & Offline Tools slide.
///
/// Features a smartphone viewfinder with animated corner reticle brackets,
/// a vertical scanning beam, and a detected real-world object vocabulary card.
///
/// **Custom SVG Hook:**
/// Can receive a custom camera illustration inside the viewfinder frame.
class OnboardingCameraHero extends StatelessWidget {
  const OnboardingCameraHero({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    Widget reticle = Container(
      width: 140.w,
      height: 120.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.blue500.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          LucideIcons.bookOpen,
          size: 42.r,
          color: AppColors.blue500,
        ),
      ),
    );
    if (!reduceMotion) {
      reticle = reticle
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(begin: const Offset(0.98, 0.98), end: const Offset(1.02, 1.02), duration: 1500.ms);
    }

    Widget scanLine = Container(
      height: 2.h,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.blue300,
            AppColors.blue500,
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue500.withValues(alpha: 0.7),
            blurRadius: 8.r,
            spreadRadius: 1,
          ),
        ],
      ),
    );
    if (!reduceMotion) {
      scanLine = scanLine
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 40.h, end: 160.h, duration: 1800.ms, curve: Curves.easeInOut);
    }

    return SizedBox(
      height: 250.h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Ambient Radar Glow ────────────────────────────────────────────
          Container(
            width: 220.w,
            height: 220.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.blue500.withValues(alpha: isDark ? 0.25 : 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // ── Smartphone Viewport Mockup ────────────────────────────────────
          Container(
            width: 200.w,
            height: 210.h,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isDark ? AppColors.slate700 : AppColors.slate200,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue500.withValues(alpha: 0.18),
                  blurRadius: 28.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top Camera Notch
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: EdgeInsets.only(top: 8.h),
                    width: 48.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate700 : AppColors.slate300,
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                ),

                // Viewfinder Reticle (Corner Brackets)
                Center(child: reticle),

                // Animated Laser Scanning Line
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: scanLine,
                  ),
                ),
              ],
            ),
          ),

          // ── Floating Detected Vocab Card ──────────────────────────────────
          Positioned(
            bottom: 4.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0369A1) : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.blue300.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue500.withValues(alpha: 0.25),
                    blurRadius: 14.r,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.checkCircle2, size: 14.r, color: isDark ? Colors.white : AppColors.blue500),
                  SizedBox(width: 6.w),
                  Text(
                    'Book • /bʊk/ • Noun',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.blue900,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Offline Badge (Top Right) ─────────────────────────────────────
          Positioned(
            right: 32.w,
            top: 24.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF164E63) : const Color(0xFFECFEFF),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.zap, size: 11, color: Color(0xFF06B6D4)),
                  SizedBox(width: 4.w),
                  Text(
                    'Offline ML',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.blue900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SLIDE 3 HERO: Buddy Boutique & Rewards
// =============================================================================

/// Dynamic illustration for the Buddy Boutique & Rewards slide.
///
/// Features the real Vowl mascot in a celebratory happy pose, accompanied by
/// floating XP badges, milestone sticker album previews, and glowing sparkles.
///
/// **Custom SVG Hook:**
/// Can receive custom accessory / sticker artwork.
class OnboardingBuddyHero extends StatelessWidget {
  const OnboardingBuddyHero({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    Widget leftBadge = _FloatingHeroBadge(
      icon: LucideIcons.sparkles,
      iconColor: AppColors.amber400,
      title: '+50 XP',
      subtitle: 'Daily Milestone',
      isDark: isDark,
    );
    if (!reduceMotion) {
      leftBadge = leftBadge
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -6.h, duration: 2300.ms);
    }

    Widget rightBadge = _FloatingHeroBadge(
      icon: LucideIcons.award,
      iconColor: AppColors.rose500,
      title: 'Rare Sticker',
      subtitle: 'Golden Quill 🪶',
      isDark: isDark,
    );
    if (!reduceMotion) {
      rightBadge = rightBadge
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: 6.h, duration: 2600.ms);
    }

    Widget crownPill = Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF4C0519) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.rose500.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.rose500.withValues(alpha: 0.25),
            blurRadius: 16.r,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('👑', style: TextStyle(fontSize: 13.sp)),
          SizedBox(width: 6.w),
          Text(
            'Custom Outfits & Boutique',
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.rose700,
            ),
          ),
        ],
      ),
    );
    if (!reduceMotion) {
      crownPill = crownPill
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(begin: const Offset(1, 1), end: const Offset(1.04, 1.04), duration: 2000.ms);
    }

    return SizedBox(
      height: 250.h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Golden Radiance Glow ──────────────────────────────────────────
          Container(
            width: 200.w,
            height: 200.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.rose500.withValues(alpha: isDark ? 0.3 : 0.18),
                  AppColors.amber400.withValues(alpha: isDark ? 0.15 : 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // ── Celebratory Vowl Mascot (Vowly Happy) ─────────────────────────
          Positioned(
            child: const VowlMascot(
              mascotId: 'vowly',
              state: VowlMascotState.happy,
              size: 140,
              useFloatingAnimation: true,
            ),
          ),

          // ── Left Floating Badge: Unlocked XP ──────────────────────────────
          Positioned(left: 20.w, top: 50.h, child: leftBadge),

          // ── Right Floating Badge: Sticker Album Preview ───────────────────
          Positioned(right: 20.w, top: 75.h, child: rightBadge),

          // ── Accessory Pill: Buddy Boutique Crown ─────────────────────────
          Positioned(bottom: 12.h, child: crownPill),
        ],
      ),
    );
  }
}

// =============================================================================
// SLIDE 4 HERO: Progress & Global Accents
// =============================================================================

/// Dynamic illustration for the Progress & Global Accents slide.
///
/// Built natively with Flutter widgets to guarantee razor-sharp typography,
/// crisp numbers, and fluid animated bar chart growth across all screen densities.
///
/// **Custom SVG Hook:**
/// Can be blended or enhanced with a world globe SVG.
class OnboardingProgressHero extends StatelessWidget {
  const OnboardingProgressHero({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final heights = [0.45, 0.65, 0.85, 0.55, 0.90, 0.75, 1.0];

    return SizedBox(
      height: 250.h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Ambient Green Glow ───────────────────────────────────────────
          Container(
            width: 220.w,
            height: 220.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.emerald500.withValues(alpha: isDark ? 0.25 : 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // ── Center Card: Weekly Growth Bar Chart ──────────────────────────
          // [CUSTOM SVG EXTENSION]: If using SVG chart/globe, place here.
          Container(
            width: 250.w,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.8) : Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: isDark ? AppColors.emerald600 : AppColors.slate200,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald500.withValues(alpha: 0.18),
                  blurRadius: 24.r,
                  offset: Offset(0, 8.h),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header: Streak Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.flame, size: 16.r, color: AppColors.amber400),
                        SizedBox(width: 4.w),
                        Text(
                          '7 Day Streak',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.emerald950,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '94% Accuracy',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.emerald500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // 7 Weekly Bars
                SizedBox(
                  height: 70.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final isToday = i == 6;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 18.w,
                                height: 50.h * heights[i],
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6.r),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: isToday
                                        ? const [AppColors.emerald400, AppColors.teal400]
                                        : [
                                            AppColors.emerald500.withValues(alpha: 0.45),
                                            AppColors.emerald500.withValues(alpha: 0.2),
                                          ],
                                  ),
                                  boxShadow: isToday
                                      ? [
                                          BoxShadow(
                                            color: AppColors.emerald400.withValues(alpha: 0.5),
                                            blurRadius: 8.r,
                                          ),
                                        ]
                                      : null,
                                ),
                              )
                                  .animate()
                                  .scaleY(
                                    begin: 0,
                                    end: 1,
                                    duration: 600.ms,
                                    delay: (i * 80).ms,
                                    curve: Curves.easeOutBack,
                                  ),
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            weekDays[i],
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                              color: isToday
                                  ? (isDark ? Colors.white : AppColors.emerald950)
                                  : (isDark ? Colors.white60 : Colors.black45),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 500.ms),

          // ── Bottom Pill: 4 Global Accent Chips ───────────────────────────
          Positioned(
            bottom: 4.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF042F2E) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AccentFlagChip(label: '🇺🇸 US', isDark: isDark),
                  SizedBox(width: 6.w),
                  _AccentFlagChip(label: '🇬🇧 UK', isDark: isDark),
                  SizedBox(width: 6.w),
                  _AccentFlagChip(label: '🇦🇺 AU', isDark: isDark),
                  SizedBox(width: 6.w),
                  _AccentFlagChip(label: '🇮🇳 IN', isDark: isDark),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0, duration: 400.ms),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SHARED HELPER WIDGETS
// =============================================================================

class _FloatingHeroBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;

  const _FloatingHeroBadge({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(5.r),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12.r, color: iconColor),
          ),
          SizedBox(width: 6.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : AppColors.slate500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SoundWaveRing extends StatelessWidget {
  final double radius;
  final Duration delay;
  final Color color;
  final bool reduceMotion;

  const _SoundWaveRing({
    required this.radius,
    required this.delay,
    required this.color,
    this.reduceMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    final ring = Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.28),
          width: 1.2,
        ),
      ),
    );
    if (reduceMotion) return ring;
    return ring
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1.06, 1.06),
          duration: 2000.ms,
          delay: delay,
          curve: Curves.easeInOut,
        );
  }
}

class _AccentFlagChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _AccentFlagChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.slate800,
        ),
      ),
    );
  }
}
