import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

import 'onboarding_illustrations.dart';

/// Four-slide onboarding.
///
/// Designed to fit 100% of the screen height on standard viewports, with a
/// sliver/scrollable fallback for smaller screens or larger accessibility text.
/// Uses [ValueNotifier] for reactive updates instead of [setState] for maximum frame rate.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onSkip,
    required this.onGetStarted,
    this.onLogin,
  });

  /// "Skip" – go to wherever your current onboarding Skip goes.
  final VoidCallback onSkip;

  /// "Get Started" on slide 4.
  final VoidCallback onGetStarted;

  /// Optional callback for login route (kept for API compatibility).
  final VoidCallback? onLogin;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

// ── content ────────────────────────────────────────────────────────────────

class _Feature {
  const _Feature(this.icon, this.title);
  final IconData icon;
  final String title;
}

class _Slide {
  const _Slide({
    required this.headline,
    required this.subtitle,
    required this.features,
  });
  final String headline, subtitle;
  final List<_Feature> features;

  /// Signature Vowl primary Indigo brand gradient for all slides.
  List<Color> get buttonGradient => const [
    AppColors.indigo600,
    AppColors.indigo500,
  ];

  /// Brand accent for interactive elements and highlights.
  Color get ink => AppColors.indigo600;
}

const _slides = <_Slide>[
  _Slide(
    headline: 'Learn English Through Games',
    subtitle:
        'Practice speaking into the mic and master grammar with 100+ fun games.',
    features: [
      _Feature(Icons.mic_rounded, 'Speech Practice'),
      _Feature(Icons.extension_rounded, 'Grammar Puzzles'),
      _Feature(Icons.forum_rounded, 'Roleplay Dialogues'),
    ],
  ),
  _Slide(
    headline: 'Learn From What You See',
    subtitle:
        'Scan objects and book pages to build your vocabulary, even without internet.',
    features: [
      _Feature(Icons.photo_camera_rounded, 'Object Recognition'),
      _Feature(Icons.document_scanner_rounded, 'Book & Text Scanner'),
      _Feature(Icons.translate_rounded, 'Offline Dictionary & Translator'),
    ],
  ),
  _Slide(
    headline: 'Stay Motivated Every Day',
    subtitle:
        'Collect milestone stickers, dress up your companion, and celebrate daily streaks.',
    features: [
      _Feature(Icons.checkroom_rounded, 'Companion Outfits & Hats'),
      _Feature(Icons.collections_bookmark_rounded, 'Sticker Rewards Album'),
      _Feature(Icons.shield_rounded, 'Safe, Ad-Free Learning'),
    ],
  ),
  _Slide(
    headline: 'Track Progress & Accents',
    subtitle:
        'Follow your learning streak and train your ear with authentic world accents.',
    features: [
      _Feature(Icons.insights_rounded, 'Daily Streaks & XP Analytics'),
      _Feature(Icons.menu_book_rounded, 'Smart Spaced Repetition'),
      _Feature(Icons.public_rounded, 'Authentic Global Accents'),
    ],
  ),
];

// ── screen state ───────────────────────────────────────────────────────────

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _pages = PageController();

  /// Exactly two controllers for the whole screen, however many slides:
  /// one-shot entrance for the active slide + one shared ambient loop.
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  /// Value notifier driving reactive updates (zero setState calls).
  final ValueNotifier<int> _pageNotifier = ValueNotifier<int>(0);

  bool _animating = false; // guards rapid Continue taps
  bool _leaving = false; // guards double navigation
  bool _reduceMotion = false;
  bool _foreground = true;
  Timer? _leaveTimer;

  static const List<List<String>> _slideLayers = [
    [
      'assets/illustrations/onb_speech_base.svg',
      'assets/illustrations/onb_speech_mic.svg',
      'assets/illustrations/onb_speech_bubbleA.svg',
      'assets/illustrations/onb_speech_bubbleB.svg',
      'assets/illustrations/onb_speech_puzzle.svg',
      'assets/illustrations/onb_speech_tile.svg',
    ],
    [
      'assets/illustrations/onb_scan_base.svg',
      'assets/illustrations/onb_scan_phone.svg',
      'assets/illustrations/onb_scan_book.svg',
      'assets/illustrations/onb_scan_cardPlant.svg',
      'assets/illustrations/onb_scan_chipOffline.svg',
      'assets/illustrations/onb_scan_chipLangs.svg',
    ],
    [
      'assets/illustrations/onb_rewards_base.svg',
      'assets/illustrations/onb_rewards_album.svg',
      'assets/illustrations/onb_rewards_hat.svg',
      'assets/illustrations/onb_rewards_glasses.svg',
      'assets/illustrations/onb_rewards_medal.svg',
      'assets/illustrations/onb_rewards_gift.svg',
    ],
    [
      'assets/illustrations/onb_progress_base.svg',
      'assets/illustrations/onb_progress_card.svg',
      'assets/illustrations/onb_progress_globe.svg',
      'assets/illustrations/onb_progress_chip1.svg',
      'assets/illustrations/onb_progress_chip2.svg',
      'assets/illustrations/onb_progress_chip3.svg',
      'assets/illustrations/onb_progress_waves.svg',
    ],
  ];

  final Set<int> _warmedSlides = {};

  void _preWarmSlide(int index) {
    if (index < 0 ||
        index >= _slideLayers.length ||
        _warmedSlides.contains(index)) {
      return;
    }
    _warmedSlides.add(index);
    for (final path in _slideLayers[index]) {
      try {
        final loader = SvgAssetLoader(path);
        vg.loadPicture(loader, null, onError: (e, stack) {});
      } catch (_) {}
    }
    if (index == 3 && mounted) {
      try {
        precacheImage(const AssetImage(kVowlyHead), context);
      } catch (_) {}
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preWarmSlide(0);
    _preWarmSlide(1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.shouldReduceMotion(context);
    _syncMotion();
    _preWarmSlide(0);
    _preWarmSlide(1);
  }

  void _syncMotion() {
    if (_reduceMotion) {
      _ambient.stop();
      _entrance.value = 1;
      return;
    }
    if (_foreground && !_ambient.isAnimating) _ambient.repeat();
    if (!_entrance.isAnimating && _entrance.value == 0) _entrance.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _syncMotion();
    } else {
      _ambient.stop(); // no ticking while backgrounded
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _leaveTimer?.cancel();
    _pages.dispose();
    _entrance.dispose();
    _ambient.dispose();
    _pageNotifier.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    _pageNotifier.value = i;
    HapticFeedback.selectionClick();
    if (!_reduceMotion) _entrance.forward(from: 0);
    _preWarmSlide(i + 1);
  }

  Future<void> _goTo(int page) async {
    if (_animating || page < 0 || page >= _slides.length) return;
    _animating = true;
    try {
      await _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } finally {
      _animating = false;
    }
  }

  void _next() {
    final currentPage = _pageNotifier.value;
    if (currentPage >= _slides.length - 1) {
      _leave(widget.onGetStarted);
    } else {
      _goTo(currentPage + 1);
    }
  }

  void _leave(VoidCallback destination) {
    if (_leaving) return;
    _leaving = true;
    destination();
    // Re-arm in case the destination was pushed (not replaced) and we return.
    _leaveTimer?.cancel();
    _leaveTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) _leaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.slate900 : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: bg,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          final currentPage = _pageNotifier.value;
          if (currentPage > 0) {
            _goTo(currentPage - 1); // back steps through slides first
          } else {
            _leave(widget.onSkip);
          }
        },
        child: Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: ValueListenableBuilder<int>(
              valueListenable: _pageNotifier,
              builder: (context, currentPage, _) {
                final slide = _slides[currentPage];
                final isLast = currentPage == _slides.length - 1;

                return Column(
                  children: [
                    _Header(
                      page: currentPage,
                      total: _slides.length,
                      ink: slide.ink,
                      onSkip: () => _leave(widget.onSkip),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pages,
                        itemCount: _slides.length,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, i) {
                          final active = i == currentPage;
                          return _SlidePage(
                            index: i,
                            slide: _slides[i],
                            entrance: _reduceMotion
                                ? kAlwaysCompleteAnimation
                                : (active
                                      ? _entrance
                                      : kAlwaysDismissedAnimation),
                            // Inactive pages stay still → only one scene animates.
                            ambient: active
                                ? _ambient
                                : kAlwaysDismissedAnimation,
                          );
                        },
                      ),
                    ),
                    _BottomBar(
                      page: currentPage,
                      total: _slides.length,
                      slide: slide,
                      isLast: isLast,
                      onPrimary: _next,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── pieces ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.page,
    required this.total,
    required this.ink,
    required this.onSkip,
  });
  final int page, total;
  final Color ink;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveInk = isDark ? AppColors.indigo400 : ink;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            label: 'Step ${page + 1} of $total',
            excludeSemantics: true,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: effectiveInk.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: effectiveInk.withValues(alpha: .25),
                  width: 1,
                ),
              ),
              child: Text(
                '${page + 1} of $total',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: effectiveInk,
                ),
              ),
            ),
          ),
          ScaleButton(
            onTap: onSkip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              alignment: Alignment.center,
              child: Text(
                'Skip',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  const _SlidePage({
    required this.index,
    required this.slide,
    required this.entrance,
    required this.ambient,
  });
  final int index;
  final _Slide slide;
  final Animation<double> entrance, ambient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, c) {
        // Dynamic illustration height: scales with viewport height (healthy hero proportion)
        final illH = (c.maxHeight * 0.40).clamp(150.0, 260.0);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  SizedBox(
                    height: illH,
                    child: OnboardingIllustration(
                      index: index,
                      entrance: entrance,
                      ambient: ambient,
                    ),
                  ),
                  const Spacer(flex: 3),
                  // Heading (1 line) + Subtitle (max 2 lines) lockup with standard 8dp spacing
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        header: true,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            slide.headline,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              letterSpacing: -0.3,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        slide.subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 3),
                  // Clean, centered 1-line feature block (visually aligned with screen center)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 290),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < slide.features.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i < slide.features.length - 1 ? 10 : 0,
                              ),
                              child: _FeatureRow(
                                feature: slide.features[i],
                                ink: slide.ink,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature, required this.ink});
  final _Feature feature;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveInk = isDark ? AppColors.indigo400 : ink;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: effectiveInk.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: effectiveInk.withValues(alpha: .14),
              width: 1,
            ),
          ),
          child: Icon(feature.icon, size: 17, color: effectiveInk),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              feature.title,
              maxLines: 1,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.page,
    required this.total,
    required this.slide,
    required this.isLast,
    required this.onPrimary,
  });
  final int page, total;
  final _Slide slide;
  final bool isLast;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveInk = isDark ? AppColors.indigo400 : slide.ink;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Smooth expanding pill page indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final isSelected = i == page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isSelected ? 26 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isSelected
                      ? effectiveInk
                      : effectiveInk.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ScaleButton(
                onTap: onPrimary,
                scaleDown: 0.97,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: slide.buttonGradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: slide.buttonGradient.last.withValues(
                          alpha: 0.32,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isLast ? 'Get Started' : 'Continue',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
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
