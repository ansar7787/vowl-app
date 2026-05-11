import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_background_renderer.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

class StickerBookScreen extends StatefulWidget {
  const StickerBookScreen({super.key});

  @override
  State<StickerBookScreen> createState() => _StickerBookScreenState();
}

class _StickerBookScreenState extends State<StickerBookScreen> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late TabController _tabController;
  final List<String> _categories = KidsAssets.stickerMap.keys.toList();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _tabController = TabController(length: _categories.length, vsync: this);
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

        final bgColor = isMidnight 
            ? Colors.black 
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              // Living Background
              KidsBackgroundRenderer(
                painterName: 'UnicornMist',
                shaderName: 'magic_twinkle',
                primaryColor: isDark ? const Color(0xFF4C1D95) : Colors.purple.shade200,
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
                        children: _categories.map((cat) => _buildStickerGrid(cat, state, isDark, isMidnight)).toList(),
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
                  ],
                  maxBlastForce: 20,
                  minBlastForce: 10,
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
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
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
                    color: isMidnight ? Colors.white.withValues(alpha: 0.05) : (isDark ? Colors.white10 : Colors.white),
                    shape: BoxShape.circle,
                    boxShadow: (isDark || isMidnight) ? null : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: isMidnight ? Colors.white.withValues(alpha: 0.1) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: (isDark || isMidnight) ? Colors.white70 : const Color(0xFF1E293B),
                    size: 20,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        VowlMascot(size: 24.r),
                        SizedBox(width: 8.w),
                        Text(
                          "$earned / $max",
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.toys_rounded,
                          color: const Color(0xFFEF4444),
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          "${user.kidsCoins}",
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Column(
            children: [
              Text(
                "STICKERS ALBUM",
                style: GoogleFonts.outfit(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: (isDark || isMidnight) ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
              SizedBox(height: 12.h),
              // MODERN 2026 PROGRESS CAPSULE
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isMidnight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 120.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        AnimatedContainer(
                          duration: 800.ms,
                          width: 120.w * (earned / max).clamp(0.0, 1.0),
                          height: 8.h,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                            borderRadius: BorderRadius.circular(4.r),
                            boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 6)],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "${((earned / max) * 100).toInt()}%",
                      style: GoogleFonts.outfit(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn().scale(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(bool isDark, bool isMidnight) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.h),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicatorColor: Colors.orange,
        indicatorWeight: 4,
        labelColor: (isDark || isMidnight) ? Colors.white : const Color(0xFF1E293B),
        unselectedLabelColor: (isDark || isMidnight) ? Colors.white38 : Colors.black26,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14.sp),
        tabs: _categories.map((cat) {
          final earned = _getCategoryEarnedCount(cat);
          return Tab(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(cat.toUpperCase().replaceAll('_', ' ')),
                if (earned > 0)
                  Container(
                    margin: EdgeInsets.only(top: 4.h),
                    width: 30.w,
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: earned / 4),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
              ],
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
      final id = level == 10 ? "sticker_$category" : "${category}_sticker_$level";
      if (earned.contains(id)) count++;
    }
    return count;
  }

  Widget _buildStickerGrid(String category, AuthState state, bool isDark, bool isMidnight) {
    final milestones = [10, 50, 100, 200];
    final earnedStickers = state.user?.kidsStickers ?? [];

    return GridView.builder(
      padding: EdgeInsets.all(20.r),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20.w,
        mainAxisSpacing: 20.w,
        childAspectRatio: 0.9,
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
                  ProfileEquipStickerRequested(isEquipped ? null : stickerId),
                );
              }
            }
          : () {
              Haptics.vibrate(HapticsType.warning);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "🚀 Complete $level quests in this category to unlock this sticker!",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: level == 200 ? Colors.black87 : Colors.white,
                    ),
                  ),
                  backgroundColor: _getLevelColor(level).withValues(alpha: 0.9),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.all(20.r),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked
              ? (isMidnight ? Colors.white.withValues(alpha: 0.05) : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white))
              : (isMidnight ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(32.r),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: level == 200 
                        ? Colors.amber.withValues(alpha: 0.5)
                        : (isEquipped ? Colors.orange.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1)),
                    blurRadius: level == 200 ? 30 : 20,
                    spreadRadius: level == 200 ? 2 : 0,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
          border: Border.all(
            color: isUnlocked 
                ? _getLevelColor(level) 
                : (isMidnight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
            width: isEquipped ? 4.0 : 5.0, // Thick borders for medal look
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isUnlocked && level >= 100)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32.r),
                    gradient: RadialGradient(
                      colors: [
                        (level == 200 ? Colors.amber : Colors.orange).withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isUnlocked ? stickerEmoji : "❓",
                    style: TextStyle(
                      fontSize: level == 200 ? 60.sp : 48.sp,
                      shadows: isUnlocked && level == 200 ? [
                        const Shadow(color: Colors.amber, blurRadius: 20),
                      ] : null,
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .scale(
                     begin: const Offset(1, 1),
                     end: level == 200 ? const Offset(1.2, 1.2) : const Offset(1.05, 1.05),
                     duration: 1.seconds,
                   ),
                  if (isUnlocked) ...[
                    SizedBox(height: 8.h),
                    _buildRarityLabel(level),
                  ],
                ],
              ),
            ),
            if (!isUnlocked)
              Positioned(
                bottom: 15.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    "QUEST $level",
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: (isDark || isMidnight) ? Colors.white38 : Colors.black26,
                    ),
                  ),
                ),
              ),
            if (isEquipped)
              Positioned(
                top: 12.r,
                right: 12.r,
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 10.r),
                ),
              ).animate().scale(duration: 300.ms, curve: Curves.bounceOut),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).scale(duration: 300.ms);
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 10:
        return const Color(0xFF4CAF50); // Green
      case 50:
        return const Color(0xFFCD7F32); // Bronze
      case 100:
        return const Color(0xFFC0C0C0); // Silver
      case 200:
        return const Color(0xFFFFD700); // Gold
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 8.sp,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
