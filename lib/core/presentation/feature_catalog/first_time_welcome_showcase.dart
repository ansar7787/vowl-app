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
      if (!hasSeen && context.mounted) {
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

  static const List<_ShowcaseSlide> _slides = [
    _ShowcaseSlide(
      title: '100+ Games Across 9 Pillars',
      subtitle:
          'From real-time Speech Recognition to Grammar Precision and dynamic Roleplay simulations.',
      heroIcon: LucideIcons.gamepad2,
      heroTag: '9 CORE PILLARS',
      gradientColors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      accentColor: AppColors.indigo500,
      highlights: [
        _ShowcaseHighlight(
          icon: LucideIcons.mic,
          title: 'Live Speech AI & Scoring',
          subtitle: 'Real-time phoneme pronunciation and pitch feedback',
          tint: Color(0xFF6366F1),
        ),
        _ShowcaseHighlight(
          icon: LucideIcons.sparkles,
          title: '19 Grammar Precision Drills',
          subtitle: 'Master tenses, syntax puzzles and vocabulary',
          tint: Color(0xFF8B5CF6),
        ),
        _ShowcaseHighlight(
          icon: LucideIcons.messageSquare,
          title: 'Immersive Real-World Roleplay',
          subtitle: 'Realistic conversational dialogues for jobs, travel & dining',
          tint: Color(0xFFA855F7),
        ),
      ],
    ),
    _ShowcaseSlide(
      title: 'AI Vision & 50+ Languages',
      subtitle:
          'Point your camera at real-world objects or printed text, and translate seamlessly without internet.',
      heroIcon: LucideIcons.camera,
      heroTag: 'ON-DEVICE VISION ML',
      gradientColors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
      accentColor: AppColors.blue500,
      highlights: [
        _ShowcaseHighlight(
          icon: LucideIcons.camera,
          title: 'Photo Vocab AI',
          subtitle: 'Instant real-world object recognition powered by vision ML',
          tint: Color(0xFF0EA5E9),
        ),
        _ShowcaseHighlight(
          icon: LucideIcons.scan,
          title: 'Scan & Learn OCR',
          subtitle: 'Turn any book page or document into interactive study quests',
          tint: Color(0xFF2563EB),
        ),
        _ShowcaseHighlight(
          icon: LucideIcons.languages,
          title: '50+ Languages Offline',
          subtitle: 'Neural sentence translation engine with zero data required',
          tint: Color(0xFF06B6D4),
        ),
      ],
    ),
    _ShowcaseSlide(
      title: 'Buddy Boutique & Kids World',
      subtitle:
          'Style your companion mascot, nurture your pet, and collect 100 stickers across 25 games.',
      heroIcon: LucideIcons.sparkles,
      heroTag: 'MASCOT & PET CARE',
      gradientColors: [Color(0xFFF43F5E), Color(0xFFFB923C)],
      accentColor: AppColors.rose500,
      highlights: [
        _ShowcaseHighlight(
          icon: LucideIcons.shirt,
          title: 'Buddy Boutique & Outfits',
          subtitle: 'Unlock skins, hats, glasses and animated accessories',
          tint: Color(0xFFF43F5E),
        ),
        _ShowcaseHighlight(
          icon: LucideIcons.baby,
          title: 'Kids Learning Room',
          subtitle: 'Child-safe phonics drills, pet care & happiness boosters',
          tint: Color(0xFFFB923C),
        ),
        _ShowcaseHighlight(
          icon: LucideIcons.penTool,
          title: '100-Sticker Collector Album',
          subtitle: 'Finger handwriting guide and collectible sticker milestones',
          tint: Color(0xFFF59E0B),
        ),
      ],
    ),
    _ShowcaseSlide(
      title: 'Reports, Accents & Error Journal',
      subtitle:
          'Track accuracy curves, conquer your mistakes with spaced recall, and tune your ear to world accents.',
      heroIcon: LucideIcons.barChart2,
      heroTag: 'PRECISION MASTERY',
      gradientColors: [Color(0xFF10B981), Color(0xFF0D9488)],
      accentColor: AppColors.emerald500,
      highlights: [
        _ShowcaseHighlight(
          icon: LucideIcons.barChart2,
          title: 'Weekly Learning Reports',
          subtitle: 'In-depth accuracy radar and personal progress analytics',
          tint: Color(0xFF10B981),
        ),
        _ShowcaseHighlight(
          icon: LucideIcons.refreshCw,
          title: 'Spaced Error Journal',
          subtitle: 'Replay and master missed questions until 100% confidence',
          tint: Color(0xFF14B8A6),
        ),
        _ShowcaseHighlight(
          icon: LucideIcons.globe,
          title: '6 World Accents',
          subtitle: 'Native American, British (IELTS), Australian & Indian accents',
          tint: Color(0xFF059669),
        ),
      ],
    ),
  ];

  Future<void> _completeShowcase() async {
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
          constraints: BoxConstraints(
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
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 12.h,
            bottom: bottomInset + 16.h,
          ),
          child: Column(
            children: [
              // ── Top Drag Handle ──────────────────────────────────────────
              Center(
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
              SizedBox(height: 14.h),

              // ── Header Navigation Bar (Step Pill & Skip) ─────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Step Indicator Pill
                  AnimatedContainer(
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
                          'Step ${_currentPage + 1} of ${_slides.length}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: slide.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Skip Button
                  TextButton(
                    onPressed: _completeShowcase,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      minimumSize: Size(44.w, 30.h),
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
                ],
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 4.h),

                          // ── Hero 3D Badge / Portal ─────────────────────────
                          Container(
                            width: 84.r,
                            height: 84.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: item.gradientColors,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: item.accentColor.withValues(
                                    alpha: 0.38,
                                  ),
                                  blurRadius: 24.r,
                                  offset: Offset(0, 6.h),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 70.r,
                                height: 70.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    item.heroIcon,
                                    size: 34.r,
                                    color: Colors.white,
                                  ),
                                ),
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
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: item.accentColor,
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),

                          // Slide Title
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 19.5.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 6.h),

                          // Slide Subtitle
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Text(
                              item.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                height: 1.35,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ),
                          SizedBox(height: 18.h),

                          // ── 3 Bento Feature Highlight Cards ────────────────
                          ...item.highlights.map(
                            (highlight) => Container(
                              margin: EdgeInsets.only(bottom: 9.h),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
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
                                    width: 36.r,
                                    height: 36.r,
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
                                      size: 17.5.r,
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
                                            fontSize: 12.5.sp,
                                            fontWeight: FontWeight.w800,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          highlight.subtitle,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 10.5.sp,
                                            color: isDark
                                                ? Colors.white54
                                                : AppColors.slate500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                        ],
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 12.h),

              // ── Bottom Step Indicator & Primary CTA ──────────────────────
              Row(
                children: [
                  // Modern Capsule Indicators
                  Row(
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        margin: EdgeInsets.only(right: 6.w),
                        width: _currentPage == i ? 24.w : 6.w,
                        height: 6.h,
                        decoration: BoxDecoration(
                          gradient: _currentPage == i
                              ? LinearGradient(colors: slide.gradientColors)
                              : null,
                          color: _currentPage == i
                              ? null
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Primary CTA Button
                  ScaleButton(
                    onTap: _nextPage,
                    child: Container(
                      height: 46.h,
                      padding: EdgeInsets.symmetric(horizontal: 22.w),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: slide.gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: slide.accentColor.withValues(alpha: 0.35),
                            blurRadius: 14.r,
                            offset: Offset(0, 3.h),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _slides.length - 1
                                ? 'Start Exploring'
                                : 'Continue',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Icon(
                            _currentPage == _slides.length - 1
                                ? LucideIcons.sparkles
                                : LucideIcons.arrowRight,
                            size: 15.r,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
