import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:shimmer/shimmer.dart';
import 'package:vowl/core/data/constants/quest_registry.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class ReviewMistakesScreen extends StatefulWidget {
  const ReviewMistakesScreen({super.key});

  @override
  State<ReviewMistakesScreen> createState() => _ReviewMistakesScreenState();
}

class _ReviewMistakesScreenState extends State<ReviewMistakesScreen> {
  final ValueNotifier<bool> _isLoading = ValueNotifier(true);
  final ValueNotifier<List<ErrorJournalEntry>> _entries = ValueNotifier([]);
  final ValueNotifier<int> _currentPage = ValueNotifier(0);
  late String _userId;

  @override
  void initState() {
    super.initState();
    _loadMistakes();
  }

  @override
  void dispose() {
    _isLoading.dispose();
    _entries.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  Future<void> _loadMistakes() async {
    _isLoading.value = true;

    final authState = context.read<AuthBloc>().state;
    _userId = authState.user?.id ?? 'local';

    final entries = await ErrorJournalCollector.fetch(
      userId: _userId,
      limit: 200, // Fetch more for pagination
    );

    if (mounted) {
      _entries.value = entries;
      // Reset to first page when loaded
      _currentPage.value = 0;
      _isLoading.value = false;
    }
  }

  Future<void> _dismissMistake(String id) async {
    await ErrorJournalCollector.dismiss(userId: _userId, entryId: id);
    if (mounted) {
      final current = List<ErrorJournalEntry>.from(_entries.value);
      current.removeWhere((e) => e.id == id);
      _entries.value = current;

      // Adjust current page if current page becomes empty
      final totalPages = (current.length / 10).ceil();
      if (_currentPage.value >= totalPages && totalPages > 0) {
        _currentPage.value = totalPages - 1;
      }
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.slate800 : Colors.white,
          title: Text(
            context.tr(
              'profile.clear_all_title',
              fallback: 'Clear All Mistakes?',
            ),
          ),
          content: Text(
            context.tr(
              'profile.clear_all_desc',
              fallback:
                  'This will permanently delete your entire error journal. You will not be able to practice these mistakes again.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.tr('general.cancel', fallback: 'Cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                context.tr('general.delete', fallback: 'Delete'),
                style: const TextStyle(color: AppColors.red500),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ErrorJournalCollector.clearAll(userId: _userId);
      if (mounted) {
        _entries.value = [];
        _currentPage.value = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        (isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black);
    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? AppColors.slate900 : AppColors.slate50);

    return Scaffold(
      backgroundColor: bgColor,
      body: ValueListenableBuilder<bool>(
        valueListenable: _isLoading,
        builder: (context, isLoading, _) {
          return ValueListenableBuilder<List<ErrorJournalEntry>>(
            valueListenable: _entries,
            builder: (context, entries, _) {
              return ValueListenableBuilder<int>(
                valueListenable: _currentPage,
                builder: (context, currentPageIndex, _) {
                  final totalPages = (entries.length / 10).ceil();
                  final validPageIndex = currentPageIndex.clamp(
                    0,
                    (totalPages - 1).clamp(0, 999999),
                  );
                  final paginatedEntries = entries
                      .skip(validPageIndex * 10)
                      .take(10)
                      .toList();

                  return Stack(
                    children: [
                      RawScrollbar(
                        thumbColor: AppColors.indigo500.withValues(alpha: 0.3),
                        thickness: 6.w,
                        radius: Radius.circular(8.r),
                        interactive: true,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          slivers: [
                            SliverAppBar(
                              expandedHeight: 110.h,
                              collapsedHeight: 60.h,
                              pinned: true,
                              backgroundColor: bgColor.withValues(alpha: 0.8),
                              elevation: 0,
                              surfaceTintColor: Colors.transparent,
                              flexibleSpace: ClipRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 16,
                                    sigmaY: 16,
                                  ),
                                  child: FlexibleSpaceBar(
                                    titlePadding: EdgeInsets.only(
                                      left: 56.w,
                                      bottom: 16.h,
                                      right: 16.w,
                                    ),
                                    title: Text(
                                      context.tr(
                                        'profile.review_mistakes',
                                        fallback: 'My Mistakes',
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    centerTitle: false,
                                  ),
                                ),
                              ),
                              leading: IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                onPressed: () => context.pop(),
                              ),
                              actions: [
                                if (entries.isNotEmpty && !isLoading)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_sweep_rounded,
                                      color: AppColors.red500,
                                    ),
                                    tooltip: context.tr(
                                      'profile.clear_all',
                                      fallback: 'Clear All',
                                    ),
                                    onPressed: _clearAll,
                                  ),
                              ],
                            ),

                            if (isLoading)
                              SliverPadding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 16.h,
                                ),
                                sliver: SliverList.separated(
                                  itemCount: 6,
                                  separatorBuilder: (_, _) =>
                                      SizedBox(height: 12.h),
                                  itemBuilder: (context, index) =>
                                      _buildShimmerItem(isDark),
                                ),
                              )
                            else if (entries.isEmpty)
                              SliverFillRemaining(
                                child: _buildEmptyState(context, isDark),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.only(
                                  left: 20.w,
                                  right: 20.w,
                                  top: 16.h,
                                  bottom: 16.h,
                                ),
                                sliver: SliverList.separated(
                                  itemCount: paginatedEntries.length,
                                  separatorBuilder: (_, _) =>
                                      SizedBox(height: 12.h),
                                  itemBuilder: (context, index) =>
                                      _buildMistakeCard(
                                        paginatedEntries[index],
                                        index,
                                        isDark,
                                      ),
                                ),
                              ),

                            if (entries.isNotEmpty &&
                                !isLoading &&
                                totalPages > 1)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: 16.h,
                                    bottom: 120.h,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.chevron_left_rounded,
                                        ),
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        onPressed: validPageIndex > 0
                                            ? () {
                                                _currentPage.value =
                                                    validPageIndex - 1;
                                                di
                                                    .sl<HapticService>()
                                                    .selection();
                                              }
                                            : null,
                                      ),
                                      SizedBox(width: 16.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 8.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.slate800
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? AppColors.slate700
                                                : AppColors.slate200,
                                          ),
                                        ),
                                        child: Text(
                                          '${validPageIndex + 1} / $totalPages',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.chevron_right_rounded,
                                        ),
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        onPressed:
                                            validPageIndex < totalPages - 1
                                            ? () {
                                                _currentPage.value =
                                                    validPageIndex + 1;
                                                di
                                                    .sl<HapticService>()
                                                    .selection();
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (entries.isNotEmpty && !isLoading)
                              SliverToBoxAdapter(
                                child: SizedBox(height: 120.h),
                              ),
                          ],
                        ),
                      ),

                      if (entries.isNotEmpty && !isLoading)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: Container(
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    bgColor,
                                    bgColor.withValues(alpha: 0.9),
                                    bgColor.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.5, 0.8, 1.0],
                                ),
                              ),
                              child: () {
                                Widget button = ElevatedButton.icon(
                                  onPressed: () async {
                                    // Pass ONLY the current paginated entries
                                    await context.push(
                                      '/practice-mistakes',
                                      extra: paginatedEntries,
                                    );
                                    if (mounted) {
                                      _loadMistakes();
                                    }
                                  },
                                  icon: const Icon(Icons.psychology_rounded),
                                  label: Text(
                                    context.tr(
                                      'profile.practice_weaknesses',
                                      fallback: 'Practice Weaknesses',
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.indigo500,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(double.infinity, 56.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    elevation: 0,
                                  ),
                                );
                                if (!VowlMotion.shouldReduceMotion(context)) {
                                  button = button
                                      .animate()
                                      .slideY(
                                        begin: 1,
                                        duration: 400.ms,
                                        curve: Curves.easeOut,
                                      )
                                      .fadeIn();
                                }
                                return button;
                              }(),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    Widget w = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_rounded, size: 64.r, color: AppColors.emerald500),
          SizedBox(height: 16.h),
          Text(
            context.tr(
              'profile.no_mistakes_title',
              fallback: "You're All Caught Up!",
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            context.tr(
              'profile.no_mistakes_subtitle',
              fallback: 'Your error journal is completely empty.',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
    if (!VowlMotion.shouldReduceMotion(context)) {
      w = w
          .animate()
          .scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack)
          .fadeIn();
    }
    return w;
  }

  Widget _buildShimmerItem(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.slate800 : Colors.grey[300]!,
      highlightColor: isDark ? AppColors.slate700 : Colors.grey[100]!,
      child: Container(
        height: 140.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );
  }

  Widget _buildMistakeCard(ErrorJournalEntry entry, int index, bool isDark) {
    final String uAnswer = entry.userAnswer.trim().isEmpty
        ? context.tr('profile.missed', fallback: 'Missed / No text')
        : entry.userAnswer;
    final String cAnswer = entry.correctAnswer.trim().isEmpty
        ? context.tr('profile.no_text', fallback: 'Visual match')
        : entry.correctAnswer;

    Widget card = ScaleButton(
      onTap: () async {
        di.sl<HapticService>().selection();

        final category =
            QuestRegistry.gameToCategory[entry.gameType] ?? 'reading';
        final uri = Uri(
          path: '/game',
          queryParameters: {
            'category': category,
            'subtype': entry.gameType,
            'level': entry.level.toString(),
          },
        );

        await context.push(uri.toString());

        if (mounted) {
          _loadMistakes();
        }
      },
      child: GlassTile(
        borderRadius: BorderRadius.circular(16.r),
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    entry.gameType.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.indigo500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _dismissMistake(entry.id),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.red500,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    context.tr('profile.remove_mistake', fallback: 'Remove'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              entry.question,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 16.h),
            _buildAnswerRow(
              context,
              Icons.close_rounded,
              AppColors.red500,
              context.tr('profile.you_answered', fallback: 'You answered:'),
              uAnswer,
            ),
            SizedBox(height: 8.h),
            _buildAnswerRow(
              context,
              Icons.check_rounded,
              AppColors.emerald500,
              context.tr('profile.correct_answer', fallback: 'Correct answer:'),
              cAnswer,
            ),
          ],
        ),
      ),
    );

    // Removed the dynamic delay index to eliminate lag during scroll
    if (!VowlMotion.shouldReduceMotion(context)) {
      return card
          .animate()
          .slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOutCubic)
          .fadeIn();
    }

    return card;
  }

  Widget _buildAnswerRow(
    BuildContext context,
    IconData icon,
    Color color,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.r, color: color),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
