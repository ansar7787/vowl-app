import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
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
import 'package:vowl/features/auth/data/repositories/gamification_repository_impl.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';

class VictoryScreen extends StatefulWidget {
  final int xp;
  final int coins;
  final String? title;

  /// BUG FIX (localization): this used to default to a hardcoded English
  /// sentence directly in the constructor signature. Dart constructor
  /// default values must be compile-time constants, so that default could
  /// never have actually been localized as written. Making it nullable and
  /// resolving the real fallback text inside `build()` mirrors exactly how
  /// `title` already correctly handles this, and is fully backward
  /// compatible — every existing caller that explicitly passes a
  /// description keeps behaving identically.
  final String? description;
  final String category; // 'accent', 'grammar', etc.
  final String gameType; // 'vowelDistinction', 'minimalPairs', etc.
  final int level;

  const VictoryScreen({
    super.key,
    required this.xp,
    required this.coins,
    this.title,
    this.description,
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
            RepaintBoundary(
              child: TwinklingStarsBackground(
                starColor: theme.primaryColor.withValues(alpha: 0.8),
                starCount: 40,
                baseOpacity: isDark ? 0.4 : 0.2,
              ),
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
            const RepaintBoundary(child: GameConfetti()),
          ],
        ),
      ),
    );
  }

  Widget _buildTrophy(Color primaryColor) {
    return ValueListenableBuilder<int>(
      valueListenable: GamificationRepositoryImpl.lastEarnedStars,
      builder: (context, stars, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final isEarned = index < stars;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Icon(
                Icons.star_rounded,
                size: index == 1 ? 90.r : 60.r,
                color: isEarned ? const Color(0xFFFFD700) : Colors.black12,
                shadows: isEarned
                    ? [
                        Shadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                          blurRadius: 20.r,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              )
                  .animate(delay: (200 * index).ms)
                  .scale(
                    begin: const Offset(0, 0),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
                  .then()
                  .shimmer(
                    delay: 2.seconds,
                    duration: 1.seconds,
                    color: Colors.white,
                  ),
            );
          }),
        ).animate().slideY(begin: -0.2, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildTitle(bool isDark) {
    return Text(
      widget.title ?? context.tr('games.level_complete').toUpperCase(),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 32.sp,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }

  Widget _buildDescription(bool isDark) {
    final resolvedDescription =
        widget.description ??
        context.tr(
          'games.victory_default_description',
          fallback: 'You are mastering your accent with precision!',
        );

    return Text(
      resolvedDescription,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white70 : Colors.black54,
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2);
  }

  Widget _buildRewardCard(bool isDark, Color primaryColor) {
    return Semantics(
      label: context.tr(
        'games.rewards_summary_label',
        args: [widget.xp.toString(), widget.coins.toString()],
        fallback: '+${widget.xp} XP, +${widget.coins} coins',
      ),
      child:
          GlassTile(
                borderRadius: BorderRadius.circular(32.r),
                padding: EdgeInsets.all(32.r),
                color: primaryColor.withValues(alpha: 0.05),
                borderColor: primaryColor.withValues(alpha: 0.2),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRewardItem(
                        context.tr('common.xp_suffix', fallback: 'XP'),
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
                        context.tr('home.coins'),
                        widget.coins,
                        Icons.generating_tokens_rounded,
                        const Color(0xFFFFD700),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: 700.ms)
              .slideY(begin: 0.3, curve: Curves.easeOutQuad),
    );
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
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                color: color,
              ),
              maxLines: 1,
            );
          },
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: color.withValues(alpha: 0.7),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildContinueButton(Color primaryColor) {
    return Column(
      children: [
        Semantics(
          button: true,
          label: context.tr(
            'games.triple_up_action',
            fallback: 'Watch an ad to triple your rewards',
          ),
          child: ScaleButton(
            onTap: () {
              final isPremium =
                  context.read<AuthBloc>().state.user?.isPremium ?? false;
              di.sl<AdService>().showRewardedAd(
                context: context,
                isPremium: isPremium,
                onUserEarnedReward: (_) {
                  if (!mounted) return;
                  context.read<EconomyBloc>().add(
                    EconomyTripleUpRewardsRequested(
                      widget.xp * 2,
                      widget.coins * 2,
                    ),
                  );
                  GameDialogHelper.showPremiumSnackBar(
                    context,
                    context.tr(
                      'games.rewards_tripled',
                      fallback: 'REWARDS TRIPLED! 💎💎💎',
                    ),
                    icon: Icons.auto_awesome_rounded,
                    color: const Color(0xFF10B981),
                  );
                  _navigateBack();
                },
                onDismissed: () {},
              );
            },
            child: ExcludeSemantics(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 18.h),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFF59E0B,
                  ), // Amber color for high-value action
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
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 24.r,
                    ),
                    SizedBox(width: 12.w),
                    Flexible(
                      child: Text(
                        context.tr(
                          'games.triple_up_label',
                          fallback: 'TRIPLE UP (3x)',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Semantics(
          button: true,
          label: context.tr('common.continue_text').toUpperCase(),
          child: ScaleButton(
            onTap: _navigateBack,
            child: ExcludeSemantics(
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
                    context.tr('common.continue_text').toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateBack() {
    di.sl<AdService>().recordLevelCompletion();
    context.read<AuthBloc>().add(const AuthRefreshUser());
    
    final route =
        '/levels?category=${Uri.encodeQueryComponent(widget.category)}&gameType=${Uri.encodeQueryComponent(widget.gameType)}';
    context.go(route);
  }
}
