import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/utils/locale_service.dart';

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
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final discoveryItems = [
      (
        title: context.tr('home.discovery_foryou_title', fallback: 'For You'),
        subtitle: context.tr('home.discovery_foryou_subtitle', fallback: 'Recommended Quests'),
        icon: Icons.lightbulb_outline_rounded,
        color: const Color(0xFF6366F1),
        quests: 3,
        difficulty: context.tr('home.discovery_diff_adaptive', fallback: 'Adaptive'),
        onTap: () => widget.onLaunchQuest('smart_recommendation'),
      ),
      (
        title: context.tr('home.discovery_dailyduo_title', fallback: 'Daily Duo'),
        subtitle: context.tr('home.discovery_dailyduo_subtitle', fallback: 'Quick Practice'),
        icon: Icons.auto_awesome_motion_rounded,
        color: const Color(0xFF2563EB),
        quests: 2,
        difficulty: context.tr('home.discovery_diff_medium', fallback: 'Medium'),
        onTap: () => widget.onLaunchQuest('daily_duo'),
      ),
      (
        title: context.tr('home.discovery_speedblitz_title', fallback: 'Speed Blitz'),
        subtitle: context.tr('home.discovery_speedblitz_subtitle', fallback: 'Beat the clock'),
        icon: Icons.bolt_rounded,
        color: const Color(0xFFF97316),
        quests: 3,
        difficulty: context.tr('home.discovery_diff_hard', fallback: 'Hard'),
        onTap: () => widget.onLaunchQuest('speed_blitz'),
      ),
      (
        title: context.tr('home.discovery_grammarpro_title', fallback: 'Grammar Pro'),
        subtitle: context.tr('home.discovery_grammarpro_subtitle', fallback: 'Master the rules'),
        icon: Icons.verified_user_rounded,
        color: const Color(0xFF10B981),
        quests: 3,
        difficulty: context.tr('home.discovery_diff_expert', fallback: 'Expert'),
        onTap: () => widget.onLaunchQuest('grammar_pro'),
      ),
    ];

    return MediaQuery.withClampedTextScaling(
      // These are fixed-height carousel cards by design; clamp local text
      // scale so very large OS accessibility settings can't overflow them,
      // while the rest of the app remains freely scalable.
      minScaleFactor: 1.0,
      maxScaleFactor: 1.3,
      child: Column(
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
                    double page;
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
                        isRtl: isRtl,
                        onTap: item.onTap,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: 16.h),
          Semantics(
            label: context.tr(
              'home.discovery_page_indicator',
              args: [
                (_currentPage + 1).toString(),
                discoveryItems.length.toString(),
              ],
            ),
            child: Row(
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
          ),
        ],
      ),
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
    required this.isRtl,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int quests;
  final String difficulty;
  final bool isSelected;
  final bool isRtl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label:
          '$title, $subtitle, ${context.tr('home.quests_count', args: [quests.toString()])}, $difficulty',
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          height: 200.h,
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          child: ExcludeSemantics(
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
                  PositionedDirectional(
                    end: -20,
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
                            Expanded(
                              child: Container(
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
                                                border: Border.all(
                                                  color: color.withValues(
                                                    alpha: 0.5,
                                                  ),
                                                  width: 1,
                                                ),
                                              ),
                                            )
                                            .animate(onPlay: (c) => c.repeat())
                                            .scale(
                                              begin: const Offset(0.5, 0.5),
                                              end: const Offset(2, 2),
                                              duration: 2.seconds,
                                              curve: Curves.easeOutExpo,
                                            )
                                            .fadeOut(duration: 2.seconds),
                                      ],
                                    ),
                                    SizedBox(width: 8.w),
                                    Flexible(
                                      child: Text(
                                        title.toUpperCase(),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w900,
                                          color: color,
                                          letterSpacing: 2.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            _buildDifficultyBadge(difficulty, color),
                          ],
                        ),
                        SizedBox(height: 16.h),

                        // Main Subtitle
                        Expanded(
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: 'Outfit',
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
                            _buildQuestCount(context, quests, color),
                            const Spacer(),
                            _buildStartButton(color, isRtl),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
          Icon(
            Icons.psychology_rounded,
            size: 10.r,
            color: color.withValues(alpha: 0.7),
          ),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 8.sp,
                fontWeight: FontWeight.w800,
                color: color.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCount(BuildContext context, int count, Color color) {
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
          context.tr('home.quests_count', args: [count.toString()]),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10.sp,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStartButton(Color color, bool isRtl) {
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
            isRtl
                ? Icons.arrow_back_ios_rounded
                : Icons.arrow_forward_ios_rounded,
            size: 14.r,
            color: color,
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(delay: 1.seconds, duration: 2.seconds);
  }
}
