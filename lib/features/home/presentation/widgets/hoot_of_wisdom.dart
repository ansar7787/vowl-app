import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HootOfWisdom extends StatefulWidget {
  const HootOfWisdom({super.key});

  @override
  State<HootOfWisdom> createState() => _HootOfWisdomState();
}

class _HootOfWisdomState extends State<HootOfWisdom> {
  static String? _cachedTitle;
  static String? _cachedText;
  static bool _hasLoaded = false;

  String? _hootTitle;
  String _hootText = "...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (_hasLoaded) {
      _hootTitle = _cachedTitle;
      _hootText = _cachedText ?? "";
      _isLoading = false;
    } else {
      _loadDailyHoot();
    }
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
      String text = "";

      // 1. Check Specific Date (e.g. 2026-04-28)
      if (data['specific'] != null && data['specific'][specificKey] != null) {
        title = data['specific'][specificKey]['title'];
        text = data['specific'][specificKey]['text'];
      }
      // 2. Check Annual Date (e.g. 12-25)
      else if (data['annual'] != null && data['annual'][dateKey] != null) {
        title = data['annual'][dateKey]['title'];
        text = data['annual'][dateKey]['text'];
      }
      // 3. Fallback to Random Wisdom
      else {
        title = null;
        final List<dynamic> fallbacks = data['fallbacks'] ?? [];
        if (fallbacks.isNotEmpty) {
          text = fallbacks[Random().nextInt(fallbacks.length)];
        } else {
          // This will be replaced in build with localized text
          text = "";
        }
      }

      if (mounted) {
        setState(() {
          _cachedTitle = title;
          _cachedText = text;
          _hasLoaded = true;

          _hootTitle = title;
          _hootText = text;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      // Curriculum calendar asset is optional content — never block the
      // home feed on it, but keep a debug-only trace so a missing/malformed
      // asset doesn't fail silently during development.
      if (kDebugMode) {
        debugPrint('HootOfWisdom: failed to load daily hoot: $e\n$stackTrace');
      }
      if (mounted) {
        setState(() {
          // This will be replaced in build with localized text
          _hootText = "";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final dayStr = DateFormat('dd', locale).format(now);
    final monthStr = DateFormat('MMM', locale).format(now).toUpperCase();
    final resolvedText = _hootText.isEmpty
        ? context.tr(
            'home.hoot_fallback_msg_2',
            fallback: 'Keep learning every day!',
          )
        : _hootText;

    return GlassTile(
      borderRadius: BorderRadius.circular(32.r),
      padding: EdgeInsets.all(24.r),
      child: Semantics(
              label:
                  '${_hootTitle ?? context.tr('home.hoot_daily_motivation', fallback: 'Daily Motivation')}. $resolvedText',
              child: Column(
                children: [
                  ExcludeSemantics(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 1. Date Badge (Standard App Style)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                monthStr,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF6366F1),
                                ),
                                maxLines: 1,
                              ),
                              Text(
                                dayStr,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),

                        // 2. Owly Identifier
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _hootTitle ??
                                      context.tr(
                                        'home.hoot_daily_motivation',
                                        fallback: 'Daily Motivation',
                                      ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF6366F1),
                                    letterSpacing: 2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              VowlMascot(
                                size: 26.r,
                                useFloatingAnimation: false,
                                state: VowlMascotState.neutral,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  if (_isLoading)
                    SizedBox(height: 22.h)
                  else
                    Text(
                      resolvedText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFF1E293B),
                        height: 1.5,
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                ],
              ),
            ),
    );
  }
}
