import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/animated_kids_asset.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_background_renderer.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';

class KidsRoomScreen extends StatefulWidget {
  const KidsRoomScreen({super.key});

  @override
  State<KidsRoomScreen> createState() => _KidsRoomScreenState();
}

class _KidsRoomScreenState extends State<KidsRoomScreen> {
  String _currentTheme = 'nature';
  final List<String> _themes = ['nature', 'space', 'ocean', 'sweet'];
  bool _isFeeding = false;
  String _currentFood = "🍎";
  bool _isTalking = false;
  bool _isSleeping = false;
  String _buddyMessage = "";
  double _happiness = 0.2;
  String _weather = 'sunny'; // sunny, rainy, starry, party
  bool _hasHiddenCoin = false;
  String _coinLocation = ""; // bed or window
  bool _isCoinFound = false;

  final Map<String, Color> _themeColors = {
    'nature': const Color(0xFFF0FDF4),
    'space': const Color(0xFFF5F3FF),
    'ocean': const Color(0xFFF0F9FF),
    'sweet': const Color(0xFFFFF1F2),
  };

  final List<String> _encouragements = [
    "You are doing amazing! 🌟",
    "I love playing with you! 🎈",
    "You are getting so smart! 🧠",
    "Keep up the great work! ✨",
    "You're my best friend! 🦉",
  ];

  @override
  void initState() {
    super.initState();
    _spawnHiddenCoin();
  }

  void _spawnHiddenCoin() {
    final rand = Random();
    if (rand.nextDouble() < 0.3) { // 30% chance
      setState(() {
        _hasHiddenCoin = true;
        _coinLocation = rand.nextBool() ? "bed" : "window";
        _isCoinFound = false;
      });
    }
  }

  final Map<String, List<Map<String, dynamic>>> _furnitureStore = {
    'bed': [
      {'id': 'default_bed', 'name': 'Snuggly Bed', 'icon': '🛏️', 'price': 0},
      {'id': 'rocket_bed', 'name': 'Rocket Pod', 'icon': '🚀', 'price': 500},
      {'id': 'cloud_bed', 'name': 'Cloud Nest', 'icon': '☁️', 'price': 800},
      {'id': 'royal_bed', 'name': 'King Throne', 'icon': '👑', 'price': 1500},
    ],
    'window': [
      {'id': 'default_window', 'name': 'Sunny View', 'icon': '🪟', 'price': 0},
      {'id': 'moon_window', 'name': 'Space View', 'icon': '🌙', 'price': 1000},
      {'id': 'forest_window', 'name': 'Secret Forest', 'icon': '🌲', 'price': 1000},
      {'id': 'undersea_window', 'name': 'Deep Sea', 'icon': '🌊', 'price': 1500},
    ],
  };

  void _speak(String text) {
    di.sl<TtsService>().speak(text);
    setState(() {
      _buddyMessage = text;
      _isTalking = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isTalking = false);
    });
  }

  void _cycleTheme() {
    setState(() {
      final index = _themes.indexOf(_currentTheme);
      _currentTheme = _themes[(index + 1) % _themes.length];
      
      // Sync weather with theme for more magic
      if (_currentTheme == 'space') {
        _weather = 'starry';
      } else if (_currentTheme == 'ocean') {
        _weather = 'rainy';
      } else if (_currentTheme == 'sweet') {
        _weather = 'party';
      } else {
        _weather = 'sunny';
      }
    });
    di.sl<SoundService>().playClick();
  }

  void _addHappiness(double amount, UserEntity user) {
    if (_isSleeping) return;
    setState(() {
      _happiness = (_happiness + amount).clamp(0.0, 1.0);
      if (_happiness >= 1.0) {
        _happiness = 0.2;
        context.read<EconomyBloc>().add(const EconomyAddKidsCoinsRequested(10));
        _speak("I am so happy! You are the best! ❤️ +10 Coins");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        if (user == null) return const Scaffold();

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            _showBackConfirmation(context);
          },
          child: Builder(
            builder: (context) {
              final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final bgColor = isMidnight 
                  ? Colors.black 
                  : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));
              return Scaffold(
                backgroundColor: bgColor,
                body: Stack(
                  children: [
                    // 1. MODERN SHADER BACKGROUND (2026 STYLE)
                    _buildModernBackground(isDark: isDark),

                    // 2. LIVING WORLD: FLYING BIRDS & MICRO DECOR
                    ..._buildLivingBackgroundItems(),

                    // 3. REFINED FURNITURE LAYER
                    _buildFurnitureLayer(user),

                    // 4. MAIN CONTENT
                    SafeArea(
                      child: Column(
                        children: [
                          _buildPremiumTopBar(context, user),
                          const Spacer(),
                          _buildMascotSection(user),
                          const Spacer(),
                          _buildModernActionPanel(context, user),
                        ],
                      ),
                    ),

                    if (_isSleeping)
                      GestureDetector(
                        onTap: () {
                          setState(() => _isSleeping = false);
                          _speak("I'm awake! Let's play!");
                        },
                        child: Container(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                          child: Stack(
                            children: [
                              // STARS
                              ...List.generate(25, (i) => Positioned(
                                top: Random().nextDouble() * 1.sh,
                                left: Random().nextDouble() * 1.sw,
                                child: const Text("⭐", style: TextStyle(fontSize: 10, color: Colors.white30))
                                    .animate(onPlay: (c) => c.repeat(reverse: true))
                                    .fadeOut(duration: (1 + Random().nextDouble() * 2).seconds),
                              )),
                              // WAKE UP PROMPT
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 200.h), // Offset to not cover mascot face too much
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(30.r),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.touch_app_rounded, color: Colors.white, size: 20.sp),
                                          SizedBox(width: 10.w),
                                          Text("TAP TO WAKE UP ☀️", 
                                            style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                                        ],
                                      ),
                                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                                     .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.seconds),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 600.ms),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildModernBackground({required bool isDark}) {
    String painterName = 'SunnyMeadow';
    if (_weather == 'rainy') {
      painterName = 'OceanWave';
    } else if (_weather == 'starry') {
      painterName = 'StarryNight';
    } else if (_weather == 'party') {
      painterName = 'CandyCloud';
    }

    return Stack(
      children: [
        // Shader Base
        Positioned.fill(
          child: KidsBackgroundRenderer(
            painterName: painterName,
            gameType: 'room',
            shaderName: _weather == 'starry' ? 'star_field' : 'magic_twinkle',
            primaryColor: _themeColors[_currentTheme]!,
          ),
        ),
        
        // Weather Overlays
        if (_weather == 'rainy')
          ...List.generate(15, (i) => Positioned(
            top: -20,
            left: Random().nextDouble() * 1.sw,
            child: const Text("💧", style: TextStyle(fontSize: 10, color: Colors.blue))
                .animate(onPlay: (c) => c.repeat())
                .moveY(begin: -50, end: 1.sh + 50, duration: (1 + Random().nextDouble()).seconds)
                .fadeOut(),
          )),
          
        if (_weather == 'party')
          ...List.generate(15, (i) => Positioned(
            top: -20,
            left: Random().nextDouble() * 1.sw,
            child: Text("🎊", style: TextStyle(fontSize: 14.sp))
                .animate(onPlay: (c) => c.repeat())
                .moveY(begin: -50, end: 1.sh + 50, duration: (2 + Random().nextDouble()).seconds)
                .rotate(begin: 0, end: 2, duration: 1.seconds),
          )),

        // Magic Theme Sparkle transition
        Positioned.fill(
          child: IgnorePointer(
            child: const Text("✨", style: TextStyle(fontSize: 20))
                .animate(key: ValueKey(_currentTheme))
                .scale(begin: const Offset(0, 0), end: const Offset(5, 5), duration: 600.ms)
                .fadeOut(duration: 600.ms),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildLivingBackgroundItems() {
    return [
      _buildMicroEmoji('✨', 50.h, 40.w),
      _buildMicroEmoji('🎈', 200.h, 300.w),
      _buildMicroEmoji('🌈', 400.h, 20.w),
      
      // FLYING BIRDS
      _buildFlyingBird(120.h, 3.seconds),
      _buildFlyingBird(250.h, 5.seconds, isSlow: true),
    ];
  }

  Widget _buildFlyingBird(double top, Duration delay, {bool isSlow = false}) {
    return Positioned(
      top: top,
      left: -50.w,
      child: Text("🕊️", style: TextStyle(fontSize: 20.sp, color: Colors.black.withValues(alpha: 0.15)))
          .animate(onPlay: (c) => c.repeat())
          .moveX(begin: -50, end: 1.sw + 50, duration: (isSlow ? 12 : 8).seconds, delay: delay)
          .moveY(begin: 0, end: 20, duration: 2.seconds, curve: Curves.easeInOutSine)
          .scale(begin: const Offset(1, 1), end: const Offset(0.8, 0.8), duration: 2.seconds),
    );
  }

  Widget _buildMicroEmoji(String emoji, double top, double left) {
    return Positioned(
      top: top,
      left: left,
      child: Text(emoji, style: TextStyle(fontSize: 18.sp, color: Colors.black.withValues(alpha: 0.1)))
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -20, duration: 3.seconds, curve: Curves.easeInOutSine)
          .fadeOut(begin: 0.2),
    );
  }

  Widget _buildPremiumTopBar(BuildContext context, UserEntity user) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Column(
        children: [
          Row(
            children: [
              ScaleButton(
                onTap: () => _showBackConfirmation(context),
                child: GlassTile(
                  padding: EdgeInsets.all(10.r),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                    size: 18.sp,
                  ),
                ),
              ),
              const Spacer(),
              _buildTopStatusCapsule(user),
              const Spacer(),
              _buildCurrencyBadge(user),
            ],
          ),
          SizedBox(height: 12.h),
          _buildCompactLoveMeter(),
        ],
      ),
    );
  }

  Widget _buildTopStatusCapsule(UserEntity user) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      borderRadius: BorderRadius.circular(20.r),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("🦉", style: TextStyle(fontSize: 16.sp)),
          SizedBox(width: 8.w),
          Text(
            "BUDDY ROOM",
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyBadge(UserEntity user) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      borderRadius: BorderRadius.circular(20.r),
      child: Row(
        children: [
          Icon(Icons.directions_car_filled_rounded, color: const Color(0xFFEF4444), size: 16.sp),
          SizedBox(width: 8.w),
          Text(
            "${user.kidsCoins}",
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLoveMeter() {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      borderRadius: BorderRadius.circular(30.r),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("❤️", style: TextStyle(fontSize: 14.sp))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
          SizedBox(width: 8.w),
          Stack(
            children: [
              Container(
                width: 100.w,
                height: 6.h,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              AnimatedContainer(
                duration: 500.ms,
                width: 100.w * _happiness,
                height: 6.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFB7185), Color(0xFFE11D48)]),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [BoxShadow(color: const Color(0xFFE11D48).withValues(alpha: 0.3), blurRadius: 4)],
                ),
              ),
            ],
          ),
          SizedBox(width: 6.w),
          Text("${(_happiness * 100).toInt()}%", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: const Color(0xFFE11D48))),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildFurnitureLayer(UserEntity user) {
    final equipped = user.kidsEquippedFurniture;
    final bedId = equipped['bed'] ?? 'default_bed';
    final windowId = equipped['window'] ?? 'default_window';

    return Stack(
      children: [
        Positioned(
          top: 180.h,
          left: 30.w,
          child: _buildFurnitureItem("window", windowId, 90.r, user), 
        ),
        Positioned(
          bottom: 120.h,
          right: 40.w,
          child: _buildFurnitureItem("bed", bedId, 120.r, user),
        ),
      ],
    );
  }

  Widget _buildFurnitureItem(String category, String id, double size, UserEntity user) {
    String emoji = '🏠';
    for (var cat in _furnitureStore.values) {
      for (var item in cat) {
        if (item['id'] == id) emoji = item['icon'];
      }
    }

    final isHidingCoin = _hasHiddenCoin && _coinLocation == category && !_isCoinFound;

    return ScaleButton(
      onTap: () {
        if (isHidingCoin) {
          _collectHiddenCoin(user);
        } else {
          di.sl<SoundService>().playClick();
        }
      },
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // THE COIN (HIDDEN BEHIND)
          if (isHidingCoin)
            Positioned(
              top: -10,
              child: Icon(Icons.directions_car_filled_rounded, color: Colors.redAccent, size: 24.sp)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.seconds)
                  .shimmer(),
            ),

          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)],
            ),
            child: Center(
              child: Text(emoji, style: TextStyle(fontSize: size * 0.45)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  void _collectHiddenCoin(UserEntity user) {
    setState(() => _isCoinFound = true);
    di.sl<SoundService>().playCorrect();
    Haptics.vibrate(HapticsType.success);
    
    context.read<EconomyBloc>().add(const EconomyAddKidsCoinsRequested(15));
    _speak("WOW! You found a hidden treasure! 🚗💎");
    
    _showModernNotification(context, "FOUND 15 KIDS COINS! 🚗✨");
  }

  Widget _buildMascotSection(UserEntity user) {
    final stickerId = user.kidsEquippedSticker;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (stickerId != null)
              Positioned(
                top: -80.h,
                left: -60.w,
                child: _buildGlossySticker(KidsAssets.getStickerEmoji(stickerId), 70.r)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: -5, end: 5, duration: 2.seconds),
              ),

            GestureDetector(
              onTap: () {
                _speak(_encouragements[Random().nextInt(_encouragements.length)]);
                _addHappiness(0.01, user); // 1% per tap
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // HAPPINESS GLOW / AURA
                  if (_happiness > 0.5)
                    Container(
                      width: 150.r,
                      height: 150.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: (_happiness - 0.5) * 0.5),
                            blurRadius: 40 * _happiness,
                            spreadRadius: 20 * _happiness,
                          ),
                        ],
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2.seconds),

                  // SPARKLES FOR HIGH HAPPINESS
                  if (_happiness > 0.8)
                    ...List.generate(5, (i) => Positioned(
                      top: Random().nextDouble() * 100 - 50,
                      left: Random().nextDouble() * 100 - 50,
                      child: const Text("✨", style: TextStyle(fontSize: 16))
                          .animate(onPlay: (c) => c.repeat())
                          .scale(duration: 1.seconds)
                          .fadeOut(),
                    )),

                  VowlMascot(
                    size: 130.r,
                    state: _isSleeping 
                        ? VowlMascotState.neutral 
                        : (_isFeeding || _happiness > 0.8 
                            ? VowlMascotState.happy 
                            : VowlMascotState.neutral),
                    useFloatingAnimation: !_isSleeping,
                  ),
                ],
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOutSine)
               .animate(target: _isTalking ? 1 : 0)
               .shake(hz: 4, curve: Curves.easeInOut)
               .animate(target: _isFeeding ? 1 : 0)
               .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 200.ms),
            ),

            if (_isSleeping)
              Positioned(
                top: -30.h,
                child: Text("Zzz...", style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 18.sp, fontWeight: FontWeight.bold))
                    .animate(onPlay: (c) => c.repeat())
                    .moveY(begin: 0, end: -30, duration: 2.seconds)
                    .fadeOut(),
              ),

            if (_isFeeding)
              Positioned(
                top: -100.h,
                child: Text(_currentFood, style: TextStyle(fontSize: 45.sp))
                    .animate(key: ValueKey(_currentFood))
                    .moveY(begin: -50, end: 120, duration: 800.ms, curve: Curves.bounceOut)
                    .scale(begin: const Offset(1, 1), end: const Offset(0.5, 0.5), duration: 800.ms)
                    .fadeOut(delay: 600.ms),
              ),
          ],
        ),
        if (_currentTheme == 'space')
           Positioned.fill(
             child: IgnorePointer(
               child: const Text("✨", style: TextStyle(fontSize: 10))
                   .animate(onPlay: (c) => c.repeat())
                   .moveX(begin: 0, end: 1.sw, duration: 5.seconds)
                   .moveY(begin: 0, end: 1.sh, duration: 3.seconds),
             ),
           ),
        SizedBox(height: 20.h),
        if (_isTalking)
          GlassTile(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            borderRadius: BorderRadius.circular(15.r),
            child: Text(
              _buddyMessage,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
              ),
            ),
          ).animate().scale().fadeIn(),
      ],
    );
  }

  Widget _buildGlossySticker(String emoji, double size, {KidsAssetAnimation animation = KidsAssetAnimation.none}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Center(
        child: AnimatedKidsAsset(emoji: emoji, size: size * 0.7, animation: animation),
      ),
    );
  }

  Widget _buildModernActionPanel(BuildContext context, UserEntity user) {
    return Container(
      margin: EdgeInsets.all(20.r),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)],
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildModernActionButton("Decor", Icons.palette_rounded, Colors.indigo, () => _showDecorStore(context, user)),
          _buildModernActionButton("Feed", Icons.restaurant_rounded, Colors.pink, () => _showFoodMenu(context, user)),
          _buildModernActionButton(_isSleeping ? "Wake" : "Sleep", _isSleeping ? Icons.wb_sunny_rounded : Icons.bedtime_rounded, Colors.amber, () {
            setState(() => _isSleeping = !_isSleeping);
            _speak(_isSleeping ? "Goodnight! Shhh..." : "I'm awake! Let's play!");
          }),
          _buildModernActionButton("Talk", Icons.chat_bubble_rounded, Colors.lightBlue, () {
            _speak(_encouragements[Random().nextInt(_encouragements.length)]);
            _addHappiness(0.02, user); // 2% per talk
          }),
          _buildModernActionButton("Theme", Icons.auto_awesome_rounded, Colors.teal, _cycleTheme),
        ],
      ),
    );
  }

  Widget _buildModernActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ScaleButton(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  void _showDecorStore(BuildContext context, UserEntity user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassTile(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        child: Container(
          padding: EdgeInsets.all(24.r),
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("DECORATE ROOM", style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w900)),
                const TabBar(tabs: [Tab(text: "BEDS"), Tab(text: "WINDOWS")], labelColor: Colors.black87, indicatorColor: Colors.black87),
                SizedBox(
                  height: 250.h,
                  child: TabBarView(
                    children: [
                      _buildStoreGrid('bed', user),
                      _buildStoreGrid('window', user),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreGrid(String category, UserEntity user) {
    final items = _furnitureStore[category]!;
    return GridView.builder(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.5, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isOwned = user.kidsOwnedFurniture.contains(item['id']);
        final isEquipped = user.kidsEquippedFurniture[category] == item['id'];
        return ScaleButton(
          onTap: () => _handleFurnitureTap(category, item, isOwned, user),
          child: Container(
            decoration: BoxDecoration(
              color: isEquipped ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: isEquipped ? Colors.black26 : Colors.transparent),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item['icon'], style: TextStyle(fontSize: 24.sp)),
                Text(item['name'], style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.bold)),
                 if (!isOwned) Row(mainAxisSize: MainAxisSize.min, children: [
                  Text("${item['price']} ", style: GoogleFonts.outfit(fontSize: 9.sp, fontWeight: FontWeight.w900, color: Colors.black54)),
                  Icon(Icons.directions_car_filled_rounded, size: 9.sp, color: const Color(0xFFEF4444)),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleFurnitureTap(String category, Map<String, dynamic> item, bool isOwned, UserEntity user) {
    if (isOwned) {
      context.read<ProfileBloc>().add(ProfileUpdateFurnitureRequested(category, item['id'] as String));
      Navigator.pop(context);
    } else if (user.kidsCoins >= item['price']) {
      context.read<ProfileBloc>().add(ProfileBuyFurnitureRequested(category, item['id'] as String, item['price'] as int));
      _speak("New item unlocked!");
      Navigator.pop(context);
    } else {
      di.sl<SoundService>().playWrong();
      _showModernNotification(context, "NOT ENOUGH COINS! 🚗", isError: true);
    }
  }

  void _showFoodMenu(BuildContext context, UserEntity user) {
    final food = [
      {'name': 'Apple', 'icon': '🍎', 'price': 0, 'happiness': 0.02},
      {'name': 'Cake', 'icon': '🍰', 'price': 50, 'happiness': 0.05},
      {'name': 'Golden Berry', 'icon': '🫐', 'price': 200, 'happiness': 0.10},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassTile(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        child: Container(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("YUMMY TREATS", style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w900)),
              SizedBox(height: 20.h),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: food.map((f) => _buildFoodItem(f, user)).toList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> f, UserEntity user) {
    return ScaleButton(
      onTap: () {
        if (user.kidsCoins >= f['price']) {
          context.read<EconomyBloc>().add(EconomyAddKidsCoinsRequested(-(f['price'] as int)));
          Navigator.pop(context);
          setState(() {
            _currentFood = f['icon'];
            _isFeeding = true;
          });
          di.sl<SoundService>().playCorrect();
          _addHappiness(f['happiness'] as double, user);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _isFeeding = false);
          });
        } else {
          di.sl<SoundService>().playWrong();
          Navigator.pop(context);
          _showModernNotification(context, "NOT ENOUGH COINS! 🚗", isError: true);
        }
      },
      child: Column(
        children: [
          Container(padding: EdgeInsets.all(12.r), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle), child: Text(f['icon'], style: TextStyle(fontSize: 30.sp))),
          Text(f['name'], style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.bold)),
          if (f['price'] > 0) Row(mainAxisSize: MainAxisSize.min, children: [
            Text("${f['price']} ", style: GoogleFonts.outfit(fontSize: 9.sp, fontWeight: FontWeight.w900, color: Colors.black54)),
            Icon(Icons.directions_car_filled_rounded, size: 9.sp, color: const Color(0xFFEF4444)),
          ]),
        ],
      ),
    );
  }

  void _showBackConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 280.w,
            child: GlassTile(
              padding: EdgeInsets.all(20.r),
              borderRadius: BorderRadius.circular(25.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("LEAVING SO SOON?", style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 1)),
                  SizedBox(height: 10.h),
                  Text("Your buddy will miss you! Stay a bit longer to earn more coins? ❤️", 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 11.sp, color: Colors.black45, fontWeight: FontWeight.w600)),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: ScaleButton(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15.r)),
                            child: Center(child: Text("STAY", style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.black54))),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ScaleButton(
                          onTap: () {
                            Navigator.pop(context); // Close dialog
                            Navigator.pop(context); // Exit room
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFFB7185), Color(0xFFE11D48)]),
                              borderRadius: BorderRadius.circular(15.r),
                              boxShadow: [BoxShadow(color: const Color(0xFFE11D48).withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Center(child: Text("EXIT", style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms).fadeIn(),
          ),
        ),
      ),
    );
  }

  void _showModernNotification(BuildContext context, String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.h,
        left: 20.w,
        right: 20.w,
        child: Material(
          color: Colors.transparent,
          child: GlassTile(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
            borderRadius: BorderRadius.circular(25.r),
            borderColor: isError ? Colors.redAccent.withValues(alpha: 0.3) : Colors.greenAccent.withValues(alpha: 0.3),
            child: Row(
              children: [
                Icon(isError ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, 
                     color: isError ? Colors.redAccent : Colors.greenAccent, size: 24.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(message, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w800, color: Colors.black87)),
                ),
              ],
            ),
          ).animate().slideY(begin: -1, end: 0, curve: Curves.easeOutBack).fadeIn().then(delay: 2.seconds).fadeOut().slideY(begin: 0, end: -1),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }
}
