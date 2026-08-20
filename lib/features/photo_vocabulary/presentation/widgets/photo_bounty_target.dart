import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/locale_service.dart';

class PhotoBountyTarget extends StatelessWidget {
  final String currentBounty;
  final bool bountyFound;

  const PhotoBountyTarget({
    super.key,
    required this.currentBounty,
    required this.bountyFound,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark
        ? Colors.amber.shade300
        : Colors.amber.shade700;

    // Background and Border colors depending on theme and found status
    final unfoundBgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
    final unfoundBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.15);

    final foundBgColor = isDark
        ? const Color(0xFF14B8A6).withValues(alpha: 0.3)
        : const Color(0xFF14B8A6).withValues(alpha: 0.15);
    final foundBorderColor = isDark
        ? const Color(0xFF2DD4BF)
        : const Color(0xFF14B8A6);

    return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: bountyFound ? foundBgColor : unfoundBgColor,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: bountyFound ? foundBorderColor : unfoundBorderColor,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      bountyFound
                          ? Icons.verified_rounded
                          : Icons.radar_rounded,
                      color: bountyFound
                          ? const Color(0xFF14B8A6)
                          : (isDark
                                ? Colors.amber.shade400
                                : Colors.amber.shade600),
                      size: 24.r,
                    ),
                    SizedBox(width: 12.w),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('vocabulary.daily_bounty', args: [currentBounty], fallback: 'Daily Bounty: $currentBounty'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!bountyFound)
                            Text(
                              context.tr('vocabulary.find_bounty_desc', fallback: 'Find this object to earn +5 XP & 5 Coins'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: subtitleColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(target: bountyFound ? 1 : 0)
        .shimmer(
          duration: 1.seconds,
          color: isDark ? Colors.white54 : Colors.black12,
        );
  }
}
