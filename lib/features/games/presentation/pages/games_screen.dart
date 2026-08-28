import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/home/presentation/widgets/category_shelf.dart';
import 'package:vowl/features/games/presentation/widgets/kids_category_shelf.dart';
import 'package:vowl/core/utils/game_helper.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMidnight = context.select<ThemeCubit, bool>(
      (c) => c.state.isMidnight,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? const Color(0xFF0F172A) : Colors.white);

    return Scaffold(
      backgroundColor: bgColor,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.status == AuthStatus.authenticated
              ? state.user
              : null;

          if (user == null) return const _QuestHubShimmer();

          return Stack(
            children: [
              const MeshGradientBackground(showLetters: false),
              CustomScrollView(
                controller: di.sl<ScrollController>(instanceName: 'games'),
                physics: const BouncingScrollPhysics(),
                cacheExtent: 500, // PERF: Pre-render 500px off-screen for smoother scroll
                slivers: [
                  _GamesAppBar(isDark: isDark, user: user),
                  SliverPadding(
                    padding: EdgeInsets.only(bottom: 120.h),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        _buildSections(context, user, isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildSections(
    BuildContext context,
    UserEntity user,
    bool isDark,
  ) => [
    // Phase 1: Hero Dashboard
    _HeroDashboard(user: user, isDark: isDark),
    // Kids Zone — visually differentiated section
    _AnimatedSection(
      index: 0,
      child: _KidsGameSection(user: user),
    ),
    // Adult categories with progress headers
    ...QuestType.values.asMap().entries.map((entry) {
      final i = entry.key;
      final type = entry.value;
      return _AnimatedSection(
        index: i + 1,
        child: _GameSection(
          titleKey: 'games.${type.serializedName}.title',
          subtitleKey: 'games.${type.serializedName}.subtitle',
          type: type,
          user: user,
        ),
      );
    }),
  ];
}

// ---------------------------------------------------------------------------
// Phase 1: Hero Dashboard — total mastery at a glance
// ---------------------------------------------------------------------------

class _HeroDashboard extends StatelessWidget {
  final UserEntity user;
  final bool isDark;

  const _HeroDashboard({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Compute overall stats
    int totalCleared = 0;
    int totalGames = 0;
    for (final type in QuestType.values) {
      final subtypes = type.subtypes.where((s) => !s.isLegacy).toList();
      totalGames += subtypes.length;
      for (final s in subtypes) {
        totalCleared += (user.completedLevels[s.name]?.length ?? 0).clamp(0, 200);
      }
    }
    final totalLevels = totalGames * 200;
    final progress = totalLevels > 0 ? totalCleared / totalLevels : 0.0;
    final percent = (progress * 100).toStringAsFixed(1);

    final contentColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 8.h),
      child: GlassTile(
        borderRadius: BorderRadius.circular(28.r),
        padding: EdgeInsets.all(20.r),
        usePremiumStyle: true,
        showShadow: true,
        blur: 10,
        child: Column(
          children: [
            // Top Row: Mastery ring + stats
            Row(
              children: [
                // Circular progress ring
                SizedBox(
                  width: 56.r,
                  height: 56.r,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 56.r,
                        height: 56.r,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0.02, 1.0),
                          backgroundColor: const Color(0xFF3B82F6)
                              .withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF3B82F6),
                          ),
                          strokeWidth: 4.r,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$percent%',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(
                          'games.core_mastery',
                          fallback: 'CORE MASTERY',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3B82F6),
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        context.tr(
                          'games.levels_cleared',
                          fallback: '$totalCleared Levels Cleared',
                          args: [totalCleared.toString()],
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: contentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            // Bottom Row: 3 stat pills
            Row(
              children: [
                _StatPill(
                  icon: Icons.sports_esports_rounded,
                  label: context.tr('games.core_games', fallback: 'Core Games'),
                  value: '$totalGames',
                  isDark: isDark,
                ),
                SizedBox(width: 8.w),
                _StatPill(
                  icon: Icons.local_fire_department_rounded,
                  label: context.tr('games.streak', fallback: 'Streak'),
                  value: '${user.currentStreak}',
                  isDark: isDark,
                  color: const Color(0xFFEF4444),
                ),
                SizedBox(width: 8.w),
                _StatPill(
                  icon: Icons.bolt_rounded,
                  label: context.tr('games.total_xp', fallback: 'XP'),
                  value: _formatNumber(user.totalExp),
                  isDark: isDark,
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.color = const Color(0xFF3B82F6),
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.08 : 0.06),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16.r),
            SizedBox(height: 4.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 7.sp,
                  fontWeight: FontWeight.w800,
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.4),
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase 3: Staggered entry animation wrapper
// ---------------------------------------------------------------------------

class _AnimatedSection extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedSection({required this.index, required this.child});

  @override
  State<_AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<_AnimatedSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  ScrollController? _scrollController;
  bool _hasTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scrollController == null && !_hasTriggered) {
      _scrollController = di.sl<ScrollController>(instanceName: 'games');
      _scrollController?.addListener(_checkVisibility);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkVisibility();
      });
    }
  }

  void _checkVisibility() {
    if (_hasTriggered || !mounted || _scrollController == null) return;
    if (!_scrollController!.hasClients) return;

    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;

    try {
      final viewport = RenderAbstractViewport.of(renderObject);
      final offsetToReveal = viewport.getOffsetToReveal(renderObject, 0.0);
      
      // Bottom edge of the current viewport
      final currentBottomEdge =
          _scrollController!.position.pixels + MediaQuery.of(context).size.height;
      
      // Trigger when the top of the widget enters the screen
      if (currentBottomEdge > offsetToReveal.offset + 20) {
        _hasTriggered = true;
        _scrollController!.removeListener(_checkVisibility);
        
        // Micro-stagger if multiple enter at once
        Future.delayed(Duration(milliseconds: 60 * (widget.index % 3)), () {
          if (mounted) _controller.forward();
        });
      }
    } catch (_) {
      // Ignore layout exceptions during early frames
    }
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Glass App Bar — with user context stats
// ---------------------------------------------------------------------------

class _GamesAppBar extends StatelessWidget {
  final bool isDark;
  final UserEntity user;

  const _GamesAppBar({required this.isDark, required this.user});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: true,
      expandedHeight: 120.h,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome_mosaic_rounded,
                      color: const Color(0xFF3B82F6),
                      size: 14.r,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    context.tr('games.quest_hub', fallback: 'Quest Hub'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        centerTitle: true,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Game category section with progress-aware header
// ---------------------------------------------------------------------------

class _GameSection extends StatelessWidget {
  final String titleKey;
  final String subtitleKey;
  final QuestType type;
  final UserEntity user;

  const _GameSection({
    required this.titleKey,
    required this.subtitleKey,
    required this.type,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final color = GameHelper.getCategoryColor(type.name);
    final subtypes = type.subtypes.where((s) => !s.isLegacy).toList();

    // Calculate category progress for the header
    int gamesStarted = 0;
    int totalCleared = 0;
    for (final s in subtypes) {
      final cleared = user.completedLevels[s.name]?.length ?? 0;
      if (cleared > 0) gamesStarted++;
      totalCleared += cleared.clamp(0, 200);
    }
    final totalLevels = subtypes.length * 200;
    final progress = totalLevels > 0 ? totalCleared / totalLevels : 0.0;
    final isEliteMastery = type == QuestType.eliteMastery;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 32.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: _GameSectionHeader(
            titleKey: titleKey,
            subtitleKey: subtitleKey,
            fallbackTitle: type == QuestType.eliteMastery 
                ? 'Elite Mastery' 
                : type.name[0].toUpperCase() + type.name.substring(1),
            fallbackSubtitle: type == QuestType.eliteMastery 
                ? 'Prestige Challenges' 
                : 'Master this skill',
            color: color,
            gamesStarted: gamesStarted,
            totalGames: subtypes.length,
            progress: progress,
            isEliteMastery: isEliteMastery,
            onSeeAll: () => context.push(
              '${AppRouter.categoryGamesRoute}?category=${type.name}',
            ),
          ),
        ),
        SizedBox(height: 16.h),
        CategoryShelf(
          user: user,
          subtypes: subtypes,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Kids game section — visually differentiated
// ---------------------------------------------------------------------------

class _KidsGameSection extends StatelessWidget {
  final UserEntity user;

  const _KidsGameSection({required this.user});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFF4081); // Bright pink for Kids Zone

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 32.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: _GameSectionHeader(
            titleKey: 'kids_zone.title',
            subtitleKey: 'kids_zone.subtitle',
            fallbackTitle: 'Kids Zone',
            fallbackSubtitle: 'Play & Learn',
            color: color,
            isKidsZone: true,
            onSeeAll: () => context.push('/kids-zone'),
          ),
        ),
        SizedBox(height: 16.h),
        KidsCategoryShelf(user: user),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section header — progress-aware with category mastery indicator
// ---------------------------------------------------------------------------

class _GameSectionHeader extends StatelessWidget {
  final String titleKey;
  final String subtitleKey;
  final String? fallbackTitle;
  final String? fallbackSubtitle;
  final Color color;
  final VoidCallback? onSeeAll;
  final int gamesStarted;
  final int totalGames;
  final double progress;
  final bool isKidsZone;
  final bool isEliteMastery;

  const _GameSectionHeader({
    required this.titleKey,
    required this.subtitleKey,
    this.fallbackTitle,
    this.fallbackSubtitle,
    required this.color,
    this.onSeeAll,
    this.gamesStarted = 0,
    this.totalGames = 0,
    this.progress = 0.0,
    this.isKidsZone = false,
    this.isEliteMastery = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Colour-coded indicator bar
            Container(
              width: 4.w,
              height: 36.h,
              decoration: BoxDecoration(
                gradient: isEliteMastery
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                      )
                    : null,
                color: isEliteMastery ? null : color,
                borderRadius: BorderRadius.circular(2.r),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          context
                              .tr(titleKey, fallback: fallbackTitle)
                              .toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            letterSpacing: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Kids Zone badge
                      if (isKidsZone) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '🎈',
                            style: TextStyle(fontSize: 10.sp),
                          ),
                        ),
                      ],
                      // Elite Mastery gold badge
                      if (isEliteMastery) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '👑',
                            style: TextStyle(fontSize: 10.sp),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    context.tr(subtitleKey, fallback: fallbackSubtitle),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (onSeeAll != null)
              ScaleButton(
                onTap: () {
                  try {
                    Haptics.vibrate(HapticsType.light);
                  } catch (_) {}
                  onSeeAll!();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    context.tr('common.see_all', fallback: 'See All'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Phase 1: Category progress indicator
        if (totalGames > 0 && !isKidsZone) ...[
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsetsDirectional.only(start: 16.w),
            child: Row(
              children: [
                // Mini progress bar
                Expanded(
                  child: Container(
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                    child: FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: progress.clamp(0.01, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  context.tr(
                    'games.section_progress',
                    fallback: '$gamesStarted/$totalGames Started',
                    args: [
                      gamesStarted.toString(),
                      totalGames.toString(),
                    ],
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Phase 4: Shimmer loading skeleton for Quest Hub
// ---------------------------------------------------------------------------

class _QuestHubShimmer extends StatelessWidget {
  const _QuestHubShimmer();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60.h),
              // Hero dashboard shimmer
              ShimmerLoading.rounded(height: 140.h, borderRadius: 28),
              SizedBox(height: 32.h),
              // Section header shimmer
              Row(
                children: [
                  ShimmerLoading.rounded(
                    width: 4.w,
                    height: 36.h,
                    borderRadius: 2,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLoading.rounded(
                          width: 120.w,
                          height: 18.h,
                          borderRadius: 6,
                        ),
                        SizedBox(height: 4.h),
                        ShimmerLoading.rounded(
                          width: 80.w,
                          height: 12.h,
                          borderRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // Shelf shimmer
              SizedBox(
                height: 215.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, i) => Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: ShimmerLoading.rounded(
                      width: 150.w,
                      height: 215.h,
                      borderRadius: 30,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              // Second section shimmer
              Row(
                children: [
                  ShimmerLoading.rounded(
                    width: 4.w,
                    height: 36.h,
                    borderRadius: 2,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ShimmerLoading.rounded(
                      width: 140.w,
                      height: 18.h,
                      borderRadius: 6,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              SizedBox(
                height: 215.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, i) => Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: ShimmerLoading.rounded(
                      width: 150.w,
                      height: 215.h,
                      borderRadius: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
