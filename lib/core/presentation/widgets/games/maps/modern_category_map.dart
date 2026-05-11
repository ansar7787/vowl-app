import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:vowl/core/utils/curriculum_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  bool _showFullBackground = false; // Delayed for performance

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

    // Preload the current batch of quests
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      final unlockedLevel = user.unlockedLevels[widget.gameType] ?? 1;
      di.sl<AssetQuestService>().preloadBatch(widget.gameType, unlockedLevel);
    }

    if (mounted) {
      // Only trigger setState if data actually changed or we were still loading
      if (_totalLevels != levels || _isLoading) {
        setState(() {
          _totalLevels = levels;
          _isLoading = false;
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Delay the scroll slightly for a smoother entry animation
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
        // Delay for smooth transition
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _activeStoryBeat = beat;
            });
          }
        });
      } else if (unlockedLevel == 1) {
        // Automatic Welcome for Level 1
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _buddyMessage == null) {
            final mascotId = user.vowlMascot ?? 'vowl_prime';
            final mascotName = mascotId.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ');
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
    final int unlockedLevels =
        authState.user?.unlockedLevels[widget.gameType] ?? 1;

    final theme = LevelThemeHelper.getCategoryTheme(
      widget.categoryId,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
    final double rowSpacing = _getVerticalSpacing(theme.category);

    // Calculate height: AppBar (approx collapsed) + Padding (150.h) + (LevelIndex * spacing)
    // We target the current level to be in the middle of the screen
    final double targetY =
        64.h + // Collapsed AppBar height
        150.h + // Bottom padding of AppBar/Header in Stack
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
    final int unlockedLevels =
        authState.user?.unlockedLevels[widget.gameType] ?? 1;

    // Generate Points based on Category Design
    final List<Offset> points = _generatePoints(theme.category);
    final double rowSpacing = _getVerticalSpacing(theme.category);
    final double totalContentHeight =
        40.h + (_totalLevels * rowSpacing) + 100.h;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          prev.user?.unlockedLevels[widget.gameType] !=
          curr.user?.unlockedLevels[widget.gameType],
      listener: (context, state) {
        // Delay to allow the Map to settle after level completion sync
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

            // 2. CustomScrollView with SliverAppBar
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── SliverAppBar ──
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

                // 2. The World Portal Header (Part of the Map Journey)
                SliverToBoxAdapter(
                  child: _buildGlassMapHeader(theme, user, isDark),
                ),

                // ── The Interactive Path Content ──
                SliverToBoxAdapter(
                  child: _isLoading
                      ? _buildShimmerMap(
                          theme,
                          points,
                          rowSpacing,
                          totalContentHeight,
                        )
                      : Stack(
                          children: [
                            // The Path Line
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

                            // Interaction Nodes
                            Column(
                              children: [
                                // No spacer - direct flow from card
                                ...List.generate(_totalLevels, (index) {
                                  final levelNumber = index + 1;
                                  final isUnlocked =
                                      levelNumber <= unlockedLevels;
                                  final isCurrent =
                                      levelNumber == unlockedLevels;
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
    final amplitude = 120.w; // Consistent organic width

    for (int i = 0; i < _totalLevels; i++) {
      double offsetX;
      // Use harmonic waves for more organic flow across all categories
      final wave = math.sin(i * 0.5) * amplitude;
      final secondaryWave = math.cos(i * 0.3) * (amplitude * 0.3);
      offsetX = centerX + wave + secondaryWave;

      final y = (i * spacing) + (spacing / 2);
      points.add(Offset(offsetX, y));
    }
    return points;
  }

  Widget _buildGlassMapHeader(
    ThemeResult theme,
    UserEntity? user,
    bool isDark,
  ) {
    final gameTheme = LevelThemeHelper.getTheme(
      widget.gameType,
      isDark: isDark,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(32.r),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Floating Game Icon
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(gameTheme.icon, color: Colors.white, size: 32.r),
            ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.title.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: theme.primaryColor,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    gameTheme.title,
                    style: GoogleFonts.outfit(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Coins Mini-Pill
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.paid_rounded,
                          color: const Color(0xFF10B981),
                          size: 10.r,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          "${user?.coins ?? 0} COINS",
                          style: GoogleFonts.outfit(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
    );
  }

  Widget _buildBackground(ThemeResult theme, bool isDark) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // 1. Core Background (Theme Aware)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.backgroundColors[0], theme.backgroundColors[1]],
              ),
            ),
          ),

          // 2. Mesh alphabets - using our tinted component
          MeshGradientBackground(
            colors: [theme.primaryColor, theme.accentColor],
            auraColor: _touchAuraColor,
          ),

          if (_showFullBackground) ...[
            // 3. Category Specific Floating Icons (Optimized Count)
            ...List.generate(15, (index) {
              final random = math.Random(index + 700);
              final duration = (40 + random.nextInt(30)).seconds;

              IconData icon;
              switch (theme.category) {
                case GameCategory.reading:
                  icon = random.nextBool()
                      ? Icons.menu_book_rounded
                      : Icons.auto_stories_rounded;
                  break;
                case GameCategory.writing:
                  icon = random.nextBool()
                      ? Icons.edit_note_rounded
                      : Icons.history_edu_rounded;
                  break;
                case GameCategory.speaking:
                  icon = random.nextBool()
                      ? Icons.mic_external_on_rounded
                      : Icons.record_voice_over_rounded;
                  break;
                case GameCategory.listening:
                  icon = random.nextBool()
                      ? Icons.headset_rounded
                      : Icons.graphic_eq_rounded;
                  break;
                case GameCategory.grammar:
                  icon = random.nextBool()
                      ? Icons.architecture_rounded
                      : Icons.account_tree_rounded;
                  break;
                case GameCategory.vocabulary:
                  icon = random.nextBool()
                      ? Icons.bubble_chart_rounded
                      : Icons.category_rounded;
                  break;
                case GameCategory.eliteMastery:
                  icon = random.nextBool()
                      ? Icons.workspace_premium_rounded
                      : Icons.military_tech_rounded;
                  break;
                default:
                  icon = Icons.star_rounded;
              }

              return Positioned(
                left: random.nextDouble() * 1.sw,
                top: random.nextDouble() * 2.sh,
                child:
                    Icon(
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

            // 4. Subtle Shimmering Particles (Optimized Count)
            ...List.generate(20, (index) {
              final random = math.Random(index + 800);
              return Positioned(
                left: random.nextDouble() * 1.sw,
                top: random.nextDouble() * 2.sh,
                child:
                    Container(
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
    // Determine tier color based on level
    Color tierColor = theme.primaryColor;
    if (level >= 50 && level < 100) {
      tierColor = const Color(0xFFCD7F32); // Bronze
    }
    if (level >= 100 && level < 150) {
      tierColor = const Color(0xFFC0C0C0); // Silver
    }
    if (level >= 150) {
      tierColor = const Color(0xFFFFD700); // Gold
    }

    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    return SizedBox(
      width: 160.r,
      height:
          220.h, // Increased height to accommodate mascot safely inside bounds
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Level Node (Game Launcher)
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
                    // Re-scroll when returning to map, especially if game was failed or the user clicked "Give Up"
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
                            color: (isUnlocked ? tierColor : Colors.black)
                                .withValues(alpha: isDark ? 0.4 : 0.2),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
              top: 5.h, // Moved down to be safely within hit-test area
              child: _buildMascotMarker(context)
                  .animate()
                  .fadeIn(duration: 600.milliseconds)
                  .scale(delay: 200.milliseconds, curve: Curves.elasticOut),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerMap(
    ThemeResult theme,
    List<Offset> points,
    double rowSpacing,
    double totalHeight,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = (isDark ? Colors.white : Colors.black).withValues(
      alpha: 0.05,
    );

    return Stack(
      children: [
        // 1. Shimmering Path Line (Exact Copy)
        CustomPaint(
              size: Size(ScreenUtil().screenWidth, totalHeight),
              painter: CategoryPathPainter(
                points: points,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                category: theme.category,
                isDark: isDark,
                unlockedLevels: 0,
              ),
            )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              duration: 2.seconds,
              color: theme.primaryColor.withValues(alpha: 0.2),
            ),

        // 2. Shimmering Nodes (Exact Copy)
        Column(
          children: [
            SizedBox(height: 150.h),
            ...List.generate(_totalLevels, (index) {
              final point = points[index];
              return Container(
                height: rowSpacing,
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: Offset(point.dx - ScreenUtil().screenWidth / 2, 0),
                  child:
                      Container(
                            width: 85.r,
                            height: 85.r,
                            decoration: BoxDecoration(
                              color: baseColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white24,
                                width: 2,
                              ),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(
                            duration: 1.5.seconds,
                            color: theme.primaryColor.withValues(alpha: 0.15),
                          ),
                ),
              );
            }),
            SizedBox(height: 150.h),
          ],
        ),
      ],
    );
  }

  void _showLockedFeedback(BuildContext context, Color color) {
    HapticFeedback.vibrate();
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

    final unlockedLevels =
        context.read<AuthBloc>().state.user?.unlockedLevels[widget.gameType] ??
        1;

    return GestureDetector(
      onTap: () {
        _buddyMessageTimer?.cancel();
        final user = context.read<AuthBloc>().state.user;
        final mascotId = user?.vowlMascot ?? 'vowl_prime';
        final mascotName = mascotId.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ');
        
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
      child:
          Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_buddyMessage != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child:
                          Container(
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
                    painter: _TrianglePainter(color: theme.primaryColor),
                  ),
                ],
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -2, end: 2, duration: 2.seconds),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CategoryPathPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final GameCategory category;
  final bool isDark;
  final int unlockedLevels;

  CategoryPathPainter({
    required this.points,
    required this.color,
    required this.category,
    required this.isDark,
    required this.unlockedLevels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.3 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.r
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.r
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Start from center top to connect with the card
    path.moveTo(size.width / 2, 0);

    // Draw "Signal Pulse" at the top (Connection Point)
    // 1. Solid Category Core
    canvas.drawCircle(
      Offset(size.width / 2, 0),
      10.r,
      Paint()..color = color,
    );

    // 2. Category Signal Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.5), Colors.transparent],
      ).createShader(
        Rect.fromCircle(center: Offset(size.width / 2, 0), radius: 30.r),
      );
    canvas.drawCircle(Offset(size.width / 2, 0), 25.r, glowPaint);

    // Continue to first point and beyond
    path.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      // Organic curved path
      final controlPoint1 = Offset(p1.dx, p1.dy + (p2.dy - p1.dy) / 2);
      final controlPoint2 = Offset(p2.dx, p2.dy - (p2.dy - p1.dy) / 2);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );
    }

    // Draw the background path (locked)
    canvas.drawPath(path, paint);

    // Draw the active path (up to unlocked levels)
    final activePath = Path();
    activePath.moveTo(size.width / 2, 0);

    if (points.isNotEmpty && unlockedLevels > 0) {
      // Connect to first node
      activePath.lineTo(points[0].dx, points[0].dy);

      // Connect subsequent unlocked nodes
      for (int i = 0; i < unlockedLevels - 1; i++) {
        if (i >= points.length - 1) break;
        final p1 = points[i];
        final p2 = points[i + 1];

        final controlPoint1 = Offset(p1.dx, p1.dy + (p2.dy - p1.dy) / 2);
        final controlPoint2 = Offset(p2.dx, p2.dy - (p2.dy - p1.dy) / 2);

        activePath.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p2.dx,
          p2.dy,
        );
      }

      // Glow for active path
      canvas.drawPath(
        activePath,
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..strokeWidth = 16.r
          ..style = PaintingStyle.stroke
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.r),
      );

      canvas.drawPath(activePath, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
