import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

/// Lifecycle of the daily hoot content.
enum _HootStatus { loading, ready, fallback }

/// Daily motivation card presenting linguistic tips, calendar trivia, and language notes.
///
/// Styled as an editorial journal card with:
/// - Real calendar date and curated theme tags.
/// - Left-aligned, readable typography with zero clipping and zero ellipses.
/// - Dynamic topic practice navigation with haptic feedback.
class DailyMotivationCard extends StatefulWidget {
  /// Current consecutive day streak tally.
  final int streakCount;

  /// Creates a [DailyMotivationCard] for [streakCount].
  const DailyMotivationCard({super.key, required this.streakCount});

  @override
  State<DailyMotivationCard> createState() => _DailyMotivationCardState();
}

class _DailyMotivationCardState extends State<DailyMotivationCard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final ValueNotifier<String?> _hootTitle = ValueNotifier(null);
  final ValueNotifier<String?> _hootText = ValueNotifier(null);
  final ValueNotifier<_HootStatus> _status = ValueNotifier(_HootStatus.loading);

  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;

  String? _loadedDay;
  Timer? _midnightTimer;

  static const String _fallbackQuote =
      "A day name and a date are different things: 'Monday' is the weekday, "
      "and 'March 9' tells you which Monday.";
  static const String _fallbackTitle = "Calendar Tip";

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadDailyHoot();
      _scheduleMidnightRefresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    _entranceController.dispose();
    _hootTitle.dispose();
    _hootText.dispose();
    _status.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshIfDayChanged();
      _scheduleMidnightRefresh();
    }
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  void _refreshIfDayChanged() {
    if (!mounted || _loadedDay == _todayKey()) return;
    _entranceController.reset();
    _loadDailyHoot();
    setState(() {});
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 1),
      () {
        if (!mounted) return;
        _refreshIfDayChanged();
        _scheduleMidnightRefresh();
      },
    );
  }

  String _formatToday(String locale, DateTime now) {
    try {
      return DateFormat('EEEE, d MMM', locale).format(now);
    } catch (_) {
      return DateFormat('EEEE, d MMM', 'en').format(now);
    }
  }

  @visibleForTesting
  static int resolveMessageIndex(DateTime date, int messageCount) {
    if (messageCount <= 0) return 0;
    final int dayOfMonth = date.day - 1;
    return (date.year * 31 + dayOfMonth) % messageCount;
  }

  Future<void> _loadDailyHoot() async {
    try {
      final assetBundle = mounted ? DefaultAssetBundle.of(context) : rootBundle;
      final String jsonString = await assetBundle.loadString(
        'assets/curriculum/calendar/vowl_calendar.json',
      );
      final Map<String, dynamic> data = json.decode(jsonString);

      final now = DateTime.now();
      _loadedDay = '${now.year}-${now.month}-${now.day}';

      String two(int v) => v.toString().padLeft(2, '0');
      final String monthKey = two(now.month);
      final String dateKey = '$monthKey-${two(now.day)}';
      final String specificKey = '${now.year}-$dateKey';

      String? title;
      String? text;

      if (data['specific']?[specificKey] != null) {
        title = data['specific'][specificKey]['title'] as String?;
        text = data['specific'][specificKey]['text'] as String?;
      } else if (data['annual']?[dateKey] != null) {
        title = data['annual'][dateKey]['title'] as String?;
        text = data['annual'][dateKey]['text'] as String?;
      } else if (data['monthly'] != null) {
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
      if (kDebugMode) {
        debugPrint(
          'DailyMotivationCard: failed to load hoot content: $e\n$stack',
        );
      }
      if (!mounted) return;
      _hootTitle.value = _fallbackTitle;
      _hootText.value = _fallbackQuote;
      _status.value = _HootStatus.fallback;
      _entranceController.forward();
    }
  }

  void _handleNavigation() {
    try {
      di.sl<HapticService>().selection();
    } catch (_) {
      HapticFeedback.lightImpact();
    }

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
      listenable: Listenable.merge([_hootTitle, _hootText, _status]),
      builder: (context, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final isMidnight = isDark &&
            theme.scaffoldBackgroundColor == Colors.black;
        final locale = Localizations.localeOf(context).toString();
        final now = DateTime.now();
        final dateString = _formatToday(locale, now);
        final title = _hootTitle.value ?? _fallbackTitle;
        final quoteText = _hootText.value ?? _fallbackQuote;

        return Semantics(
          button: true,
          label: '$title. $quoteText. Double tap to explore topic.',
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isMidnight
                  ? AppColors.midnightSurface
                  : (isDark ? const Color(0xFF111827) : Colors.white),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isMidnight
                    ? Colors.white.withValues(alpha: 0.12)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.slate100),
                width: 1.r,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isMidnight ? 0.35 : (isDark ? 0.20 : 0.03),
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Header Row: Date & Topic Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date Badge
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 13.r,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              dateString,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                letterSpacing: -0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // Topic Pill
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 2.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.indigo500.withValues(
                          alpha: isDark ? 0.18 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: AppColors.indigo500.withValues(
                            alpha: isDark ? 0.32 : 0.20,
                          ),
                          width: 1.r,
                        ),
                      ),
                      child: Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFA5B4FC)
                              : const Color(0xFF4F46E5),
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // 2. Editorial Quote Body (Left-aligned, zero ellipses, zero overflow)
                _status.value == _HootStatus.loading
                    ? _buildShimmer(isDark)
                    : FadeTransition(
                        opacity: _fadeIn,
                        child: Text(
                          '"$quoteText"',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                            color: isDark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF1E293B),
                          ),
                          softWrap: true,
                        ),
                      ),

                SizedBox(height: 14.h),

                // 3. Footer Row: Mascot Identity & Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Identity
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24.r,
                            height: 24.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : const Color(0xFFF1F5F9),
                            ),
                            child: Center(
                              child: _SafeMascot(size: 18.r),
                            ),
                          ),
                          SizedBox(width: 7.w),
                          Flexible(
                            child: Text(
                              context.tr(
                                'home.daily_note_footer',
                                fallback: 'Daily Language Note',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // Action Button
                    ScaleButton(
                      onTap: _handleNavigation,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(
                            alpha: isDark ? 0.16 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppColors.indigo500.withValues(
                              alpha: isDark ? 0.30 : 0.22,
                            ),
                            width: 1.r,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.tr(
                                'home.practice_topic',
                                fallback: 'Practice Topic',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? const Color(0xFFA5B4FC)
                                    : const Color(0xFF4F46E5),
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 9.r,
                              color: isDark
                                  ? const Color(0xFFA5B4FC)
                                  : const Color(0xFF4F46E5),
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
        );
      },
    );
  }

  Widget _buildShimmer(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerBlock(width: double.infinity, height: 16.h, isDark: isDark),
        SizedBox(height: 6.h),
        _ShimmerBlock(width: 220.w, height: 16.h, isDark: isDark),
      ],
    );
  }
}

/// Fallback-safe mascot widget that checks for [AuthBloc] presence before attempting
/// to build [VowlMascot], avoiding missing provider assertions in isolated contexts.
class _SafeMascot extends StatelessWidget {
  final double size;

  const _SafeMascot({required this.size});

  @override
  Widget build(BuildContext context) {
    try {
      final hasAuthBloc =
          context.findAncestorWidgetOfExactType<BlocProvider<AuthBloc>>() !=
          null;
      if (hasAuthBloc) {
        return VowlMascot(
          size: size,
          useFloatingAnimation: false,
          state: VowlMascotState.happy,
        );
      }
    } catch (_) {}

    return Icon(
      Icons.auto_awesome_rounded,
      size: size * 0.75,
      color: AppColors.indigo500,
    );
  }
}

class _ShimmerBlock extends StatefulWidget {
  final double width;
  final double height;
  final bool isDark;

  const _ShimmerBlock({
    required this.width,
    required this.height,
    required this.isDark,
  });

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (!VowlMotion.lowAnimationModeOverride.value) {
      _controller.repeat();
    }
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
        : Colors.black.withValues(alpha: 0.08);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + 3.0 * t, 0),
              end: Alignment(0.0 + 3.0 * t, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(6.r),
            ),
          ),
        );
      },
    );
  }
}
