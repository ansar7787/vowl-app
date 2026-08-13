import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/games/modern_path_painter.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/locale_service.dart';

class ModernPathGameMap extends StatelessWidget {
  final String gameType;
  final String categoryId;
  final int totalLevels;

  const ModernPathGameMap({
    super.key,
    required this.gameType,
    required this.categoryId,
    this.totalLevels = 200,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(gameType);
    // PERF FIX: was `context.watch<AuthBloc>().state`, which rebuilds this
    // entire screen - including all `totalLevels` (up to 200) node widgets
    // constructed eagerly below - on *any* AuthState change, even ones
    // unrelated to this screen (coins, XP, etc.). The sibling
    // ModernCategoryMap screen already documents and applies this exact
    // fix for the exact same reason; this screen had the same gap.
    // context.select narrows rebuilds to only fire when the `user`
    // reference itself changes.
    final user = context.select<AuthBloc, UserEntity?>(
      (bloc) => bloc.state.user,
    );

    // Fallback logic for unlocked levels
    final int unlockedLevels = user?.unlockedLevels[gameType] ?? 1;

    final List<Offset> points = [];
    for (int i = 0; i < totalLevels; i++) {
      final levelNumber = i + 1;
      // Generate a curvy layout similar to the image
      // Alternating left/right snake pattern
      final horizontalOffset = (math.sin(levelNumber * 1.5) * 80.w);
      final verticalPosition = 120.h + (i * 140.h);
      points.add(
        Offset(
          ScreenUtil().screenWidth / 2 + horizontalOffset,
          verticalPosition,
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, theme, isDark),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Stack(
              children: [
                // Dynamic Background Layer - GPU Isolated
                RepaintBoundary(
                  child: _buildBackground(context, theme, totalLevels),
                ),
                // The Curvy Path - GPU Isolated
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size(
                      ScreenUtil().screenWidth,
                      120.h + (totalLevels * 140.h) + 100.h,
                    ),
                    painter: ModernPathPainter(
                      points: points,
                      color: theme.primaryColor.withValues(alpha: 0.2),
                      thickness: 8.w,
                    ),
                  ),
                ),

                // Interaction Nodes
                //
                // PERFORMANCE NOTE: all `totalLevels` (default 200) nodes
                // are still built eagerly here rather than lazily — the
                // connecting curvy path is one continuous CustomPaint
                // computed from every point up front, which doesn't lend
                // itself to simple sliver-based lazy loading without a
                // deeper rendering rework (a custom RenderSliver that only
                // paints visible path segments). That's a real, valuable
                // follow-up for very low-end devices, but is too large a
                // structural change to make blind in this pass without the
                // ability to visually test it. What *is* safely fixed here:
                // each node now gets its own RepaintBoundary, and only the
                // few elements that actually animate continuously (the
                // current-level pulse ring, the floating mascot) are
                // isolated into their own boundary — so animating those no
                // longer has to walk/repaint the other ~199 static nodes.
                Column(
                  children: [
                    SizedBox(height: 120.h),
                    ...List.generate(totalLevels, (index) {
                      final levelNumber = index + 1;
                      final isUnlocked = levelNumber <= unlockedLevels;
                      final isCurrent = levelNumber == unlockedLevels;
                      final horizontalOffset =
                          (math.sin(levelNumber * 1.5) * 80.w);

                      return Center(
                        child: Transform.translate(
                          offset: Offset(horizontalOffset, 0),
                          child: RepaintBoundary(
                            child: _buildPathNode(
                              context,
                              levelNumber,
                              isUnlocked,
                              isCurrent,
                              isDark,
                              theme,
                              user,
                            ),
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
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeResult theme,
    bool isDark,
  ) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return AppBar(
      title: Text(
        theme.title,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w900,
          fontSize: 14.sp,
          letterSpacing: 4,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: Semantics(
        button: true,
        label: context.tr('common.back', fallback: 'Back'),
        child: IconButton(
          icon: Icon(
            isRtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
            size: 28.r,
          ),
          onPressed: () => context.pop(),
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildBackground(
    BuildContext context,
    ThemeResult theme,
    int totalLevels,
  ) {
    final segmentHeight = (totalLevels * 140.h) / 4;
    return Stack(
      children: [
        // Dividing the map into 4 environments
        Column(
          children: [
            _buildEnvSection(
              context,
              Colors.green,
              'games.env_emerald_forest',
              'EMERALD FOREST',
              segmentHeight,
            ),
            _buildEnvSection(
              context,
              Colors.blue,
              'games.env_azure_peaks',
              'AZURE PEAKS',
              segmentHeight,
            ),
            _buildEnvSection(
              context,
              Colors.orange,
              'games.env_sunset_plateau',
              'SUNSET PLATEAU',
              segmentHeight,
            ),
            _buildEnvSection(
              context,
              Colors.amber,
              'games.env_celestial_citadel',
              'CELESTIAL CITADEL',
              segmentHeight,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnvSection(
    BuildContext context,
    Color color,
    String nameKey,
    String fallbackName,
    double height,
  ) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -20.w,
            top: 50.h,
            child: ExcludeSemantics(
              child: Text(
                context.tr(nameKey, fallback: fallbackName),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 60.sp,
                  fontWeight: FontWeight.w900,
                  color: color.withValues(alpha: 0.03),
                ),
                maxLines: 1,
              ),
            ),
          ),
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
    UserEntity? user,
  ) {
    final statusLabel = !isUnlocked
        ? context.tr('games.level_locked', fallback: 'Locked')
        : (isCurrent
              ? context.tr('games.level_current', fallback: 'Current level')
              : context.tr('games.level_completed', fallback: 'Completed'));

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // "Today's Topic" Tooltip for current level
          if (isCurrent)
            Positioned(
              top: -85.h,
              child: _buildTopicTooltip(context, theme, isDark),
            ),



          // Floating Vowl Mascot near the current level
          if (isCurrent)
            PositionedDirectional(
              start: -80.w,
              child: RepaintBoundary(
                child: ExcludeSemantics(
                  child:
                      VowlMascot(
                            state: VowlMascotState.happy,
                            size: 80,
                            level: user?.level ?? 1,
                            accessoryId: user?.vowlEquippedAccessory,
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(
                            begin: -5,
                            end: 5,
                            duration: 2.seconds,
                            curve: Curves.easeInOut,
                          )
                          .rotate(begin: -0.05, end: 0.05, duration: 4.seconds),
                ),
              ),
            ),

          // The Glass Node
          Semantics(
            button: true,
            label:
                '${context.tr('games.level_label_short', args: [level.toString()], fallback: 'Level $level')}, $statusLabel',
            child: ScaleButton(
              onTap: () async {
                if (!isUnlocked) {
                  _showLockedFeedback(context, theme.primaryColor);
                  return;
                }
                final authState = context.read<AuthBloc>().state;
                di.sl<AdService>().showInterstitialAd(
                  onDismissed: () {
                    if (context.mounted) {
                      context.push(
                        '/game?category=${Uri.encodeQueryComponent(categoryId)}&gameType=${Uri.encodeQueryComponent(gameType)}&level=$level',
                      );
                    }
                  },
                  isPremium: authState.user?.isPremium ?? false,
                );
              },
              child: ExcludeSemantics(
                child: Container(
                  width: isCurrent ? 100.r : 80.r,
                  height: isCurrent ? 100.r : 80.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnlocked
                        ? (isCurrent
                              ? theme.primaryColor
                              : theme.primaryColor.withValues(alpha: 0.15))
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03)),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.5),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                    border: Border.all(
                      color: isCurrent
                          ? Colors.white
                          : (isUnlocked
                                ? theme.primaryColor.withValues(alpha: 0.3)
                                : Colors.transparent),
                      width: isCurrent ? 4 : 2,
                    ),
                  ),
                  child: Center(
                    child: isUnlocked
                        ? (isCurrent
                              ? Icon(
                                  theme.icon,
                                  color: Colors.white,
                                  size: 38.r,
                                )
                              : Text(
                                  "$level",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ))
                        : Icon(
                            Icons.lock_outline_rounded,
                            color: isDark ? Colors.white24 : Colors.black12,
                            size: 24.r,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicTooltip(
    BuildContext context,
    ThemeResult theme,
    bool isDark,
  ) {
    return ExcludeSemantics(
      child:
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('games.todays_topic', fallback: "TODAY'S TOPIC"),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  theme.title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ).animate().move(
            begin: const Offset(0, 5),
            end: const Offset(0, 0),
            duration: 600.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }

  void _showLockedFeedback(BuildContext context, Color color) {
    HapticFeedback.mediumImpact();
    CustomSnackBar.show(
      context: context,
      message: context.tr(
        'games.quest_locked_message',
        fallback: 'QUEST LOCKED! COMPLETE PREVIOUS LEVELS.',
      ),
      type: CustomSnackBarType.info,
    );
  }
}
