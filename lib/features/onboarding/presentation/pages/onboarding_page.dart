import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/feature_catalog/vowl_showcase_catalog.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/onboarding_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/onboarding/presentation/widgets/onboarding_hero_illustrations.dart';

/// Production-grade full-screen onboarding experience presenting Vowl's core ecosystem.
///
/// Designed to provide maximum brand immersion, eliminate accidental flick dismissals,
/// and ensure a smooth, zero-latency transition into login/home.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isNavigating = false;

  static const List<ShowcaseSlide> _slides = VowlShowcaseCatalog.slides;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_currentPage != index) {
      setState(() => _currentPage = index);
      try {
        di.sl<HapticService>().selection();
      } catch (_) {}
    }
  }

  Future<void> _completeAndNavigate() async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      di.sl<HapticService>().light();
    } catch (_) {}

    await OnboardingService.completeOnboarding();

    if (!mounted) return;

    // Check if the user is already authenticated
    final isAuthenticated = di.sl.isRegistered<AuthBloc>() &&
        di.sl<AuthBloc>().state.status == AuthStatus.authenticated;

    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return;
      }
      if (isAuthenticated) {
        context.go(AppRouter.homeRoute);
      } else {
        context.go(AppRouter.loginRoute);
      }
    } catch (_) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      try {
        di.sl<HapticService>().selection();
      } catch (_) {}
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeAndNavigate();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      try {
        di.sl<HapticService>().selection();
      } catch (_) {}
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentSlide = _slides[_currentPage];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentPage > 0) {
          _previousPage();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          _completeAndNavigate();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        child: Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        currentSlide.accentColor.withValues(alpha: 0.16),
                        const Color(0xFF0B0F19),
                        const Color(0xFF090D16),
                      ]
                    : [
                        currentSlide.accentColor.withValues(alpha: 0.08),
                        Colors.white,
                        const Color(0xFFF8FAFC),
                      ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 580.w),
                  child: Column(
                    children: [
                      // ── Top Bar (Step Indicator & Skip) ───────────────────
                      _buildHeader(context, isDark, currentSlide),

                      // ── Middle Carousel (Illustrations + Highlights) ──────
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _slides.length,
                          onPageChanged: _onPageChanged,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return _buildSlideContent(context, _slides[index], index, isDark);
                          },
                        ),
                      ),

                      // ── Bottom Dock (Dots, CTA, Login link) ───────────────
                      _buildBottomDock(context, isDark, currentSlide),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isDark, ShowcaseSlide slide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Step Indicator Pill
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: slide.accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: slide.accentColor.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.sparkles,
                  size: 13.r,
                  color: slide.accentColor,
                ),
                SizedBox(width: 6.w),
                Text(
                  context.tr(
                    'onboarding.step_indicator',
                    fallback: 'Step ${_currentPage + 1} of ${_slides.length}',
                    args: ['${_currentPage + 1}', '${_slides.length}'],
                  ),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: slide.accentColor,
                  ),
                ),
              ],
            ),
          ),

          // Skip Button
          ScaleButton(
            onTap: _completeAndNavigate,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              child: Text(
                context.tr('onboarding.skip', fallback: 'Skip'),
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : AppColors.slate500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Slide Content ─────────────────────────────────────────────────────────
  Widget _buildSlideContent(
    BuildContext context,
    ShowcaseSlide slide,
    int index,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          SizedBox(height: 8.h),

          // Hero Illustration Container
          _buildHeroIllustration(index),

          SizedBox(height: 18.h),

          // Slide Category Tag Pill
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: slide.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              slide.heroTag,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: slide.accentColor,
              ),
            ),
          ),

          SizedBox(height: 10.h),

          // Main Headline
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),

          SizedBox(height: 8.h),

          // Subtitle Value Proposition
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: isDark ? AppColors.slate400 : AppColors.slate600,
            ),
          ),

          SizedBox(height: 20.h),

          // 3 Feature Highlights
          ...slide.highlights.map(
            (highlight) => _buildHighlightRow(highlight, isDark),
          ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  // ── Dynamic Hero Illustration Dispatcher ──────────────────────────────────
  Widget _buildHeroIllustration(int index) {
    return switch (index) {
      0 => const OnboardingSpeechHero(),
      1 => const OnboardingCameraHero(),
      2 => const OnboardingBuddyHero(),
      3 => const OnboardingProgressHero(),
      _ => const OnboardingSpeechHero(),
    };
  }

  // ── Highlight Bullet Row ──────────────────────────────────────────────────
  Widget _buildHighlightRow(ShowcaseHighlight highlight, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
              color: highlight.tint.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              highlight.icon,
              size: 15.r,
              color: highlight.tint,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight.title,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  highlight.subtitle,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w400,
                    color: isDark ? AppColors.slate400 : AppColors.slate600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Dock (Dots, CTA Button & Login Link) ───────────────────────────
  Widget _buildBottomDock(BuildContext context, bool isDark, ShowcaseSlide slide) {
    final isLastSlide = _currentPage == _slides.length - 1;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF090D16).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final isSelected = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                width: isSelected ? 26.w : 7.w,
                height: 7.h,
                decoration: BoxDecoration(
                  color: isSelected
                      ? slide.accentColor
                      : (isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              );
            }),
          ),

          SizedBox(height: 16.h),

          // Primary CTA Button ("Continue" / "Get Started")
          ScaleButton(
            onTap: _nextPage,
            child: Container(
              width: double.infinity,
              height: 52.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: slide.gradientColors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: slide.accentColor.withValues(alpha: 0.35),
                    blurRadius: 18.r,
                    offset: Offset(0, 5.h),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLastSlide
                          ? context.tr('onboarding.get_started', fallback: 'Get Started')
                          : context.tr('onboarding.continue', fallback: 'Continue'),
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      isLastSlide ? LucideIcons.sparkles : LucideIcons.arrowRight,
                      size: 17.r,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 10.h),

          // Secondary Link ("Already have an account? Log In")
          ScaleButton(
            onTap: _completeAndNavigate,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: RichText(
                text: TextSpan(
                  text: context.tr('onboarding.have_account', fallback: 'Already have an account? '),
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    color: isDark ? Colors.white60 : AppColors.slate500,
                  ),
                  children: [
                    TextSpan(
                      text: context.tr('onboarding.log_in', fallback: 'Log In'),
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: slide.accentColor,
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
  }
}
