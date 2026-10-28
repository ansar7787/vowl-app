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
    headline: 'Speak English With Confidence',
    subtitle:
        'Play interactive games that train your pronunciation and real-time conversation.',
    features: [
      _Feature(Icons.mic_rounded, 'Voice Practice'),
      _Feature(Icons.extension_rounded, 'Word Puzzles'),
      _Feature(Icons.forum_rounded, 'Daily Roleplay'),
    ],
  ),
  _Slide(
    headline: 'Turn the World Into Flashcards',
    subtitle:
        'Point your camera at real-world items or book pages to learn words anywhere.',
    features: [
      _Feature(Icons.photo_camera_rounded, 'Camera Scan'),
      _Feature(Icons.menu_book_rounded, 'Book Flashcards'),
      _Feature(Icons.public_off_rounded, 'Offline Mode'),
    ],
  ),
  _Slide(
    headline: 'Build an Unbreakable Habit',
    subtitle:
        'Earn daily streaks, unlock outfits for your buddy, and celebrate real progress.',
    features: [
      _Feature(Icons.shield_rounded, 'Streak Shields'),
      _Feature(Icons.checkroom_rounded, 'Outfits & Badges'),
      _Feature(Icons.auto_awesome_rounded, '100% Ad-Free'),
    ],
  ),
  _Slide(
    headline: 'Master Natural World Accents',
    subtitle:
        'Track your daily fluency growth and train your ear with authentic global voices.',
    features: [
      _Feature(Icons.bolt_rounded, 'Daily Streaks'),
      _Feature(Icons.autorenew_rounded, 'Spaced Memory'),
      _Feature(Icons.public_rounded, 'US & UK Voices'),
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
                      onPageSelect: _goTo,
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

class _SlidePage extends StatefulWidget {
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
  State<_SlidePage> createState() => _SlidePageState();
}

class _SlidePageState extends State<_SlidePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                  _TactileStage(
                    height: illH,
                    child: OnboardingIllustration(
                      index: widget.index,
                      entrance: widget.entrance,
                      ambient: widget.ambient,
                    ),
                  ),
                  const Spacer(flex: 3),
                  // Heading (1 line) + Subtitle lockup with standard 8dp spacing
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        header: true,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.slide.headline,
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
                        widget.slide.subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Gamified Tag Cloud: symmetrical 2-and-1 pyramid layout across ALL 4 slides
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: _FeaturePill(
                                feature: widget.slide.features[0],
                                ink: widget.slide.ink,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: _FeaturePill(
                                feature: widget.slide.features[1],
                                ink: widget.slide.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: _FeaturePill(
                                feature: widget.slide.features[2],
                                ink: widget.slide.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _TactileStage extends StatefulWidget {
  const _TactileStage({required this.height, required this.child});
  final double height;
  final Widget child;

  @override
  State<_TactileStage> createState() => _TactileStageState();
}

class _TactileStageState extends State<_TactileStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.96,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    _controller.forward().then((_) {
      if (mounted) _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: widget.child,
        ),
      ),
    );
  }
}

class _FeaturePill extends StatefulWidget {
  const _FeaturePill({required this.feature, required this.ink});
  final _Feature feature;
  final Color ink;

  @override
  State<_FeaturePill> createState() => _FeaturePillState();
}

class _FeaturePillState extends State<_FeaturePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.93,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  bool _selected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.selectionClick();
    setState(() {
      _selected = !_selected;
    });
    _controller.forward().then((_) {
      if (mounted) _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveInk = isDark ? AppColors.indigo400 : widget.ink;
    final scheme = theme.colorScheme;

    final unselectedBg = effectiveInk.withValues(alpha: isDark ? .16 : .08);
    final unselectedBorder = effectiveInk.withValues(alpha: isDark ? .30 : .18);

    return Semantics(
      button: true,
      selected: _selected,
      label:
          '${widget.feature.title}, ${_selected ? "selected" : "unselected"}',
      child: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _selected
                    ? const [AppColors.indigo600, AppColors.indigo500]
                    : [unselectedBg, unselectedBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selected ? Colors.transparent : unselectedBorder,
                width: 1.2,
              ),
              boxShadow: _selected
                  ? [
                      BoxShadow(
                        color: AppColors.indigo600.withValues(alpha: 0.32),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    _selected
                        ? Icons.check_circle_rounded
                        : widget.feature.icon,
                    key: ValueKey<bool>(_selected),
                    size: 15,
                    color: _selected ? Colors.white : effectiveInk,
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                        fontSize: 12.5,
                        fontWeight: _selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        letterSpacing: -0.1,
                        color: _selected ? Colors.white : scheme.onSurface,
                      ),
                      child: Text(
                        widget.feature.title,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    this.onPageSelect,
  });
  final int page, total;
  final _Slide slide;
  final bool isLast;
  final VoidCallback onPrimary;
  final ValueChanged<int>? onPageSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveInk = isDark ? AppColors.indigo400 : slide.ink;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Smooth expanding pill page indicator with interactive tap navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final isSelected = i == page;
              return GestureDetector(
                onTap: onPageSelect != null ? () => onPageSelect!(i) : null,
                behavior: HitTestBehavior.opaque,
                child: Semantics(
                  button: true,
                  label: 'Go to slide ${i + 1}',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      width: isSelected ? 26 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? effectiveInk
                            : effectiveInk.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
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
