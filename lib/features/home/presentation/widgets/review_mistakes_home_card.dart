import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Home card badge tracking active error count and providing one-tap mistake mastery.
///
/// Refactored to an adult precision mastery hub:
/// - Real error counts via [ErrorJournalCollector].
/// - Tactile crosshair icon with active amber pulse pip.
/// - Un-crowded single-mention count typography (zero ellipses / zero text clipping).
/// - Vowl obsidian/porcelain luxury styling with subtle borders.
class ReviewMistakesHomeCard extends StatefulWidget {
  /// Current authenticated [user] entity.
  final UserEntity user;

  /// Creates a [ReviewMistakesHomeCard] for [user].
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
    ErrorJournalCollector.updateNotifier.addListener(_loadMistakeCount);
  }

  @override
  void dispose() {
    ErrorJournalCollector.updateNotifier.removeListener(_loadMistakeCount);
    _mistakeCount.dispose();
    super.dispose();
  }

  Future<void> _loadMistakeCount() async {
    final count = await ErrorJournalCollector.count(userId: widget.user.id);
    if (mounted) {
      _mistakeCount.value = count;
    }
  }

  void _triggerHaptic() {
    try {
      di.sl<HapticService>().selection();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black;

    return ValueListenableBuilder<int>(
      valueListenable: _mistakeCount,
      builder: (context, count, _) {
        if (count == 0) return const SizedBox.shrink();

        final title = context.tr(
          'home.review_mistakes_title',
          fallback: 'Review & Master',
        );
        final subtitle = context.tr(
          'home.review_mistakes_subtitle',
          fallback: count == 1
              ? 'Master 1 past challenge'
              : 'Master $count past challenges',
          args: [count.toString()],
        );

        Widget card = Semantics(
          button: true,
          label: '$title. $subtitle',
          child: ScaleButton(
            onTap: () async {
              _triggerHaptic();
              await context.push('/review-mistakes');
              if (mounted) {
                _loadMistakeCount();
              }
            },
            child: Container(
              margin: EdgeInsets.only(top: 16.h),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: isMidnight
                    ? AppColors.midnightSurface
                    : (isDark ? const Color(0xFF131A29) : Colors.white),
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: isMidnight
                      ? Colors.white.withValues(alpha: 0.12)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.slate100),
                  width: 1.r,
                ),
              ),
              child: Row(
                children: [
                  // Tactical Target Halo with Active Pulse Pip
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44.r,
                        height: 44.r,
                        decoration: BoxDecoration(
                          color: AppColors.orange500.withValues(
                            alpha: isDark ? 0.14 : 0.09,
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: AppColors.orange500.withValues(
                              alpha: isDark ? 0.30 : 0.20,
                            ),
                            width: 1.r,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.crisis_alert_rounded,
                            color: AppColors.orange500,
                            size: 22.r,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -2.r,
                        right: -2.r,
                        child: Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.orange500,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF131A29)
                                  : Colors.white,
                              width: 1.5.r,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.orange500.withValues(
                                  alpha: 0.6,
                                ),
                                blurRadius: 4.r,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 14.w),

                  // Center Information (Un-crowded, Single Mention, Zero Ellipses)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.slate900,
                            letterSpacing: -0.2,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.slate400
                                : AppColors.slate500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),

                  // Tactile Circular Action Chevron
                  Container(
                    width: 28.r,
                    height: 28.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.orange500.withValues(
                        alpha: isDark ? 0.12 : 0.08,
                      ),
                      border: Border.all(
                        color: AppColors.orange500.withValues(
                          alpha: isDark ? 0.28 : 0.18,
                        ),
                        width: 1.r,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.orange500,
                        size: 12.r,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (!VowlMotion.shouldReduceMotion(context)) {
          card = card.animate().fadeIn().slideY(begin: 0.08);
        }

        return card;
      },
    );
  }
}
