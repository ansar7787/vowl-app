import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_magic_chest.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_watch_earn_card.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_category_grid.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_zone_home_header.dart';
import 'package:vowl/core/theme/theme_cubit.dart';

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
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
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
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

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
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + 10.h)),
                  
                  _buildSlimAppBar(context, user.kidsCoins),

                  KidsZoneHomeHeader(
                    mascot: user.kidsMascot ?? 'owly',
                    isDark: isDark,
                  ),

                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                    sliver: SliverToBoxAdapter(
                      child: KidsMagicChest(
                        onClaimed: _spawnCoins,
                        showNotification: _showModernNotification,
                      ),
                    ),
                  ),

                  KidsCategoryGrid(isDark: isDark),

                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                    sliver: SliverToBoxAdapter(
                      child: KidsWatchEarnCard(showNotification: _showModernNotification),
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
                color: (isDark ? Colors.black54 : Colors.white).withValues(alpha: isDark ? 0.8 : 0.9),
                borderRadius: BorderRadius.circular(40.r),
                border: Border.all(color: (isDark ? Colors.white24 : Colors.indigo.withValues(alpha: 0.2)), width: 1.5.r),
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
                    padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
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
              colors: const [Colors.amber, Colors.orange, Colors.yellow, Colors.white],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return ScaleButton(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlimAppBar(BuildContext context, int coins) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contrastColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final buttonBgColor = isDark ? Colors.white10 : Colors.indigo.withValues(alpha: 0.08);

    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Center(
        child: ScaleButton(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: buttonBgColor,
              shape: BoxShape.circle,
              border: Border.all(color: contrastColor.withValues(alpha: 0.1)),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: contrastColor, size: 20.sp),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: Center(child: _buildCoinBadge(context, coins, contrastColor)),
        ),
      ],
    );
  }

  Widget _buildCoinBadge(BuildContext context, int coins, Color contrastColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: contrastColor.withValues(alpha: isDark ? 0.1 : 0.2)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Text('🚗', style: TextStyle(fontSize: 20.sp)),
          SizedBox(width: 8.w),
          Text(
            coins.toString(),
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              color: contrastColor,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  void _showModernNotification(BuildContext context, String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Center(
          child: GlassTile(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
            borderRadius: BorderRadius.circular(25.r),
            borderColor: isError ? Colors.redAccent.withValues(alpha: 0.3) : Colors.greenAccent.withValues(alpha: 0.3),
            child: Row(
              children: [
                Icon(isError ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                    color: isError ? Colors.redAccent : Colors.greenAccent, size: 24.sp),
                SizedBox(width: 15.w),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingCoin extends StatefulWidget {
  final double x, y, targetX, targetY;
  final int delay;
  const _FloatingCoin({required this.x, required this.y, required this.targetX, required this.targetY, required this.delay});
  @override
  State<_FloatingCoin> createState() => _FloatingCoinState();
}

class _FloatingCoinState extends State<_FloatingCoin> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animX, _animY, _animScale, _animOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _animX = Tween<double>(begin: widget.x, end: widget.targetX).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _animY = Tween<double>(begin: widget.y, end: widget.targetY).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInCubic));
    _animScale = TweenSequence([TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.5), weight: 30), TweenSequenceItem(tween: Tween<double>(begin: 1.5, end: 1.0), weight: 70)])
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _animOpacity = TweenSequence([TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20), TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 60), TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 20)])
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _controller.forward(); });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _animX.value * 1.sw,
          top: _animY.value * 1.sh,
          child: Opacity(opacity: _animOpacity.value, child: Transform.scale(scale: _animScale.value, child: Text('🚗', style: TextStyle(fontSize: 30.sp)))),
        );
      },
    );
  }
}
