import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class MainWrapper extends StatelessWidget {
  const MainWrapper({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;

    return Scaffold(
      backgroundColor: isMidnight
          ? const Color(0xFF020617)
          : (isDark ? const Color(0xFF0F172A) : Colors.white),
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: RepaintBoundary(
        child: Container(
          height: 82.h,
          margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // 1. Premium Glass Background
              ClipRRect(
                borderRadius: BorderRadius.circular(24.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    height: 65.h,
                    decoration: BoxDecoration(
                      color: isMidnight
                          ? Colors.black.withValues(alpha: 0.2)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.7)),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: isMidnight
                            ? Colors.white.withValues(alpha: 0.08)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.4)),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 40,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 2. Navigation Items
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: SizedBox(
                  height: 65.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(context, 0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                      _buildNavItem(context, 1, Icons.sports_esports_outlined, Icons.sports_esports_rounded, 'Games'),
                      _buildNavItem(context, 2, Icons.leaderboard_outlined, Icons.leaderboard_rounded, 'Ranks'),
                      _buildNavItem(context, 3, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().slideY(
            begin: 0.5,
            end: 0,
            duration: 350.ms,
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData inactiveIcon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = navigationShell.currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = const Color(0xFF3B82F6);

    return GestureDetector(
      onTap: () => _onTap(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12.w : 8.w,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected
                  ? accentColor
                  : (isDark ? Colors.white54 : Colors.black45),
              size: 24.r,
            ).animate(target: isSelected ? 1 : 0)
             .shimmer(delay: 400.ms, duration: 1200.ms, color: Colors.white24)
             .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
            
            if (isSelected) ...[
              SizedBox(width: 4.w),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn().slideX(begin: -0.2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    if (navigationShell.currentIndex == index) {
      if (index == 0 && di.sl.isRegistered<ScrollController>(instanceName: 'home')) {
        final homeController = di.sl<ScrollController>(instanceName: 'home');
        if (homeController.hasClients) {
          homeController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.fastOutSlowIn,
          );
        }
      } else if (index == 1 && di.sl.isRegistered<ScrollController>(instanceName: 'games')) {
        final gamesController = di.sl<ScrollController>(instanceName: 'games');
        if (gamesController.hasClients) {
          gamesController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.fastOutSlowIn,
          );
        }
      }
    }

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
