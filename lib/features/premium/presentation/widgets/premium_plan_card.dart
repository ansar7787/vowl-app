import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/premium/domain/entities/subscription_plan.dart';
import 'package:auto_size_text/auto_size_text.dart';

class PremiumPlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isSelected;
  final VoidCallback onTap;

  const PremiumPlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = plan.getColorFromHex();

    final currencyFormat = NumberFormat.currency(
      locale: Localizations.localeOf(context).toString(),
      symbol: '₹',
      decimalDigits: 0,
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${plan.name}, ${currencyFormat.format(plan.price)}, '
          '${context.tr('premium.days_of_elite_access', fallback: 'Days of Elite Access', args: ['${plan.days}'])}',
      child: GestureDetector(
        onTap: onTap,
        child:
            Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: 300.ms,
                        curve: Curves.easeOutQuart,
                        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                    ? accentColor.withValues(alpha: 0.1)
                                    : accentColor.withValues(alpha: 0.05))
                              : (isDark
                                    ? const Color(0x08FFFFFF)
                                    : Colors.white),
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(
                            color: isSelected
                                ? accentColor
                                : (isDark
                                      ? const Color(0x1AFFFFFF)
                                      : const Color(0x0A000000)),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.25),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [
                                  if (!isDark)
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                        ),
                        child: Row(
                          children: [
                            // Radio indicator
                            Container(
                              width: 24.r,
                              height: 24.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? accentColor
                                      : (isDark
                                            ? Colors.white30
                                            : Colors.black26),
                                  width: isSelected ? 6.r : 2.r,
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AutoSizeText(
                                    plan.name.toUpperCase(),
                                    maxLines: 1,
                                    minFontSize: 10,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  AutoSizeText(
                                    context.tr(
                                      'premium.days_of_elite_access',
                                      fallback: 'Days of Elite Access',
                                      args: ['${plan.days}'],
                                    ),
                                    maxLines: 1,
                                    minFontSize: 8,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 8.w),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormat.format(plan.oldPrice),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.black38,
                                    fontSize: 14.sp,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  currencyFormat.format(plan.price),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // The gorgeous floating tag at the top right
                      if (plan.tag.isNotEmpty)
                        Positioned(
                          top: -12.h,
                          right: 20.w,
                          child:
                              Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          accentColor,
                                          accentColor.withValues(alpha: 0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: AutoSizeText(
                                      plan.tag,
                                      maxLines: 1,
                                      minFontSize: 6,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: Colors.white,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  )
                                  .animate(target: isSelected ? 1 : 0)
                                  .scale(
                                    begin: const Offset(0.9, 0.9),
                                    end: const Offset(1.1, 1.1),
                                    duration: 300.ms,
                                    curve: Curves.elasticOut,
                                  ),
                        ),
                    ],
                  ),
                )
                .animate(target: isSelected ? 1 : 0)
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.02, 1.02),
                ),
      ),
    );
  }
}
