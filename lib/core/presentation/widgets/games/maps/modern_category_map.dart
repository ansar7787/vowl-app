import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:voxai_quest/core/presentation/widgets/glass_tile.dart';
import 'package:voxai_quest/core/presentation/utils/voxin_assets.dart';
import 'package:voxai_quest/core/presentation/widgets/ad_banner_widget.dart';

class ModernCategoryMap extends StatefulWidget {
  final String gameType;
  final String categoryId;
  final int totalLevels;

  const ModernCategoryMap({
    super.key,
    required this.gameType,
    required this.categoryId,
    this.totalLevels = 200,
  });

  @override
  State<ModernCategoryMap> createState() => _ModernCategoryMapState();
}

class _ModernCategoryMapState extends State<ModernCategoryMap> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel(animate: false);
    });
  }

  void _scrollToCurrentLevel({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final authState = context.read<AuthBloc>().state;
    final int unlockedLevels =
        authState.user?.unlockedLevels[widget.gameType] ?? 1;

    final theme = LevelThemeHelper.getTheme(
      widget.gameType,
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
        duration: 800.milliseconds,
        curve: Curves.easeOutBack,
      );
    } else {
      _scrollController.jumpTo(safeTargetY);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(widget.gameType, isDark: isDark);
    final authState = context.watch<AuthBloc>().state;
    final int unlockedLevels =
        authState.user?.unlockedLevels[widget.gameType] ?? 1;

    // Generate Points based on Category Design
    final List<Offset> points = _generatePoints(theme.category);
    final double rowSpacing = _getVerticalSpacing(theme.category);
    final double totalContentHeight =
        150.h + (widget.totalLevels * rowSpacing) + 150.h;

    return PopScope(
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
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        body: Stack(
          children: [
            // 1. Clean Minimal Static Background
            _buildBackground(theme, isDark),

            // 2. CustomScrollView with SliverAppBar
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── SliverAppBar ──
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  snap: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 64.h,
                  expandedHeight: 120.h,
                  collapsedHeight: 64.h,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    titlePadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    title: GlassTile(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 6.h,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 32.r,
                            height: 32.r,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 18.r,
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/home');
                                }
                              },
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              theme.title,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: GoogleFonts.outfit(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            theme.icon,
                            color: theme.primaryColor,
                            size: 16.r,
                          ),
                        ],
                      ),
                    ),
                    background: Container(
                      padding: EdgeInsets.fromLTRB(24.w, 40.h, 24.w, 0),
                      alignment: Alignment.center,
                      child: Text(
                        theme.category.name.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: theme.primaryColor.withValues(alpha: 0.6),
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── The Interactive Path Content ──
                SliverToBoxAdapter(
                  child: Stack(
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
                          SizedBox(
                            height: 150.h,
                          ), // Match the 150.h base in _generatePoints
                          ...List.generate(widget.totalLevels, (index) {
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
          ],
        ),
        bottomNavigationBar: const AdBannerWidget(),
      ),
    );
  }

  double _getVerticalSpacing(GameCategory category) {
    switch (category) {
      case GameCategory.reading:
        return 160.h;
      case GameCategory.grammar:
        return 190.h;
      default:
        return 180.h;
    }
  }

  List<Offset> _generatePoints(GameCategory category) {
    final List<Offset> points = [];
    final centerX = ScreenUtil().screenWidth / 2;
    final spacing = _getVerticalSpacing(category);

    for (int i = 0; i < widget.totalLevels; i++) {
      final x =
          centerX + (math.sin(i * 0.5) * 115.w) + (math.sin(i * 0.2) * 50.w);
      final y =
          150.h + (i * spacing) + (spacing / 2) + (math.sin(i * 1.8) * 20.h);
      points.add(Offset(x, y));
    }
    return points;
  }

  Widget _buildBackground(ThemeResult theme, bool isDark) {
    return Stack(
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
        MeshGradientBackground(colors: [theme.primaryColor, theme.accentColor]),

        // 3. Falling Shimmering Stars (Calm Twinkling Sky)
        ...List.generate(60, (index) {
          final random = math.Random(index + 600);
          final duration = (90 + random.nextInt(60)).seconds;

          return Positioned(
            left: random.nextDouble() * 1.sw,
            top: random.nextDouble() * 2.sh, // Spread vertically for parallax
            child:
                Icon(
                      Icons.auto_awesome,
                      size: (6 + random.nextInt(10)).r,
                      color: theme.primaryColor.withValues(
                        alpha: isDark ? 0.45 : 0.4,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .moveY(
                      begin: -30.h,
                      end: 1.1.sh,
                      duration: duration,
                      curve: Curves.linear,
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1.1, 1.1),
                      duration: (2 + random.nextDouble() * 3).seconds,
                      curve: Curves.easeInOut,
                    )
                    .fadeOut(duration: 3.seconds),
          );
        }),
      ],
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
    return ScaleButton(
      onTap: () {
        if (!isUnlocked) {
          _showLockedFeedback(context, theme.primaryColor);
          return;
        }
        // Navigate directly to game — no pre-game ad
        context.push(
          '/game?category=${theme.category.name}&gameType=${widget.gameType}&level=$level',
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
                width: isCurrent ? 95.r : 82.r,
                height: isCurrent ? 95.r : 82.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.4 : 0.15,
                      ),
                      offset: Offset(0, 6.h),
                      blurRadius: 12.r,
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 3.r),
                ),
                child: Container(
                  margin: EdgeInsets.all(3.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.4),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.r,
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
                                    "LVL",
                                    style: GoogleFonts.outfit(
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  Text(
                                    "$level",
                                    style: GoogleFonts.outfit(
                                      fontSize: (isCurrent ? 26 : 22).sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.0,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
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
                            size: 30.r,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2.h),
                                blurRadius: 4.r,
                              ),
                            ],
                          ),
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: isCurrent ? -4.r : -2.r,
                end: isCurrent ? 4.r : 2.r,
                duration: (isCurrent ? 1.5 : 2.5).seconds,
                curve: Curves.easeInOut,
              ),

          if (isCurrent) ...[
            // Mascot Marker
            Positioned(
              top: -65.h,
              child: _buildMascotMarker(context)
                  .animate()
                  .fadeIn(duration: 600.milliseconds)
                  .scale(delay: 200.milliseconds, curve: Curves.elasticOut),
            ),
          ],

          Positioned(
            top: isCurrent ? 12.r : 10.r,
            left: isCurrent ? 12.r : 10.r,
            child: Container(
              width: isCurrent ? 40.r : 35.r,
              height: isCurrent ? 18.r : 15.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle, // Match the node precisely
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
    );
  }

  void _showLockedFeedback(BuildContext context, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'LEVEL LOCKED',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 12.sp,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20.r),
        duration: 1.seconds,
      ),
    );
  }

  Widget _buildMascotMarker(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    final mascotEmoji =
        VoxinAssets.mascotMap[user?.voxinMascot] ??
        VoxinAssets.mascotMap['voxin_prime']!;
    final accessoryEmoji =
        VoxinAssets.accessoryMap[user?.voxinEquippedAccessory] ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.r), // Pill shape
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(mascotEmoji, style: TextStyle(fontSize: 24.sp)),
                  if (accessoryEmoji.isNotEmpty) ...[
                    SizedBox(width: 4.w),
                    Text(accessoryEmoji, style: TextStyle(fontSize: 16.sp)),
                  ],
                ],
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: -4,
              end: 4,
              duration: 1.5.seconds,
              curve: Curves.easeInOut,
            ),
        CustomPaint(
          size: Size(12.w, 8.h),
          painter: _TrianglePainter(color: Colors.white),
        ),
      ],
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
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 10.r
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final levelNum1 = i + 1;
      final isUnlockedSegment = levelNum1 < unlockedLevels;

      final segmentPath = Path();
      segmentPath.moveTo(p1.dx, p1.dy);

      final spacing = (p2.dy - p1.dy).abs();
      final cp1 = Offset(p1.dx, p1.dy + spacing * 0.5);
      final cp2 = Offset(p2.dx, p2.dy - spacing * 0.5);
      segmentPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);

      if (isUnlockedSegment) {
        canvas.drawPath(segmentPath, paint);
      } else {
        final dashPaint = Paint()
          ..color = color.withValues(alpha: 0.25)
          ..strokeWidth = 8.r
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        const dashWidth = 14.0;
        const dashSpace = 12.0;

        for (final metric in segmentPath.computeMetrics()) {
          double distance = 0;
          while (distance < metric.length) {
            final dashPath = metric.extractPath(
              distance,
              math.min(distance + dashWidth, metric.length),
            );
            canvas.drawPath(dashPath, dashPaint);
            distance += dashWidth + dashSpace;
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
