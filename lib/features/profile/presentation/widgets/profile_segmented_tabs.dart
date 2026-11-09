import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// High-polish sticky segmented control for switching between Profile tabs:
/// - 0: Journey & Arena
/// - 1: Hall of Fame (Trophy Room)
/// - 2: Vault & Rewards
///
/// Implements a fluid sliding pill indicator that smoothly translates across tabs
/// with zero cutter or jarring flicker effects.
class ProfileSegmentedTabs extends StatelessWidget {
  /// Currently active tab index (0, 1, or 2).
  final int activeIndex;

  /// Callback executed when tapping a tab.
  final ValueChanged<int> onTabSelected;

  /// Creates a [ProfileSegmentedTabs] widget.
  const ProfileSegmentedTabs({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.borderLight);

    final tabs = [
      (
        icon: Icons.explore_rounded,
        label: context.tr('profile.tab_journey', fallback: 'Journey'),
      ),
      (
        icon: Icons.emoji_events_rounded,
        label: context.tr('profile.tab_trophies', fallback: 'Trophies'),
      ),
      (
        icon: Icons.shield_rounded,
        label: context.tr('profile.tab_vault', fallback: 'Vault'),
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Container(
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: isMidnight
              ? AppColors.midnightSurface
              : (isDark
                    ? AppColors.midnightNavy
                    : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / tabs.length;

            return Stack(
              children: [
                // ── Fluid Sliding Glass Capsule Indicator ──
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: activeIndex * tabWidth,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isMidnight
                          ? const Color(0xFF1E293B)
                          : (isDark ? AppColors.slate800 : Colors.white),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: isMidnight
                            ? Colors.white.withValues(alpha: 0.12)
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppColors.slate200),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.08,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Interactive Tab Triggers ──
                Row(
                  children: List.generate(tabs.length, (index) {
                    final tab = tabs[index];
                    final isSelected = activeIndex == index;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!isSelected) {
                            di.sl<HapticService>().selection();
                            onTabSelected(index);
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tab.icon,
                                size: 15.r,
                                color: isSelected
                                    ? AppColors.indigo500
                                    : (isDark
                                          ? Colors.white38
                                          : Colors.black38),
                              ),
                              SizedBox(width: 5.w),
                              Flexible(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 180),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.5.sp,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? (isDark
                                              ? Colors.white
                                              : AppColors.slate900)
                                        : (isDark
                                              ? Colors.white38
                                              : Colors.black38),
                                  ),
                                  child: Text(
                                    tab.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
