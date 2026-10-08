import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';

class SituationalResponseSceneDisplay extends StatelessWidget {
  final RoleplayQuest quest;
  final Color color;
  final bool isDark;
  final VoidCallback onListen;

  const SituationalResponseSceneDisplay({
    super.key,
    required this.quest,
    required this.color,
    required this.isDark,
    required this.onListen,
  });

  IconData _getContextIcon(String? scene, String? culturalNote) {
    final text = "${scene ?? ''} ${culturalNote ?? ''}".toLowerCase();

    if (text.contains('coffee') ||
        text.contains('café') ||
        text.contains('cafe') ||
        text.contains('barista')) {
      return Icons.local_cafe_rounded;
    }
    if (text.contains('elevator')) {
      return Icons.elevator_rounded;
    }
    if (text.contains('school') ||
        text.contains('class') ||
        text.contains('teacher')) {
      return Icons.school_rounded;
    }
    if (text.contains('train') ||
        text.contains('bus') ||
        text.contains('station') ||
        text.contains('transport')) {
      return Icons.directions_transit_rounded;
    }
    if (text.contains('restaurant') ||
        text.contains('waiter') ||
        text.contains('menu')) {
      return Icons.restaurant_rounded;
    }
    if (text.contains('shop') ||
        text.contains('clothing') ||
        text.contains('shirt')) {
      return Icons.checkroom_rounded;
    }
    if (text.contains('phone') ||
        text.contains('call') ||
        text.contains('text')) {
      return Icons.phone_iphone_rounded;
    }
    if (text.contains('grocery') || text.contains('store')) {
      return Icons.local_grocery_store_rounded;
    }
    if (text.contains('driv') ||
        text.contains('lift') ||
        text.contains('car')) {
      return Icons.directions_car_rounded;
    }
    if (text.contains('work') ||
        text.contains('coworker') ||
        text.contains('colleague') ||
        text.contains('report') ||
        text.contains('office')) {
      return Icons.work_rounded;
    }
    if (text.contains('birthday') ||
        text.contains('party') ||
        text.contains('celebrat')) {
      return Icons.cake_rounded;
    }
    if (text.contains('apartment') || text.contains('home')) {
      return Icons.home_rounded;
    }
    if (text.contains('hike') || text.contains('hiking')) {
      return Icons.terrain_rounded;
    }
    if (text.contains('study') ||
        text.contains('library') ||
        text.contains('book')) {
      return Icons.menu_book_rounded;
    }
    if (text.contains('dog') || text.contains('pet') || text.contains('vet')) {
      return Icons.pets_rounded;
    }
    if (text.contains('interview')) {
      return Icons.handshake_rounded;
    }
    if (text.contains('pharmacist') ||
        text.contains('allerg') ||
        text.contains('medical') ||
        text.contains('hospital')) {
      return Icons.medical_services_rounded;
    }
    if (text.contains('direction') || text.contains('map')) {
      return Icons.map_rounded;
    }

    return Icons.forum_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final Color glowColor = color.withValues(alpha: 0.25);

    return Container(
      width: 1.sw,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: glowColor, blurRadius: 15, spreadRadius: -3),
        ],
      ),
      child: Stack(
        children: [
          // Contextual Watermark Icon
          Positioned(
            right: -20.w,
            bottom: -30.h,
            child: IgnorePointer(
              child: Icon(
                _getContextIcon(quest.scene, quest.culturalNote),
                size: 150.r,
                color: color.withValues(alpha: isDark ? 0.04 : 0.06),
              ),
            ),
          ),

          // Foreground Content
          Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.theater_comedy_rounded,
                      color: color,
                      size: 24.r,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "ACTIVE SCENARIO",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    ScaleButton(
                      onTap: onListen,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.volume_up_rounded,
                              size: 16.r,
                              color: color,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              "LISTEN",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Text(
                  quest.scene ?? "",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}
