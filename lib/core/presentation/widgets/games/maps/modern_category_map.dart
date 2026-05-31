import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vowl/core/utils/curriculum_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/story_service.dart';
import 'package:vowl/core/presentation/widgets/story_dialogue_box.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/data/services/asset_quest_service.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/tts_service.dart';

// Decoupled modular imports
import 'package:vowl/core/presentation/painters/category_path_painter.dart';
import 'package:vowl/core/presentation/widgets/games/maps/components/glass_map_header.dart';
import 'package:vowl/core/presentation/widgets/games/maps/components/shimmer_map_placeholder.dart';

/// A premium, highly-performant quest category selection map.
/// 
/// Incorporates organic paths, mesh gradient backgrounds, interactive mascot triggers,
/// and automated local data preloading.
class ModernCategoryMap extends StatefulWidget {
  final String gameType;
  final String categoryId;

  const ModernCategoryMap({
    super.key,
    required this.gameType,
    required this.categoryId,
  });

  @override
  State<ModernCategoryMap> createState() => _ModernCategoryMapState();
}

class _ModernCategoryMapState extends State<ModernCategoryMap> {
  Color? _touchAuraColor;
  Timer? _auraTimer;
  String? _buddyMessage;
  Timer? _buddyMessageTimer;
  late ScrollController _scrollController;
  StoryBeat? _activeStoryBeat;
  int _totalLevels = 10;
  bool _isLoading = true;
  bool _showFullBackground = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // 1. Check Cache Synchronously for Instant Load
    final cachedLevels = CurriculumService.getCachedLevels(widget.gameType);
    if (cachedLevels != null) {
      _totalLevels = cachedLevels;
      _isLoading = false;
    }

    _loadCurriculum();

    // 2. Delay background icons to ensure smooth page transition
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showFullBackground = true);
      }
    });
  }

  Future<void> _loadCurriculum() async {
    final levels = await CurriculumService.getTotalLevels(widget.gameType);
    if (!mounted) return;

    // Preload current quest batch
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      final unlockedLevel = user.unlockedLevels[widget.gameType] ?? 1;
      di.sl<AssetQuestService>().preloadBatch(widget.gameType, unlockedLevel);
    }

    if (mounted) {
      if (_totalLevels != levels || _isLoading) {
        setState(() {
          _totalLevels = levels;
          _isLoading = false;
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _scrollToCurrentLevel(animate: true);
          }
        });
        _checkAndShowStoryBeat();
      });
    }
  }

  void _checkAndShowStoryBeat() {
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      final unlockedLevel = user.unlockedLevels[widget.gameType] ?? 1;
      final beat = di.sl<StoryService>().getStoryBeat(
        widget.gameType,
        unlockedLevel,
      );
      if (beat != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _activeStoryBeat = beat;
            });
          }
        });
      } else if (unlockedLevel == 1) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _buddyMessage == null) {
            final mascotId = user.vowlMascot ?? 'vowl_prime';
            final mascotName = mascotId.isNotEmpty
                ? mascotId.split('_').map((e) => e.isNotEmpty ? e[0].toUpperCase() + e.substring(1) : '').join(' ')
                : 'Companion';
            setState(() {
              _buddyMessage = "Hey! $mascotName here. Let's start Level 1! 🚀";
            });
            _buddyMessageTimer = Timer(const Duration(seconds: 5), () {
              if (mounted) setState(() => _buddyMessage = null);
            });
          }
        });
      }
    }
  }

  void _scrollToCurrentLevel({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final authState = context.read<AuthBloc>().state;
    final int unlockedLevels = authState.user?.unlockedLevels[widget.gameType] ?? 1;

    final theme = LevelThemeHelper.getCategoryTheme(
      widget.categoryId,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
    final double rowSpacing = _getVerticalSpacing(theme.category);

    final double targetY =
        64.h +
        150.h +
        ((unlockedLevels - 1) * rowSpacing) +
        (rowSpacing / 2) -
        (ScreenUtil().screenHeight / 2);

    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double safeTargetY = targetY.clamp(0.0, maxScroll);

    if (animate) {
      _scrollController.animateTo(
        safeTargetY,
        duration: 1200.milliseconds,
        curve: Curves.easeInOutCubic,
      );
    } else {
      _scrollController.jumpTo(safeTargetY);
    }
  }

  @override
  void dispose() {
    _auraTimer?.cancel();
    _buddyMessageTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getCategoryTheme(
      widget.categoryId,
      isDark: isDark,
    );
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;
    final int unlockedLevels = authState.user?.unlockedLevels[widget.gameType] ?? 1;

    final List<Offset> points = _generatePoints(theme.category);
    final double rowSpacing = _getVerticalSpacing(theme.category);
    final double totalContentHeight = 40.h + (_totalLevels * rowSpacing) + 100.h;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          prev.user?.unlockedLevels[widget.gameType] !=
          curr.user?.unlockedLevels[widget.gameType],
      listener: (context, state) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _scrollToCurrentLevel(animate: true);
          }
        });
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
        child: Scaffold(
          backgroundColor: theme.backgroundColors[1],
          extendBody: true,
          body: Stack(
            children: [
              // 1. Clean Minimal Static Background
              _buildBackground(theme, isDark),

              // Touch Listener for Engagement
              GestureDetector(
                onTapDown: (details) {
                  _auraTimer?.cancel();
                  setState(() {
                    _touchAuraColor = theme.primaryColor;
                  });
                  _auraTimer = Timer(const Duration(milliseconds: 1500), () {
                    if (mounted) {
                      setState(() => _touchAuraColor = null);
                    }
                  });
                },
                child: Container(color: Colors.transparent),
              ),

              // 2. Scrollable Map Core
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // SliverAppBar Back Pill
                  SliverAppBar(
                    pinned: false,
                    floating: false,
                    snap: false,
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    toolbarHeight: 50.h,
                    title: Align(
                      alignment: Alignment.centerLeft,
                      child: ScaleButton(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        child: Container(
                          width: 36.r,
                          height: 36.r,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: const Color(0xFF0F172A),
                            size: 16.r,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Header Panel Widget
                  SliverToBoxAdapter(
                    child: GlassMapHeader(
                      theme: theme,
                      user: user,
                      isDark: isDark,
                      gameType: widget.gameType,
                    ),
                  ),

                  // Track View
                  SliverToBoxAdapter(
                    child: _isLoading
                        ? ShimmerMapPlaceholder(
                            theme: theme,
                            points: points,
                            rowSpacing: rowSpacing,
                            totalHeight: totalContentHeight,
                            totalLevels: _totalLevels,
                          )
                        : Stack(
                            children: [
                              // Decoupled Path Line Graphics
                              CustomPaint(
                                size: Size(
                                  ScreenUtil().screenWidth,
                                  totalContentHeight,
                                ),
                                painter: CategoryPathPainter(
                                  points: points,
                                  color: theme.primaryColor,
                                  category: theme.category,
                                  isDark: isDark,
                                  unlockedLevels: unlockedLevels,
                                ),
                              ),

                              // Interactive Stage Nodes
                              Column(
                                children: [
                                  ...List.generate(_totalLevels, (index) {
                                    final levelNumber = index + 1;
                                    final isUnlocked = levelNumber <= unlockedLevels;
                                    final isCurrent = levelNumber == unlockedLevels;
                                    final point = points[index];

                                    return Container(
                                      height: rowSpacing,
                                      alignment: Alignment.center,
                                      child: Transform.translate(
                                        offset: Offset(
                                          point.dx - ScreenUtil().screenWidth / 2,
                                          0,
                                        ),
                                        child: _buildPathNode(
                                          context,
                                          levelNumber,
                                          isUnlocked,
                                          isCurrent,
                                          isDark,
                                          theme,
                                        ),
                                      ),
                                    );
                                  }),
                                  SizedBox(height: 150.h),
                                ],
                              ),
                            ],
                          ),
                  ),
                ],
              ),

              if (_activeStoryBeat != null)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: StoryDialogueBox(
                      beat: _activeStoryBeat!,
                      onDismiss: () {
                        setState(() {
                          _activeStoryBeat = null;
                        });
                      },
                    ),
                  ).animate().fadeIn(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _getVerticalSpacing(GameCategory category) {
    switch (category) {
      case GameCategory.vocabulary:
        return 160.h;
      case GameCategory.grammar:
        return 180.h;
      case GameCategory.listening:
        return 150.h;
      case GameCategory.speaking:
        return 200.h;
      case GameCategory.reading:
        return 190.h;
      case GameCategory.writing:
        return 200.h;
      case GameCategory.accent:
        return 170.h;
      case GameCategory.roleplay:
        return 210.h;
      case GameCategory.eliteMastery:
        return 220.h;
    }
  }

  List<Offset> _generatePoints(GameCategory category) {
    final List<Offset> points = [];
    final centerX = ScreenUtil().screenWidth / 2;
    final spacing = _getVerticalSpacing(category);
    final amplitude = 120.w;

    for (int i = 0; i < _totalLevels; i++) {
      final wave = math.sin(i * 0.5) * amplitude;
      final secondaryWave = math.cos(i * 0.3) * (amplitude * 0.3);
      final offsetX = centerX + wave + secondaryWave;
      final y = (i * spacing) + (spacing / 2);
      points.add(Offset(offsetX, y));
    }
    return points;
  }

  Widget _buildBackground(ThemeResult theme, bool isDark) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // 1. Core Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.backgroundColors[0], theme.backgroundColors[1]],
              ),
            ),
          ),

          // 2. Interactive Mesh Alpha Gradient
          MeshGradientBackground(
            colors: [theme.primaryColor, theme.accentColor],
            auraColor: _touchAuraColor,
          ),

          if (_showFullBackground) ...[
            // 3. Floating Icons
            ...List.generate(15, (index) {
              final random = math.Random(index + 700);
              final duration = (40 + random.nextInt(30)).seconds;

              IconData icon;
              switch (theme.category) {
                case GameCategory.reading:
                  icon = random.nextBool() ? Icons.menu_book_rounded : Icons.auto_stories_rounded;
                  break;
                case GameCategory.writing:
                  icon = random.nextBool() ? Icons.edit_note_rounded : Icons.history_edu_rounded;
                  break;
                case GameCategory.speaking:
                  icon = random.nextBool() ? Icons.mic_external_on_rounded : Icons.record_voice_over_rounded;
                  break;
                case GameCategory.listening:
                  icon = random.nextBool() ? Icons.headset_rounded : Icons.graphic_eq_rounded;
                  break;
                case GameCategory.grammar:
                  icon = random.nextBool() ? Icons.architecture_rounded : Icons.account_tree_rounded;
                  break;
                case GameCategory.vocabulary:
                  icon = random.nextBool() ? Icons.bubble_chart_rounded : Icons.category_rounded;
                  break;
                case GameCategory.eliteMastery:
                  icon = random.nextBool() ? Icons.workspace_premium_rounded : Icons.military_tech_rounded;
                  break;
                default:
                  icon = Icons.star_rounded;
              }

              return Positioned(
                left: random.nextDouble() * 1.sw,
                top: random.nextDouble() * 2.sh,
                child: Icon(
                  icon,
                  size: (12 + random.nextInt(18)).r,
                  color: theme.primaryColor.withValues(
                    alpha: isDark ? 0.20 : 0.12,
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .moveY(
                  begin: 1.1.sh,
                  end: -100.h,
                  duration: duration,
                  curve: Curves.linear,
                ),
              );
            }),

            // 4. Shimmering Particles
            ...List.generate(20, (index) {
              final random = math.Random(index + 800);
              return Positioned(
                left: random.nextDouble() * 1.sw,
                top: random.nextDouble() * 2.sh,
                child: Container(
                  width: 3.r,
                  height: 3.r,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeOut(
                  duration: (1 + random.nextDouble() * 2).seconds,
                  curve: Curves.easeInOut,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPathNode(
    BuildContext context,
    int level,
    bool isUnlocked,
    bool isCurrent,
    bool isDark,
    ThemeResult theme,
  ) {
    Color tierColor = theme.primaryColor;
    if (level >= 50 && level < 100) {
      tierColor = const Color(0xFFCD7F32);
    }
    if (level >= 100 && level < 150) {
      tierColor = const Color(0xFFC0C0C0);
    }
    if (level >= 150) {
      tierColor = const Color(0xFFFFD700);
    }

    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    return SizedBox(
      width: 160.r,
      height: 220.h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ScaleButton(
            onTap: () {
              if (!isUnlocked) {
                _showLockedFeedback(context, theme.primaryColor);
                return;
              }

              di.sl<AdService>().showInterstitialAd(
                isPremium: isPremium,
                isLevelCompletion: false,
                onDismissed: () async {
                  if (context.mounted) {
                    await context.push(
                      '/game?category=${theme.category.name}&gameType=${widget.gameType}&level=$level',
                    );
                    if (mounted) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          _scrollToCurrentLevel(animate: true);
                        }
                      });
                    }
                  }
                },
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: isCurrent ? 100.r : 85.r,
                  height: isCurrent ? 100.r : 85.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isUnlocked
                          ? [Colors.white, const Color(0xFFF1F5F9)]
                          : [Colors.grey.shade400, Colors.grey.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isUnlocked ? tierColor : Colors.black).withValues(alpha: isDark ? 0.4 : 0.2),
                        offset: Offset(0, 8.h),
                        blurRadius: 15.r,
                      ),
                    ],
                    border: Border.all(
                      color: isUnlocked ? tierColor : Colors.white24,
                      width: isCurrent ? 4.r : 3.r,
                    ),
                  ),
                  child: Container(
                    margin: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: Center(
                      child: isUnlocked
                          ? Padding(
                              padding: EdgeInsets.all(4.r),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "LEVEL",
                                      style: GoogleFonts.outfit(
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.w900,
                                        color: tierColor,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    Text(
                                      "$level",
                                      style: GoogleFonts.outfit(
                                        fontSize: (isCurrent ? 32 : 26).sp,
                                        fontWeight: FontWeight.w900,
                                        color: tierColor,
                                        height: 0.9,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black38,
                                            offset: Offset(0, 2.h),
                                            blurRadius: 4.r,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Icon(
                              Icons.lock_rounded,
                              size: 32.r,
                              color: Colors.white54,
                            ),
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                  begin: isCurrent ? -6.r : -3.r,
                  end: isCurrent ? 6.r : 3.r,
                  duration: (isCurrent ? 1.2 : 2.0).seconds,
                  curve: Curves.easeInOut,
                ),

                Positioned(
                  top: isCurrent ? 12.r : 10.r,
                  left: isCurrent ? 12.r : 10.r,
                  child: Container(
                    width: isCurrent ? 40.r : 35.r,
                    height: isCurrent ? 18.r : 15.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.5),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isCurrent)
            Positioned(
              top: 5.h,
              child: _buildMascotMarker(context)
                  .animate()
                  .fadeIn(duration: 600.milliseconds)
                  .scale(delay: 200.milliseconds, curve: Curves.elasticOut),
            ),
        ],
      ),
    );
  }

  void _showLockedFeedback(BuildContext context, Color color) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'MASTER PREVIOUS LEVELS TO UNLOCK',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 12.sp,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.r),
        ),
        margin: EdgeInsets.all(20.r),
        duration: 2.seconds,
      ),
    );
  }

  Widget _buildMascotMarker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(widget.gameType, isDark: isDark);

    final unlockedLevels = context.read<AuthBloc>().state.user?.unlockedLevels[widget.gameType] ?? 1;

    return GestureDetector(
      onTap: () {
        _buddyMessageTimer?.cancel();
        final user = context.read<AuthBloc>().state.user;
        final mascotId = user?.vowlMascot ?? 'vowl_prime';
        final mascotName = mascotId.isNotEmpty
            ? mascotId.split('_').map((e) => e.isNotEmpty ? e[0].toUpperCase() + e.substring(1) : '').join(' ')
            : 'Companion';
        
        final messages = [
          "Level $unlockedLevels! You're unstoppable, Superstar! ⭐",
          "Level $unlockedLevels! $mascotName is impressed! 🚀",
          "Level $unlockedLevels! Pure linguistic magic! ✨",
          "Level $unlockedLevels! Absolute genius energy! 🧠",
          "Level $unlockedLevels! You rock this stage! 🎸",
          "Level $unlockedLevels! We're winning big! 🏆",
          "Level $unlockedLevels! Boom! Perfect progress! 💥",
          "Level $unlockedLevels! $mascotName says: You're so smart! 🦉",
          "Level $unlockedLevels! Keep that momentum! 🏃‍♂️",
          "Level $unlockedLevels! Wow! Simply breathtaking! 🎈",
        ];
        final message = messages[math.Random().nextInt(messages.length)];
        setState(() {
          _buddyMessage = message;
          _touchAuraColor = theme.primaryColor;
        });

        final cleanMessage = message
            .replaceAll(
              RegExp(
                r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2B50}]',
                unicode: true,
              ),
              '',
            )
            .trim();
        di.sl<TtsService>().speak(cleanMessage);

        HapticFeedback.lightImpact();
        _buddyMessageTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _buddyMessage = null);
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_buddyMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(15.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.r,
                      offset: Offset(0, 5.h),
                    ),
                  ],
                ),
                child: Text(
                  _buddyMessage!,
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ).animate().scale(
                curve: Curves.elasticOut,
                duration: 500.ms,
              ),
            ),
          VowlMascot(
            size: 55.r,
            useFloatingAnimation: true,
          ).animate().scale(curve: Curves.elasticOut, duration: 500.ms),
          CustomPaint(
            size: Size(12.w, 8.h),
            painter: TrianglePainter(color: theme.primaryColor),
          ),
        ],
      )
      .animate(onPlay: (c) => c.repeat(reverse: true))
      .moveY(begin: -2, end: 2, duration: 2.seconds),
    );
  }
}
