import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// Model defining a slide in the welcome showcase.
class _ShowcaseSlide {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<String> highlights;

  const _ShowcaseSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.highlights,
  });
}

/// Full-screen or modal welcome showcase presenting the complete Vowl ecosystem.
class FirstTimeWelcomeShowcase extends StatefulWidget {
  const FirstTimeWelcomeShowcase({super.key});

  static const String prefsKeyHasSeenShowcase = 'has_seen_vowl_welcome_showcase';

  /// Evaluates if the user is seeing the app for the first time and presents showcase.
  static Future<void> checkAndShow(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool(prefsKeyHasSeenShowcase) ?? false;
      if (!hasSeen && context.mounted) {
        await show(context);
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
          'From real-time Speech Recognition and Audio Comprehension to Grammar Precision & Immersive Roleplay.',
      icon: LucideIcons.gamepad2,
      accentColor: AppColors.indigo500,
      highlights: [
        '10 Speaking Quests with Live Mic Scoring',
        '19 Grammar Challenges & Tense Drills',
        'Real-World Roleplays: Job, Travel & Dining',
      ],
    ),
    _ShowcaseSlide(
      title: 'AI Vision & 50+ Languages',
      subtitle:
          'Point your camera at real-world objects or book pages, and translate instantly without needing internet.',
      icon: LucideIcons.sparkles,
      accentColor: AppColors.blue500,
      highlights: [
        'Photo Vocab: Instant Object Identification',
        'Scan & Learn: Document & Book Page OCR',
        '50+ Languages Offline Neural Translator',
      ],
    ),
    _ShowcaseSlide(
      title: 'Buddy Boutique & Kids World',
      subtitle:
          'Evolve your pet, customize outfits, explore the Kids Room and collect 100 stickers across 25 games.',
      icon: LucideIcons.baby,
      accentColor: AppColors.rose500,
      highlights: [
        'Buddy Boutique: Outfits, Hats & Accessories',
        'Kids Room: Interactive Pet Care & Decor',
        'Finger Handwriting & 100-Sticker Collector Book',
      ],
    ),
    _ShowcaseSlide(
      title: 'Reports, Accents & Error Journal',
      subtitle:
          'Track weekly accuracy with Learning Reports, replay missed questions in the Error Journal, and master world accents.',
      icon: LucideIcons.barChart2,
      accentColor: AppColors.emerald500,
      highlights: [
        'Learning Report: Weekly Accuracy & Stats',
        'Review & Master: Spaced Repetition Error Journal',
        '6 World Accents: British (IELTS), US, AU & IN',
      ],
    ),
  ];

  Future<void> _completeShowcase() async {
    di.sl<HapticService>().light();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(FirstTimeWelcomeShowcase.prefsKeyHasSeenShowcase, true);
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _nextPage() {
    di.sl<HapticService>().light();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
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
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF13141C).withValues(alpha: 0.96)
                : Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
            top: 14.h,
            bottom: bottomInset + 20.h,
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Top Bar with Skip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: slide.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(slide.icon, size: 12.r, color: slide.accentColor),
                        SizedBox(width: 5.w),
                        Text(
                          'Step ${_currentPage + 1} of ${_slides.length}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: slide.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _completeShowcase,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size(44.w, 30.h),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Page View Slides
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
                          // Large Accent Icon Container
                          Container(
                            width: 64.r,
                            height: 64.r,
                            decoration: BoxDecoration(
                              color: item.accentColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: item.accentColor.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              item.icon,
                              size: 30.r,
                              color: item.accentColor,
                            ),
                          ),
                          SizedBox(height: 18.h),

                          // Title
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 8.h),

                          // Subtitle
                          Text(
                            item.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              height: 1.35,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // Highlight Pills
                          ...item.highlights.map(
                            (highlight) => Container(
                              margin: EdgeInsets.only(bottom: 8.h),
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1A1C26)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20.r,
                                    height: 20.r,
                                    decoration: BoxDecoration(
                                      color: item.accentColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      LucideIcons.check,
                                      size: 11.r,
                                      color: item.accentColor,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      highlight,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.5.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.onSurface,
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

              // Page Indicators & Next / Start Button
              Row(
                children: [
                  // Smooth Dots
                  Row(
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(right: 6.w),
                        width: _currentPage == i ? 20.w : 6.w,
                        height: 6.h,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? slide.accentColor
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Primary CTA Button
                  ScaleButton(
                    onTap: _nextPage,
                    child: Container(
                      height: 44.h,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: slide.accentColor,
                        borderRadius: BorderRadius.circular(12.r),
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
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Icon(
                            LucideIcons.arrowRight,
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

