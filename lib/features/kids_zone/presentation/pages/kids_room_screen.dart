import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/animated_kids_asset.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/buddy_lifecycle_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_layout.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_play_game.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_clean_activity.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_daily_care_card.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/utils/locale_service.dart';

// Decoupled sub-widgets
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_top_bar.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_action_panel.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_exit_dialog.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_decor_sheet.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_food_sheet.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_theme_sheet.dart';

class KidsRoomScreen extends StatefulWidget {
  const KidsRoomScreen({super.key});

  @override
  State<KidsRoomScreen> createState() => _KidsRoomScreenState();
}

class _KidsRoomScreenState extends State<KidsRoomScreen> {
  String _currentTheme = 'nature';
  bool _isFeeding = false;
  String _currentFood = "🍎";
  bool _isTalking = false;
  bool _isSleeping = false;
  String _buddyMessage = "";

  bool _hasPlayedToday = false;
  bool _hasCleanedToday = false;
  bool _dailyCareClaimed = false;

  Timer? _speechTimer;

  final BuddyLifecycleService _lifecycleService = const BuddyLifecycleService();

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
      {
        'id': 'forest_window',
        'name': 'Secret Forest',
        'icon': '🌲',
        'price': 1000,
      },
      {
        'id': 'undersea_window',
        'name': 'Deep Sea',
        'icon': '🌊',
        'price': 1500,
      },
    ],
    'shelf': [
      {'id': 'default_shelf', 'name': 'Wood Shelf', 'icon': '📚', 'price': 0},
      {'id': 'toy_shelf', 'name': 'Toy Rack', 'icon': '🧸', 'price': 500},
      {'id': 'magic_shelf', 'name': 'Potion Shelf', 'icon': '🧪', 'price': 800},
      {'id': 'trophy_shelf', 'name': 'Trophy Case', 'icon': '🏆', 'price': 1200},
    ],
    'toy': [
      {'id': 'default_toy', 'name': 'Toy Train', 'icon': '🚂', 'price': 0},
      {'id': 'robot_toy', 'name': 'Robot', 'icon': '🤖', 'price': 300},
      {'id': 'puzzle_toy', 'name': 'Rubik Cube', 'icon': '🧩', 'price': 400},
      {'id': 'magic_toy', 'name': 'Magic Ball', 'icon': '🔮', 'price': 600},
    ],
    'plant': [
      {'id': 'default_plant', 'name': 'Potted Fern', 'icon': '🪴', 'price': 0},
      {'id': 'flower_plant', 'name': 'Sunflower', 'icon': '🌻', 'price': 200},
      {'id': 'cactus_plant', 'name': 'Cactus', 'icon': '🌵', 'price': 250},
      {'id': 'tree_plant', 'name': 'Bonsai', 'icon': '🌳', 'price': 500},
    ],
    'rug': [
      {'id': 'default_rug', 'name': 'Blue Rug', 'icon': '🟦', 'price': 0},
      {'id': 'star_rug', 'name': 'Star Mat', 'icon': '⭐', 'price': 300},
      {'id': 'flower_rug', 'name': 'Flower Rug', 'icon': '🌸', 'price': 450},
      {'id': 'magic_rug', 'name': 'Magic Carpet', 'icon': '🧞‍♂️', 'price': 800},
    ],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyLifecycleDecay();
    });
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    super.dispose();
  }

  void _applyLifecycleDecay() {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;
    
    final newEnergy = _lifecycleService.computeDecayedEnergy(user);
    final newHunger = _lifecycleService.computeIncreasedHunger(user);
    final theme = user.kidsRoomTheme;

    setState(() {
      _currentTheme = theme;
    });

    if (newEnergy != user.kidsBuddyEnergy || newHunger != user.kidsBuddyHunger) {
      context.read<ProfileBloc>().add(
        ProfileUpdateBuddyRoomRequested(
          energy: newEnergy,
          hunger: newHunger,
        ),
      );
    }
    
    // Set initial greeting
    if (_buddyMessage.isEmpty) {
      _buddyMessage = _lifecycleService.getGreeting(user);
      _isTalking = true;
      _speechTimer?.cancel();
      _speechTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _isTalking = false);
      });
    }
  }

  void _speak(String text) {
    di.sl<TtsService>().speak(text);
    setState(() {
      _buddyMessage = text;
      _isTalking = true;
    });
    _speechTimer?.cancel();
    _speechTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isTalking = false);
    });
  }

  void _showThemeMenu(BuildContext context, UserEntity user) {
    KidsRoomThemeSheet.show(
      context,
      user: user,
      currentTheme: _currentTheme,
      onThemeSelected: (theme) {
        setState(() {
          _currentTheme = theme;
        });
        context.read<ProfileBloc>().add(
          ProfileUpdateBuddyRoomRequested(theme: theme),
        );
        di.sl<SoundService>().playClick();
        Navigator.pop(context);
        _speak("Ooh, I love this theme!");
      },
    );
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
            if (didPop) return;
            _showBackConfirmation(context, user);
          },
          child: Builder(
            builder: (context) {
              final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final bgColor = isMidnight
                  ? Colors.black
                  : (isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC));
              return Scaffold(
                backgroundColor: bgColor,
                body: KidsRoomLayout(
                  theme: _currentTheme,
                  equippedFurniture: user.kidsEquippedFurniture,
                  furnitureStore: _furnitureStore,
                  mascotWidget: _buildMascotSection(user),
                  topBarWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KidsRoomTopBar(
                        user: user,
                        onBack: () => _showBackConfirmation(context, user),
                      ),
                      if (!_dailyCareClaimed)
                        Padding(
                          padding: EdgeInsets.only(left: 16.w, top: 4.h),
                          child: KidsRoomDailyCareCard(
                            user: user,
                            hasPlayed: _hasPlayedToday,
                            hasCleaned: _hasCleanedToday,
                            onClaim: () {
                              setState(() => _dailyCareClaimed = true);
                              final newStreak = _lifecycleService.computeUpdatedStreak(user);
                              context.read<ProfileBloc>().add(
                                ProfileUpdateBuddyRoomRequested(
                                  careStreak: newStreak,
                                  lastCareDate: DateTime.now(),
                                ),
                              );
                              context.read<EconomyBloc>().add(const EconomyAddKidsCoinsRequested(25));
                              _speak("Great job! You earned 25 coins! ⭐");
                              di.sl<SoundService>().playCorrect();
                            },
                          ),
                        ),
                    ],
                  ),
                  actionPanelWidget: KidsRoomActionPanel(
                    isSleeping: _isSleeping,
                    onDecor: () => _showDecorStore(context, user),
                    onFeed: () => _showFoodMenu(context, user),
                    onPlay: () {
                      if (_isSleeping) return;
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => KidsRoomPlayGame(
                          onComplete: () {
                            Navigator.pop(context);
                            final isFirstPlay = !_hasPlayedToday;
                            setState(() => _hasPlayedToday = true);
                            // Update energy/happiness logic
                            final newEnergy = (user.kidsBuddyEnergy - 10).clamp(0, 100);
                            final newHunger = (user.kidsBuddyHunger + 5).clamp(0, 100);
                            context.read<ProfileBloc>().add(
                              ProfileUpdateBuddyRoomRequested(
                                energy: newEnergy,
                                hunger: newHunger,
                              ),
                            );
                            if (isFirstPlay) {
                              context.read<EconomyBloc>().add(const EconomyAddKidsCoinsRequested(15));
                              _speak("Yay! 15 Coins! Let's play again soon! 🎮");
                            } else {
                              _speak("That was fun! 🎮");
                            }
                          },
                        ),
                      );
                    },
                    onClean: () {
                      if (_isSleeping) return;
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => KidsRoomCleanActivity(
                          onComplete: () {
                            Navigator.pop(context);
                            final isFirstClean = !_hasCleanedToday;
                            setState(() => _hasCleanedToday = true);
                            if (isFirstClean) {
                              context.read<EconomyBloc>().add(const EconomyAddKidsCoinsRequested(10));
                              _speak("Wow! The room is so clean! 10 Coins! ✨");
                            } else {
                              _speak("Sparkling clean! ✨");
                            }
                          },
                        ),
                      );
                    },
                    onSleepToggle: () {
                      setState(() => _isSleeping = !_isSleeping);
                      _speak(
                        _isSleeping
                            ? "Goodnight! Shhh..."
                            : "I'm awake! Let's play!",
                      );
                    },
                    onTalk: () {
                      final messages = _lifecycleService.getMoodMessages(user.kidsBuddyMood);
                      _speak(messages[Random().nextInt(messages.length)]);
                    },
                    onThemeTap: () => _showThemeMenu(context, user),
                  ),
                  overlayWidget: _isSleeping ? GestureDetector(
                        onTap: () {
                          setState(() => _isSleeping = false);
                          _speak("I'm awake! Let's play!");
                        },
                        child: Container(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                          child: Stack(
                            children: [
                              ...List.generate(
                                25,
                                (i) => Positioned(
                                  top: Random().nextDouble() * 1.sh,
                                  left: Random().nextDouble() * 1.sw,
                                  child:
                                      const Text(
                                            "⭐",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.white30,
                                            ),
                                          )
                                          .animate(
                                            onPlay: (c) =>
                                                c.repeat(reverse: true),
                                          )
                                          .fadeOut(
                                            duration:
                                                (1 + Random().nextDouble() * 2)
                                                    .seconds,
                                          ),
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 200.h),
                                    Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 24.w,
                                            vertical: 12.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30.r,
                                            ),
                                            border: Border.all(
                                              color: Colors.white24,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.touch_app_rounded,
                                                color: Colors.white,
                                                size: 20.sp,
                                              ),
                                              SizedBox(width: 10.w),
                                              Text(
                                                context.tr(
                                                  'games.kids_tap_wake',
                                                  fallback: 'Tap to wake',
                                                ),
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                        .animate(
                                          onPlay: (c) =>
                                              c.repeat(reverse: true),
                                        )
                                        .scale(
                                          begin: const Offset(1, 1),
                                          end: const Offset(1.05, 1.05),
                                          duration: 1.seconds,
                                        ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 600.ms) : null,
                ),
              );
            },
          ),
        );
      },
    );
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
                child:
                    _buildGlossySticker(
                          KidsAssets.getStickerEmoji(stickerId),
                          70.r,
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(begin: -5, end: 5, duration: 2.seconds),
              ),

            GestureDetector(
              onTap: () {
                final messages = _lifecycleService.getMoodMessages(user.kidsBuddyMood);
                _speak(messages[Random().nextInt(messages.length)]);
              },
              child:
                  Stack(
                        alignment: Alignment.center,
                        children: [
                          if (user.kidsBuddyMood == 'excited' || user.kidsBuddyMood == 'happy')
                            Container(
                                  width: 150.r,
                                  height: 150.r,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withValues(
                                          alpha: user.kidsBuddyMood == 'excited' ? 0.3 : 0.1,
                                        ),
                                        blurRadius: user.kidsBuddyMood == 'excited' ? 40 : 20,
                                        spreadRadius: user.kidsBuddyMood == 'excited' ? 20 : 10,
                                      ),
                                    ],
                                  ),
                                )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(
                                  begin: const Offset(0.9, 0.9),
                                  end: const Offset(1.1, 1.1),
                                  duration: 2.seconds,
                                ),

                          if (user.kidsBuddyMood == 'excited')
                            ...List.generate(
                              5,
                              (i) => Positioned(
                                top: Random().nextDouble() * 100 - 50,
                                left: Random().nextDouble() * 100 - 50,
                                child:
                                    const Text(
                                          "✨",
                                          style: TextStyle(fontSize: 16),
                                        )
                                        .animate(onPlay: (c) => c.repeat())
                                        .scale(duration: 1.seconds)
                                        .fadeOut(),
                              ),
                            ),

                          VowlMascot(
                            size: 130.r,
                            state: _isSleeping
                                ? VowlMascotState.neutral
                                : (_isFeeding
                                      ? VowlMascotState.happy
                                      : _getMascotStateForMood(user.kidsBuddyMood)),
                            useFloatingAnimation: !_isSleeping,
                            isKidsMode: true,
                          ),
                        ],
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(
                        begin: -5,
                        end: 5,
                        duration: 2.seconds,
                        curve: Curves.easeInOutSine,
                      )
                      .animate(target: _isTalking ? 1 : 0)
                      .shake(hz: 4, curve: Curves.easeInOut)
                      .animate(target: _isFeeding ? 1 : 0)
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 200.ms,
                      ),
            ),

            if (_isSleeping)
              Positioned(
                top: -30.h,
                child:
                    Text(
                          context.tr('games.kids_zzz', fallback: 'Zzz...'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white70,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .moveY(begin: 0, end: -30, duration: 2.seconds)
                        .fadeOut(),
              ),

            if (_isFeeding)
              Positioned(
                top: -100.h,
                child: Text(_currentFood, style: TextStyle(fontSize: 45.sp))
                    .animate(key: ValueKey(_currentFood))
                    .moveY(
                      begin: -50,
                      end: 120,
                      duration: 800.ms,
                      curve: Curves.bounceOut,
                    )
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(0.5, 0.5),
                      duration: 800.ms,
                    )
                    .fadeOut(delay: 600.ms),
              ),
          ],
        ),
        SizedBox(height: 20.h),
        if (_isTalking)
          Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.lightBlue, width: 4.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.lightBlue.shade700,
                      offset: Offset(0, 6.h),
                    ),
                  ],
                ),
                child: Text(
                  _buddyMessage,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.lightBlue.shade700,
                  ),
                ),
              )
              .animate()
              .scale(curve: Curves.easeOutBack, duration: 400.ms)
              .fadeIn(),
      ],
    );
  }

  Widget _buildGlossySticker(String emoji, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: AnimatedKidsAsset(
          emoji: emoji,
          size: size * 0.7,
          animation: KidsAssetAnimation.none,
        ),
      ),
    );
  }

  void _showDecorStore(BuildContext context, UserEntity user) {
    KidsRoomDecorSheet.show(
      context,
      user: user,
      furnitureStore: _furnitureStore,
      onItemTap: (category, item) => _handleFurnitureTap(category, item, user),
    );
  }

  void _handleFurnitureTap(
    String category,
    Map<String, dynamic> item,
    UserEntity user,
  ) {
    final isOwned = user.kidsOwnedFurniture.contains(item['id']);
    if (isOwned) {
      context.read<ProfileBloc>().add(
        ProfileUpdateFurnitureRequested(category, item['id'] as String),
      );
      Navigator.pop(context);
    } else if (user.kidsCoins >= (item['price'] as int)) {
      context.read<ProfileBloc>().add(
        ProfileBuyFurnitureRequested(
          category,
          item['id'] as String,
          item['price'] as int,
        ),
      );
      _speak("New item unlocked!");
      Navigator.pop(context);
    } else {
      di.sl<SoundService>().playWrong();
      _showModernNotification(context, "NOT ENOUGH COINS! ⭐", isError: true);
    }
  }

  void _showFoodMenu(BuildContext context, UserEntity user) {
    KidsRoomFoodSheet.show(
      context,
      user: user,
      onFoodSelected: (f) {
        if (user.kidsCoins >= (f['price'] as int)) {
          context.read<EconomyBloc>().add(
            EconomyAddKidsCoinsRequested(-(f['price'] as int)),
          );
          Navigator.pop(context);
          setState(() {
            _currentFood = f['icon'] as String;
            _isFeeding = true;
          });
          di.sl<SoundService>().playCorrect();
          final newHunger = (user.kidsBuddyHunger - 20).clamp(0, 100);
          final newEnergy = (user.kidsBuddyEnergy + 10).clamp(0, 100);
          context.read<ProfileBloc>().add(
            ProfileUpdateBuddyRoomRequested(
              hunger: newHunger,
              energy: newEnergy,
              lastFeedTime: DateTime.now(),
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _isFeeding = false);
          });
        } else {
          di.sl<SoundService>().playWrong();
          Navigator.pop(context);
          _showModernNotification(
            context,
            "NOT ENOUGH COINS! ⭐",
            isError: true,
          );
        }
      },
    );
  }

  void _showBackConfirmation(BuildContext context, UserEntity user) {
    KidsRoomExitDialog.show(
      context,
      user: user,
      onExit: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );
  }

  void _showModernNotification(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.h,
        left: 20.w,
        right: 20.w,
        child: Material(
          color: Colors.transparent,
          child:
              GlassTile(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 15.h,
                    ),
                    borderRadius: BorderRadius.circular(25.r),
                    borderColor: isError
                        ? Colors.redAccent.withValues(alpha: 0.3)
                        : Colors.greenAccent.withValues(alpha: 0.3),
                    child: Row(
                      children: [
                        Icon(
                          isError
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline_rounded,
                          color: isError
                              ? Colors.redAccent
                              : Colors.greenAccent,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .slideY(begin: -1, end: 0, curve: Curves.easeOutBack)
                  .fadeIn()
                  .then(delay: 2.seconds)
                  .fadeOut()
                  .slideY(begin: 0, end: -1),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  VowlMascotState _getMascotStateForMood(String mood) {
    switch (mood) {
      case 'hungry':
        return VowlMascotState.worried;
      case 'sleepy':
        return VowlMascotState.sleeping;
      case 'bored':
        return VowlMascotState.thinking;
      case 'excited':
      case 'happy':
      default:
        return VowlMascotState.happy;
    }
  }
}
