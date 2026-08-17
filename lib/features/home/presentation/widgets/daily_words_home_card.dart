import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/daily_words/data/services/daily_words_service.dart';

class DailyWordsHomeCard extends StatefulWidget {
  final bool isDark;

  const DailyWordsHomeCard({super.key, required this.isDark});

  @override
  State<DailyWordsHomeCard> createState() => _DailyWordsHomeCardState();
}

class _DailyWordsHomeCardState extends State<DailyWordsHomeCard>
    with SingleTickerProviderStateMixin {
  final DailyWordsService _service = di.sl<DailyWordsService>();
  bool _isLoading = true;
  bool _isPressed = false;
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
    _initService();
  }

  Future<void> _initService() async {
    await _service.init();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pressController.reverse();
    _launchDailyWords();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
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
    final int streak = _service.streak;

    // Premium Emerald Green Theme for Learning Card
    final Color cardColor = const Color(0xFF10B981);
    final Color shadowColor = const Color(0xFF047857);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: EdgeInsets.only(
            top: _isPressed ? 6.h : 0,
            bottom: _isPressed ? 0 : 6.h,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: shadowColor,
                      offset: Offset(0, 6.h),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: cardColor.withValues(alpha: 0.3),
                      offset: const Offset(0, 10),
                      blurRadius: 20,
                    ),
                  ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Row(
              children: [
                // Icon Block
                Container(
                  width: 64.r,
                  height: 64.r,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                      size: 32.r,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AutoSizeText(
                              context.tr(
                                'home.daily_words_title',
                                fallback: 'Vocabulary',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          if (streak > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_fire_department_rounded,
                                    color: const Color(0xFFF59E0B),
                                    size: 14.r,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    '$streak',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFF59E0B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      AutoSizeText(
                        context.tr(
                          'home.daily_words_subtitle',
                          fallback: 'Master 10 new words today',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 2,
                      ),
                      SizedBox(height: 12.h),

                      // Day indicator (Renamed to Lesson to avoid confusion)
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              'LESSON $day',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: cardColor,
                              size: 20.r,
                            ),
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
      ),
    );
  }
}
