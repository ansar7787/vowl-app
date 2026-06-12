import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_background_renderer.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

class StickerBookScreen extends StatefulWidget {
  const StickerBookScreen({super.key});

  @override
  State<StickerBookScreen> createState() => _StickerBookScreenState();
}

class _StickerBookScreenState extends State<StickerBookScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late TabController _tabController;
  final List<String> _categories = KidsAssets.stickerMap.keys.toList();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        if (user == null) return const SizedBox.shrink();

        final totalEarned = user.kidsStickers.length;
        const totalMax = 88; // 22 categories * 4 stickers
        final mascotEmoji = KidsAssets.mascotMap[user.kidsMascot] ?? '🦉';

        return Scaffold(
          backgroundColor: isMidnight
              ? Colors.black
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          body: Stack(
            children: [
              // Living Background - updated for cleaner look in light mode
              if (!isMidnight && !isDark)
                Container(color: Colors.white)
              else
                KidsBackgroundRenderer(
                  painterName: 'UnicornMist',
                  shaderName: 'magic_twinkle',
                  primaryColor: isDark
                      ? const Color(0xFF4C1D95)
                      : Colors.purple.shade200,
                  gameType: 'album',
                ),
              SafeArea(
                child: Column(
                  children: [
                    _buildPremiumAppBar(
                      context,
                      totalEarned,
                      totalMax,
                      mascotEmoji,
                      user,
                      isDark,
                      isMidnight,
                    ),
                    _buildCategoryTabs(isDark, isMidnight),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const BouncingScrollPhysics(),
                        children: _categories
                            .map(
                              (cat) => _buildStickerGrid(
                                cat,
                                state,
                                isDark,
                                isMidnight,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Colors.orange,
                    Colors.pink,
                    Colors.blue,
                    Colors.yellow,
                    Colors.purple,
                    Colors.greenAccent,
                  ],
                  maxBlastForce: 25,
                  minBlastForce: 15,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumAppBar(
    BuildContext context,
    int earned,
    int max,
    String mascotEmoji,
    dynamic user,
    bool isDark,
    bool isMidnight,
  ) {
    return Container(
          margin: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: isMidnight
                ? Colors.white.withValues(alpha: 0.05)
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: isMidnight
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
            border: Border.all(
              color: isMidnight
                  ? Colors.white24
                  : (isDark ? Colors.white12 : Colors.grey.shade200),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ScaleButton(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.orange[800],
                        size: 20.r,
                      ),
                    ),
                  ),
                  Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                          ),
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              mascotEmoji,
                              style: TextStyle(fontSize: 18.sp),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "$earned / $max",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.05, 1.05),
                        duration: 2.seconds,
                        curve: Curves.easeInOutSine,
                      ),
                ],
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "STICKER ALBUM",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                            color: (isDark || isMidnight)
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        // Modern 2026 Progress Bar
                        Container(
                          height: 16.h,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.02),
                            ),
                          ),
                          child: Stack(
                            children: [
                              AnimatedContainer(
                                duration: 1.seconds,
                                curve: Curves.easeOutCirc,
                                width:
                                    (MediaQuery.of(context).size.width -
                                        128.w) *
                                    (earned / max).clamp(0.0, 1.0),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF59E0B),
                                      Color(0xFFF97316),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.deepOrange.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 28.r,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.1, end: 0, curve: Curves.easeOutBack);
  }

  Widget _buildCategoryTabs(bool isDark, bool isMidnight) {
    return Container(
      height: 44.h,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        indicatorSize: TabBarIndicatorSize.label,
        labelPadding: EdgeInsets.symmetric(horizontal: 8.w),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        indicator: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(100.r),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark || isMidnight
            ? Colors.white54
            : Colors.grey.shade600,
        labelStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.sp,
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        tabs: _categories.map((cat) {
          final earned = _getCategoryEarnedCount(cat);

          return Tab(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.toUpperCase().replaceAll('_', ' ')),
                  if (earned > 0) ...[
                    SizedBox(width: 8.w),
                    // We use an opacity hack to make the badge look good whether selected or not
                    Opacity(
                      opacity: 0.9,
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: isMidnight || isDark
                              ? Colors.white24
                              : Colors.black12,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "$earned",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  int _getCategoryEarnedCount(String category) {
    final state = context.read<AuthBloc>().state;
    final earned = state.user?.kidsStickers ?? [];
    int count = 0;
    for (var level in [10, 50, 100, 200]) {
      final id = level == 10
          ? "sticker_$category"
          : "${category}_sticker_$level";
      if (earned.contains(id)) count++;
    }
    return count;
  }

  Widget _buildStickerGrid(
    String category,
    AuthState state,
    bool isDark,
    bool isMidnight,
  ) {
    final milestones = [10, 50, 100, 200];
    final earnedStickers = state.user?.kidsStickers ?? [];

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 24.w,
        mainAxisSpacing: 24.h,
        childAspectRatio: 0.85,
      ),
      itemCount: milestones.length,
      itemBuilder: (context, mIndex) {
        final level = milestones[mIndex];
        final stickerId = level == 10
            ? "sticker_$category"
            : "${category}_sticker_$level";
        final isUnlocked = earnedStickers.contains(stickerId);

        return _buildModernStickerItem(
          context,
          category,
          stickerId,
          isUnlocked,
          level,
          mIndex,
          isDark,
          isMidnight,
        );
      },
    );
  }

  Widget _buildModernStickerItem(
    BuildContext context,
    String category,
    String stickerId,
    bool isUnlocked,
    int level,
    int index,
    bool isDark,
    bool isMidnight,
  ) {
    final user = context.watch<AuthBloc>().state.user;
    final equippedStickerId = user?.kidsEquippedSticker;
    final isEquipped = equippedStickerId == stickerId;
    final stickerEmoji = KidsAssets.getStickerEmoji(stickerId);
    final rarityColor = _getLevelColor(level);

    return ScaleButton(
          onTap: isUnlocked
              ? () {
                  if (!isEquipped) {
                    _confettiController.play();
                    Haptics.vibrate(HapticsType.heavy);
                  } else {
                    Haptics.vibrate(HapticsType.medium);
                  }
                  if (user != null) {
                    context.read<ProfileBloc>().add(
                      ProfileEquipStickerRequested(
                        isEquipped ? null : stickerId,
                      ),
                    );
                  }
                }
              : () {
                  Haptics.vibrate(HapticsType.warning);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "🔒 Complete $level quests in this category to unlock this sticker!",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          color: level == 200 ? Colors.black87 : Colors.white,
                        ),
                      ),
                      backgroundColor: rarityColor.withValues(alpha: 0.95),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(24.r),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
          child: Container(
            decoration: BoxDecoration(
              color: isUnlocked
                  ? (isMidnight
                        ? rarityColor.withValues(alpha: 0.15)
                        : (isDark ? const Color(0xFF1E293B) : Colors.white))
                  : (isMidnight
                        ? Colors.black26
                        : (isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9))),
              borderRadius: BorderRadius.circular(32.r),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: isMidnight
                            ? rarityColor.withValues(alpha: 0.3)
                            : (isDark
                                  ? Colors.black45
                                  : Colors.black.withValues(alpha: 0.05)),
                        blurRadius: level >= 100 ? 20 : 12,
                        offset: const Offset(0, 8),
                        spreadRadius: isEquipped ? 2 : 0,
                      ),
                    ]
                  : null,
              border: Border.all(
                color: isUnlocked
                    ? rarityColor
                    : (isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.05)),
                width: isUnlocked ? (isEquipped ? 6.0 : 4.0) : 2.0,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Holographic Background Effects for Unlocked Rare/Legendary
                if (isUnlocked && level >= 100)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28.r),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              isMidnight || isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : rarityColor.withValues(alpha: 0.1),
                              Colors.transparent,
                              isMidnight || isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : rarityColor.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Dotted placeholder shadow for locked
                if (!isUnlocked)
                  Center(
                    child: Opacity(
                      opacity: 0.15,
                      child: Text(
                        stickerEmoji,
                        style: TextStyle(fontSize: 60.sp),
                      ),
                    ),
                  ),

                // Content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isUnlocked)
                        Text(
                              stickerEmoji,
                              style: TextStyle(
                                fontSize: level == 200 ? 64.sp : 54.sp,
                                shadows: level >= 100
                                    ? [
                                        Shadow(
                                          color: rarityColor,
                                          blurRadius: 25,
                                        ),
                                      ]
                                    : null,
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(1, 1),
                              end: level == 200
                                  ? const Offset(1.15, 1.15)
                                  : const Offset(1.05, 1.05),
                              duration: 2.seconds,
                              curve: Curves.easeInOutBack,
                            ),

                      if (isUnlocked) ...[
                        SizedBox(height: 16.h),
                        _buildRarityLabel(level),
                      ],
                    ],
                  ),
                ),

                // Locked Overlay Text Badge
                if (!isUnlocked)
                  Positioned(
                    bottom: 16.h,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black54 : Colors.white70,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 14.r,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            "LVL $level",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w900,
                              color: (isDark || isMidnight)
                                  ? Colors.white70
                                  : const Color(0xFF1E293B),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Equipped Checkmark Badge
                if (isEquipped)
                  Positioned(
                    top: 12.r,
                    right: 12.r,
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: rarityColor.withValues(alpha: 0.6),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: rarityColor, width: 3),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: rarityColor,
                        size: 16.r,
                      ),
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (index * 50).ms)
        .slideY(
          begin: 0.15,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutBack,
        );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 10:
        return const Color(0xFF10B981); // Vibrant Emerald
      case 50:
        return const Color(0xFFF59E0B); // Bright Bronze/Amber
      case 100:
        return const Color(0xFF94A3B8); // Shiny Silver
      case 200:
        return const Color(0xFFFFD700); // Radiant Gold
      default:
        return Colors.grey;
    }
  }

  Widget _buildRarityLabel(int level) {
    Color color;
    String label;
    if (level >= 200) {
      color = Colors.amber;
      label = "LEGENDARY";
    } else if (level >= 100) {
      color = Colors.orange;
      label = "EPIC";
    } else if (level >= 50) {
      color = Colors.purpleAccent;
      label = "RARE";
    } else {
      color = Colors.blueAccent;
      label = "COMMON";
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 10.sp,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
