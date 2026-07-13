import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/ad_reward_card.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

import 'package:vowl/features/home/presentation/widgets/streak_hero.dart';
import 'package:vowl/features/home/presentation/widgets/streak_calendar.dart';
import 'package:vowl/features/home/presentation/widgets/streak_milestones.dart';
import 'package:vowl/features/home/presentation/widgets/streak_boosters_shop.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isMidnight
        ? const Color(0xFF020617)
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));
    final contentColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) {
            return Center(
              child: CircularProgressIndicator(
                color: isDark ? Colors.white38 : const Color(0xFF3B82F6),
              ),
            );
          }

          return Stack(
            children: [
              // 1. Immersive Background
              const MeshGradientBackground(showLetters: false),

              // 2. Dynamic Scrollable Body
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Safe area space matching the floating app bar
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).padding.top + 95.h,
                    ),
                  ),

                  // 3. Main Streak Metrics/Contents
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 100.h),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        RepaintBoundary(child: StreakHero(user: user)),
                        SizedBox(height: 24.h),
                        RepaintBoundary(child: StreakCalendar(user: user)),
                        SizedBox(height: 32.h),
                        RepaintBoundary(child: StreakMilestones(user: user)),
                        SizedBox(height: 32.h),
                        RepaintBoundary(child: StreakBoostersShop(user: user)),
                        SizedBox(height: 24.h),
                        const RepaintBoundary(
                          child: AdRewardCard(margin: EdgeInsets.zero),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),

              // 4. Floating Glass Island AppBar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RepaintBoundary(
                  child: _buildFloatingGlassAppBar(
                    context,
                    isDark,
                    contentColor,
                    user,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFloatingGlassAppBar(
    BuildContext context,
    bool isDark,
    Color contentColor,
    UserEntity user,
  ) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12.h,
            bottom: 16.h,
            left: 20.w,
            right: 20.w,
          ),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(
              alpha: 0.1,
            ),
            border: Border(
              bottom: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.05,
                ),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                button: true,
                label: context.tr('common.back', fallback: 'Back', fallback: 'Back'),
                child: ScaleButton(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRouter.homeRoute);
                    }
                  },
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: 48.r,
                      minHeight: 48.r,
                    ),
                    alignment: Alignment.center,
                    child: ExcludeSemantics(
                      child: Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        child: Icon(
                          isRtl
                              ? Icons.arrow_forward_ios_rounded
                              : Icons.arrow_back_ios_new_rounded,
                          color: contentColor,
                          size: 20.r,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Centered Title Pill
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: const Color(0xFFF97316).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: const Color(0xFFF97316),
                      size: 16.r,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      context.tr('streak.daily_streak_title', fallback: 'Daily Streak', fallback: 'Daily Streak'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: contentColor,
                        letterSpacing: 1.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Coins Info Pill
              _buildCoinsChip(context, user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoinsChip(BuildContext context, UserEntity user) {
    return Semantics(
      label: context.tr(
        'home.coins_value_label', fallback: 'Coins',
        args: [user.coins.toString()],
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.2),
          ),
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monetization_on_rounded,
                color: const Color(0xFF10B981),
                size: 16.r,
              ),
              SizedBox(width: 6.w),
              Text(
                '${user.coins}',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF10B981),
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
