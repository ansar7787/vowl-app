import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class DiscoveryDeck extends StatefulWidget {
  const DiscoveryDeck({
    super.key,
    required this.user,
    required this.onLaunchQuest,
  });

  final UserEntity user;
  final Function(String) onLaunchQuest;

  @override
  State<DiscoveryDeck> createState() => _DiscoveryDeckState();
}

class _DiscoveryDeckState extends State<DiscoveryDeck> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final discoveryItems = [
      (
        title: 'For You',
        subtitle: 'Smart recommendation based on your progress',
        icon: Icons.lightbulb_outline_rounded,
        color: const Color(0xFF6366F1),
        quests: 3,
        difficulty: 'Adaptive',
        onTap: () => widget.onLaunchQuest('smart_recommendation'),
      ),
      (
        title: 'Daily Duo',
        subtitle: 'Vocal warm-up followed by reading mastery',
        icon: Icons.auto_awesome_motion_rounded,
        color: const Color(0xFF2563EB),
        quests: 2,
        difficulty: 'Medium',
        onTap: () => widget.onLaunchQuest('daily_duo'),
      ),
      (
        title: 'Speed Blitz',
        subtitle: 'High-speed challenges to sharpen focus',
        icon: Icons.bolt_rounded,
        color: const Color(0xFFF97316),
        quests: 3,
        difficulty: 'Hard',
        onTap: () => widget.onLaunchQuest('speed_blitz'),
      ),
      (
        title: 'Grammar Pro',
        subtitle: 'Elite structural drills for sentence mastery',
        icon: Icons.verified_user_rounded,
        color: const Color(0xFF10B981),
        quests: 3,
        difficulty: 'Expert',
        onTap: () => widget.onLaunchQuest('grammar_pro'),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220.h,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: discoveryItems.length,
            itemBuilder: (context, index) {
              final item = discoveryItems[index];

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double page = 0;
                  try {
                    page = _pageController.page ?? _currentPage.toDouble();
                  } catch (_) {
                    page = _currentPage.toDouble();
                  }
                  
                  // Calculate how centered the card is (1.0 = center, 0.0 = far away)
                  final double diff = (page - index).abs();
                  final double activeFactor = (1 - diff).clamp(0.0, 1.0);
                  
                  // Scale from 0.9 to 1.0 based on center proximity
                  final double scale = 0.9 + (activeFactor * 0.1);

                  return Transform.scale(
                    scale: scale,
                    child: _DiscoveryCollectionCard(
                      title: item.title,
                      subtitle: item.subtitle,
                      icon: item.icon,
                      color: item.color,
                      quests: item.quests,
                      difficulty: item.difficulty,
                      isSelected: activeFactor > 0.8,
                      activeFactor: activeFactor,
                      onTap: item.onTap,
                    ),
                  );
                },
              );
            },
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            discoveryItems.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              height: 6.r,
              width: _currentPage == index ? 28.w : 8.r,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? discoveryItems[index].color
                    : discoveryItems[index].color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiscoveryCollectionCard extends StatelessWidget {
  const _DiscoveryCollectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.quests,
    required this.difficulty,
    required this.isSelected,
    required this.activeFactor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int quests;
  final String difficulty;
  final bool isSelected;
  final double activeFactor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleButton(
      onTap: onTap,
      child: Container(
        height: 200.h,
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
        child: GlassTile(
          borderRadius: BorderRadius.circular(32.r),
          padding: EdgeInsets.zero,
          showShadow: false,
          borderColor: isSelected 
            ? color.withValues(alpha: 0.5) 
            : Colors.white.withValues(alpha: 0.1),
          child: Stack(
            children: [
              // Decorative Background Icon
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  icon,
                  size: 140.r,
                  color: color.withValues(alpha: isSelected ? 0.08 : 0.03),
                ),
              ),

              // Content Layer
              Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Tag & Difficulty Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: color.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.4),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
                                    ),
                                  ).animate(onPlay: (c) => c.repeat())
                                   .scale(begin: const Offset(0.5, 0.5), end: const Offset(2, 2), duration: 2.seconds, curve: Curves.easeOutExpo)
                                   .fadeOut(duration: 2.seconds),
                                ],
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                title.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                  letterSpacing: 2.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildDifficultyBadge(difficulty, color),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Main Subtitle
                    Expanded(
                      child: Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Action Footer
                    Row(
                      children: [
                        _buildQuestCount(quests, color),
                        const Spacer(),
                        _buildStartButton(color),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology_rounded, size: 10.r, color: color.withValues(alpha: 0.7)),
          SizedBox(width: 4.w),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 8.sp,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCount(int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.layers_rounded, size: 12.r, color: color),
        ),
        SizedBox(width: 8.w),
        Text(
          '$count QUESTS',
          style: GoogleFonts.outfit(
            fontSize: 10.sp,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(Color color) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14.r,
        color: color,
      ),
    ).animate(onPlay: (c) => c.repeat())
     .shimmer(delay: 1.seconds, duration: 2.seconds);
  }
}
