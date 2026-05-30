import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/ad_reward_card.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/theme/theme_cubit.dart';

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
  @override
  Widget build(BuildContext context) {
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isMidnight 
        ? Colors.black 
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

    return Scaffold(
      backgroundColor: bgColor,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) return const SizedBox.shrink();

          return Stack(
            children: [
              const MeshGradientBackground(),
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      toolbarHeight: 70.h,
                      automaticallyImplyLeading: false,
                      title: GlassTile(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        borderRadius: BorderRadius.circular(24.r),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32.r,
                              height: 32.r,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 18.r,
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Daily Streak',
                              style: GoogleFonts.outfit(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            _buildCoinsChip(user),
                          ],
                        ),
                      ),
                    ),

                    // Body Content
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 40.h),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          StreakHero(user: user),
                          SizedBox(height: 24.h),
                          StreakCalendar(user: user),
                          SizedBox(height: 32.h),
                          StreakMilestones(user: user),
                          SizedBox(height: 32.h),
                          StreakBoostersShop(user: user),
                          SizedBox(height: 24.h),
                          const AdRewardCard(margin: EdgeInsets.zero),
                          SizedBox(height: 40.h),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCoinsChip(UserEntity user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.15),
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
            '${user.coins}',
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}
