import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class KidsCategoryGrid extends StatelessWidget {
  final bool isDark;

  const KidsCategoryGrid({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20.h,
          crossAxisSpacing: 20.w,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildListDelegate([
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/alphabet', extra: {'title': 'Alphabet', 'primaryColor': const Color(0xFFF43F5E)}),
            'ABC',
            'Letters & Phonics',
            const Color(0xFFF43F5E),
            Icons.abc_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/numbers', extra: {'title': 'Numbers', 'primaryColor': const Color(0xFF0EA5E9)}),
            '123',
            'Numbers & Math',
            const Color(0xFF0EA5E9),
            Icons.pin_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/colors', extra: {'title': 'Colors', 'primaryColor': const Color(0xFFF59E0B)}),
            'Colors',
            'Rainbow Fun',
            const Color(0xFFF59E0B),
            Icons.palette_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/shapes', extra: {'title': 'Shapes', 'primaryColor': const Color(0xFF10B981)}),
            'Shapes',
            'Geometry Fun',
            const Color(0xFF10B981),
            Icons.category_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/animals', extra: {'title': 'Animals', 'primaryColor': const Color(0xFF8B5CF6)}),
            'Animals',
            'Farm & Wild',
            const Color(0xFF8B5CF6),
            Icons.pets_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/fruits', extra: {'title': 'Fruits', 'primaryColor': const Color(0xFFEC4899)}),
            'Fruits',
            'Healthy Eating',
            const Color(0xFFEC4899),
            Icons.apple_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/family', extra: {'title': 'Family', 'primaryColor': const Color(0xFFEC4899)}),
            'Family',
            'Love & Home',
            const Color(0xFFEC4899),
            Icons.people_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/school', extra: {'title': 'School', 'primaryColor': const Color(0xFFF59E0B)}),
            'School',
            'Let\'s Learn',
            const Color(0xFFF59E0B),
            Icons.school_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/verbs', extra: {'title': 'Verbs', 'primaryColor': const Color(0xFF8B5CF6)}),
            'Verbs',
            'Action Words',
            const Color(0xFF8B5CF6),
            Icons.run_circle_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/routine', extra: {'title': 'Routine', 'primaryColor': const Color(0xFFF97316)}),
            'Routine',
            'My Day',
            const Color(0xFFF97316),
            Icons.schedule_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/emotions', extra: {'title': 'Emotions', 'primaryColor': const Color(0xFF06B6D4)}),
            'Emotions',
            'Feelings',
            const Color(0xFF06B6D4),
            Icons.mood_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/prepositions', extra: {'title': 'Prepositions', 'primaryColor': const Color(0xFF64748B)}),
            'Positions',
            'Where is it?',
            const Color(0xFF64748B),
            Icons.place_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/phonics', extra: {'title': 'Phonics', 'primaryColor': const Color(0xFFFFCC00)}),
            'Phonics',
            'Sound Out',
            const Color(0xFFFFCC00),
            Icons.record_voice_over_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/time', extra: {'title': 'Time', 'primaryColor': const Color(0xFF333333)}),
            'Time',
            'Tick Tock',
            const Color(0xFF333333),
            Icons.watch_later_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/opposites', extra: {'title': 'Opposites', 'primaryColor': const Color(0xFF94A3B8)}),
            'Opposites',
            'Flip It',
            const Color(0xFF94A3B8),
            Icons.swap_horiz_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/day_night', extra: {'title': 'Day/Night', 'primaryColor': const Color(0xFF1E293B)}),
            'Day & Night',
            'Sun & Moon',
            const Color(0xFF1E293B),
            Icons.brightness_4_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/nature', extra: {'title': 'Nature', 'primaryColor': const Color(0xFF16A34A)}),
            'Nature',
            'Outdoors',
            const Color(0xFF16A34A),
            Icons.forest_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/home', extra: {'title': 'Home', 'primaryColor': const Color(0xFFD946EF)}),
            'Home',
            'Rooms & Items',
            const Color(0xFFD946EF),
            Icons.home_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/food', extra: {'title': 'Food', 'primaryColor': const Color(0xFFFB923C)}),
            'Food',
            'Yummy!',
            const Color(0xFFFB923C),
            Icons.restaurant_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/transport', extra: {'title': 'Transport', 'primaryColor': const Color(0xFF2563EB)}),
            'Transport',
            'Vroom Vroom',
            const Color(0xFF2563EB),
            Icons.directions_car_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/body_parts', extra: {'title': 'Body Parts', 'primaryColor': const Color(0xFFF43F5E)}),
            'Body',
            'My Body',
            const Color(0xFFF43F5E),
            Icons.accessibility_new_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push('/kids/map/clothing', extra: {'title': 'Clothing', 'primaryColor': const Color(0xFF8B5CF6)}),
            'Clothing',
            'Dress Up',
            const Color(0xFF8B5CF6),
            Icons.checkroom_rounded,
          ),
        ]),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    VoidCallback onTap,
    String title,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return ScaleButton(
      onTap: onTap,
      child: GlassTile(
        borderRadius: BorderRadius.circular(32.r),
        borderColor: color.withValues(alpha: 0.3),
        child: Container(
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(icon, color: color, size: 32.sp),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
