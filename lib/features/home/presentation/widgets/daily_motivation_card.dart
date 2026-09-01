import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';

/// Lifecycle of the daily hoot content, kept distinct from the text
/// itself so the UI can tell "still loading" apart from "loaded, but
/// nothing was configured for today" without inspecting strings.
enum _HootStatus { loading, ready, fallback }

/// Design tokens for this card. Pulling these out of the widget tree
/// makes the few genuinely brand-specific colors easy to audit and
/// keeps the build method focused on layout rather than hex values.
class _VowlCardPalette {
  // NOTE: #6366F1 measures ~4.47:1 against white, just under the 4.5:1
  // WCAG AA threshold for normal-weight text under 18pt/24px (see the
  // design write-up for the full contrast table). It's kept here for
  // backgrounds, icons, and the badge border, where 3:1 is sufficient.
  // For the eyebrow label and CTA text we use [textSafeIndigo], which
  // clears AA with real margin.
  static const Color indigo = Color(0xFF6366F1);
  static const Color textSafeIndigo = Color(0xFF4F46E5); // ~6.3:1 on white
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkSecondaryText = Color(0xFF94A3B8);
  static const Color lightSecondaryText = Color(0xFF64748B);
  static const Color lightSurfaceAlt = Color(0xFFF8FAFC);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberDarkText = Color(0xFFFBBF24);
  static const Color amberLightText = Color(0xFFD97706);
  static const Color amberDarkBg = Color(0xFF332000);
  static const Color amberLightBg = Color(0xFFFFF7ED);

  // Streak milestone tiers: at 7/30/100+ days the badge shifts to a
  // slightly richer tone so long streaks read as more valuable without
  // introducing a whole new color language.
  static Color streakTextFor(int streak, bool isDark) {
    if (streak >= 100) {
      return isDark ? const Color(0xFFFFD700) : const Color(0xFFB45309);
    }
    if (streak >= 30) {
      return isDark ? const Color(0xFFFCD34D) : const Color(0xFFC2740A);
    }
    return isDark ? amberDarkText : amberLightText;
  }
}

class DailyMotivationCard extends StatefulWidget {
  final int streakCount;

  const DailyMotivationCard({super.key, required this.streakCount});

  @override
  State<DailyMotivationCard> createState() => _DailyMotivationCardState();
}

class _DailyMotivationCardState extends State<DailyMotivationCard>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<String?> _hootTitle = ValueNotifier(null);
  final ValueNotifier<String?> _hootText = ValueNotifier(null);
  final ValueNotifier<_HootStatus> _status = ValueNotifier(_HootStatus.loading);

  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  final ValueNotifier<bool> _pressed = ValueNotifier(false);

  static const String _fallbackQuote =
      "Small steps today make fluent conversations tomorrow.";
  static const String _fallbackTitle = "Daily Wisdom";

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_fadeIn);
    _loadDailyHoot();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _hootTitle.dispose();
    _hootText.dispose();
    _status.dispose();
    _pressed.dispose();
    super.dispose();
  }

  /// Resolves which message index to show for [date] out of
  /// [messageCount] entries. Pure and unit-testable on purpose.
  ///
  /// The previous implementation indexed by day-*of-year* modulo the
  /// message count. Day-of-year resets to 1 every January 1st, so for
  /// any fixed calendar day the same index was produced *every single
  /// year* (Jan 1 always mapped to index 1; most other dates only ever
  /// shifted by the one day a leap year adds). With 100 messages per
  /// month, that meant the "hundred unique messages" pool was never
  /// actually reached — most days repeated the same message annually.
  ///
  /// This version indexes by day-*of-month* and shifts the starting
  /// offset by 31 for every calendar year. Since gcd(31, 100) == 1,
  /// the mapping for any fixed day-of-month walks through the entire
  /// 100-message pool before repeating — a ~100 year period instead of
  /// repeating the very next year.
  @visibleForTesting
  static int resolveMessageIndex(DateTime date, int messageCount) {
    if (messageCount <= 0) return 0;
    final int dayOfMonth = date.day - 1; // 0-based
    return (date.year * 31 + dayOfMonth) % messageCount;
  }

  Future<void> _loadDailyHoot() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/curriculum/calendar/vowl_calendar.json',
      );
      final Map<String, dynamic> data = json.decode(jsonString);

      final now = DateTime.now();
      final String dateKey = DateFormat('MM-dd').format(now);
      final String specificKey = DateFormat('yyyy-MM-dd').format(now);

      String? title;
      String? text;

      if (data['specific']?[specificKey] != null) {
        title = data['specific'][specificKey]['title'] as String?;
        text = data['specific'][specificKey]['text'] as String?;
      } else if (data['annual']?[dateKey] != null) {
        title = data['annual'][dateKey]['title'] as String?;
        text = data['annual'][dateKey]['text'] as String?;
      } else if (data['monthly'] != null) {
        final String monthKey = DateFormat('MM').format(now);
        final monthData = data['monthly'][monthKey];
        if (monthData != null) {
          title = monthData['theme'] as String?;
          final List<dynamic> messages = monthData['messages'] ?? [];
          if (messages.isNotEmpty) {
            final index = resolveMessageIndex(now, messages.length);
            text = messages[index] as String;
          }
        }
      }

      if (!mounted) return;
      final bool foundNothing = title == null && text == null;
      _hootTitle.value = title ?? _fallbackTitle;
      _hootText.value = (text == null || text.isEmpty) ? _fallbackQuote : text;
      _status.value = foundNothing ? _HootStatus.fallback : _HootStatus.ready;
      _entranceController.forward();
    } catch (e, stack) {
      // Surfaced for debugging rather than swallowed silently — a
      // malformed asset should be visible in logs, even though the
      // user still sees a graceful fallback quote either way.
      debugPrint(
        'DailyMotivationCard: failed to load hoot content: $e\n$stack',
      );
      if (!mounted) return;
      _hootTitle.value = _fallbackTitle;
      _hootText.value = _fallbackQuote;
      _status.value = _HootStatus.fallback;
      _entranceController.forward();
    }
  }

  void _handleNavigation() {
    HapticFeedback.lightImpact();
    final title = _hootTitle.value?.toLowerCase() ?? '';
    String route = AppRouter.libraryRoute;

    if (title.contains('vocabulary') || title.contains('word')) {
      route = '${AppRouter.categoryGamesRoute}?category=vocabulary';
    } else if (title.contains('grammar')) {
      route = '${AppRouter.categoryGamesRoute}?category=grammar';
    } else if (title.contains('reading')) {
      route = '${AppRouter.categoryGamesRoute}?category=reading';
    } else if (title.contains('writing')) {
      route = '${AppRouter.categoryGamesRoute}?category=writing';
    } else if (title.contains('speaking') || title.contains('speak')) {
      route = '${AppRouter.categoryGamesRoute}?category=speaking';
    } else if (title.contains('listening') || title.contains('listen')) {
      route = '${AppRouter.categoryGamesRoute}?category=listening';
    } else if (title.contains('accent') || title.contains('pronunciation')) {
      route = '${AppRouter.categoryGamesRoute}?category=accent';
    } else if (title.contains('roleplay') || title.contains('conversation')) {
      route = '${AppRouter.categoryGamesRoute}?category=roleplay';
    }

    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_hootTitle, _hootText, _status, _pressed]),
      builder: (context, _) {
        final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final dateString = DateFormat('EEEE, d MMM', locale).format(now);

    final card = Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32.r),
        color: isDark ? _VowlCardPalette.darkCard : Colors.white,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: _VowlCardPalette.indigo.withValues(alpha: 0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : _VowlCardPalette.indigo.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30.w,
            top: -20.h,
            child: Icon(
              Icons.format_quote_rounded,
              size: 180.r,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : _VowlCardPalette.indigo.withValues(alpha: 0.04),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.transparent,
                    _VowlCardPalette.indigo.withValues(
                      alpha: isDark ? 0.05 : 0.02,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 52.r,
                      height: 52.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : _VowlCardPalette.lightSurfaceAlt,
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: VowlMascot(
                          size: 38.r,
                          useFloatingAnimation: false,
                          state: VowlMascotState.happy,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_hootTitle.value ??
                                    context.tr(
                                      'home.daily_wisdom',
                                      fallback: 'DAILY WISDOM',
                                    ))
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Outfit',
                              letterSpacing: 1.8,
                              // textSafeIndigo, not the raw brand indigo:
                              // this label sits right at AA's small-text
                              // threshold and this shade clears it cleanly.
                              color: _VowlCardPalette.textSafeIndigo,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            dateString,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Outfit',
                              color: isDark
                                  ? _VowlCardPalette.darkSecondaryText
                                  : _VowlCardPalette.lightSecondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _StreakBadge(
                      streakCount: widget.streakCount,
                      isDark: isDark,
                    ),
                  ],
                ),
                SizedBox(height: 28.h),
                _status.value == _HootStatus.loading
                    ? _buildShimmerQuote(isDark)
                    : FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: _slideIn,
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              "${_hootText.value}",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Outfit',
                                height: 1.5,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                      ),
                SizedBox(height: 32.h),
                GestureDetector(
                  onTap: _handleNavigation,
                  onTapDown: (_) => _pressed.value = true,
                  onTapUp: (_) => _pressed.value = false,
                  onTapCancel: () => _pressed.value = false,
                  child: AnimatedScale(
                    scale: _pressed.value ? 0.96 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: _VowlCardPalette.indigo,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: _VowlCardPalette.indigo.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.tr(
                              'home.start_next_task',
                              fallback: 'Start Next Task',
                            ),
                            style: TextStyle(
                              // Pure white on the indigo fill keeps the same
                              // ~4.47:1 ratio as the eyebrow label did on
                              // white. Bumping weight/size alone won't fix
                              // contrast, so if this button ever needs to
                              // clear strict AA independently, darken the
                              // fill toward textSafeIndigo rather than the
                              // text color.
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Outfit',
                              fontSize: 15.sp,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 24.r,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      // excludeSemantics collapses the whole card into this one
      // announcement. Without it, a screen reader can still land on
      // the title, date, quote, and streak count as separate stops,
      // repeating everything this label already says.
      excludeSemantics: true,
      onTap: _handleNavigation,
      label:
          '${_hootTitle.value ?? 'Daily Wisdom'}. ${_hootText.value ?? 'Loading...'}. ${widget.streakCount} day streak. Double tap to start next task.',
      child: card,
    );
      }
    );
  }

  Widget _buildShimmerQuote(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerLine(width: double.infinity, isDark: isDark),
        SizedBox(height: 8.h),
        _ShimmerLine(width: 200.w, isDark: isDark),
        SizedBox(height: 8.h),
        _ShimmerLine(width: 120.w, isDark: isDark),
      ],
    );
  }
}

/// Animated shimmer placeholder shown while content loads. A moving
/// gradient sweep reads as noticeably more premium than a static
/// translucent block for very little extra code.
class _ShimmerLine extends StatefulWidget {
  final double width;
  final bool isDark;

  const _ShimmerLine({required this.width, required this.isDark});

  @override
  State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    final highlightColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.10);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1.0 + 3.0 * t, 0),
              end: Alignment(0.0 + 3.0 * t, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: Container(
            width: widget.width,
            height: 22.h,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        );
      },
    );
  }
}

class _StreakBadge extends StatefulWidget {
  final int streakCount;
  final bool isDark;

  const _StreakBadge({required this.streakCount, required this.isDark});

  @override
  State<_StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<_StreakBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popController;
  late final Animation<double> _pop;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _pop = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _popController, curve: Curves.elasticOut),
    );
    _popController.forward();
  }

  @override
  void didUpdateWidget(covariant _StreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-plays the little "pop" whenever the streak number actually
    // changes (e.g. the user just completed today's task), so the
    // badge itself becomes a small reward moment rather than a static
    // counter.
    if (oldWidget.streakCount != widget.streakCount) {
      _popController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _VowlCardPalette.streakTextFor(
      widget.streakCount,
      widget.isDark,
    );
    return ScaleTransition(
      scale: _pop,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: widget.isDark
              ? _VowlCardPalette.amberDarkBg
              : _VowlCardPalette.amberLightBg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _VowlCardPalette.amber.withValues(alpha: 0.4),
          ),
          boxShadow: widget.isDark
              ? null
              : [
                  BoxShadow(
                    color: _VowlCardPalette.amber.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: _VowlCardPalette.amber,
              size: 18.r,
            ),
            SizedBox(width: 6.w),
            Text(
              '${widget.streakCount}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
