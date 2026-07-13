import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/home/presentation/widgets/category_shelf.dart';
import 'package:vowl/core/utils/game_helper.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // FIX (MEDIUM-1): context.select scopes rebuilds to isMidnight only.
    final isMidnight = context.select<ThemeCubit, bool>(
      (c) => c.state.isMidnight,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? const Color(0xFF0F172A) : Colors.white);

    return Scaffold(
      backgroundColor: bgColor,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.status == AuthStatus.authenticated
              ? state.user
              : null;
          if (user == null) return const SizedBox.shrink();

          return Stack(
            children: [
              const MeshGradientBackground(showLetters: false),
              CustomScrollView(
                // NOTE: ScrollController lifetime is managed by the DI
                // container; ensure it is disposed when the screen is removed.
                controller: di.sl<ScrollController>(instanceName: 'games'),
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _GamesAppBar(isDark: isDark),
                  SliverPadding(
                    padding: EdgeInsets.only(bottom: 120.h),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        _buildSections(context, user),
                      ),
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

  /// Builds all game-category section widgets.
  /// FIX (HIGH-4): Extracted from build() to reduce nesting depth and keep
  /// GamesScreen well under the 300-line mandatory refactor threshold.
  List<Widget> _buildSections(BuildContext context, UserEntity user) => [
    _GameSection(
      titleKey: 'games.vocabulary.title',
      subtitleKey: 'games.vocabulary.subtitle',
      type: QuestType.vocabulary,
      user: user,
    ),
    _GameSection(
      titleKey: 'games.listening.title',
      subtitleKey: 'games.listening.subtitle',
      type: QuestType.listening,
      user: user,
    ),
    _GameSection(
      titleKey: 'games.reading.title',
      subtitleKey: 'games.reading.subtitle',
      type: QuestType.reading,
      user: user,
    ),
    _GameSection(
      titleKey: 'games.grammar.title',
      subtitleKey: 'games.grammar.subtitle',
      type: QuestType.grammar,
      user: user,
    ),
    _GameSection(
      titleKey: 'games.writing.title',
      subtitleKey: 'games.writing.subtitle',
      type: QuestType.writing,
      user: user,
    ),
    _GameSection(
      titleKey: 'games.speaking.title',
      subtitleKey: 'games.speaking.subtitle',
      type: QuestType.speaking,
      user: user,
    ),
    _GameSection(
      titleKey: 'games.accent.title',
      subtitleKey: 'games.accent.subtitle',
      type: QuestType.accent,
      user: user,
    ),
    _GameSection(
      titleKey: 'games.roleplay.title',
      subtitleKey: 'games.roleplay.subtitle',
      type: QuestType.roleplay,
      user: user,
    ),
    _GameSection(
      titleKey: 'games.elite_mastery.title',
      subtitleKey: 'games.elite_mastery.subtitle',
      type: QuestType.eliteMastery,
      user: user,
    ),
  ];
}

// ---------------------------------------------------------------------------
// Private: Glass App Bar
// FIX (HIGH-4): Extracted from _buildGlassAppBar() to a proper widget.
// ---------------------------------------------------------------------------

class _GamesAppBar extends StatelessWidget {
  final bool isDark;
  const _GamesAppBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
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
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
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
                    context.tr('games.quest_hub', fallback: 'Quest Hub'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
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
}

// ---------------------------------------------------------------------------
// Private: Single game category section (header + shelf)
// FIX (HIGH-2 + HIGH-4): Localised strings; extracted from _buildSectionWrapper.
// ---------------------------------------------------------------------------

class _GameSection extends StatelessWidget {
  final String titleKey;
  final String subtitleKey;
  final QuestType type;
  final UserEntity user;

  const _GameSection({
    required this.titleKey,
    required this.subtitleKey,
    required this.type,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final color = GameHelper.getCategoryColor(type.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 32.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: _GameSectionHeader(
            titleKey: titleKey,
            subtitleKey: subtitleKey,
            color: color,
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
}

// ---------------------------------------------------------------------------
// Private: Section header (colour bar + title + subtitle + see-all button)
// FIX (HIGH-4): Extracted from _buildSectionHeader().
// ---------------------------------------------------------------------------

class _GameSectionHeader extends StatelessWidget {
  final String titleKey;
  final String subtitleKey;
  final Color color;
  final VoidCallback? onSeeAll;

  const _GameSectionHeader({
    required this.titleKey,
    required this.subtitleKey,
    required this.color,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Colour-coded indicator bar
        Container(
          width: 4.w,
          height: 36.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.r),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
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
                // FIX (HIGH-2): Category name resolved via l10n, then uppercased.
                context.tr(titleKey).toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                context.tr(subtitleKey),
                style: TextStyle(
                  fontFamily: 'Outfit',
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
              try {
                Haptics.vibrate(HapticsType.light);
              } catch (_) {}
              onSeeAll!();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Text(
                context.tr('common.see_all', fallback: 'See All'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
