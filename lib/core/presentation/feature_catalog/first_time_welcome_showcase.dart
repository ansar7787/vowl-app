import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class _ShowcaseHighlight {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;

  const _ShowcaseHighlight({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
  });
}

class _ShowcaseSlide {
  final String title;
  final String subtitle;
  final IconData heroIcon;
  final String heroTag;
  final List<Color> gradientColors;
  final Color accentColor;
  final List<_ShowcaseHighlight> highlights;

  const _ShowcaseSlide({
    required this.title,
    required this.subtitle,
    required this.heroIcon,
    required this.heroTag,
    required this.gradientColors,
    required this.accentColor,
    required this.highlights,
  });
}

/// Ultra-modern full-screen onboarding modal showcasing Vowl's core ecosystem.
class FirstTimeWelcomeShowcase extends StatefulWidget {
  const FirstTimeWelcomeShowcase({super.key});

  static const String prefsKeyHasSeenShowcase =
      'has_seen_vowl_welcome_showcase';

  /// Evaluates if the user is seeing the app for the first time and presents showcase.
  static Future<void> checkAndShow(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool(prefsKeyHasSeenShowcase) ?? false;
      if (hasSeen) return;

      if (context.mounted) {
        // If existing user with progress, do not show beginner tour
        if (di.sl.isRegistered<AuthBloc>()) {
          final user = di.sl<AuthBloc>().state.user;
          if (user != null && user.totalLevelsCompleted > 0) {
            await prefs.setBool(prefsKeyHasSeenShowcase, true);
            return;
          }
        }
        // Allow initial screen transition & daily reward check to settle smoothly
        await Future.delayed(const Duration(milliseconds: 600));
        if (context.mounted) {
          await show(context);
        }
      }
    } catch (_) {}
  }

  /// Explicitly presents the showcase (e.g. from the Feature Directory or Settings).
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => const FirstTimeWelcomeShowcase(),
    );
  }

  @override
  State<FirstTimeWelcomeShowcase> createState() =>
      _FirstTimeWelcomeShowcaseState();
}

class _FirstTimeWelcomeShowcaseState extends State<FirstTimeWelcomeShowcase> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  static const List<_ShowcaseSlide> _slides = [
    _ShowcaseSlide(
      title: '100+ Games Across 9 Pillars',
      subtitle:
          'Practice speaking, master daily grammar, and build confidence through real-world conversation practice.',
      heroIcon: LucideIcons.gamepad2,
      heroTag: '9 LEARNING PILLARS',
      gradientColors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      accentColor: AppColors.indigo500,
      highlights: [
        _ShowcaseHighlight(
          icon: LucideIcons.mic,
          title: 'Live Speech Practice',
          subtitle:
              'Instant pronunciation guidance to help you speak clearly and naturally',
          tint: Color(0xFF6366F1),
        ),
        _ShowcaseHighlight(
          icon: LucideIcons.sparkles,
          title: '19 Grammar Practice Games',
          subtitle: 'Master verb tenses, sentence puzzles, and vocabulary',
          tint: Color(0xFF8B5CF6),
        ),
        _ShowcaseHighlight(
          icon: LucideIcons.messageSquare,
          title: 'Everyday Conversations',
          subtitle:
              'Interactive dialogues for travel, dining, and daily situations',
          tint: Color(0xFFA855F7),
        ),
      ],
    ),
    _ShowcaseSlide(
      title: 'AI Vision & 50+ Languages',
      subtitle:
          'Point your camera at objects or text around you, and translate words offline whenever you need.',
      heroIcon: LucideIcons.camera,
      heroTag: 'CAMERA & OFFLINE TOOLS',
      gradientColors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
      accentColor: AppColors.blue500,
      highlights: [
        _ShowcaseHighlight(
          icon: LucideIcons.camera,
          title: 'Photo Vocab',
          subtitle:
              'Scan everyday objects to learn their English names instantly',
          tint: Color(0xFF0EA5E9),
        ),
        _ShowcaseHighlight(
          icon: LucideIcons.scan,
          title: 'Scan & Learn',
          subtitle:
              'Turn book pages and printed text into interactive study lists',
          tint: Color(0xFF2563EB),
        ),
        _ShowcaseHighlight(
          icon: LucideIcons.languages,
          title: '50+ Languages Offline',
          subtitle:
              'Translate words and full sentences without needing internet',
          tint: Color(0xFF06B6D4),
        ),
      ],
    ),
    _ShowcaseSlide(
      title: 'Buddy Boutique & Kids World',
      subtitle:
          'Dress up your companion mascot, care for your pet, and collect colorful stickers as you learn.',
      heroIcon: LucideIcons.sparkles,
      heroTag: 'MASCOT & KIDS ROOM',
      gradientColors: [Color(0xFFF43F5E), Color(0xFFFB923C)],
      accentColor: AppColors.rose500,
      highlights: [
        _ShowcaseHighlight(
          icon: LucideIcons.shirt,
          title: 'Buddy Boutique',
          subtitle:
              'Unlock cute outfits, hats, glasses, and accessories for your buddy',
          tint: Color(0xFFF43F5E),
        ),
        _ShowcaseHighlight(
          icon: LucideIcons.baby,
          title: 'Kids Room',
          subtitle:
              'Gentle phonics games, pet care, and fun beginner activities',
          tint: Color(0xFFFB923C),
        ),
        _ShowcaseHighlight(
          icon: LucideIcons.penTool,
          title: '100-Sticker Album',
          subtitle: 'Learn letter handwriting and collect milestone stickers',
          tint: Color(0xFFF59E0B),
        ),
      ],
    ),
    _ShowcaseSlide(
      title: 'Reports, Accents & Error Journal',
      subtitle:
          'Track your weekly progress, review past mistakes at your own pace, and tune your ear to global accents.',
      heroIcon: LucideIcons.barChart2,
      heroTag: 'PROGRESS & ACCENTS',
      gradientColors: [Color(0xFF10B981), Color(0xFF0D9488)],
      accentColor: AppColors.emerald500,
      highlights: [
        _ShowcaseHighlight(
          icon: LucideIcons.barChart2,
          title: 'Weekly Learning Reports',
          subtitle:
              'Clear charts showing your daily accuracy, streak, and study time',
          tint: Color(0xFF10B981),
        ),
        _ShowcaseHighlight(
          icon: LucideIcons.refreshCw,
          title: 'Review Mistake Journal',
          subtitle:
              'Replay and practice words and questions you missed earlier',
          tint: Color(0xFF14B8A6),
        ),
        _ShowcaseHighlight(
          icon: LucideIcons.globe,
          title: '6 World Accents',
          subtitle:
              'Practice listening to American, British, Australian, and Indian voices',
          tint: Color(0xFF059669),
        ),
      ],
    ),
  ];

  Future<void> _completeShowcase() async {
    if (_isCompleting) return;
    _isCompleting = true;
    di.sl<HapticService>().light();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        FirstTimeWelcomeShowcase.prefsKeyHasSeenShowcase,
        true,
      );
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _nextPage() {
    di.sl<HapticService>().selection();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeShowcase();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final slide = _slides[_currentPage];

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: 540.w,
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF11131E).withValues(alpha: 0.97)
                : Colors.white.withValues(alpha: 0.98),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: slide.accentColor.withValues(
                  alpha: isDark ? 0.12 : 0.08,
                ),
                blurRadius: 32.r,
                offset: Offset(0, -6.h),
              ),
            ],
          ),
          padding: EdgeInsets.only(top: 12.h, bottom: bottomInset + 16.h),
          child: Column(
            children: [
              // ── Top Drag Handle ──────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Center(
                  child: Container(
                    width: 38.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.22)
                          : Colors.black.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // ── Header Navigation Bar (Step Pill & Skip) ─────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Step Indicator Pill
                    Semantics(
                      label: context.tr(
                        'welcome_showcase.step_indicator',
                        fallback:
                            'Step ${_currentPage + 1} of ${_slides.length}',
                        args: ['${_currentPage + 1}', '${_slides.length}'],
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: EdgeInsets.symmetric(
                          horizontal: 11.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: slide.accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: slide.accentColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.sparkles,
                              size: 11.5.r,
                              color: slide.accentColor,
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              context.tr(
                                'welcome_showcase.step_indicator',
                                fallback:
                                    'Step ${_currentPage + 1} of ${_slides.length}',
                                args: [
                                  '${_currentPage + 1}',
                                  '${_slides.length}',
                                ],
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: slide.accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Skip Button
                    Semantics(
                      button: true,
                      label: context.tr(
                        'welcome_showcase.skip',
                        fallback: 'Skip',
                      ),
                      child: TextButton(
                        onPressed: _completeShowcase,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          minimumSize: Size(48.w, 48.h),
                        ),
                        child: Text(
                          context.tr('welcome_showcase.skip', fallback: 'Skip'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),

              // ── PageView Slide Carousel ──────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final item = _slides[index];
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 4.h),

                          // ── Modern Hero Badge (Zero Shadow, Liquid Accent Tint) ──
                          Container(
                            width: 72.r,
                            height: 72.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  item.accentColor.withValues(
                                    alpha: isDark ? 0.22 : 0.14,
                                  ),
                                  item.accentColor.withValues(
                                    alpha: isDark ? 0.10 : 0.05,
                                  ),
                                ],
                              ),
                              border: Border.all(
                                color: item.accentColor.withValues(
                                  alpha: isDark ? 0.35 : 0.22,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                item.heroIcon,
                                size: 32.r,
                                color: item.accentColor,
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),

                          // Hero Category Pill
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 3.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: item.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Text(
                              item.heroTag,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: item.accentColor,
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),

                          // Slide Title
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            softWrap: true,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18.5.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 6.h),

                          // Slide Subtitle
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            child: Text(
                              item.subtitle,
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.5.sp,
                                height: 1.4,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.slate600,
                              ),
                            ),
                          ),
                          SizedBox(height: 18.h),

                          // ── 3 Bento Feature Highlight Cards ────────────────
                          ...item.highlights.map(
                            (highlight) => Semantics(
                              container: true,
                              label:
                                  '${highlight.title}: ${highlight.subtitle}',
                              child: Container(
                                margin: EdgeInsets.only(bottom: 9.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 11.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF161928)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.black.withValues(alpha: 0.05),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    if (!isDark)
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.03,
                                        ),
                                        blurRadius: 8.r,
                                        offset: Offset(0, 2.h),
                                      ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Squircle Icon
                                    Container(
                                      width: 38.r,
                                      height: 38.r,
                                      decoration: BoxDecoration(
                                        color: highlight.tint.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          11.r,
                                        ),
                                      ),
                                      child: Icon(
                                        highlight.icon,
                                        size: 18.r,
                                        color: highlight.tint,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),

                                    // Feature Title & Subtitle
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            highlight.title,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 13.5.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ),
                                            softWrap: true,
                                          ),
                                          SizedBox(height: 3.h),
                                          Text(
                                            highlight.subtitle,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 11.5.sp,
                                              height: 1.35,
                                              color: isDark
                                                  ? Colors.white70
                                                  : AppColors.slate600,
                                            ),
                                            softWrap: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 6.w),

                                    // Trailing Accent Dot
                                    Container(
                                      width: 5.r,
                                      height: 5.r,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: highlight.tint.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 12.h),

              // ── Bottom Step Indicator & Primary CTA ──────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Smooth, continuous real-time reactive page indicator
                    AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, _) {
                        final double page =
                            _pageController.hasClients &&
                                _pageController.page != null
                            ? _pageController.page!
                            : _currentPage.toDouble();
                        final Color inactiveColor = isDark
                            ? Colors.white24
                            : Colors.black12;

                        return Semantics(
                          label:
                              'Step ${_currentPage + 1} of ${_slides.length}',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_slides.length, (i) {
                              final double distance = (page - i).abs();
                              final double factor = (1.0 - distance).clamp(
                                0.0,
                                1.0,
                              );
                              final double width = 8.w + (18.w * factor);
                              final Color dotColor = Color.lerp(
                                inactiveColor,
                                _slides[i].accentColor,
                                factor,
                              )!;

                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: 3.5.w),
                                width: width,
                                height: 6.h,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Modern 2026 Prominent Full-Width Tactile CTA
                    Semantics(
                      button: true,
                      label: _currentPage == _slides.length - 1
                          ? context.tr(
                              'welcome_showcase.start_exploring',
                              fallback: 'Start Exploring',
                            )
                          : context.tr(
                              'welcome_showcase.next_step',
                              fallback: 'Next',
                            ),
                      child: ScaleButton(
                        onTap: _nextPage,
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(minHeight: 52.h),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: slide.gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18.r),
                            boxShadow: [
                              BoxShadow(
                                color: slide.accentColor.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 18.r,
                                offset: Offset(0, 4.h),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _currentPage == _slides.length - 1
                                  ? context.tr(
                                      'welcome_showcase.start_exploring',
                                      fallback: 'Start Exploring',
                                    )
                                  : context.tr(
                                      'welcome_showcase.next_step',
                                      fallback: 'Next',
                                    ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
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
}
