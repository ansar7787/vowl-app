import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/reward_limit_service.dart';
import 'package:vowl/core/utils/ad_service.dart';
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
  final ValueNotifier<String?> _selectedCategory = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();
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
    _selectedCategory.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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

      // Preserve the user's page unless it's now out of bounds
      final totalPages = (entries.length / 10).ceil();
      if (_currentPage.value >= totalPages && totalPages > 0) {
        _currentPage.value = totalPages - 1;
      } else if (totalPages == 0) {
        _currentPage.value = 0;
      }

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
              return ValueListenableBuilder<String?>(
                valueListenable: _selectedCategory,
                builder: (context, selectedCategory, _) {
                  final filteredEntries = selectedCategory == null
                      ? entries
                      : entries
                            .where(
                              (e) =>
                                  QuestRegistry.gameToCategory[e.gameType] ==
                                  selectedCategory,
                            )
                            .toList();

                  return ValueListenableBuilder<int>(
                    valueListenable: _currentPage,
                    builder: (context, currentPageIndex, _) {
                      final totalPages = (filteredEntries.length / 10).ceil();
                      final validPageIndex = currentPageIndex.clamp(
                        0,
                        (totalPages - 1).clamp(0, 999999),
                      );
                      final paginatedEntries = filteredEntries
                          .skip(validPageIndex * 10)
                          .take(10)
                          .toList();

                      return Stack(
                        children: [
                          RawScrollbar(
                            controller: _scrollController,
                            thumbColor: AppColors.indigo500.withValues(
                              alpha: 0.3,
                            ),
                            thickness: 6.w,
                            radius: Radius.circular(8.r),
                            interactive: true,
                            child: CustomScrollView(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              slivers: [
                                SliverAppBar(
                                  expandedHeight: 110.h,
                                  collapsedHeight: 60.h,
                                  pinned: true,
                                  backgroundColor: bgColor.withValues(
                                    alpha: 0.8,
                                  ),
                                  elevation: 0,
                                  scrolledUnderElevation: 0,
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
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    onPressed: () => context.pop(),
                                  ),
                                ),

                                if (!isLoading && entries.isNotEmpty)
                                  SliverToBoxAdapter(
                                    child: _buildFilterChips(
                                      context,
                                      entries,
                                      selectedCategory,
                                      isDark,
                                    ),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                                    _scrollToTop();
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
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
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
                                                    _scrollToTop();
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
                                        if (filteredEntries.isEmpty) return;
                                        
                                        final randomList = List.of(filteredEntries)..shuffle();
                                        final target = randomList.first;
                                        final cat = QuestRegistry.gameToCategory[target.gameType] ?? 'reading';
                                        
                                        di.sl<HapticService>().selection();

                                        if (!(await _checkMonetizationGate())) return;

                                        await _dismissMistake(target.id);

                                        final uri = Uri(
                                          path: '/game',
                                          queryParameters: {
                                            'category': cat,
                                            'subtype': target.gameType,
                                            'level': target.level.toString(),
                                          },
                                        );

                                        if (!context.mounted) return;
                                        await context.push(uri.toString());

                                        if (mounted) {
                                          _loadMistakes();
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.psychology_rounded,
                                      ),
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
                                        minimumSize: Size(
                                          double.infinity,
                                          56.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    );
                                    if (!VowlMotion.shouldReduceMotion(
                                      context,
                                    )) {
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

    final category = QuestRegistry.gameToCategory[entry.gameType] ?? 'reading';
    final categoryColor = _categoryColor(category);
    final humanName = ErrorJournalCollector.humanReadableName(entry.gameType);

    // Relative timestamp
    final timeAgo = entry.timestamp != null
        ? _relativeTime(entry.timestamp!)
        : '';

    Widget card = Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24.w),
        margin: EdgeInsets.only(bottom: 4.h),
        decoration: BoxDecoration(
          color: AppColors.red500.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: AppColors.red500,
          size: 28.r,
        ),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) {
        // Capture the entry before removing
        final dismissedEntry = entry;

        _dismissMistake(entry.id);

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr(
                  'profile.mistake_removed',
                  fallback: 'Mistake removed',
                ),
                style: const TextStyle(fontFamily: 'Outfit'),
              ),
              action: SnackBarAction(
                label: context.tr('general.undo', fallback: 'Undo'),
                onPressed: () {
                  // Re-record the entry to restore it
                  ErrorJournalCollector.record(
                    userId: _userId,
                    gameType: dismissedEntry.gameType,
                    question: dismissedEntry.question,
                    userAnswer: dismissedEntry.userAnswer,
                    correctAnswer: dismissedEntry.correctAnswer,
                    level: dismissedEntry.level,
                  );
                  _loadMistakes();
                },
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: ScaleButton(
        onTap: () async {
          di.sl<HapticService>().selection();

          if (!(await _checkMonetizationGate())) return;

          await _dismissMistake(entry.id);

          final uri = Uri(
            path: '/game',
            queryParameters: {
              'category': category,
              'subtype': entry.gameType,
              'level': entry.level.toString(),
            },
          );

          if (!mounted) return;
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
              // Top row: category badge + timestamp + level
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      humanName.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'Lv.${entry.level}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (timeAgo.isNotEmpty)
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                ],
              ),

              SizedBox(height: 12.h),

              // Question
              Text(
                entry.question,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 14.h),

              // Answers row
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
                context.tr(
                  'profile.correct_answer',
                  fallback: 'Correct answer:',
                ),
                cAnswer,
              ),

              SizedBox(height: 10.h),

              // Tap to replay hint
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    context.tr(
                      'profile.tap_to_replay',
                      fallback: 'Tap to replay',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 14.r,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                ],
              ),
            ],
          ),
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

  /// Returns a category-specific accent color for visual differentiation.
  Color _categoryColor(String category) {
    switch (category) {
      case 'accent':
        return AppColors.violet500;
      case 'grammar':
        return AppColors.indigo500;
      case 'listening':
        return AppColors.blue500;
      case 'reading':
        return AppColors.emerald500;
      case 'roleplay':
        return AppColors.amber500;
      case 'speaking':
        return AppColors.rose500;
      case 'vocabulary':
        return AppColors.teal500;
      case 'writing':
        return AppColors.orange500;
      case 'elite_mastery':
        return AppColors.red500;
      default:
        return AppColors.indigo500;
    }
  }

  /// Returns a human-readable relative time string.
  String _relativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
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

  Widget _buildFilterChips(
    BuildContext context,
    List<ErrorJournalEntry> allEntries,
    String? selectedCategory,
    bool isDark,
  ) {
    // Extract unique categories from entries
    final categories = allEntries
        .map((e) => QuestRegistry.gameToCategory[e.gameType])
        .whereType<String>()
        .toSet()
        .toList();

    if (categories.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Row(
        children: [
          _buildChip(
            context: context,
            label: context.tr('general.all', fallback: 'All'),
            isSelected: selectedCategory == null,
            color: AppColors.slate500,
            onTap: () {
              di.sl<HapticService>().selection();
              _selectedCategory.value = null;
              _currentPage.value = 0;
            },
            isDark: isDark,
          ),
          ...categories.map((cat) {
            final color = _categoryColor(cat);
            // Capitalize category name
            final name = cat[0].toUpperCase() + cat.substring(1);
            return Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: _buildChip(
                context: context,
                label: name,
                isSelected: selectedCategory == cat,
                color: color,
                onTap: () {
                  di.sl<HapticService>().selection();
                  _selectedCategory.value = cat;
                  _currentPage.value = 0;
                },
                isDark: isDark,
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<bool> _checkMonetizationGate() async {
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
    if (isPremium) return true;

    final hasReachedLimit = await RewardLimitService.hasReachedDailyLimit(
      'practice',
    );
    if (!hasReachedLimit) {
      await RewardLimitService.incrementClaimCount('practice');
      return true;
    }

    final unlocked = await _showMonetizationGate();
    return unlocked;
  }

  Future<bool> _showMonetizationGate() async {
    final completer = Completer<bool>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slate900 : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48.w,
                height: 6.h,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate700 : AppColors.slate200,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              SizedBox(height: 32.h),
              Icon(
                Icons.workspace_premium_rounded,
                size: 64.sp,
                color: AppColors.amber500,
              ),
              SizedBox(height: 24.h),
              Text(
                context.tr(
                  'practice.limit_reached',
                  fallback: 'Daily Limit Reached',
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  context.tr(
                    'practice.limit_desc',
                    fallback:
                        'You\'ve used your 5 free practice attempts today. Watch an ad to get 1 more, or go Premium for unlimited practice.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : AppColors.slate600,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 40.h),
              Container(
                width: double.infinity,
                height: 60.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  gradient: const LinearGradient(
                    colors: [AppColors.indigo500, AppColors.violet500],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo500.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20.r),
                    onTap: () {
                      final adService = di.sl<AdService>();
                      adService.showRewardedAd(
                        context: context,
                        isPremium: false,
                        childSafe: false,
                        onUserEarnedReward: (_) {
                          if (!completer.isCompleted) {
                            completer.complete(true);
                          }
                        },
                        onDismissed: () {
                          if (!completer.isCompleted) {
                            completer.complete(false);
                          }
                          context.pop();
                        },
                      );
                    },
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_circle_outline_rounded,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            context.tr(
                              'practice.watch_ad',
                              fallback: 'Watch Ad for +1',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                height: 60.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.amber500.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  color: AppColors.amber500.withValues(alpha: 0.05),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20.r),
                    onTap: () {
                      context.pop();
                      context.push('/premium');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.amber500,
                          size: 24.r,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          context.tr(
                            'practice.go_premium',
                            fallback: 'Unlock Premium',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.amber500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: () {
                  if (!completer.isCompleted) completer.complete(false);
                  context.pop();
                },
                child: Text(
                  context.tr('general.maybe_later', fallback: 'Maybe Later'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    color: isDark ? Colors.white60 : AppColors.slate500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    return completer.future;
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? AppColors.slate800 : Colors.white),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppColors.slate700 : AppColors.slate200),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
