import 'dart:math';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/animated_kids_asset.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
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
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';

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
  final ValueNotifier<String> _currentTheme = ValueNotifier('nature');
  final ValueNotifier<String> _currentFood = ValueNotifier('');

  final ValueNotifier<bool> _isInitializing = ValueNotifier(true);

  // ---------------------------------------------------------------------------
  // State: Animations & Flow
  final ValueNotifier<bool> _isFeeding = ValueNotifier(false);
  final ValueNotifier<bool> _isTalking = ValueNotifier(false);
  final ValueNotifier<bool> _isSleeping = ValueNotifier(false);
  final ValueNotifier<String> _buddyMessage = ValueNotifier("");

  final ValueNotifier<bool> _hasCleanedToday = ValueNotifier(false);
  final ValueNotifier<bool> _dailyCareClaimed = ValueNotifier(false);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);

  Timer? _speechTimer;

  final BuddyLifecycleService _lifecycleService = const BuddyLifecycleService();

  // Pre-computed star positions for sleeping overlay (seeded to avoid teleporting on rebuild)
  late final List<Offset> _sleepStarPositions = List.generate(25, (i) {
    final r = Random(i * 42 + 7);
    return Offset(r.nextDouble(), r.nextDouble());
  });

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
      {
        'id': 'trophy_shelf',
        'name': 'Trophy Case',
        'icon': '🏆',
        'price': 1200,
      },
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
      {
        'id': 'magic_rug',
        'name': 'Magic Carpet',
        'icon': '🧞‍♂️',
        'price': 800,
      },
    ],
  };

  @override
  void initState() {
    super.initState();

    // Defer heavy database writes and disk I/O until the route transition finishes (400ms)
    // to ensure a buttery smooth 120fps entry animation.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _loadLocalState();
        _applyLifecycleDecay();
        _isInitializing.value = false;
      }
    });
  }

  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final lastClean = prefs.getString('kids_last_clean_date');
    if (lastClean != null) {
      final date = DateTime.parse(lastClean);
      final now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        _hasCleanedToday.value = true;
      }
    }
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    _currentTheme.dispose();
    _currentFood.dispose();
    _isInitializing.dispose();
    _isFeeding.dispose();
    _isTalking.dispose();
    _isSleeping.dispose();
    _buddyMessage.dispose();
    _hasCleanedToday.dispose();
    _dailyCareClaimed.dispose();
    _showConfetti.dispose();
    super.dispose();
  }

  void _applyLifecycleDecay() {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    final newEnergy = _lifecycleService.computeDecayedEnergy(user);
    final newHunger = _lifecycleService.computeIncreasedHunger(user);

    // Compute the new mood using the updated energy and hunger
    final tempUser = user.copyWith(
      kidsBuddyEnergy: newEnergy,
      kidsBuddyHunger: newHunger,
    );
    final newMood = _lifecycleService.computeMood(tempUser);

    final theme = user.kidsRoomTheme;

    _currentTheme.value = theme;

    if (newEnergy != user.kidsBuddyEnergy ||
        newHunger != user.kidsBuddyHunger ||
        newMood != user.kidsBuddyMood) {
      context.read<ProfileBloc>().add(
        ProfileUpdateBuddyRoomRequested(
          energy: newEnergy,
          hunger: newHunger,
          mood: newMood,
        ),
      );
    }

    // Set initial greeting
    if (_buddyMessage.value.isEmpty) {
      _buddyMessage.value = _lifecycleService.getGreeting(user);
      _isTalking.value = true;
      _speechTimer?.cancel();
      _speechTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) _isTalking.value = false;
      });
    }
  }

  void _speak(String text) {
    di.sl<TtsService>().speak(text);
        _buddyMessage.value = text;
    _isTalking.value = true;
    _speechTimer?.cancel();
    _speechTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _isTalking.value = false;
    });
  }

  void _triggerConfetti() {
    _showConfetti.value = true;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _showConfetti.value = false;
    });
  }

  void _showThemeMenu(BuildContext context, UserEntity user) {
    KidsRoomThemeSheet.show(
      context,
      user: user,
      currentTheme: _currentTheme.value,
      onThemeSelected: (theme) {
                _currentTheme.value = theme;
        context.read<ProfileBloc>().add(
          ProfileUpdateBuddyRoomRequested(theme: theme),
        );
        di.sl<SoundService>().playClick();
        Navigator.pop(context);
        final themeMessages = {
          'nature': [
            "Wow, it smells like pine trees!",
            "Let's play hide and seek in the bushes!",
            "I love the forest!",
            "Look, a butterfly!",
            "This is the perfect place for a picnic!",
            "It feels so breezy and nice here.",
            "I can hear the birds singing to us!",
            "Let's build a little treehouse!",
            "The leaves are so green and pretty!",
            "I feel like a little forest explorer!",
          ],
          'space': [
            "Whoa, we are floating in space!",
            "Look at all those shiny stars!",
            "Zero gravity is so bouncy!",
            "Are there aliens out here? Hello?",
            "To the moon, best friend!",
            "I feel like a real astronaut now!",
            "Can we ride a comet?",
            "The galaxy is so huge and sparkly!",
            "Ground control, we are ready to play!",
            "Look, a shooting star! Make a wish!",
          ],
          'ocean': [
            "Splish splash! Time to swim!",
            "Under the sea is the best place to be!",
            "Look at those funny little bubbles!",
            "Do you think we'll see a dolphin?",
            "I feel like a happy little fish!",
            "The water is so blue and wavy!",
            "Let's look for hidden pirate treasure!",
            "I love swimming around with you!",
            "Glub glub! That's fish talk for hello!",
            "It's a beautiful day at the bottom of the sea!",
          ],
          'sweet': [
            "Yummy! The clouds look like cotton candy!",
            "Everything is so pink and sweet!",
            "I want to take a tiny bite out of the wall!",
            "This room makes me so happy and giggly!",
            "It's like a giant candy land!",
            "I love sugar and sprinkles!",
            "Can we build a castle out of chocolate?",
            "It smells like warm cookies in here!",
            "This is the yummiest room ever!",
            "Welcome to our sweet little bakery!",
          ],
        };
        final messages =
            themeMessages[theme] ??
            [
              "Ooh, I love this theme!",
              "This looks amazing!",
              "Wow, so pretty!",
            ];
        _speak(messages[Random().nextInt(messages.length)]);
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
              final now = DateTime.now();
              final isGameToday =
                  user.kidsLastGameDate != null &&
                  user.kidsLastGameDate!.year == now.year &&
                  user.kidsLastGameDate!.month == now.month &&
                  user.kidsLastGameDate!.day == now.day;
              final hasPlayedToday =
                  isGameToday && user.kidsGamesPlayedToday > 0;

              return ListenableBuilder(
                listenable: Listenable.merge([
                  _currentTheme, _currentFood, _isInitializing, _isFeeding, _isTalking,
                  _isSleeping, _buddyMessage, _hasCleanedToday, _dailyCareClaimed, _showConfetti
                ]),
                builder: (context, _) {
                  return Scaffold(
                    backgroundColor: bgColor,
                    body: Stack(
                  children: [
                    KidsRoomLayout(
                      theme: _currentTheme.value,
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
                          Padding(
                            padding: EdgeInsets.only(left: 16.w, top: 4.h),
                            child: KidsRoomDailyCareCard(
                              user: user,
                              hasPlayed: hasPlayedToday,
                              hasCleaned: _hasCleanedToday.value,
                              isClaimed: _dailyCareClaimed.value || _hasClaimedToday(user),
                              onClaim: () {
                                  _dailyCareClaimed.value = true;
                                  final newStreak = _lifecycleService
                                      .computeUpdatedStreak(user);
                                  context.read<ProfileBloc>().add(
                                    ProfileUpdateBuddyRoomRequested(
                                      careStreak: newStreak,
                                      lastCareDate: DateTime.now(),
                                    ),
                                  );
                                  context.read<EconomyBloc>().add(
                                    const EconomyAddKidsCoinsRequested(25),
                                  );
                                  _speak(
                                    "Great job! You earned 25 Kids Coins! 🪙",
                                  );
                                  _triggerConfetti();
                                  di.sl<SoundService>().playCorrect();
                                },
                              ),
                            ),
                        ],
                      ),
                      actionPanelWidget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeroNameplate(user),
                          SizedBox(height: 12.h),
                          KidsRoomActionPanel(
                            isSleeping: _isSleeping.value,
                            gamesPlayedToday: isGameToday ? user.kidsGamesPlayedToday : 0,
                        onDecor: () => _showDecorStore(context, user),
                        onFeed: () => _showFoodMenu(context, user),
                        onPlay: () {
                          if (_isSleeping.value) return;

                          final playedCount = isGameToday
                              ? user.kidsGamesPlayedToday
                              : 0;

                          if (playedCount >= 3) {
                            _speak(
                              "I'm tired of playing today. Come back tomorrow! 😴",
                            );
                            di.sl<SoundService>().playClick();
                            return;
                          }

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => KidsRoomPlayGame(
                              onComplete: (score) {
                                Navigator.pop(context);

                                // Update energy/happiness logic & daily game limit
                                final newEnergy = (user.kidsBuddyEnergy - 10)
                                    .clamp(0, 100);
                                final newHunger = (user.kidsBuddyHunger + 5)
                                    .clamp(0, 100);

                                final tempUser = user.copyWith(
                                  kidsBuddyEnergy: newEnergy,
                                  kidsBuddyHunger: newHunger,
                                );
                                final newMood = _lifecycleService.computeMood(
                                  tempUser,
                                );

                                context.read<ProfileBloc>().add(
                                  ProfileUpdateBuddyRoomRequested(
                                    energy: newEnergy,
                                    hunger: newHunger,
                                    mood: newMood,
                                    gamesPlayedToday: playedCount + 1,
                                    lastGameDate: DateTime.now(),
                                  ),
                                );

                                if (score > 0) {
                                  context.read<EconomyBloc>().add(
                                    EconomyAddKidsCoinsRequested(score),
                                  );
                                  _speak("Yay! You got $score Kids Coins! 🪙");
                                  _triggerConfetti();
                                } else {
                                  _speak("That was fun! Let's try again! 🎮");
                                }
                              },
                            ),
                          );
                        },
                        onClean: () {
                          if (_isSleeping.value) return;
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => KidsRoomCleanActivity(
                              onComplete: () {
                                Navigator.pop(context);
                                final isFirstClean =
                                    !_hasCleanedToday.value &&
                                    !_hasClaimedToday(user);
                                _hasCleanedToday.value = true;
                                SharedPreferences.getInstance().then((prefs) {
                                  prefs.setString(
                                    'kids_last_clean_date',
                                    DateTime.now().toIso8601String(),
                                  );
                                });
                                if (isFirstClean) {
                                  context.read<EconomyBloc>().add(
                                    const EconomyAddKidsCoinsRequested(10),
                                  );
                                  _speak(
                                    "Wow! The room is so clean! 10 Kids Coins! 🪙",
                                  );
                                  _triggerConfetti();
                                } else {
                                  _speak("Sparkling clean! ✨");
                                }
                              },
                            ),
                          );
                        },
                        onSleepToggle: () {
                          _isSleeping.value = !_isSleeping.value;
                          _speak(
                            _isSleeping.value
                                ? "Goodnight! Shhh..."
                                : "I'm awake! Let's play!",
                          );
                        },
                        onTalk: () {
                          final messages = _lifecycleService.getMoodMessages(
                            user.kidsBuddyMood,
                          );
                          _speak(messages[Random().nextInt(messages.length)]);
                        },
                        onThemeTap: () => _showThemeMenu(context, user),
                      ),
                    ],
                  ),
                      overlayWidget: (_isSleeping.value || _showConfetti.value)
                          ? Stack(
                              children: [
                                if (_isSleeping.value)
                                  GestureDetector(
                                    onTap: () {
                                      _isSleeping.value = false;
                                      _speak("I'm awake! Let's play!");
                                    },
                                    child: Container(
                                      color: const Color(
                                        0xFF0F172A,
                                      ).withValues(alpha: 0.6),
                                      child: Stack(
                                        children: [
                                          ...List.generate(
                                            25,
                                            (i) => Positioned(
                                              top: _sleepStarPositions[i].dy * 1.sh,
                                              left:
                                                  _sleepStarPositions[i].dx * 1.sw,
                                              child:
                                                  const Text(
                                                        "⭐",
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.white30,
                                                        ),
                                                      )
                                                      .animate(
                                                        onPlay: (c) => c.repeat(
                                                          reverse: true,
                                                        ),
                                                      )
                                                      .fadeOut(
                                                        duration:
                                                            (1 +
                                                                    Random().nextDouble() *
                                                                        2)
                                                                .seconds,
                                                      ),
                                            ),
                                          ),
                                          Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SizedBox(height: 200.h),
                                                Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 24.w,
                                                            vertical: 12.h,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30.r,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.white24,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .touch_app_rounded,
                                                            color: Colors.white,
                                                            size: 20.sp,
                                                          ),
                                                          SizedBox(width: 10.w),
                                                          Text(
                                                            context.tr(
                                                              'games.kids_tap_wake',
                                                              fallback:
                                                                  'Tap to wake',
                                                            ),
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Outfit',
                                                              fontSize: 12.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                              color:
                                                                  Colors.white,
                                                              letterSpacing: 1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                    .animate(
                                                      onPlay: (c) => c.repeat(
                                                        reverse: true,
                                                      ),
                                                    )
                                                    .scale(
                                                      begin: const Offset(1, 1),
                                                      end: const Offset(
                                                        1.05,
                                                        1.05,
                                                      ),
                                                      duration: 1.seconds,
                                                    ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ).animate().fadeIn(duration: 600.ms),

                                if (_showConfetti.value)
                                  const Positioned.fill(
                                    child: IgnorePointer(child: GameConfetti()),
                                  ),
                              ],
                            )
                          : null,
                    ),
                    // Premium Shimmer Overlay
                    IgnorePointer(
                      ignoring: !_isInitializing.value,
                      child: AnimatedOpacity(
                        opacity: _isInitializing.value ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        child: _buildShimmerScreen(bgColor),
                      ),
                    ),
                  ],
                ),
              );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmerScreen(Color bgColor) {
    return Container(
      color: bgColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShimmerLoading.circular(width: 120.r, height: 120.r),
            SizedBox(height: 32.h),
            ShimmerLoading.rounded(
              width: 180.w,
              height: 24.h,
              borderRadius: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMascotSection(UserEntity user) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isTalking.value)
          Padding(
            padding: EdgeInsets.only(bottom: 20.h),
            child:
                ClipRRect(
                      borderRadius: BorderRadius.circular(24.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 24.w),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 14.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(24.r),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 2.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.6),
                                blurRadius: 10,
                                spreadRadius: -2,
                                offset: const Offset(0, -2), // Inner top glow
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                offset: Offset(0, 6.h),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                          child: Text(
                            _buddyMessage.value,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .scale(curve: Curves.easeOutBack, duration: 400.ms)
                    .fadeIn(),
          ),
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () {
                final messages = _lifecycleService.getMoodMessages(
                  user.kidsBuddyMood,
                );
                _speak(messages[Random().nextInt(messages.length)]);
              },
              child:
                  SizedBox(
                        width: 180.r,
                        height: 180.r,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            if (user.kidsBuddyMood == 'excited' ||
                                user.kidsBuddyMood == 'happy')
                              Container(
                                    width: 150.r,
                                    height: 150.r,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.amber.withValues(
                                            alpha:
                                                user.kidsBuddyMood == 'excited'
                                                ? 0.3
                                                : 0.1,
                                          ),
                                          blurRadius:
                                              user.kidsBuddyMood == 'excited'
                                              ? 40
                                              : 20,
                                          spreadRadius:
                                              user.kidsBuddyMood == 'excited'
                                              ? 20
                                              : 10,
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate(
                                    onPlay: (c) => c.repeat(reverse: true),
                                  )
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

                            // The Theme-Specific Nest underneath the mascot
                            Positioned(
                              bottom: -5.h,
                              child: _buildThemeNest(user.kidsRoomTheme),
                            ),

                            VowlMascot(
                              size: 85.r,
                              state: _isSleeping.value
                                  ? VowlMascotState.neutral
                                  : (_isFeeding.value
                                        ? VowlMascotState.happy
                                        : _getMascotStateForMood(
                                            user.kidsBuddyMood,
                                          )),
                              useFloatingAnimation: !_isSleeping.value,
                              isKidsMode: true,
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(
                        begin: -5,
                        end: 5,
                        duration: 2.seconds,
                        curve: Curves.easeInOutSine,
                      )
                      .animate(target: _isTalking.value ? 1 : 0)
                      .shake(hz: 4, curve: Curves.easeInOut)
                      .animate(target: _isFeeding.value ? 1 : 0)
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 200.ms,
                      ),
            ),

            if (_isSleeping.value)
              Positioned(
                top: -60.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                      bottomRight: Radius.circular(20.r),
                      bottomLeft: Radius.circular(4.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("☁️", style: TextStyle(fontSize: 18.sp)),
                      SizedBox(width: 8.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dreaming about...",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black45,
                            ),
                          ),
                          Text(
                            "Tomorrow's Adventure! 🚀",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -10, duration: 3.seconds, curve: Curves.easeInOutSine),
              ),

            if (_isFeeding.value)
              Positioned(
                top: -100.h,
                child: Text(_currentFood.value, style: TextStyle(fontSize: 45.sp))
                    .animate(key: ValueKey(_currentFood.value))
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
      ],
    );
  }

  Widget _buildHeroNameplate(UserEntity user) {
    final stickerId = user.kidsEquippedSticker;
    final buddyName = user.kidsMascot == 'foxie' ? 'FOXIE' : user.kidsMascot == 'dino' ? 'DINO' : 'OWLY';
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            buddyName,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          if (stickerId != null) ...[
            SizedBox(width: 8.w),
            Container(
              width: 26.r,
              height: 26.r,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Center(
                child: AnimatedKidsAsset(
                  emoji: KidsAssets.getStickerEmoji(stickerId),
                  size: 16.r,
                  animation: KidsAssetAnimation.none,
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: -1, end: 1, duration: 1.5.seconds),
          ],
        ],
      ),
    );
  }


  Widget _buildThemeNest(String theme) {
    switch (theme) {
      case 'space':
        // Glowing anti-gravity neon ring
        return Container(
              width: 140.r,
              height: 35.r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.elliptical(70.r, 17.5.r)),
                border: Border.all(color: Colors.cyanAccent, width: 3.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.6),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1.05, 1.05),
              duration: 1.5.seconds,
            );
      case 'ocean':
        // Glowing coral/bubble pad
        return Container(
          width: 150.r,
          height: 45.r,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.elliptical(75.r, 22.5.r)),
            gradient: RadialGradient(
              colors: [
                Colors.lightBlueAccent.withValues(alpha: 0.8),
                Colors.blue.withValues(alpha: 0.2),
              ],
            ),
          ),
          child: Center(
            child: Text("🫧", style: TextStyle(fontSize: 24.sp)),
          ),
        );
      case 'sweet':
        // Pink cotton candy cloud
        return Container(
              width: 160.r,
              height: 55.r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.elliptical(80.r, 27.5.r)),
                color: Colors.pinkAccent.withValues(alpha: 0.3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "☁️",
                  style: TextStyle(
                    fontSize: 40.sp,
                    color: Colors.pink.withValues(alpha: 0.8),
                  ),
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: -3, end: 3, duration: 2.seconds);
      case 'nature':
      default:
        // Leafy wooden nest
        return Container(
          width: 150.r,
          height: 45.r,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.elliptical(75.r, 22.5.r)),
            color: Colors.brown.shade700.withValues(alpha: 0.8),
            border: Border.all(color: Colors.green.shade600, width: 4.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("🌿", style: TextStyle(fontSize: 16.sp)),
                Text("🍃", style: TextStyle(fontSize: 16.sp)),
              ],
            ),
          ),
        );
    }
  }

  void _showDecorStore(BuildContext context, UserEntity user) {
    KidsRoomDecorSheet.show(
      context,
      user: user,
      furnitureStore: _furnitureStore,
      onItemTap: (category, item) => _handleFurnitureTap(category, item, user),
    );
  }

  bool _hasClaimedToday(UserEntity user) {
    if (user.kidsLastCareDate == null) return false;
    final now = DateTime.now();
    return user.kidsLastCareDate!.year == now.year &&
        user.kidsLastCareDate!.month == now.month &&
        user.kidsLastCareDate!.day == now.day;
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
      _showModernNotification(context, context.tr('kids_zone.not_enough_coins_hint', fallback: 'Keep playing to earn more coins! 🎮'), isError: true);
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
                    _currentFood.value = f['icon'] as String;
          _isFeeding.value = true;
          di.sl<SoundService>().playCorrect();
          final newHunger = (user.kidsBuddyHunger - 20).clamp(0, 100);
          final newEnergy = (user.kidsBuddyEnergy + 10).clamp(0, 100);

          final tempUser = user.copyWith(
            kidsBuddyEnergy: newEnergy,
            kidsBuddyHunger: newHunger,
          );
          final newMood = _lifecycleService.computeMood(tempUser);

          context.read<ProfileBloc>().add(
            ProfileUpdateBuddyRoomRequested(
              hunger: newHunger,
              energy: newEnergy,
              mood: newMood,
              lastFeedTime: DateTime.now(),
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _isFeeding.value = false;
          });
        } else {
          di.sl<SoundService>().playWrong();
          Navigator.pop(context);
          _showModernNotification(
            context,
            context.tr('kids_zone.not_enough_coins_hint', fallback: 'Keep playing to earn more coins! 🎮'),
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
    CustomSnackBar.show(
      context: context,
      message: message,
      type: isError ? CustomSnackBarType.error : CustomSnackBarType.success,
    );
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
