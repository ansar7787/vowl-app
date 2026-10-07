import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class ReviewMistakesHomeCard extends StatefulWidget {
  final UserEntity user;

  const ReviewMistakesHomeCard({super.key, required this.user});

  @override
  State<ReviewMistakesHomeCard> createState() => _ReviewMistakesHomeCardState();
}

class _ReviewMistakesHomeCardState extends State<ReviewMistakesHomeCard> {
  final ValueNotifier<int> _mistakeCount = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _loadMistakeCount();
  }

  @override
  void dispose() {
    _mistakeCount.dispose();
    super.dispose();
  }

  Future<void> _loadMistakeCount() async {
    final count = await ErrorJournalCollector.count(
      userId: widget.user.id,
    );
    if (mounted) {
      _mistakeCount.value = count;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _mistakeCount,
      builder: (context, count, _) {
        if (count == 0) return const SizedBox.shrink();

        Widget card = ScaleButton(
          onTap: () async {
            di.sl<HapticService>().selection();
            await context.push('/review-mistakes');
            if (mounted) {
              _loadMistakeCount();
            }
          },
          child: Container(
            margin: EdgeInsets.only(top: 16.h),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.orange500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.orange500.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.orange500.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: AppColors.orange500,
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(
                          'home.review_mistakes_title',
                          fallback: 'Review Mistakes',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange500,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        context.tr(
                          'home.review_mistakes_subtitle',
                          fallback: 'You have {0} mistakes to practice',
                          args: [count.toString()],
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.orange500,
                  size: 16.r,
                ),
              ],
            ),
          ),
        );

        if (!VowlMotion.shouldReduceMotion(context)) {
          card = card.animate().fadeIn().slideY(begin: 0.1);
        }

        return card;
      },
    );
  }
}
