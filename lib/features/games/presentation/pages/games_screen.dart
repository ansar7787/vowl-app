import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/home/presentation/widgets/category_shelf.dart';
import 'package:vowl/core/utils/game_helper.dart';
import 'package:vowl/core/theme/theme_cubit.dart';

final ScrollController gamesScrollController = ScrollController();

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  @override
  Widget build(BuildContext context) {
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isMidnight 
        ? Colors.black 
        : (isDark ? const Color(0xFF0F172A) : Colors.white);

    return Scaffold(
      backgroundColor: bgColor,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.status == AuthStatus.authenticated ? state.user : null;
          if (user == null) return const SizedBox.shrink();

          return Stack(
            children: [
              const MeshGradientBackground(showLetters: false),
              CustomScrollView(
                controller: gamesScrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildGlassAppBar(context, isDark),
                  SliverPadding(
                    padding: EdgeInsets.only(bottom: 120.h),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // 1. Vocabulary
                        _buildSectionWrapper(
                          context,
                          'Vocabulary Vault',
                          'Master words and expressions',
                          QuestType.vocabulary,
                          user: user,
                        ),

                        // 2. Listening
                        _buildSectionWrapper(
                          context,
                          'Listening Lab',
                          'Understand spoken language',
                          QuestType.listening,
                          user: user,
                        ),

                        // 3. Reading
                        _buildSectionWrapper(
                          context,
                          'Reading Foundations',
                          'Comprehend texts and stories',
                          QuestType.reading,
                          user: user,
                        ),

                        // 4. Grammar
                        _buildSectionWrapper(
                          context,
                          'Grammar Hub',
                          'Master structural rules',
                          QuestType.grammar,
                          user: user,
                        ),

                        // 5. Writing
                        _buildSectionWrapper(
                          context,
                          'Writing Studio',
                          'Express yourself in writing',
                          QuestType.writing,
                          user: user,
                        ),

                        // 6. Speaking
                        _buildSectionWrapper(
                          context,
                          'Speaking Mastery',
                          'Communicate with confidence',
                          QuestType.speaking,
                          user: user,
                        ),

                        // 7. Accent
                        _buildSectionWrapper(
                          context,
                          'Accent Academy',
                          'Perfect your pronunciation',
                          QuestType.accent,
                          user: user,
                        ),

                        // 8. Roleplay
                        _buildSectionWrapper(
                          context,
                          'Roleplay Realm',
                          'Immersive real-world scenarios',
                          QuestType.roleplay,
                          user: user,
                        ),

                        // 9. Elite Mastery
                        _buildSectionWrapper(
                          context,
                          'Elite Mastery',
                          'Legendary challenges for top masters',
                          QuestType.eliteMastery,
                          user: user,
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlassAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: true,
      expandedHeight: 120.h,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome_mosaic_rounded,
                      color: const Color(0xFF3B82F6),
                      size: 14.r,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'QUEST HUB',
                    style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildSectionWrapper(
    BuildContext context,
    String title,
    String subtitle,
    QuestType type, {
    required dynamic user,
  }) {
    final color = GameHelper.getCategoryColor(type.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 32.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: _buildSectionHeader(
            context,
            title,
            subtitle,
            color,
            onSeeAll: () => context.push(
              '${AppRouter.categoryGamesRoute}?category=${type.name}',
            ),
          ),
        ),
        SizedBox(height: 16.h),
        CategoryShelf(
          user: user,
          subtypes: type.subtypes.where((s) => !s.isLegacy).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
    Color categoryColor, {
    VoidCallback? onSeeAll,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Color-coded indicator
        Container(
          width: 4.w,
          height: 36.h,
          decoration: BoxDecoration(
            color: categoryColor,
            borderRadius: BorderRadius.circular(2.r),
            boxShadow: [
              BoxShadow(
                color: categoryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        if (onSeeAll != null)
          ScaleButton(
            onTap: () {
              Haptics.vibrate(HapticsType.light);
              onSeeAll();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: categoryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                'SEE ALL',
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: categoryColor,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
