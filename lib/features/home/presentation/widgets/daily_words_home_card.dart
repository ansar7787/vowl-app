import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/daily_words/data/services/daily_words_service.dart';

class DailyWordsHomeCard extends StatefulWidget {
  final bool isDark;
  
  const DailyWordsHomeCard({super.key, required this.isDark});

  @override
  State<DailyWordsHomeCard> createState() => _DailyWordsHomeCardState();
}

class _DailyWordsHomeCardState extends State<DailyWordsHomeCard> {
  final DailyWordsService _service = di.sl<DailyWordsService>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    await _service.init();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _launchDailyWords() {
    di.sl<HapticService>().light();
    _navigateAndRefresh();
  }

  Future<void> _navigateAndRefresh() async {
    await context.push(AppRouter.dailyWordsRoute);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(height: 120.h);
    }

    final int day = _service.currentDay;
    final int streak = context.watch<AuthBloc>().state.user?.currentStreak ?? 0;

    // Premium Emerald Green Theme matching the app's aesthetic
    final Color primaryAccent = const Color(0xFF10B981);
    final Color secondaryAccent = const Color(0xFF059669);

    return GestureDetector(
      onTap: _launchDailyWords,
      child: GlassTile(
        padding: EdgeInsets.zero,
        borderColor: primaryAccent.withValues(alpha: 0.3),
        borderWidth: 1.5,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDark
                  ? [
                      primaryAccent.withValues(alpha: 0.15),
                      secondaryAccent.withValues(alpha: 0.05),
                    ]
                  : [
                      primaryAccent.withValues(alpha: 0.1),
                      secondaryAccent.withValues(alpha: 0.02),
                    ],
            ),
          ),
          padding: EdgeInsets.all(20.r),
          child: Row(
            children: [
              // Icon block
              Container(
                width: 60.r,
                height: 60.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryAccent, secondaryAccent],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryAccent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 28.r,
                ),
              ),
              SizedBox(width: 16.w),
              
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AutoSizeText(
                            context.tr('home.daily_words_title', fallback: 'Daily Words'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                          ),
                        ),
                        if (streak > 0)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_fire_department_rounded, color: const Color(0xFFF59E0B), size: 12.r),
                                SizedBox(width: 4.w),
                                Text(
                                  '$streak',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    AutoSizeText(
                      context.tr('home.daily_words_subtitle', fallback: 'Expand your vocabulary every day'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: widget.isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 12.h),
                    
                    // Day indicator & Action
                    Row(
                      children: [
                        Text(
                          'LESSON $day',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: primaryAccent,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: primaryAccent,
                          size: 18.r,
                        ),
                      ],
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
