import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_magic_chest.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_watch_earn_card.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_category_grid.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_smart_mix_widget.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_zone_home_header.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/presentation/widgets/key_shop_bottom_sheet.dart';
import 'package:vowl/core/utils/age_gate_service.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';

class KidsZoneScreen extends StatefulWidget {
  const KidsZoneScreen({super.key});

  @override
  State<KidsZoneScreen> createState() => _KidsZoneScreenState();
}

class _KidsZoneScreenState extends State<KidsZoneScreen> {
  final math.Random _random = math.Random();
  final List<Map<String, dynamic>> _activeCoins = [];
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _spawnCoins() {
    _confettiController.play();
    for (int i = 0; i < 15; i++) {
      final id = DateTime.now().millisecondsSinceEpoch + i;
      setState(() {
        _activeCoins.add({
          'id': id,
          'x': 0.3 + _random.nextDouble() * 0.4,
          'y': 0.8,
          'targetX': 0.8 + _random.nextDouble() * 0.1,
          'targetY': 0.05,
          'delay': i * 100,
        });
      });
      Future.delayed(Duration(milliseconds: 1000 + (i * 100)), () {
        if (mounted) {
          setState(() {
            _activeCoins.removeWhere((c) => c['id'] == id);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: SafeArea(child: HomeShimmerLoading()));
    }

    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          const MeshGradientBackground(showLetters: false),

          // Floating Coins Layer
          ..._activeCoins.map((coin) {
            return _FloatingCoin(
              x: coin['x'],
              y: coin['y'],
              targetX: coin['targetX'],
              targetY: coin['targetY'],
              delay: coin['delay'],
            );
          }),

          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              // React to state changes if needed
            },
            child: RefreshIndicator(
              onRefresh: () async {
                di.sl<HapticService>().selection();
                context.read<AuthBloc>().add(const AuthReloadUser());
                await Future.delayed(const Duration(milliseconds: 1000));
              },
              color: const Color(0xFF6366F1),
              backgroundColor: Colors.white,
              displacement: 100,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).padding.top + 10.h,
                    ),
                  ),

                  _buildSlimAppBar(context, user.kidsCoins),

                  KidsZoneHomeHeader(
                    mascot: user.kidsMascot ?? 'owly',
                    isDark: isDark,
                  ),

                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 8.h,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: KidsMagicChest(
                        onClaimed: _spawnCoins,
                        showNotification: _showModernNotification,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: KidsSmartMixWidget(isDark: isDark)),

                  KidsCategoryGrid(isDark: isDark),

                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 32.h,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: KidsWatchEarnCard(
                        showNotification: _showModernNotification,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 40.h)),
                ],
              ),
            ),
          ),

          // FLOATING QUICK MENU
          Positioned(
            bottom: 24.h,
            left: 20.w,
            right: 20.w,
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? Colors.black54 : Colors.white).withValues(
                  alpha: isDark ? 0.8 : 0.9,
                ),
                borderRadius: BorderRadius.circular(40.r),
                border: Border.all(
                  color: (isDark
                      ? Colors.white24
                      : Colors.indigo.withValues(alpha: 0.2)),
                  width: 1.5.r,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 14.h,
                      horizontal: 12.w,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavIcon(
                          context,
                          Icons.auto_stories_rounded,
                          "Album",
                          Colors.pinkAccent,
                          () => context.push('/kids-stickers'),
                        ),
                        _buildNavIcon(
                          context,
                          Icons.bedroom_child_rounded,
                          "Room",
                          Colors.purpleAccent,
                          () => context.push('/kids-room'),
                          badgeEmoji: _getMoodEmoji(user.kidsBuddyMood),
                        ),
                        _buildNavIcon(
                          context,
                          Icons.shopping_bag_rounded,
                          "Shop",
                          Colors.orangeAccent,
                          () => context.pushNamed('kids-boutique'),
                        ),
                        _buildNavIcon(
                          context,
                          Icons.face_retouching_natural_rounded,
                          "Buddies",
                          Colors.blueAccent,
                          () => context.push('/kids-mascot'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.amber,
                Colors.orange,
                Colors.yellow,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap, {
    String? badgeEmoji,
  }) {
    return ScaleButton(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24.sp),
              ),
              if (badgeEmoji != null)
                Positioned(
                  top: -4.h,
                  right: -4.w,
                  child:
                      Container(
                            padding: EdgeInsets.all(2.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: Text(
                              badgeEmoji,
                              style: TextStyle(fontSize: 12.sp),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(begin: -2, end: 2, duration: 1.seconds),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'hungry':
        return '🥺';
      case 'sleepy':
        return '😴';
      case 'bored':
        return '😒';
      case 'excited':
        return '🤩';
      case 'happy':
      default:
        return '😊';
    }
  }

  Widget _buildSlimAppBar(BuildContext context, int coins) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contrastColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Center(
        child: ScaleButton(
          onTap: () {
            // If locked to kids zone, back button acts as settings button
            if (!AgeGateService.isAdultCached) {
              context.push('/settings');
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            }
          },
          child: Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
                width: 3.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.blue.shade900 : Colors.blue.shade100,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Icon(
              // If they can't leave, show settings icon instead of back
              AgeGateService.isAdultCached
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.settings_rounded,
              color: contrastColor,
              size: 20.sp,
            ),
          ),
        ),
      ),
      actions: [
        Center(child: _buildKeyShopButton(context)),
        SizedBox(width: 8.w),
        Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: Center(child: _buildCoinBadge(context, coins, contrastColor)),
        ),
      ],
    );
  }

  Widget _buildKeyShopButton(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final keys = state.user?.keys ?? 0;

        return ScaleButton(
          onTap: () {
            KeyShopBottomSheet.show(
              context: context,
              isKidsMode: true,
              primaryColor: const Color(0xFF6366F1),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.amber.shade400,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.amber.shade700, width: 3.w),
              boxShadow: [
                BoxShadow(color: Colors.amber.shade700, offset: Offset(0, 4.h)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.key_rounded, color: Colors.white, size: 16.r),
                SizedBox(width: 6.w),
                Text(
                  keys.toString(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoinBadge(BuildContext context, int coins, Color contrastColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.amber, width: 3.w),
        boxShadow: [
          BoxShadow(color: Colors.amber.shade700, offset: Offset(0, 4.h)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 24.sp),
          SizedBox(width: 8.w),
          Text(
            coins.toString(),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w900,
              color: Colors.amber.shade700,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  void _showModernNotification(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    CustomSnackBar.show(
      context: context,
      message: message,
      type: isError ? CustomSnackBarType.error : CustomSnackBarType.success,
    );
  }
}

class _FloatingCoin extends StatefulWidget {
  final double x, y, targetX, targetY;
  final int delay;
  const _FloatingCoin({
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
    required this.delay,
  });
  @override
  State<_FloatingCoin> createState() => _FloatingCoinState();
}

class _FloatingCoinState extends State<_FloatingCoin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animX, _animY, _animScale, _animOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animX = Tween<double>(
      begin: widget.x,
      end: widget.targetX,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _animY = Tween<double>(
      begin: widget.y,
      end: widget.targetY,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInCubic));
    _animScale = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.5), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.5, end: 1.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _animOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _animX.value * 1.sw,
          top: _animY.value * 1.sh,
          child: Opacity(
            opacity: _animOpacity.value,
            child: Transform.scale(
              scale: _animScale.value,
              child: Text('🪙', style: TextStyle(fontSize: 30.sp)),
            ),
          ),
        );
      },
    );
  }
}
