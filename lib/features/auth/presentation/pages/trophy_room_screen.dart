import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:go_router/go_router.dart';

class TrophyRoomScreen extends StatelessWidget {
  const TrophyRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;

    return Scaffold(
      backgroundColor: isMidnight
          ? const Color(0xFF020617)
          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
      body: Stack(
        children: [
          // Dynamic mesh background with gold/purple theme for achievements
          MeshGradientBackground(
            colors: isMidnight
                ? [const Color(0xFF020617), const Color(0xFF4C1D95).withValues(alpha: 0.3), const Color(0xFFB45309).withValues(alpha: 0.2)]
                : (isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF5B21B6), const Color(0xFF92400E)]
                    : [const Color(0xFFF8FAFC), const Color(0xFFEDE9FE), const Color(0xFFFEF3C7)]),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  snap: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  expandedHeight: 80.h,
                  collapsedHeight: 64.h,
                  toolbarHeight: 64.h,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    title: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return GlassTile(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 6.h,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 32.r,
                                height: 32.r,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 18.r,
                                  onPressed: () => context.pop(),
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  'Trophy Room',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.monetization_on_rounded,
                                      color: const Color(0xFF10B981),
                                      size: 14.r,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '${state.user?.coins ?? 0}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        SizedBox(height: 16.h),
                        _buildMascotStage(context, isDark, isMidnight),
                        SizedBox(height: 48.h),
                        _buildSectionTitle("LEGENDARY BADGES", isDark, isMidnight),
                        SizedBox(height: 20.h),
                        _buildBadgeSection(context, isDark, isMidnight),
                        SizedBox(height: 48.h),
                        _buildSectionTitle("COLLECTIBLES VAULT", isDark, isMidnight),
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

  Widget _buildSectionTitle(String title, bool isDark, bool isMidnight) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 24.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B),
            borderRadius: BorderRadius.circular(2.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
            color: (isDark || isMidnight) ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B),
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

        return GlassTile(
          borderRadius: BorderRadius.circular(40.r),
          padding: EdgeInsets.all(2.r),
          borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
          child: Container(
            height: 240.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(38.r),
              gradient: RadialGradient(
                center: const Alignment(0, 0.2),
                radius: 1.2,
                colors: [
                  const Color(0xFFF59E0B).withValues(alpha: 0.15),
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
                    width: (140 + (index * 30)).r,
                    height: (140 + (index * 30)).r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1 - (index * 0.02)),
                        width: 1,
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                   .rotate(duration: Duration(seconds: 10 + (index * 5)))
                   .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: Duration(seconds: 4 + index), curve: Curves.easeInOut)
                   .then().scale(begin: const Offset(1.1, 1.1), end: const Offset(0.9, 0.9), duration: Duration(seconds: 4 + index), curve: Curves.easeInOut);
                }),
                
                // Core Glow
                Container(
                  width: 110.r,
                  height: 110.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds, color: Colors.white24),

                // Mascot & Accessory
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        VowlMascot(
                          size: 90.r,
                          state: VowlMascotState.happy,
                          useFloatingAnimation: true,
                        ),
                      ],
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .moveY(begin: -8, end: 8, duration: 2.5.seconds, curve: Curves.easeInOutSine),
                    SizedBox(height: 20.h),
                    
                    // Premium Level Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: Colors.white, size: 16.r),
                          SizedBox(width: 6.w),
                          Text(
                            "LEVEL $level",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16.sp,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgeSection(BuildContext context, bool isDark, bool isMidnight) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final badges = state.user?.badges ?? [];
        if (badges.isEmpty) {
          return _buildEmptySection("No badges yet. Start your journey to earn legendary rewards!", isDark, isMidnight);
        }
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16.r,
            crossAxisSpacing: 16.r,
            childAspectRatio: 0.75,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            return _buildBadgeCard(badges[index], isDark, isMidnight, index);
          },
        );
      },
    );
  }

  Widget _buildBadgeCard(String badgeId, bool isDark, bool isMidnight, int index) {
    // Generate a pseudo-random color based on the badge ID
    final colors = [
      [const Color(0xFF3B82F6), const Color(0xFF2563EB)], // Blue
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], // Purple
      [const Color(0xFF10B981), const Color(0xFF059669)], // Green
      [const Color(0xFFF43F5E), const Color(0xFFE11D48)], // Rose
      [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Amber
    ];
    
    final colorPair = colors[badgeId.hashCode % colors.length];

    return GlassTile(
      borderRadius: BorderRadius.circular(24.r),
      padding: EdgeInsets.all(2.r),
      borderColor: colorPair[0].withValues(alpha: 0.3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorPair[0].withValues(alpha: 0.15),
              colorPair[1].withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56.r,
              height: 56.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: colorPair,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorPair[0].withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Center(
                child: Text(
                  "🏆",
                  style: TextStyle(fontSize: 28.sp, shadows: [
                    Shadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))
                  ]),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .moveY(begin: -3, end: 3, duration: 2.seconds, curve: Curves.easeInOut),
             
            SizedBox(height: 12.h),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                badgeId.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: (isDark || isMidnight) ? Colors.white : const Color(0xFF0F172A),
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ).animate()
     .scale(delay: (100 * index).ms, duration: 400.ms, curve: Curves.easeOutBack)
     .fadeIn(delay: (100 * index).ms);
  }

  Widget _buildFurnitureSection(BuildContext context, bool isDark, bool isMidnight) {
    return _buildEmptySection(
      "The vault is currently locked. Win more badges to unlock legendary furniture for your mascot!", 
      isDark, 
      isMidnight,
      icon: Icons.lock_outline_rounded
    );
  }

  Widget _buildEmptySection(String text, bool isDark, bool isMidnight, {IconData icon = Icons.emoji_events_outlined}) {
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
              size: 48.r,
              color: (isDark || isMidnight) ? Colors.white24 : Colors.black26,
            ),
            SizedBox(height: 16.h),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: (isDark || isMidnight) ? Colors.white54 : const Color(0xFF64748B),
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
