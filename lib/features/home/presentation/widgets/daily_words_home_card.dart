import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
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
      return SizedBox(height: 140.h);
    }

    final int day = _service.currentDay;
    final int streak = context.watch<AuthBloc>().state.user?.currentStreak ?? 0;

    return Semantics(
      button: true,
      label: 'Daily Words',
      child: ScaleButton(
        onTap: _launchDailyWords,
        child: ExcludeSemantics(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                constraints: BoxConstraints(minHeight: 140.h),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32.r),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF10B981), // Emerald Green (Habit/Dopamine)
                      Color(0xFF059669), // Deep Emerald
                      Color(0xFF14B8A6), // Teal accent
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32.r),
                  child: Stack(
                    children: [
                      // Decorative background circles
                      PositionedDirectional(
                        end: -30.w,
                        bottom: -30.h,
                        child: Container(
                          width: 180.r,
                          height: 180.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),

                      // Playful background icons
                      PositionedDirectional(
                        start: 20.w,
                        top: 20.h,
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 24.r,
                          color: Colors.white.withValues(alpha: 0.2),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.3, 1.3),
                          duration: 3.seconds,
                        ),
                      ),

                      // Text Content
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          24.w,
                          16.h,
                          130.w,
                          16.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 10.r,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4.w),
                                      Flexible(
                                        child: AutoSizeText(
                                          'LESSON $day',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            color: Colors.white,
                                            fontSize: 8.sp,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                          ),
                                          maxLines: 1,
                                          minFontSize: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (streak > 0) ...[
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 10.r),
                                        SizedBox(width: 4.w),
                                        Text(
                                          '$streak',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 8.h),
                            AutoSizeText(
                              context.tr(
                                'home.daily_words_title',
                                fallback: 'DAILY WORDS',
                              ).toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                height: 1.0,
                              ),
                              maxLines: 1,
                              minFontSize: 12,
                            ),
                            SizedBox(height: 4.h),
                            AutoSizeText(
                              context.tr(
                                'home.daily_words_subtitle',
                                fallback: 'EXPAND YOUR VOCABULARY EVERY DAY',
                              ).toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              minFontSize: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Mascot Area (Concentric & Engaging Design)
              PositionedDirectional(
                end: 0,
                bottom: 0,
                top: 0,
                child: SizedBox(
                  width: 140.w,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Outer Soft Glow
                      Container(
                        width: 140.r,
                        height: 140.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.2, 1.2),
                        duration: 4.seconds,
                      ),

                      // 2. Secondary Interactive Ring
                      Container(
                        width: 100.r,
                        height: 100.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).rotate(
                        duration: 10.seconds,
                      ),

                      // 3. Floating Sparkles/Particles
                      ...List.generate(5, (index) {
                        return Positioned(
                          left: 20.w + (index * 20).w,
                          top: 20.h + (index * 15).h,
                          child: Icon(
                            Icons.star_rounded,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: (8 + (index % 3) * 4).r,
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .fadeIn(
                                duration: (1 + (index * 0.2)).seconds,
                              )
                              .moveY(
                                begin: 0,
                                end: -20,
                                duration: 2.seconds,
                              ),
                        );
                      }),

                      // 4. The Buddy Icon
                      Container(
                        padding: EdgeInsets.all(18.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 2.r,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Text(
                          "📚",
                          style: TextStyle(fontSize: 48.sp, height: 1.0),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                        begin: -6,
                        end: 6,
                        duration: 2.seconds,
                        curve: Curves.easeInOut,
                      ).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.05, 1.05),
                        duration: 2.seconds,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
