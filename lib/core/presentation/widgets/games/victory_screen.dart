import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/game_confetti.dart';
import 'package:voxai_quest/core/presentation/widgets/glass_tile.dart';
import 'package:voxai_quest/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/widgets/twinkling_stars_background.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';

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
  int _displayedXp = 0;
  int _displayedCoins = 0;

  @override
  void initState() {
    super.initState();
    _animateCounters();
  }

  void _animateCounters() async {
    await Future.delayed(800.ms);
    if (!mounted) return;

    // Animate XP
    for (int i = 0; i <= widget.xp; i++) {
      if (!mounted) break;
      setState(() => _displayedXp = i);
      await Future.delayed(20.ms);
    }

    // Animate Coins
    for (int i = 0; i <= widget.coins; i++) {
      if (!mounted) break;
      setState(() => _displayedCoins = i);
      await Future.delayed(15.ms);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      widget.category,
      level: widget.level,
      isDark: isDark,
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            MeshGradientBackground(colors: theme.backgroundColors),
            TwinklingStarsBackground(
              starColor: theme.primaryColor.withValues(alpha: 0.8),
              starCount: 100, // Slightly reduced for clarity
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
    return Container(
          padding: EdgeInsets.all(32.r),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.emoji_events_rounded,
            color: primaryColor,
            size: 80.r,
          ),
        )
        .animate()
        .scale(duration: 800.ms, curve: Curves.elasticOut)
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
                _displayedXp,
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
                _displayedCoins,
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
        Text(
          '+$value',
          style: GoogleFonts.outfit(
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            color: color,
          ),
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
    return ScaleButton(
      onTap: () {
        final route =
            '/levels?category=${widget.category}&gameType=${widget.gameType}';
        final isPremium =
            context.read<AuthBloc>().state.user?.isPremium ?? false;
        final adService = di.sl<AdService>();

        // Record this level completion & check if interstitial is due
        final shouldShowAd = adService.recordLevelCompletion();

        if (shouldShowAd && !isPremium) {
          // Show interstitial, then navigate after dismissal
          adService.showInterstitialAd(
            isPremium: false,
            onDismissed: () {
              if (mounted) context.go(route);
            },
          );
        } else {
          // Navigate directly — no ad this time
          context.go(route);
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Text(
            "CONTINUE",
            style: GoogleFonts.outfit(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.5);
  }
}
