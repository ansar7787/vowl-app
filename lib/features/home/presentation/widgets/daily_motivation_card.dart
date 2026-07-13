import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';

class DailyMotivationCard extends StatefulWidget {
  final int streakCount;
  
  const DailyMotivationCard({super.key, required this.streakCount});

  @override
  State<DailyMotivationCard> createState() => _DailyMotivationCardState();
}

class _DailyMotivationCardState extends State<DailyMotivationCard> {
  String? _hootTitle;
  String? _hootText; // Null means loading

  @override
  void initState() {
    super.initState();
    _loadDailyHoot();
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

      if (data['specific'] != null && data['specific'][specificKey] != null) {
        title = data['specific'][specificKey]['title'];
        text = data['specific'][specificKey]['text'];
      } else if (data['annual'] != null && data['annual'][dateKey] != null) {
        title = data['annual'][dateKey]['title'];
        text = data['annual'][dateKey]['text'];
      } else if (data['monthly'] != null) {
        final String monthKey = DateFormat('MM').format(now);
        final monthData = data['monthly'][monthKey];
        if (monthData != null) {
          title = monthData['theme'];
          final List<dynamic> messages = monthData['messages'] ?? [];
          if (messages.isNotEmpty) {
            final int dayOfYear = int.tryParse(DateFormat('D').format(now)) ?? now.day;
            final int index = dayOfYear % messages.length;
            text = messages[index];
          }
        }
      }

      if (mounted) {
        setState(() {
          _hootTitle = title;
          _hootText = text.isEmpty ? "Small steps today make fluent conversations tomorrow." : text;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hootTitle = "Daily Wisdom";
          _hootText = "Small steps today make fluent conversations tomorrow.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final dateString = DateFormat('EEEE, d MMM', locale).format(now);
    
    return Semantics(
      button: true,
      label: '${_hootTitle ?? 'Daily Wisdom'}. ${_hootText ?? 'Loading...'}. ${widget.streakCount} day streak. Double tap to start next task.',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(AppRouter.libraryRoute);
        },
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 600),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32.r),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
            boxShadow: isDark 
                ? null 
                : [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.08) 
                  : const Color(0xFF6366F1).withValues(alpha: 0.15), 
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // 1. Premium Background Quote Watermark
              Positioned(
                right: -30.w,
                top: -20.h,
                child: Icon(
                  Icons.format_quote_rounded,
                  size: 180.r,
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.04) 
                      : const Color(0xFF6366F1).withValues(alpha: 0.04),
                ),
              ),
              
              // Subtle gradient overlay for depth
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.transparent,
                        isDark 
                            ? const Color(0xFF6366F1).withValues(alpha: 0.05) 
                            : const Color(0xFF6366F1).withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Main Content
              Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Mascot + Title + Streak
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
                                : const Color(0xFFF8FAFC),
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
                                (_hootTitle ?? context.tr('home.daily_wisdom', fallback: 'DAILY WISDOM')).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Outfit',
                                  letterSpacing: 1.8,
                                  color: const Color(0xFF6366F1),
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
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _StreakBadge(streakCount: widget.streakCount, isDark: isDark),
                      ],
                    ),
                    
                    SizedBox(height: 28.h),
                    
                    // Body: The Quote
                    _hootText == null
                        ? _buildShimmerQuote(isDark)
                        : Text(
                            "\"$_hootText\"",
                            style: TextStyle(
                              fontSize: 19.sp,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Outfit',
                              height: 1.4,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          
                    SizedBox(height: 32.h),
                    
                    // Action: A highly engaging bottom CTA
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.tr('home.start_next_task', fallback: 'Start Next Task'),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Outfit',
                              fontSize: 15.sp,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20.r,
                          ),
                        ],
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

  Widget _buildShimmerQuote(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmerLine(width: double.infinity, isDark: isDark),
        SizedBox(height: 8.h),
        _shimmerLine(width: 200.w, isDark: isDark),
        SizedBox(height: 8.h),
        _shimmerLine(width: 120.w, isDark: isDark),
      ],
    );
  }

  Widget _shimmerLine({required double width, required bool isDark}) {
    return Container(
      width: width,
      height: 22.h,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streakCount;
  final bool isDark;

  const _StreakBadge({required this.streakCount, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF332000) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, color: const Color(0xFFF59E0B), size: 18.r),
          SizedBox(width: 6.w),
          Text(
            '$streakCount',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }
}
