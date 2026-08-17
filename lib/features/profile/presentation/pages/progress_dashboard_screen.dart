import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/category_radar_chart.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/home/presentation/widgets/streak_calendar.dart';

class ProgressDashboardScreen extends StatelessWidget {
  const ProgressDashboardScreen({super.key});

  List<MapEntry<String, int>> _getWeakAreas(UserEntity user) {
    if (user.categoryStats.isEmpty) return [];
    final entries = user.categoryStats.entries.toList();
    entries.sort((a, b) => a.value.compareTo(b.value));
    return entries.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final weakAreas = _getWeakAreas(user);

          return Stack(
            children: [
              const MeshGradientBackground(showLetters: false),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, isDark),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 24.h),
                            // Heatmap (Task 2)
                            StreakCalendar(user: user),
                            SizedBox(height: 24.h),
                            
                            // Radar Chart (Task 4)
                            GlassTile(
                              padding: EdgeInsets.all(20.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Skill Radar',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  SizedBox(
                                    height: 250.h,
                                    child: CategoryRadarChart(
                                      user: user,
                                      isDark: isDark,
                                      primaryColor: const Color(0xFF6366F1),
                                      categoryId: 'vocabulary',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h),
                            
                            // Weak Areas Detection (Task 3)
                            Text(
                              'Focus Areas',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            if (weakAreas.isEmpty)
                              GlassTile(
                                padding: EdgeInsets.all(20.r),
                                child: Text(
                                  'Play more games to reveal your weak areas!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14.sp,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              )
                            else
                              ...weakAreas.map((area) => Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: GlassTile(
                                  padding: EdgeInsets.all(16.r),
                                  borderColor: const Color(0xFFF43F5E).withValues(alpha: 0.3),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(12.r),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.trending_up_rounded,
                                          color: const Color(0xFFF43F5E),
                                          size: 20.r,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatCategoryName(area.key),
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w800,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              'Needs improvement (Score: ${area.value})',
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 12.sp,
                                                color: isDark ? Colors.white60 : Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                            
                            SizedBox(height: 48.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              context.tr('profile.progress_dashboard', fallback: 'Progress Dashboard'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatCategoryName(String raw) {
    // Converts e.g. "word_formation" to "Word Formation"
    return raw.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
