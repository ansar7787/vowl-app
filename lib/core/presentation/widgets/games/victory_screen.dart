import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/twinkling_stars_background.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';

class VictoryScreen extends StatefulWidget {
  final int xp;
  final int coins;
  final String title;
  final String description;
  final String category; // 'accent', 'grammar', etc.
  final String gameType; // 'vowelDistinction', 'minimalPairs', etc.
  final int level;

  const VictoryScreen({
    super.key,
    required this.xp,
    required this.coins,
    this.title = 'LEVEL COMPLETE!',
    this.description = 'You are mastering your accent with precision!',
    required this.category,
    required this.gameType,
    required this.level,
  });

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final theme = LevelThemeHelper.getTheme(
      widget.category,
      level: widget.level,
      isDark: isDark,
      isMidnight: isMidnight,
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.backgroundColors[1],
        body: Stack(
          children: [
            MeshGradientBackground(colors: theme.backgroundColors),
            TwinklingStarsBackground(
              starColor: theme.primaryColor.withValues(alpha: 0.8),
              starCount: 40, // Reduced for less clutter
              baseOpacity: isDark ? 0.4 : 0.2, // Subtler
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 40.h),
                              _buildTrophy(theme.primaryColor),
                              SizedBox(height: 32.h),
                              _buildTitle(isDark),
                              SizedBox(height: 12.h),
                              _buildDescription(isDark),
                              SizedBox(height: 48.h),
                              _buildRewardCard(isDark, theme.primaryColor),
                              SizedBox(height: 40.h),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildContinueButton(theme.primaryColor),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
            const GameConfetti(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrophy(Color primaryColor) {
    const goldColor = Color(0xFFFFD700);

    return Container(
          padding: EdgeInsets.all(32.r),
          decoration: BoxDecoration(
            color: goldColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: goldColor.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(
              color: goldColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Icon(Icons.emoji_events_rounded, color: goldColor, size: 80.r),
        )
        .animate()
        .rotate(
          begin: -0.2,
          end: 0,
          duration: 1000.ms,
          curve: Curves.elasticOut,
        )
        .scale(duration: 800.ms, curve: Curves.elasticOut)
        .shake(hz: 3, curve: Curves.easeInOutCubic, duration: 1000.ms)
        .shimmer(delay: 1.seconds, duration: 2.seconds);
  }

  Widget _buildTitle(bool isDark) {
    return Text(
      widget.title,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 32.sp,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }

  Widget _buildDescription(bool isDark) {
    return Text(
      widget.description,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white70 : Colors.black54,
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2);
  }

  Widget _buildRewardCard(bool isDark, Color primaryColor) {
    return GlassTile(
          borderRadius: BorderRadius.circular(32.r),
          padding: EdgeInsets.all(32.r),
          color: primaryColor.withValues(alpha: 0.05),
          borderColor: primaryColor.withValues(alpha: 0.2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRewardItem(
                'XP',
                widget.xp,
                Icons.bolt_rounded,
                Colors.amber,
              ),
              Container(
                width: 1,
                height: 40.h,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
              _buildRewardItem(
                'COINS',
                widget.coins,
                Icons.generating_tokens_rounded,
                const Color(0xFFFFD700),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 700.ms)
        .slideY(begin: 0.3, curve: Curves.easeOutQuad);
  }

  Widget _buildRewardItem(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32.r),
        SizedBox(height: 8.h),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: 1500.ms,
          curve: Curves.easeOutCubic,
          builder: (context, currentValue, child) {
            return Text(
              '+$currentValue',
              style: GoogleFonts.outfit(
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            );
          },
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(Color primaryColor) {
    return Column(
      children: [
        ScaleButton(
          onTap: () {
            final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
            di.sl<AdService>().showRewardedAd(
              isPremium: isPremium,
              onUserEarnedReward: (_) {
                context.read<EconomyBloc>().add(
                  EconomyTripleUpRewardsRequested(widget.xp * 2, widget.coins * 2),
                );
                GameDialogHelper.showPremiumSnackBar(
                  context,
                  'REWARDS TRIPLED! 💎💎💎',
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xFF10B981),
                );
                _navigateBack();
              },
              onDismissed: () {},
            );
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 18.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B), // Amber color for high-value action
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24.r),
                SizedBox(width: 12.w),
                Text(
                  "TRIPLE UP (3x)",
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        ScaleButton(
          onTap: _navigateBack,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                "CONTINUE",
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateBack() {
    final route = '/levels?category=${widget.category}&gameType=${widget.gameType}';
    context.go(route);
  }
}
